
#define OGRE_FR_STAND1     0
#define OGRE_FR_STAND9     8
#define OGRE_FR_WALK1      9
#define OGRE_FR_WALK16     24
#define OGRE_FR_RUN1       25
#define OGRE_FR_RUN8       32
#define OGRE_FR_SWING1     33
#define OGRE_FR_SWING14    46
#define OGRE_FR_SMASH1     47
#define OGRE_FR_SMASH14    60
#define OGRE_FR_SHOOT1     61
#define OGRE_FR_SHOOT4     64
#define OGRE_FR_SHOOT6     66
#define OGRE_FR_PAIN1      67
#define OGRE_FR_PAIN5      71
#define OGRE_FR_DEATH1     112
#define OGRE_FR_DEATH3     114
#define OGRE_FR_DEATH14    125
#define OGRE_FR_BDEATH1    126
#define OGRE_FR_BDEATH3    128
#define OGRE_FR_BDEATH10   135

#define OGRE_MODEL          "progs/ogre.mdl"
#define OGRE_HEAD_MODEL     "progs/h_ogre.mdl"
#define OGRE_GRENADE_MODEL  "progs/grenade.mdl"
#define OGRE_EXPLODE_MODEL  "progs/s_explod.spr"

#define OGRE_SND_DRAG       "ogre/ogdrag.wav"
#define OGRE_SND_DEATH      "ogre/ogdth.wav"
#define OGRE_SND_IDLE       "ogre/ogidle.wav"
#define OGRE_SND_IDLE2      "ogre/ogidle2.wav"
#define OGRE_SND_PAIN       "ogre/ogpain1.wav"
#define OGRE_SND_SAW        "ogre/ogsawatk.wav"
#define OGRE_SND_WAKE       "ogre/ogwake.wav"
#define OGRE_SND_GRENADE    "weapons/grenade.wav"
#define OGRE_SND_BOUNCE     "weapons/bounce.wav"
#define OGRE_SND_EXPLODE    "weapons/explode3.wav"
#define OGRE_SND_GIB        "player/udeath.wav"

#define OGRE_HEALTH         100
#define OGRE_GRENADE_DMG    35
#define OGRE_GRENADE_RADIUS 120
#define OGRE_GRENADE_SPEED  600
#define OGRE_GRENADE_FUSE   2.5
#define OGRE_SAW_DMG_MIN    4
#define OGRE_SAW_DMG_MAX    12
#define OGRE_SAW_REACH      80
#define OGRE_PAIN_COOLDOWN  1
#define OGRE_THINK_RATE     0.1

float Ogre_WalkStep(float fi)
{
    switch (fi)
    {
        case 0:  return 3;
        case 1:  return 2;
        case 2:  return 2;
        case 3:  return 2;
        case 4:  return 2;
        case 5:  return 5;
        case 6:  return 3;
        case 7:  return 2;
        case 8:  return 3;
        case 9:  return 1;
        case 10: return 2;
        case 11: return 3;
        case 12: return 3;
        case 13: return 3;
        case 14: return 3;
        case 15: return 4;
    }
    return 0;
}

float Ogre_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 9;
        case 1: return 12;
        case 2: return 8;
        case 3: return 22;
        case 4: return 16;
        case 5: return 4;
        case 6: return 13;
        case 7: return 24;
    }
    return 0;
}

void Ogre_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_WAKE);
}

void Ogre_Stand();
void Ogre_Walk();
void Ogre_Run();
void Ogre_Swing();
void Ogre_Smash();
void Ogre_Shoot();
void Ogre_Pain(entity attacker, float damage);
void Ogre_Die();
void Ogre_DieThink();
void Ogre_Melee();
void Ogre_FireGrenade();
void Ogre_GrenadeTouch();
void Ogre_GrenadeExplode();
void Ogre_Chainsaw();

// Idle / locomotion
void Ogre_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - OGRE_FR_STAND1;
    if (fi < 0 || fi > 8) { self.frame = OGRE_FR_STAND1; fi = 0; }

    if (fi == 4 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, OGRE_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_STAND9) self.frame = OGRE_FR_STAND1;
    self.think     = Ogre_Stand;
    self.nextthink = time + OGRE_THINK_RATE;

    AI_Stand();
}

void Ogre_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - OGRE_FR_WALK1;
    if (fi < 0 || fi > 15) { self.frame = OGRE_FR_WALK1; fi = 0; }

    if (fi == 2 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, OGRE_SND_IDLE);
    else if (fi == 5 && random() < 0.1)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, OGRE_SND_DRAG);

    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_WALK16) self.frame = OGRE_FR_WALK1;
    self.think     = Ogre_Walk;
    self.nextthink = time + OGRE_THINK_RATE;

    AI_Walk(Ogre_WalkStep(fi));
}

void Ogre_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - OGRE_FR_RUN1;
    if (fi < 0 || fi > 7) { self.frame = OGRE_FR_RUN1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, OGRE_SND_IDLE2);

    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_RUN8) self.frame = OGRE_FR_RUN1;
    self.think     = Ogre_Run;
    self.nextthink = time + OGRE_THINK_RATE;

    AI_Run(Ogre_RunStep(fi));
}

void Ogre_Chainsaw()
{
    if (!self.enemy || !CanDamage(self.enemy, self)) return;
    if (vlen(self.enemy.origin - self.origin) > OGRE_SAW_REACH) return;
    T_Damage(self.enemy, self, self, Math_RandomInt(OGRE_SAW_DMG_MIN,OGRE_SAW_DMG_MAX), DMG_SLASH);
    self.angles_y = self.angles_y + random() * 25 - 12.5;
}

void Ogre_Swing()
{
    if (self.frame < OGRE_FR_SWING1 || self.frame > OGRE_FR_SWING14)
        self.frame = OGRE_FR_SWING1;

    float fi = self.frame - OGRE_FR_SWING1;
    if (fi == 0)  Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_SAW);
    if (fi >= 4 && fi <= 10) Ogre_Chainsaw();
    else                     AI_Face();

    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_SWING14)
    {
        self.frame     = OGRE_FR_RUN1;
        self.think     = Ogre_Run;
        self.nextthink = time + OGRE_THINK_RATE;
        return;
    }
    self.think     = Ogre_Swing;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_Smash()
{
    if (self.frame < OGRE_FR_SMASH1 || self.frame > OGRE_FR_SMASH14)
        self.frame = OGRE_FR_SMASH1;

    float fi = self.frame - OGRE_FR_SMASH1;
    if (fi == 0) Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_SAW);
    if (fi >= 5 && fi <= 10) Ogre_Chainsaw();
    else                     AI_Face();

    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_SMASH14)
    {
        self.frame     = OGRE_FR_RUN1;
        self.think     = Ogre_Run;
        self.nextthink = time + OGRE_THINK_RATE;
        return;
    }
    self.think     = Ogre_Smash;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_Melee()
{
    if (random() > 0.5)
    {
        self.frame = OGRE_FR_SMASH1;
        self.think = Ogre_Smash;
    }
    else
    {
        self.frame = OGRE_FR_SWING1;
        self.think = Ogre_Swing;
    }
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_GrenadeExplode()
{
    T_RadiusDamage(self, self.owner, OGRE_GRENADE_DMG, OGRE_GRENADE_RADIUS, DMG_BLAST);
    te_explosion(self.origin);
    Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(2000), PITCH_NORM, OGRE_SND_EXPLODE);
    remove(self);
}

void Ogre_GrenadeTouch()
{
    if (other == self.owner) return;
    if (other.takedamage == DAMAGE_AIM)
    {
        Ogre_GrenadeExplode();
        return;
    }
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_BOUNCE);
    if (self.velocity == '0 0 0') self.avelocity = '0 0 0';
}

void Ogre_FireGrenade()
{
    if (!self.enemy) return;

    self.effects = self.effects | EF_MUZZLEFLASH;
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_GRENADE);

    entity m = spawn();
    m.owner     = self;
    m.movetype  = MOVETYPE_BOUNCE;
    m.solid     = SOLID_BBOX;
    m.classname = "ogre_grenade";

    vector dir   = normalize(self.enemy.origin - self.origin);
    m.velocity   = dir * OGRE_GRENADE_SPEED;
    m.velocity_z = 200;
    m.avelocity  = '300 300 300';
    m.angles     = vectoangles(m.velocity);

    setmodel(m, OGRE_GRENADE_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, self.origin + '0 0 16');

    m.touch     = Ogre_GrenadeTouch;
    m.think     = Ogre_GrenadeExplode;
    m.nextthink = time + OGRE_GRENADE_FUSE;
}

void Ogre_Shoot()
{
    if (self.frame < OGRE_FR_SHOOT1 || self.frame > OGRE_FR_SHOOT6)
        self.frame = OGRE_FR_SHOOT1;

    if (self.frame == OGRE_FR_SHOOT4)
    {
        AI_Face();
        Ogre_FireGrenade();
    }
    else
    {
        AI_Face();
    }

    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_SHOOT6)
    {
        self.frame     = OGRE_FR_RUN1;
        self.think     = Ogre_Run;
        self.nextthink = time + OGRE_THINK_RATE;
        return;
    }
    self.think     = Ogre_Shoot;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > OGRE_FR_PAIN5)
    {
        self.frame     = OGRE_FR_RUN1;
        self.think     = Ogre_Run;
        self.nextthink = time + OGRE_THINK_RATE;
        return;
    }
    self.think     = Ogre_PainThink;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + OGRE_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_PAIN);
    self.frame     = OGRE_FR_PAIN1;
    self.think     = Ogre_PainThink;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == OGRE_FR_DEATH3)
        Monster_BecomeCorpse('-24 -24 -24', '24 24 -4');

    if (self.frame >= OGRE_FR_DEATH14)
    {
        self.frame = OGRE_FR_DEATH14;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Ogre_DieThink;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_Die()
{
    if (self.health < -80)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OGRE_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = OGRE_FR_DEATH1;

    self.think     = Ogre_DieThink;
    self.nextthink = time + OGRE_THINK_RATE;
}

void Ogre_Precache()
{
    precache_model(OGRE_MODEL);
    precache_model(OGRE_HEAD_MODEL);
    precache_model(OGRE_GRENADE_MODEL);
    precache_model(OGRE_EXPLODE_MODEL);
    Gib_Q1Precache();

    precache_sound(OGRE_SND_DRAG);
    precache_sound(OGRE_SND_DEATH);
    precache_sound(OGRE_SND_IDLE);
    precache_sound(OGRE_SND_IDLE2);
    precache_sound(OGRE_SND_PAIN);
    precache_sound(OGRE_SND_SAW);
    precache_sound(OGRE_SND_WAKE);
    precache_sound(OGRE_SND_GRENADE);
    precache_sound(OGRE_SND_BOUNCE);
    precache_sound(OGRE_SND_EXPLODE);
    precache_sound(OGRE_SND_GIB);
}

float OgreCheckAttack()
{
	vector spot1, spot2;
	entity targ;
	float chance;

	if (enemy_range == RANGE_MELEE)
	{
		if (CanDamage(self.enemy, self))
		{
			self.attack_state = AS_MELEE;
			return TRUE;
		}
	}

	if (time < self.attack_finished)
		return FALSE;

	if (!enemy_vis)
		return FALSE;

	targ = self.enemy;
	spot1 = self.origin + self.view_ofs;
	spot2 = targ.origin + targ.view_ofs;

	traceline(spot1, spot2, FALSE, self);
	if (trace_inopen && trace_inwater)
		return FALSE;
	if (trace_ent != targ)
	{
		return FALSE;
	}

	if (time < self.attack_finished)
		return FALSE;

	if (enemy_range == RANGE_FAR)
		return FALSE;

	else if (enemy_range == RANGE_NEAR)
		chance = 0.10;
	else if (enemy_range == RANGE_MID)
		chance = 0.05;
	else
		chance = 0;

	self.attack_state = AS_MISSILE;
	return TRUE;
}

void monster_ogre()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Ogre_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = OGRE_HEALTH;
    self.max_health  = OGRE_HEALTH;
    self.view_ofs    = '0 0 32';

    setmodel(self, OGRE_MODEL);
    setsize(self, '-24 -24 -24', '24 24 32');

    self.th_stand   = Ogre_Stand;
    self.th_walk    = Ogre_Walk;
    self.th_run     = Ogre_Run;
    self.th_die     = Ogre_Die;
    self.monster_gibHead  = OGRE_HEAD_MODEL;
    self.monster_gibPiece = "progs/gib3.mdl";
    self.th_pain    = Ogre_Pain;
    self.th_melee   = Ogre_Melee;
    self.th_missile = Ogre_Shoot;
    self.sightSound = Ogre_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}

void monster_ogre_marksman()
{
    monster_ogre();
}
