// Map keys (BSP interface):
// angles: direction to fire (e.g., '0 -1 0' for up, '0 -2 0' for down)

#define SPAWNFLAG_SUPERSPIKE   1
#define SPAWNFLAG_LASER        2

#define SPIKE_MODEL            "progs/spike.mdl"
#define SUPERSPIKE_MODEL       "progs/s_spike.mdl"
#define LASER_MODEL            "progs/laser.mdl"

#define SPIKE_SOUND            "weapons/spike2.wav"
#define LASER_FIRE_SOUND       "enforcer/enfire.wav"
#define LASER_HIT_SOUND        "enforcer/enfstop.wav"

#define SPIKE_SPEED            500
#define LASER_SPEED            600

#define SPIKE_DMG              9
#define SUPERSPIKE_DMG         18
#define LASER_DMG              15

// Projectile touch handlers
void TrapSpike_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    if (other.takedamage)
        T_Damage(other, self, self.owner, SPIKE_DMG, DMG_GENERIC);

    remove(self);
}

void TrapSuperSpike_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    if (other.takedamage)
        T_Damage(other, self, self.owner, SUPERSPIKE_DMG, DMG_GENERIC);

    remove(self);
}

void TrapLaser_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    if (other.takedamage)
        T_Damage(other, self, self.owner, LASER_DMG, DMG_ENERGYBEAM);

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, LASER_HIT_SOUND);
    remove(self);
}

// Spawn helpers
void TrapSpike_Launch(vector org, vector dir, float superSpike)
{
    entity m = spawn();
    m.owner     = self;
    m.classname = superSpike ? "superspike" : "spike";
    m.movetype  = MOVETYPE_FLYMISSILE;
    m.solid     = SOLID_BBOX;
    m.touch     = superSpike ? TrapSuperSpike_Touch : TrapSpike_Touch;
    m.think     = SUB_Remove;
    m.nextthink = time + 6;

    setmodel(m, superSpike ? SUPERSPIKE_MODEL : SPIKE_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, org);

    m.velocity = dir * SPIKE_SPEED;
    m.angles   = vectoangles(m.velocity);
}

void TrapLaser_Launch(vector org, vector dir)
{
    entity m = spawn();
    m.owner     = self;
    m.classname = "trap_laser";
    m.movetype  = MOVETYPE_FLY;
    m.solid     = SOLID_BBOX;
    m.touch     = TrapLaser_Touch;
    m.think     = SUB_Remove;
    m.nextthink = time + 6;
    m.effects   = m.effects | EF_DIMLIGHT;

    setmodel(m, LASER_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, org);

    m.velocity = dir * LASER_SPEED;
    m.angles   = vectoangles(m.velocity);
}

// Use callbacks (legacy and modern)
void TrapSpikeshooter_Fire()
{
    if (self.spawnflags & SPAWNFLAG_LASER)
    {
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, LASER_FIRE_SOUND);
        TrapLaser_Launch(self.origin, self.movedir);
    }
    else
    {
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SPIKE_SOUND);
        TrapSpike_Launch(self.origin, self.movedir,
                         self.spawnflags & SPAWNFLAG_SUPERSPIKE);
    }
}

void TrapSpikeshooter_Use()
{
    TrapSpikeshooter_Fire();
}

void TrapSpikeshooter_UseHL(entity pActivator, entity pCaller, float utype, float uvalue)
{
    TrapSpikeshooter_Fire();
}

// Auto-firing variant: re-fires every self.wait seconds.
void TrapShooter_Think()
{
    TrapSpikeshooter_Fire();
    self.nextthink = time + self.wait;
    self.think     = TrapShooter_Think;
}

// Spawn fns
void trap_spikeshooter()
{
    SetMovedir();

    self.use   = TrapSpikeshooter_Use;
    self.usehl = TrapSpikeshooter_UseHL;

    if (self.spawnflags & SPAWNFLAG_LASER)
    {
        precache_model(LASER_MODEL);
        precache_sound(LASER_FIRE_SOUND);
        precache_sound(LASER_HIT_SOUND);
    }
    else
    {
        precache_model(SPIKE_MODEL);
        if (self.spawnflags & SPAWNFLAG_SUPERSPIKE)
            precache_model(SUPERSPIKE_MODEL);
        precache_sound(SPIKE_SOUND);
    }
}

void trap_shooter()
{
    trap_spikeshooter();

    if (self.wait == 0) self.wait = 1;

    self.nextthink = self.nextthink + self.wait + self.ltime;
    self.think     = TrapShooter_Think;
}
