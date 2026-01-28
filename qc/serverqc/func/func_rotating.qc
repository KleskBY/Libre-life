// -----------------------------------------------------------------------------
// FuncRotating (Half-Life style) - QuakeC port
// -----------------------------------------------------------------------------
// Spawnflags (you MUST align these with your project definitions)
// The names match HL intent; values here are placeholders.
// -----------------------------------------------------------------------------
#define SF_BRUSH_ROTATE_Y_AXIS		0
#define SF_BRUSH_ROTATE_INSTANT		1
#define SF_BRUSH_ROTATE_BACKWARDS	2
#define SF_BRUSH_ROTATE_Z_AXIS		4
#define SF_BRUSH_ROTATE_X_AXIS		8
#define SF_PENDULUM_AUTO_RETURN		16
#define	SF_PENDULUM_PASSABLE		32
#define SF_BRUSH_ACCDCC				16// brush should accelerate and decelerate when toggled
#define SF_BRUSH_HURT				32// rotating brush that inflicts pain based on rotation speed
#define SF_ROTATING_NOT_SOLID		64	// some special rotating objects are not solid.


#define SF_BRUSH_ROTATE_SMALLRADIUS	128
#define SF_BRUSH_ROTATE_MEDIUMRADIUS 256
#define SF_BRUSH_ROTATE_LARGERADIUS 512

// Sound constants
#define FANPITCHMIN   30
#define FANPITCHMAX  100

// -----------------------------------------------------------------------------
// Custom fields (map keys)
// fanfriction = m_flFanFriction (HL divides by 100)
// Volume      = m_flVolume (HL divides by 10, clamps 0..1)
// sounds      = m_sounds (preset)
// spawnorigin = optional origin override (string)
// -----------------------------------------------------------------------------
.float fanfriction;     // 0..?
.float volume;          // 0..1
.float sounds;          // 0..5 preset
.float pitch;           // current pitch (HL: PITCH_NORM-1)
.float attenuation;     // ATTN_*
.string spawnorigin;    // "x y z" optional (if you can parse)

// store running sound path
.string noiseRunning;
void() FuncRotating_spinup;
// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

float(float x, float a, float b) clampf =
{
    if (x < a) return a;
    if (x > b) return b;
    return x;
}

// Best-effort bmodel origin (center); for many QC engines self.origin is fine.
// If you already have VecBModelOrigin() in your codebase, use that instead.
vector(entity e) VecBModelOrigin_QC =
{
    return e.origin + (e.mins + e.maxs) * 0.5;
}

// Optional: parse "x y z" into vector. Only works if your engine supports argv/stof.
// If not, just ignore spawnorigin, or set origin in the map.
vector(string s) StringToVector_Optional =
{
    vector v;
    // Many QC environments don't have tokenize/argv. Replace with your own if needed.
    // FTE/DP often have tokenizebyseparator / argv / stof.
    // We'll assume tokenize(s) exists; if not, remove spawnorigin support.
    tokenizebyseparator(s, " ");
    v_x = stof(argv(0));
    v_y = stof(argv(1));
    v_z = stof(argv(2));
    return v;
}

// -----------------------------------------------------------------------------
// Sound selection (HL Precache logic)
// HL uses pev->message as custom wav path.
// We'll use self.message too.
// -----------------------------------------------------------------------------
void() FuncRotating_precache =
{
    string sz;

    // defaults
    if (self.volume == 0)
        self.volume = 1;

    sz = self.message; // HL: pev->message for override sound path

    if (sz != "")
    {
        precache_sound(sz);
        self.noiseRunning = sz;
    }
    else
    {
        if (self.sounds == 1) { precache_sound("fans/fan1.wav"); self.noiseRunning = "fans/fan1.wav"; }
        else if (self.sounds == 2) { precache_sound("fans/fan2.wav"); self.noiseRunning = "fans/fan2.wav"; }
        else if (self.sounds == 3) { precache_sound("fans/fan3.wav"); self.noiseRunning = "fans/fan3.wav"; }
        else if (self.sounds == 4) { precache_sound("fans/fan4.wav"); self.noiseRunning = "fans/fan4.wav"; }
        else if (self.sounds == 5) { precache_sound("fans/fan5.wav"); self.noiseRunning = "fans/fan5.wav"; }
        else self.noiseRunning = "common/null.wav";
    }

    // If already spinning (save/restore/transition), restart sound after delay
    if (self.avelocity != '0 0 0')
    {
        self.think = FuncRotating_spinup;
        self.nextthink = time + 1.5;
    }
}

// -----------------------------------------------------------------------------
// HurtTouch (SF_BRUSH_HURT)
// Damage is based on angular speed, and pushes the toucher away.
// -----------------------------------------------------------------------------
void() FuncRotating_hurttouch =
{
    entity o;
    vector dir;

    o = other;
    if (!o.takedamage)
        return;

    // approximate: damage = angspeed / 10
    float damage = vlen(self.avelocity) / 10;
    self.dmg = damage;

    // You likely have a custom damage system; if not, this is placeholder:
    if (o.th_pain) o.th_pain(self, damage);

    dir = normalize(o.origin - VecBModelOrigin_QC(self));
    o.velocity = dir * damage;
}

// -----------------------------------------------------------------------------
// Ramp pitch/volume based on current angular velocity vs target.
// In QC we don’t have abs(vec) function; do component logic.
// -----------------------------------------------------------------------------
void(float fUp) FuncRotating_ramppitchvol =
{
    vector av;
    float cur, final, fpct;
    float fvol, fpitch;

    av = self.avelocity;

    // current "speed" along axis
    if (av_x != 0) cur = fabs(av_x);
    else if (av_y != 0) cur = fabs(av_y);
    else cur = fabs(av_z);

    // final target speed along axis
    if (self.movedir_x != 0) final = fabs(self.movedir_x * self.speed);
    else if (self.movedir_y != 0) final = fabs(self.movedir_y * self.speed);
    else final = fabs(self.movedir_z * self.speed);

    if (final <= 0)
        return;

    fpct = cur / final;
    fpct = clampf(fpct, 0, 1);

    // HL uses slowdown volume ramps down to 0 (spinup variant commented out)
    fvol = self.volume * fpct;
    fpitch = FANPITCHMIN + (FANPITCHMAX - FANPITCHMIN) * fpct;
    sound(self, CHAN_STATIC, self.noiseRunning, fvol, self.attenuation);
};

// -----------------------------------------------------------------------------
// SpinUp / SpinDown (SF_BRUSH_ACCDCC)
// -----------------------------------------------------------------------------
void() FuncRotating_rotate;

void() FuncRotating_spinup =
{
    vector av;

    self.nextthink = time + 0.1;

    // accelerate
    self.avelocity = self.avelocity + (self.movedir * (self.speed * self.fanfriction));

    av = self.avelocity;

    // reached target?
    if (fabs(av_x) >= fabs(self.movedir_x * self.speed) &&
        fabs(av_y) >= fabs(self.movedir_y * self.speed) &&
        fabs(av_z) >= fabs(self.movedir_z * self.speed))
    {
        self.avelocity = self.movedir * self.speed;
        sound(self, CHAN_STATIC, self.noiseRunning, self.volume, self.attenuation);

        self.think = FuncRotating_rotate;
        FuncRotating_rotate();
        return;
    }

    FuncRotating_ramppitchvol(1);
}

void() FuncRotating_SpinDown =
{
    vector av;
    float axisdir;

    self.nextthink = time + 0.1;

    // decelerate
    self.avelocity = self.avelocity - (self.movedir * (self.speed * self.fanfriction));

    av = self.avelocity;

    // determine sign of axis
    if (self.movedir_x != 0) axisdir = self.movedir_x;
    else if (self.movedir_y != 0) axisdir = self.movedir_y;
    else axisdir = self.movedir_z;

    // stop when we cross/meet zero in all axes (HL-ish)
    if ((axisdir > 0 && av_x <= 0 && av_y <= 0 && av_z <= 0) ||
        (axisdir < 0 && av_x >= 0 && av_y >= 0 && av_z >= 0))
    {
        self.avelocity = '0 0 0';

#ifdef HAVE_EMIT_SOUND_DYN
        EMIT_SOUND_DYN(self, CHAN_STATIC, self.noiseRunning, 0, 0, SND_STOP, self.pitch);
#endif

        self.think = FuncRotating_rotate;
        FuncRotating_rotate();
        return;
    }

    FuncRotating_ramppitchvol(0);
};

// -----------------------------------------------------------------------------
// Rotate idle think
// -----------------------------------------------------------------------------
void() FuncRotating_rotate =
{
    self.nextthink = time + 10;
};

// -----------------------------------------------------------------------------
// Instant-use callback (HL: SUB_CallUseToggle)
// In QC, just call self.use with a safe context.
// -----------------------------------------------------------------------------
void() FuncRotating_calluse =
{
    entity stemp, otemp;
    stemp = self; otemp = other;
    other = world;
    self.use();
    other = otemp;
    self = stemp;

    self.think = SUB_Null;
    self.nextthink = -1;
};

// -----------------------------------------------------------------------------
// Use handler
// -----------------------------------------------------------------------------
void() FuncRotating_use =
{
    // Fan accel/decel mode
    if (self.spawnflags & SF_BRUSH_ACCDCC)
    {
        if (self.avelocity != '0 0 0')
        {
            self.think = FuncRotating_SpinDown;
            self.nextthink = time + 0.1;
        }
        else
        {
            sound(self, CHAN_STATIC, self.noiseRunning, 0.01, self.attenuation);
            self.think = FuncRotating_spinup;
            self.nextthink = time + 0.1;
        }
        return;
    }

    // Normal start/stop (no ramp)
    if (self.avelocity != '0 0 0')
    {
        self.think = FuncRotating_SpinDown;
        self.nextthink = time + 0.1;
        return;
    }

    sound(self, CHAN_STATIC, self.noiseRunning, self.volume, self.attenuation);
    self.avelocity = self.movedir * self.speed;
    self.think = FuncRotating_rotate;
    FuncRotating_rotate();
};

// -----------------------------------------------------------------------------
// Blocked: crush damage
// -----------------------------------------------------------------------------
void() FuncRotating_blocked =
{
    if (other && other.takedamage)
    {
		T_Damage(other, self, self, self.dmg);
    }
};

// -----------------------------------------------------------------------------
// Spawn
// -----------------------------------------------------------------------------
void func_rotating()
{
    // HL: m_pitch = PITCH_NORM - 1
    self.pitch = PITCH_NORM - 1; // close enough; tweak if you have PITCH_NORM

    // defaults compatible with HL
    if (self.volume == 0) self.volume = 1;
    self.volume = clampf(self.volume, 0, 1);

    // attenuation selection
    self.attenuation = ATTN_NORM;
    if (self.spawnflags & SF_BRUSH_ROTATE_SMALLRADIUS) self.attenuation = ATTN_IDLE;
    else if (self.spawnflags & SF_BRUSH_ROTATE_MEDIUMRADIUS) self.attenuation = ATTN_STATIC;
    else if (self.spawnflags & SF_BRUSH_ROTATE_LARGERADIUS) self.attenuation = ATTN_NORM;

    // friction default
    if (self.fanfriction == 0) self.fanfriction = 1;

    // axis selection (HL: Z default, but their flags differ; match your flag mapping!)
    if (self.spawnflags & SF_BRUSH_ROTATE_Z_AXIS) self.movedir = '0 0 1';
    else if (self.spawnflags & SF_BRUSH_ROTATE_X_AXIS) self.movedir = '1 0 0';
    else self.movedir = '0 1 0'; // y-axis

    // reverse rotation
    if (self.spawnflags & SF_BRUSH_ROTATE_BACKWARDS)
        self.movedir = self.movedir * -1;

    // solidity
    if (self.spawnflags & SF_ROTATING_NOT_SOLID)
    {
        self.solid = SOLID_NOT;
        self.movetype = MOVETYPE_PUSH;
    }
    else
    {
        self.solid = SOLID_BSP;
        self.movetype = MOVETYPE_PUSH;
    }

    // optional spawnorigin override (if you can parse)
    if (self.spawnorigin != "")
    {
        // If your QC doesn't have tokenizebyseparator/stof, remove this block.
        vector tmp;
        tmp = StringToVector_Optional(self.spawnorigin);
        if (tmp != '0 0 0')
            setorigin(self, tmp);
    }

    setmodel(self, self.model);

    // Use handler
    self.use = FuncRotating_use;

    // "did level designer forget to assign speed?"
    if (self.speed < 0) self.speed = 0;

    // instant-use brush
    if (self.spawnflags & SF_BRUSH_ROTATE_INSTANT)
    {
        self.think = FuncRotating_calluse;
        self.nextthink = time + 1.5;
    }

    // Hurt touch
    if (self.spawnflags & SF_BRUSH_HURT)
        self.touch = FuncRotating_hurttouch;

    // Blocked
    self.blocked = FuncRotating_blocked;

    FuncRotating_precache();


	// start immediately as "normal" start (no ramp unless ACCDCC)
	self.use();
    
};
