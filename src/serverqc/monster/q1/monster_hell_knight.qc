
#define HK_FR_STAND1     0
#define HK_FR_STAND9     8
#define HK_FR_WALK1      9
#define HK_FR_WALK20     28
#define HK_FR_RUN1       29
#define HK_FR_RUN8       36
#define HK_FR_PAIN1      37
#define HK_FR_PAIN5      41
#define HK_FR_DEATH1     42
#define HK_FR_DEATH3     44
#define HK_FR_DEATH12    53
#define HK_FR_SLICE1     112
#define HK_FR_SLICE10    121
#define HK_FR_SMASH1     122
#define HK_FR_SMASH11    132
#define HK_FR_WATK1      133
#define HK_FR_WATK22     154
#define HK_FR_MAGICC1    155
#define HK_FR_MAGICC11   165

#define HK_MODEL         "progs/hknight.mdl"
#define HK_HEAD_MODEL    "progs/h_hellkn.mdl"
#define HK_SPIKE_MODEL   "progs/k_spike.mdl"

#define HK_SND_ATTACK    "hknight/attack1.wav"
#define HK_SND_DEATH     "hknight/death1.wav"
#define HK_SND_PAIN      "hknight/pain1.wav"
#define HK_SND_SIGHT     "hknight/sight1.wav"
#define HK_SND_HIT       "hknight/hit.wav"
#define HK_SND_SLASH     "hknight/slash1.wav"
#define HK_SND_IDLE      "hknight/idle.wav"
#define HK_SND_GRUNT     "hknight/grunt.wav"
#define HK_SND_SWORD1    "knight/sword1.wav"
#define HK_SND_SWORD2    "knight/sword2.wav"
#define HK_SND_GIB       "player/udeath.wav"

#define HK_HEALTH        180
#define HK_SLASH_DMG_MIN 6
#define HK_SLASH_DMG_MAX 18
#define HK_SLASH_REACH   90
#define HK_SPIKE_DMG     9
#define HK_SPIKE_SPEED   600
#define HK_PAIN_COOLDOWN 1
#define HK_THINK_RATE    0.1


float Hknight_WalkStep(float fi)
{
    switch (fi)
    {
        case 0:  return 2;
        case 1:  return 5;
        case 2:  return 5;
        case 3:  return 4;
        case 4:  return 4;
        case 5:  return 2;
        case 6:  return 2;
        case 7:  return 3;
        case 8:  return 3;
        case 9:  return 4;
        case 10: return 3;
        case 11: return 4;
        case 12: return 6;
        case 13: return 2;
        case 14: return 2;
        case 15: return 4;
        case 16: return 3;
        case 17: return 3;
        case 18: return 3;
        case 19: return 2;
    }
    return 0;
}

float Hknight_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 20;
        case 1: return 25;
        case 2: return 18;
        case 3: return 16;
        case 4: return 14;
        case 5: return 25;
        case 6: return 21;
        case 7: return 13;
    }
    return 0;
}

float Hknight_SliceCharge(float fi)
{
    switch (fi)
    {
        case 0: return 9;
        case 1: return 6;
        case 2: return 13;
        case 3: return 4;
        case 4: return 7;
        case 5: return 15;
        case 6: return 8;
        case 7: return 2;
        case 8: return 0;
        case 9: return 3;
    }
    return 0;
}

float Hknight_SmashCharge(float fi)
{
    switch (fi)
    {
        case 0:  return 1;
        case 1:  return 13;
        case 2:  return 9;
        case 3:  return 11;
        case 4:  return 10;
        case 5:  return 7;
        case 6:  return 12;
        case 7:  return 2;
        case 8:  return 3;
        case 9:  return 0;
        case 10: return 0;
    }
    return 0;
}

float Hknight_WatkCharge(float fi)
{
    switch (fi)
    {
        case 0:  return 2;
        case 1:  return 0;
        case 2:  return 0;
        case 3:  return 0;
        case 4:  return 0;
        case 5:  return 0;
        case 6:  return 1;
        case 7:  return 4;
        case 8:  return 5;
        case 9:  return 3;
        case 10: return 2;
        case 11: return 2;
        case 12: return 0;
        case 13: return 0;
        case 14: return 0;
        case 15: return 1;
        case 16: return 1;
        case 17: return 3;
        case 18: return 4;
        case 19: return 6;
        case 20: return 7;
        case 21: return 3;
    }
    return 0;
}

void Hknight_Stand();
void Hknight_Walk();
void Hknight_Run();
void Hknight_MagicC();
void Hknight_Slice();
void Hknight_Smash();
void Hknight_Watk();
void Hknight_Melee();
void Hknight_Pain(entity attacker, float damage);
void Hknight_Die();
void Hknight_DieThink();
void Hknight_Slash();
void Hknight_Spike(float yawOffset);
void Hknight_Spike_Touch();

void Hknight_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, HK_SND_SIGHT);
}

void Hknight_IdleSound()
{
    if (random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, HK_SND_IDLE);
}

// Idle / locomotion
void Hknight_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - HK_FR_STAND1;
    if (fi < 0 || fi > 8) { self.frame = HK_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_STAND9) self.frame = HK_FR_STAND1;
    self.think     = Hknight_Stand;
    self.nextthink = time + HK_THINK_RATE;

    AI_Stand();
}

void Hknight_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - HK_FR_WALK1;
    if (fi < 0 || fi > 19) { self.frame = HK_FR_WALK1; fi = 0; }

    if (fi == 0) Hknight_IdleSound();

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_WALK20) self.frame = HK_FR_WALK1;
    self.think     = Hknight_Walk;
    self.nextthink = time + HK_THINK_RATE;

    AI_Walk(Hknight_WalkStep(fi));
}

void Hknight_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - HK_FR_RUN1;
    if (fi < 0 || fi > 7) { self.frame = HK_FR_RUN1; fi = 0; }

    if (fi == 0) Hknight_IdleSound();

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_RUN8) self.frame = HK_FR_RUN1;
    self.think     = Hknight_Run;
    self.nextthink = time + HK_THINK_RATE;

    AI_Run(Hknight_RunStep(fi));
}

void Hknight_Spike_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    if (other.takedamage)
        T_Damage(other, self, self.owner, HK_SPIKE_DMG, DMG_GENERIC);

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HK_SND_HIT);
    remove(self);
}

void Hknight_Spike(float yawOffset)
{
    if (!self.enemy) return;

    vector offang = vectoangles(self.enemy.origin - self.origin);
    offang_y = offang_y + yawOffset * 6;          // Q1 used 6° per step
    makevectors(offang);

    vector org = self.origin + self.mins + self.size * 0.5 + v_forward * 20;
    vector dir = normalize(v_forward);
    dir_z = -dir_z + (random() - 0.5) * 0.1;       // mild vertical jitter

    entity m = spawn();
    m.owner     = self;
    m.classname = "knightspike";
    m.movetype  = MOVETYPE_FLYMISSILE;
    m.solid     = SOLID_BBOX;
    m.touch     = Hknight_Spike_Touch;
    m.think     = SUB_Remove;
    m.nextthink = time + 5;

    setmodel(m, HK_SPIKE_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, org);

    m.velocity = dir * HK_SPIKE_SPEED;
    m.angles   = vectoangles(m.velocity);

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HK_SND_ATTACK);
}

void Hknight_MagicC()
{
    if (self.frame < HK_FR_MAGICC1 || self.frame > HK_FR_MAGICC11)
        self.frame = HK_FR_MAGICC1;

    float fi = self.frame - HK_FR_MAGICC1;
    if      (fi == 5)  Hknight_Spike(-2);
    else if (fi == 6)  Hknight_Spike(-1);
    else if (fi == 7)  Hknight_Spike(0);
    else if (fi == 8)  Hknight_Spike(1);
    else if (fi == 9)  Hknight_Spike(2);
    else if (fi == 10) Hknight_Spike(3);
    else               AI_Face();

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_MAGICC11)
    {
        self.frame     = HK_FR_RUN1;
        self.think     = Hknight_Run;
        self.nextthink = time + HK_THINK_RATE;
        return;
    }
    self.think     = Hknight_MagicC;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_Slash()
{
    if (!self.enemy) return;
    if (vlen(self.enemy.origin - self.origin) > HK_SLASH_REACH) return;

    float dmg = HK_SLASH_DMG_MIN + random() * (HK_SLASH_DMG_MAX - HK_SLASH_DMG_MIN);
    T_Damage(self.enemy, self, self, dmg, DMG_SLASH);
}

void Hknight_Slice()
{
    if (self.frame < HK_FR_SLICE1 || self.frame > HK_FR_SLICE10)
        self.frame = HK_FR_SLICE1;

    float fi = self.frame - HK_FR_SLICE1;
    if (fi >= 4 && fi <= 8) Hknight_Slash();
    AI_Charge(Hknight_SliceCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_SLICE10)
    {
        self.frame     = HK_FR_RUN1;
        self.think     = Hknight_Run;
        self.nextthink = time + HK_THINK_RATE;
        return;
    }
    self.think     = Hknight_Slice;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_Smash()
{
    if (self.frame < HK_FR_SMASH1 || self.frame > HK_FR_SMASH11)
        self.frame = HK_FR_SMASH1;

    float fi = self.frame - HK_FR_SMASH1;
    if (fi >= 4 && fi <= 8) Hknight_Slash();
    AI_Charge(Hknight_SmashCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_SMASH11)
    {
        self.frame     = HK_FR_RUN1;
        self.think     = Hknight_Run;
        self.nextthink = time + HK_THINK_RATE;
        return;
    }
    self.think     = Hknight_Smash;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_Watk()
{
    if (self.frame < HK_FR_WATK1 || self.frame > HK_FR_WATK22)
        self.frame = HK_FR_WATK1;

    float fi = self.frame - HK_FR_WATK1;
    if ((fi >= 3 && fi <= 5) || (fi >= 9 && fi <= 11) || (fi >= 16 && fi <= 18))
        Hknight_Slash();
    AI_Charge(Hknight_WatkCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > HK_FR_WATK22)
    {
        self.frame     = HK_FR_RUN1;
        self.think     = Hknight_Run;
        self.nextthink = time + HK_THINK_RATE;
        return;
    }
    self.think     = Hknight_Watk;
    self.nextthink = time + HK_THINK_RATE;
}

float hknight_type;
void Hknight_Melee()
{
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HK_SND_SLASH);

    hknight_type = hknight_type + 1;
    if (hknight_type == 1)
    {
        self.frame = HK_FR_SLICE1;
        self.think = Hknight_Slice;
    }
    else if (hknight_type == 2)
    {
        self.frame = HK_FR_SMASH1;
        self.think = Hknight_Smash;
    }
    else
    {
        self.frame = HK_FR_WATK1;
        self.think = Hknight_Watk;
        hknight_type = 0;
    }
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > HK_FR_PAIN5)
    {
        self.frame     = HK_FR_RUN1;
        self.think     = Hknight_Run;
        self.nextthink = time + HK_THINK_RATE;
        return;
    }
    self.think     = Hknight_PainThink;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, HK_SND_PAIN);
    if (time - self.pain_finished <= 5)
    {
        if (random() * 30 > damage) return;
    }

    self.pain_finished = time + HK_PAIN_COOLDOWN;
    self.frame     = HK_FR_PAIN1;
    self.think     = Hknight_PainThink;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == HK_FR_DEATH3)
        Monster_BecomeCorpse('-16 -16 -24', '16 16 -8');

    if (self.frame >= HK_FR_DEATH12)
    {
        self.frame = HK_FR_DEATH12;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Hknight_DieThink;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_Die()
{
    if (self.health < -40)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, HK_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = HK_FR_DEATH1;

    self.think     = Hknight_DieThink;
    self.nextthink = time + HK_THINK_RATE;
}

void Hknight_Precache()
{
    precache_model(HK_MODEL);
    precache_model(HK_HEAD_MODEL);
    precache_model(HK_SPIKE_MODEL);
    Gib_Q1Precache();

    precache_sound(HK_SND_ATTACK);
    precache_sound(HK_SND_DEATH);
    precache_sound(HK_SND_PAIN);
    precache_sound(HK_SND_SIGHT);
    precache_sound(HK_SND_HIT);
    precache_sound(HK_SND_SLASH);
    precache_sound(HK_SND_IDLE);
    precache_sound(HK_SND_GRUNT);
    precache_sound(HK_SND_SWORD1);
    precache_sound(HK_SND_SWORD2);
    precache_sound(HK_SND_GIB);
}

void monster_hell_knight()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Hknight_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = HK_HEALTH;
    self.max_health  = HK_HEALTH;
    self.view_ofs    = '0 0 24';

    setmodel(self, HK_MODEL);
    setsize(self, '-16 -16 -24', '16 16 40');

    self.th_stand   = Hknight_Stand;
    self.th_walk    = Hknight_Walk;
    self.th_run     = Hknight_Run;
    self.th_die     = Hknight_Die;
    self.monster_gibHead = HK_HEAD_MODEL;
    self.th_pain    = Hknight_Pain;
    self.th_melee   = Hknight_Melee;
    self.th_missile = Hknight_MagicC;
    self.sightSound = Hknight_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
