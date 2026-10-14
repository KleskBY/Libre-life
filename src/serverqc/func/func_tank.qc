
#define SF_TANK_ACTIVE        0x0001
#define SF_TANK_PLAYER        0x0002
#define SF_TANK_HUMANS        0x0004
#define SF_TANK_ALIENS        0x0008
#define SF_TANK_LINEOFSIGHT   0x0010
#define SF_TANK_CANCONTROL    0x0020
#define SF_TANK_SOUNDON       0x8000

#define TANK_BULLET_NONE  0
#define TANK_BULLET_9MM   1
#define TANK_BULLET_MP5   2
#define TANK_BULLET_12MM  3

vector g_tankSpreadPerfect      = '0 0 0';
vector g_tankSpreadSmall        = '0.025 0.025 0.025';
vector g_tankSpreadMedium       = '0.05  0.05  0.05';
vector g_tankSpreadLarge        = '0.1   0.1   0.1';
vector g_tankSpreadExtraLarge   = '0.25  0.25  0.25';
#define TANK_MAX_FIRING_SPREADS 5

vector FuncTank_GetSpread(float idx)
{
    if (idx <= 0) return g_tankSpreadPerfect;
    if (idx == 1) return g_tankSpreadSmall;
    if (idx == 2) return g_tankSpreadMedium;
    if (idx == 3) return g_tankSpreadLarge;
    return g_tankSpreadExtraLarge;
}

float FuncTank_DefaultBulletDamage(float bulletType)
{
    if (bulletType == TANK_BULLET_9MM)  return 8;
    if (bulletType == TANK_BULLET_MP5)  return 5;
    if (bulletType == TANK_BULLET_12MM) return 14;
    return 0;
}

entity Sprite_Create(string pSpriteName, vector origin, float animate);    // env_sprite.qc (later in .src)
void FuncTank_Think();
void FuncTank_TrackTarget();
void FuncTank_Use();
void FuncTank_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg);
void FuncTank_StartControl(entity pController);
void FuncTank_StopControl();
void FuncTank_ControllerPostFrame();
void FuncTank_StartRotSound();
void FuncTank_StopRotSound();
void FuncTank_BaseFireFX(vector barrelEnd);
void FuncTankGun_Fire(vector barrelEnd, vector forward, entity attacker);


vector FuncTank_BarrelPosition(entity t)
{
    makevectors(t.angles);
    return t.origin
        + v_forward * t.m_barrelPos_x
        + v_right   * t.m_barrelPos_y
        + v_up      * t.m_barrelPos_z;
}

float FuncTank_IsActive()  { return (self.spawnflags & SF_TANK_ACTIVE) ? TRUE : FALSE; }
float FuncTank_InRange(float range)
{
    if (range < self.minRange) return FALSE;
    if (self.maxRange > 0 && range > self.maxRange) return FALSE;
    return TRUE;
}
float FuncTank_CanFire() { return (time - self.tank_lastSightTime) < self.persistence; }

void FuncTank_TankActivate()
{
    self.spawnflags = self.spawnflags | SF_TANK_ACTIVE;
    self.nextthink = self.ltime + 0.1;
    self.tank_fireLast = 0;
}

void FuncTank_TankDeactivate()
{
    self.spawnflags = self.spawnflags - (self.spawnflags & SF_TANK_ACTIVE);
    self.tank_fireLast = 0;
    FuncTank_StopRotSound();
}

vector FuncTank_AdjustAnglesForBarrel(vector aim, float distance)
{
    float r2, d2;

    if (self.m_barrelPos_y != 0 || self.m_barrelPos_z != 0)
    {
        distance = distance - self.m_barrelPos_z;
        d2 = distance * distance;
        if (self.m_barrelPos_y)
        {
            r2 = self.m_barrelPos_y * self.m_barrelPos_y;
            aim_y = aim_y + (180.0 / 3.14159265) * atan2(self.m_barrelPos_y, sqrt(d2 - r2));
        }
        if (self.m_barrelPos_z)
        {
            r2 = self.m_barrelPos_z * self.m_barrelPos_z;
            aim_x = aim_x + (180.0 / 3.14159265) * atan2(-self.m_barrelPos_z, sqrt(d2 - r2));
        }
    }
    return aim;
}

// Returns the impact point in trace_endpos via globals (caller reads).
vector FuncTank_TankTrace(vector vecStart, vector vecForward, vector vecSpread)
{
    float x, y, z;
    do {
        x = random(-0.5, 0.5) + random(-0.5, 0.5);
        y = random(-0.5, 0.5) + random(-0.5, 0.5);
        z = x*x + y*y;
    } while (z > 1);

    vector vecDir = vecForward
        + x * vecSpread_x * v_right
        + y * vecSpread_y * v_up;

    vector vecEnd = vecStart + vecDir * 4096;
    traceline(vecStart, vecEnd, FALSE, self);
    return trace_endpos;
}

entity FuncTank_FindPlayer()
{
    entity p = find(world, classname, "player");
    while (p)
    {
        if (p.deadflag == DEAD_NO && checkpvs(self.origin, p))
            return p;
        p = find(p, classname, "player");
    }
    return world;
}

void FuncTank_StartRotSound()
{
    if (!self.noise || self.noise == "") return;
    if (self.spawnflags & SF_TANK_SOUNDON) return;
    self.spawnflags = self.spawnflags | SF_TANK_SOUNDON;
    Sound_Play(self, CHAN_STATIC, 0.85, ATTN_NORM, PITCH_NORM, self.noise);
}

void FuncTank_StopRotSound()
{
    if (self.spawnflags & SF_TANK_SOUNDON)
    {
        if (self.noise && self.noise != "")
            Sound_Play(self, CHAN_STATIC, 0, ATTN_NORM, PITCH_NORM, "common/null.wav");
    }
    self.spawnflags = self.spawnflags - (self.spawnflags & SF_TANK_SOUNDON);
}

void FuncTank_BaseFireFX(vector barrelEnd)
{
    if (self.tank_fireLast != 0)
    {
        if (self.spritesmoke && self.spritesmoke != "")
        {
            entity smoke = Sprite_Create(self.spritesmoke, barrelEnd, TRUE);
            smoke.velocity_z = random(40, 80);
            smoke.scale = self.spritescale;
            smoke.alpha = 1.0;
            smoke.rendercolor = self.rendercolor;
            smoke.think = SUB_Remove;
            smoke.nextthink = time + random(0.6, 1.2);
        }
        if (self.spriteflash && self.spriteflash != "")
        {
            entity flash = Sprite_Create(self.spriteflash, barrelEnd, TRUE);
            flash.scale = self.spritescale;
            flash.effects = flash.effects | EF_FULLBRIGHT | EF_ADDITIVE;
            flash.think = SUB_Remove;
            flash.nextthink = time + 0.1;
        }
        SUB_UseTargetsHL(self, USE_TOGGLE, 0);
    }
    self.tank_fireLast = time;
}


void FuncTank_PlayFireSoundAt(vector pos, string snd)
{
    if (!snd || snd == "") return;
    entity e = spawn();
    e.classname = "func_tank_soundsrc";
    e.solid     = SOLID_NOT;
    e.movetype  = MOVETYPE_NONE;
    setorigin(e, pos);
    Sound_Play(e, CHAN_WEAPON, 1.0, ATTN_NORM, PITCH_NORM, snd);
    e.think     = SUB_Remove;
    e.nextthink = time + 1.5;
}

string FuncTank_PickFireSound(float bulletType)
{
    float r;
    if (bulletType == TANK_BULLET_9MM)
    {
        r = floor(random() * 2);
        if (r == 0) return "weapons/pl_gun3.wav";
        return "weapons/pl_gun1.wav";
    }
    if (bulletType == TANK_BULLET_MP5)
    {
        r = floor(random() * 3);
        if (r == 0) return "weapons/hks1.wav";
        if (r == 1) return "weapons/hks2.wav";
        return "weapons/hks3.wav";
    }
    if (bulletType == TANK_BULLET_12MM) return "weapons/357_shot1.wav";
    return "";
}

// Tracer streak from barrel toward impact. MF_TRACER2 = orange split trail.
#define FUNCTANK_TRACER_SPEED 6000
void FuncTank_SpawnTracer(vector start, vector end)
{
    vector dir = end - start;
    float dist = vlen(dir);
    if (dist <= 0) return;
    dir = dir * (1 / dist);

    entity tr = spawn();
    tr.classname  = "func_tank_tracer";
    tr.owner      = self;
    tr.movetype   = MOVETYPE_FLY;
    tr.solid      = SOLID_NOT;
    setmodel(tr, "models/shell.iqm");
    setsize(tr, '0 0 0', '0 0 0');
    setorigin(tr, start);
    tr.angles     = vectoangles(dir);
    tr.velocity   = dir * FUNCTANK_TRACER_SPEED;
    tr.modelflags = MF_TRACER2;
    tr.effects    = EF_ADDITIVE | EF_FULLBRIGHT;
    tr.think      = SUB_Remove;
    tr.nextthink  = time + dist / FUNCTANK_TRACER_SPEED;
}

void FuncTank_FireBullet(vector start, vector dir, vector spread, float dmg)
{
    // Caller has already called makevectors(self.angles).
    vector cone = dir
        + (random() * 2 - 1) * spread_x * v_right
        + (random() * 2 - 1) * spread_y * v_up;

    vector end = start + cone * 4096;
    traceline(start, end, FALSE, self);

    FuncTank_SpawnTracer(start, trace_endpos);
    FuncTank_PlayFireSoundAt(start, FuncTank_PickFireSound(self.bullet));

    if (trace_fraction != 1.0)
    {
        if (trace_ent && trace_ent.takedamage)
            T_Damage(trace_ent, self, self, dmg, DMG_BULLET);
        else
            te_gunshot(trace_endpos);
    }
}

void FuncTankGun_Fire(vector barrelEnd, vector forward, entity attacker)
{
    if (self.tank_fireLast != 0)
    {
        makevectors(self.angles);
        float bulletCount = floor((time - self.tank_fireLast) * self.firerate);
        if (bulletCount > 0)
        {
            float dmg = self.bullet_damage;
            if (dmg <= 0) dmg = FuncTank_DefaultBulletDamage(self.bullet);

            vector spread = FuncTank_GetSpread(self.firespread);
            float i;
            for (i = 0; i < bulletCount; i = i + 1)
            {
                if (self.bullet == TANK_BULLET_NONE) break;
                FuncTank_FireBullet(barrelEnd, forward, spread, dmg);
            }
            FuncTank_BaseFireFX(barrelEnd);
        }
    }
    else
    {
        FuncTank_BaseFireFX(barrelEnd);
    }
}


float FuncTank_OnControls(entity pevTest)
{
    if (!(self.spawnflags & SF_TANK_CANCONTROL)) return FALSE;
    return vlen(self.tank_controllerUsePos - pevTest.origin) < 30;
}

void FuncTank_StartControl(entity pController)
{
    if (self.tank_controller) return;

    if (self.master && self.master != "")
    {
        if (!Master_IsTriggered(self.master, pController))
            return;
    }

    self.tank_controller = pController;
    pController.tank_ent = self;
    self.tank_controllerUsePos = pController.origin;
    self.nextthink = self.ltime + 0.1;
}

void FuncTank_StopControl()
{
    if (!self.tank_controller) return;
    self.tank_controller.tank_ent = world;
    self.tank_controller = world;
    self.nextthink = 0;
    if (FuncTank_IsActive())
        self.nextthink = self.ltime + 1.0;
}

void FuncTank_ControllerPostFrame()
{
    if (!self.tank_controller) return;
    if (time < self.m_flNextAttack) return;

    if (self.tank_controller.button0)
    {
        makevectors(self.angles);
        vector vecForward = v_forward;
        self.tank_fireLast = time - (1 / self.firerate) - 0.01;

        if (self.tankFire)
            self.tankFire(FuncTank_BarrelPosition(self), vecForward, self.tank_controller);
        else
            FuncTank_BaseFireFX(FuncTank_BarrelPosition(self));

        self.m_flNextAttack = time + (1 / self.firerate);
    }
}


void FuncTank_TrackTarget()
{
    vector aim, direction, targetPosition, barrelEnd;
    entity pTarget = world;
    float updateTime = FALSE;
    float lineOfSight = FALSE;
    float range = 0;

    if (self.tank_controller)
    {
        // Mirror controller's view angles
        aim = self.tank_controller.v_angle;
        aim_x = 0 - aim_x;
        self.nextthink = self.ltime + 0.05;
    }
    else
    {
        if (FuncTank_IsActive())
            self.nextthink = self.ltime + 0.1;
        else
            return;

        pTarget = FuncTank_FindPlayer();
        if (!pTarget)
        {
            if (FuncTank_IsActive())
                self.nextthink = self.ltime + 2;     // wait 2s
            return;
        }

        barrelEnd = FuncTank_BarrelPosition(self);
        targetPosition = pTarget.origin + pTarget.view_ofs;
        range = vlen(targetPosition - barrelEnd);

        if (!FuncTank_InRange(range)) return;

        traceline(barrelEnd, targetPosition, FALSE, self);
        if (trace_fraction == 1.0 || trace_ent == pTarget)
        {
            lineOfSight = TRUE;
            if (FuncTank_InRange(range) && pTarget.health > 0)
            {
                updateTime = TRUE;
                self.tank_sightOrigin = targetPosition;
            }
        }

        direction = self.tank_sightOrigin - self.origin;
        aim = vectoangles(direction);
        aim = FuncTank_AdjustAnglesForBarrel(aim, vlen(direction));
    }

    aim_x = -aim_x;

    // Clamp to range around center (yaw)
    aim_y = self.tank_yawCenter + Math_AngleDistance(aim_y, self.tank_yawCenter);
    aim_x = self.tank_pitchCenter + Math_AngleDistance(aim_x, self.tank_pitchCenter);

    if (aim_y > self.tank_yawCenter + self.yawrange)
    {
        aim_y = self.tank_yawCenter + self.yawrange;
        updateTime = FALSE;
    }
    else if (aim_y < self.tank_yawCenter - self.yawrange)
    {
        aim_y = self.tank_yawCenter - self.yawrange;
        updateTime = FALSE;
    }

    if (updateTime) self.tank_lastSightTime = time;

    float distY = Math_AngleDistance(aim_y, self.angles_y);
    self.avelocity_y = distY * 10;
    if (self.avelocity_y > self.yawrate)        self.avelocity_y =  self.yawrate;
    else if (self.avelocity_y < -self.yawrate)  self.avelocity_y = -self.yawrate;

    // Clamp pitch
    if (aim_x > self.tank_pitchCenter + self.pitchrange)
        aim_x = self.tank_pitchCenter + self.pitchrange;
    else if (aim_x < self.tank_pitchCenter - self.pitchrange)
        aim_x = self.tank_pitchCenter - self.pitchrange;

    float distX = Math_AngleDistance(aim_x, self.angles_x);
    self.avelocity_x = distX * 10;
    if (self.avelocity_x > self.pitchrate)        self.avelocity_x =  self.pitchrate;
    else if (self.avelocity_x < -self.pitchrate)  self.avelocity_x = -self.pitchrate;

    if (self.tank_controller) return;     // controlled tank doesn't auto-fire

    if (FuncTank_CanFire() &&
        ((fabs(distX) < self.pitchtolerance && fabs(distY) < self.yawtolerance) ||
         (self.spawnflags & SF_TANK_LINEOFSIGHT)))
    {
        float fire = FALSE;
        makevectors(self.angles);
        vector forward = v_forward;

        if (self.spawnflags & SF_TANK_LINEOFSIGHT)
        {
            float length = vlen(direction);
            traceline(barrelEnd, barrelEnd + forward * length, FALSE, self);
            if (trace_ent == pTarget) fire = TRUE;
        }
        else fire = TRUE;

        if (fire)
        {
            if (self.tankFire)
                self.tankFire(FuncTank_BarrelPosition(self), forward, self);
            else
                FuncTank_BaseFireFX(FuncTank_BarrelPosition(self));
        }
        else
            self.tank_fireLast = 0;
    }
    else
        self.tank_fireLast = 0;
}

void FuncTank_Think()
{
    self.avelocity = '0 0 0';
    FuncTank_TrackTarget();

    if (fabs(self.avelocity_x) > 1 || fabs(self.avelocity_y) > 1)
        FuncTank_StartRotSound();
    else
        FuncTank_StopRotSound();
}


void FuncTank_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (self.spawnflags & SF_TANK_CANCONTROL)
    {
        if (pActivator.classname != "player") return;

        if (useTypeArg == USE_SET && useValueArg == 2)
        {
            FuncTank_ControllerPostFrame();
        }
        else if (!self.tank_controller && useTypeArg != USE_OFF)
        {
            FuncTank_StartControl(pActivator);
        }
        else
        {
            FuncTank_StopControl();
        }
    }
    else
    {
        useType = useTypeArg;       // ShouldToggle reads global useType
        if (!ShouldToggle(FuncTank_IsActive())) return;

        if (FuncTank_IsActive())
            FuncTank_TankDeactivate();
        else
            FuncTank_TankActivate();
    }
}

void FuncTank_Use()
{
    FuncTank_UseHL(activator, self, useType, 0);
}

// Every key is a declared field now, so ED_ParseEdict fills it before this
// runs. Only values that need assembling or aliasing are touched here.
void FuncTank_ParseKeyValues()
{
    self.m_barrelPos = [self.barrel, self.barrely, self.barrelz];
    if (self.rotatesound != "") self.noise   = self.rotatesound;
    if (self.laserentity != "") self.message = self.laserentity;
}

// Called by func_tank() and by the variant spawn fns after they install tankFire.
void FuncTank_Init()
{
    FuncTank_ParseKeyValues();

    self.movetype = MOVETYPE_PUSH;
    self.solid    = SOLID_BSP;
    setmodel(self, self.model);

    self.tank_yawCenter   = self.angles_y;
    self.tank_pitchCenter = self.angles_x;

    if (self.firerate <= 0) self.firerate = 1;
    if (self.firespread >= TANK_MAX_FIRING_SPREADS) self.firespread = 0;
    if (self.persistence == 0) self.persistence = 0;	// 0 is valid; CanFire always fails

    self.oldorigin = self.origin;
    self.tank_sightOrigin = FuncTank_BarrelPosition(self);

    self.use   = FuncTank_Use;
    self.usehl = FuncTank_UseHL;
    self.object_caps = FCAP_IMPULSE_USE;

    self.think = FuncTank_Think;
    if (FuncTank_IsActive())
        self.nextthink = self.ltime + 1.0;

    if (self.noise && self.noise != "")
        precache_sound(self.noise);
    if (self.spritesmoke && self.spritesmoke != "")
        precache_model(self.spritesmoke);
    if (self.spriteflash && self.spriteflash != "")
        precache_model(self.spriteflash);
    precache_model("models/shell.iqm");  // bullet tracer body

    // Per-bullet-type fire sounds. Precache only what we need.
    if (self.bullet == TANK_BULLET_9MM)
    {
        precache_sound("weapons/pl_gun1.wav");
        precache_sound("weapons/pl_gun3.wav");
    }
    else if (self.bullet == TANK_BULLET_MP5)
    {
        precache_sound("weapons/hks1.wav");
        precache_sound("weapons/hks2.wav");
        precache_sound("weapons/hks3.wav");
    }
    else if (self.bullet == TANK_BULLET_12MM)
    {
        precache_sound("weapons/357_shot1.wav");
    }
}

void func_tank()
{
    self.tankFire = FuncTankGun_Fire;
    FuncTank_Init();
}
