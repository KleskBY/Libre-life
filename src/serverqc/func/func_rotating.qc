// Rotating brush functions
#define SF_BRUSH_ROTATE_Y_AXIS		0
#define SF_BRUSH_ROTATE_INSTANT		1
#define SF_BRUSH_ROTATE_BACKWARDS	2
#define SF_BRUSH_ROTATE_Z_AXIS		4
#define SF_BRUSH_ROTATE_X_AXIS		8
#define SF_PENDULUM_AUTO_RETURN		16
#define	SF_PENDULUM_PASSABLE		32
#define SF_BRUSH_ACCDCC				16
#define SF_BRUSH_HURT				32
#define SF_ROTATING_NOT_SOLID		64


#define SF_BRUSH_ROTATE_SMALLRADIUS	128
#define SF_BRUSH_ROTATE_MEDIUMRADIUS 256
#define SF_BRUSH_ROTATE_LARGERADIUS 512

// Sound constants
#define FANPITCHMIN   30
#define FANPITCHMAX  100

.float fanfriction;     // 0..?
.float sounds;          // 0..5 preset
.float attenuation;     // ATTN_*
.vector spawnorigin;    // "x y z" optional (if you can parse)

// store running sound path
.string noiseRunning;
void() FuncRotating_SpinUp;

void FuncRotating_Precache()
{
    string sz;

    // defaults
    if (self.volume == 0)
        self.volume = 1;

    sz = self.message;

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
        self.think = FuncRotating_SpinUp;
        self.nextthink = time + 1.5;
    }
}

// HurtTouch (SF_BRUSH_HURT)
// Damage is based on angular speed, and pushes the toucher away.
void FuncRotating_HurtTouch()
{
    entity o;
    vector dir;

    o = other;
    if (!o.takedamage)
        return;

    // approximate: damage = angspeed / 10
    float damage = vlen(self.avelocity) / 10;
    self.dmg = damage;

    if (o.th_pain)
    {
        entity oldself = self;
        self = o;
        o.th_pain(oldself, damage);
        self = oldself;
    }

    dir = normalize(o.origin - VecBModelOrigin(self));
    o.velocity = dir * damage;
}

// Ramp pitch/volume based on current angular velocity vs target.
// In QC we don’t have abs(vec) function; do component logic.
void FuncRotating_RampPitchVol(float fUp)
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
    fpct = Math_Clamp(fpct, 0, 1);

    fvol = self.volume * fpct;
    fpitch = FANPITCHMIN + (FANPITCHMAX - FANPITCHMIN) * fpct;
    Sound_Play(self, CHAN_STATIC, fvol, self.attenuation, PITCH_NORM, self.noiseRunning);
};

// SpinUp / SpinDown (SF_BRUSH_ACCDCC)
void FuncRotating_Rotate();

void FuncRotating_SpinUp()
{
    self.nextthink = time + 0.1;
    // accelerate
    self.avelocity = self.avelocity + (self.movedir * (self.speed * self.fanfriction));
    vector av = self.avelocity;

    // reached target?
    if (fabs(av_x) >= fabs(self.movedir_x * self.speed) &&
        fabs(av_y) >= fabs(self.movedir_y * self.speed) &&
        fabs(av_z) >= fabs(self.movedir_z * self.speed))
    {
        self.avelocity = self.movedir * self.speed;
        Sound_Play(self, CHAN_STATIC, self.volume, self.attenuation, PITCH_NORM, self.noiseRunning);

        self.think = FuncRotating_Rotate;
        FuncRotating_Rotate();
        return;
    }

    FuncRotating_RampPitchVol(1);
}

void FuncRotating_SpinDown()
{
    float axisdir;

    self.nextthink = time + 0.1;

    // decelerate
    self.avelocity = self.avelocity - (self.movedir * (self.speed * self.fanfriction));

    vector av = self.avelocity;

    // determine sign of axis
    if (self.movedir_x != 0) axisdir = self.movedir_x;
    else if (self.movedir_y != 0) axisdir = self.movedir_y;
    else axisdir = self.movedir_z;

    // stop when we cross/meet zero in all axes
    if ((axisdir > 0 && av_x <= 0 && av_y <= 0 && av_z <= 0) ||
        (axisdir < 0 && av_x >= 0 && av_y >= 0 && av_z >= 0))
    {
        self.avelocity = '0 0 0';

        Sound_Emit(self, CHAN_STATIC, self.noiseRunning, 0, 0, self.pitch, 0);

        self.think = FuncRotating_Rotate;
        FuncRotating_Rotate();
        return;
    }

    FuncRotating_RampPitchVol(0);
}

void FuncRotating_Rotate()
{
    self.nextthink = time + 10;
}

void FuncRotating_DispatchUse()
{
    if (self.usehl) self.usehl(self, self, USE_TOGGLE, 0);
    else if (self.use) self.use();
}

void FuncRotating_CallUse()
{
    entity stemp, otemp;
    stemp = self; otemp = other;
    other = world;
    FuncRotating_DispatchUse();
    other = otemp;
    self = stemp;
}

void FuncRotating_Use()
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
            Sound_Play(self, CHAN_STATIC, 0.01, self.attenuation, PITCH_NORM, self.noiseRunning);
            self.think = FuncRotating_SpinUp;
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

    Sound_Play(self, CHAN_STATIC, self.volume, self.attenuation, PITCH_NORM, self.noiseRunning);
    self.avelocity = self.movedir * self.speed;
    self.think = FuncRotating_Rotate;
    FuncRotating_Rotate();
};

void FuncRotating_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (self.spawnflags & SF_BRUSH_ACCDCC)
    {
        if (self.avelocity != '0 0 0')
        {
            self.think = FuncRotating_SpinDown;
            self.nextthink = time + 0.1;
        }
        else
        {
            Sound_Play(self, CHAN_STATIC, 0.01, self.attenuation, PITCH_NORM, self.noiseRunning);
            self.think = FuncRotating_SpinUp;
            self.nextthink = time + 0.1;
        }
        return;
    }

    if (self.avelocity != '0 0 0')
    {
        self.think = FuncRotating_SpinDown;
        self.nextthink = time + 0.1;
        return;
    }

    Sound_Play(self, CHAN_STATIC, self.volume, self.attenuation, PITCH_NORM, self.noiseRunning);
    self.avelocity = self.movedir * self.speed;
    self.think = FuncRotating_Rotate;
    FuncRotating_Rotate();
}

void FuncRotating_Blocked()
{
    if (Blocked_IgnorePhantom(other))
        return;

    if (Blocked_DisposeDebris(other))
        return;

    if (other && other.takedamage)
    {
		T_Damage(other, self, self, self.dmg);
    }
};

void func_rotating()
{
    self.pitch = PITCH_NORM - 1;

    if (self.volume == 0) self.volume = 1;
    else self.volume = Math_Clamp(self.volume / 10, 0, 1);	// Volume (10=loudest) key

    // attenuation selection
    self.attenuation = ATTN_NORM;
    if (self.spawnflags & SF_BRUSH_ROTATE_SMALLRADIUS) self.attenuation = ATTN_IDLE;
    else if (self.spawnflags & SF_BRUSH_ROTATE_MEDIUMRADIUS) self.attenuation = ATTN_STATIC;
    else if (self.spawnflags & SF_BRUSH_ROTATE_LARGERADIUS) self.attenuation = ATTN_NORM;

    // friction default (stores fanfriction as raw/100; prevent divide-by-zero if unset)
    if (self.fanfriction == 0) self.fanfriction = 1;
    else self.fanfriction = self.fanfriction / 100;

    if (self.spawnflags & SF_BRUSH_ROTATE_Z_AXIS) self.movedir = '0 0 1';
    else if (self.spawnflags & SF_BRUSH_ROTATE_X_AXIS) self.movedir = '1 0 0';
    else self.movedir = '0 1 0'; // y-axis

    if (self.spawnflags & SF_BRUSH_ROTATE_BACKWARDS)
        self.movedir = self.movedir * -1;

    if (self.spawnflags & SF_ROTATING_NOT_SOLID)
    {
        self.solid = SOLID_NOT;
        self.movetype = MOVETYPE_PUSH;
		//self.skin = CONTENTS_EMPTY;
    }
    else
    {
        self.solid = SOLID_BSP;
        self.movetype = MOVETYPE_PUSH;
    }

    if (self.spawnorigin) setorigin(self, self.spawnorigin);
    setmodel(self, self.model);

    self.use = FuncRotating_Use;
    self.usehl = FuncRotating_UseHL;
    if (self.speed < 0) self.speed = 0;

    if (self.spawnflags & SF_BRUSH_ROTATE_INSTANT)
    {
        self.think = FuncRotating_CallUse;
        self.nextthink = self.ltime + 1.5;
    }

    if (self.spawnflags & SF_BRUSH_HURT)
        self.touch = FuncRotating_HurtTouch;

    self.blocked = FuncRotating_Blocked;

    FuncRotating_Precache();
    Render_Apply(self);
    Brush_ApplyContents(self);

};
