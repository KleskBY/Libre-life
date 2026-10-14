
#define KN_FR_STAND1    0
#define KN_FR_STAND9    8
#define KN_FR_RUN1      9
#define KN_FR_RUN8      16
#define KN_FR_PAIN1     28
#define KN_FR_PAIN3     30
#define KN_FR_ATTACK1   42
#define KN_FR_ATTACK11  52
#define KN_FR_WALK1     53
#define KN_FR_WALK14    66
#define KN_FR_DEATH1    76
#define KN_FR_DEATH3    78
#define KN_FR_DEATH10   85

#define KN_MODEL        "progs/knight.mdl"
#define KN_HEAD_MODEL   "progs/h_knight.mdl"

#define KN_SND_DEATH    "knight/kdeath.wav"
#define KN_SND_PAIN     "knight/khurt.wav"
#define KN_SND_SIGHT    "knight/ksight.wav"
#define KN_SND_SWORD1   "knight/sword1.wav"
#define KN_SND_SWORD2   "knight/sword2.wav"
#define KN_SND_IDLE     "knight/idle.wav"
#define KN_SND_GIB      "player/udeath.wav"

#define KN_HEALTH       60
#define KN_SLASH_DMG_MIN 4
#define KN_SLASH_DMG_MAX 12
#define KN_SLASH_REACH  90
#define KN_PAIN_COOLDOWN 1
#define KN_THINK_RATE   0.1

float Knight_WalkStep(float fi)
{
    switch (fi)
    {
        case 0:  return 3;
        case 1:  return 2;
        case 2:  return 3;
        case 3:  return 4;
        case 4:  return 3;
        case 5:  return 3;
        case 6:  return 3;
        case 7:  return 4;
        case 8:  return 3;
        case 9:  return 3;
        case 10: return 2;
        case 11: return 3;
        case 12: return 4;
        case 13: return 3;
    }
    return 0;
}

float Knight_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 16;
        case 1: return 20;
        case 2: return 13;
        case 3: return 7;
        case 4: return 16;
        case 5: return 20;
        case 6: return 14;
        case 7: return 6;
    }
    return 0;
}

float Knight_AttackCharge(float fi)
{
    switch (fi)
    {
        case 0:  return 0;
        case 1:  return 7;
        case 2:  return 4;
        case 3:  return 0;
        case 4:  return 3;
        case 5:  return 4;
        case 6:  return 1;
        case 7:  return 3;
        case 8:  return 1;
        case 9:  return 5;
    }
    return 0;
}

void Knight_Stand();
void Knight_Walk();
void Knight_Run();
void Knight_Attack();
void Knight_Pain(entity attacker, float damage);
void Knight_Die();
void Knight_DieThink();
void Knight_Slash();

void Knight_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, KN_SND_SIGHT);
}

void Knight_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - KN_FR_STAND1;
    if (fi < 0 || fi > 8) { self.frame = KN_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > KN_FR_STAND9) self.frame = KN_FR_STAND1;
    self.think     = Knight_Stand;
    self.nextthink = time + KN_THINK_RATE;

    AI_Stand();
}

void Knight_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - KN_FR_WALK1;
    if (fi < 0 || fi > 13) { self.frame = KN_FR_WALK1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, KN_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > KN_FR_WALK14) self.frame = KN_FR_WALK1;
    self.think     = Knight_Walk;
    self.nextthink = time + KN_THINK_RATE;

    AI_Walk(Knight_WalkStep(fi));
}

void Knight_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - KN_FR_RUN1;
    if (fi < 0 || fi > 7) { self.frame = KN_FR_RUN1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, KN_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > KN_FR_RUN8) self.frame = KN_FR_RUN1;
    self.think     = Knight_Run;
    self.nextthink = time + KN_THINK_RATE;

    AI_Run(Knight_RunStep(fi));
}

void Knight_Slash()
{
    if (!self.enemy) return;
    if (vlen(self.enemy.origin - self.origin) > KN_SLASH_REACH) return;

    float dmg = KN_SLASH_DMG_MIN + random() * (KN_SLASH_DMG_MAX - KN_SLASH_DMG_MIN);
    T_Damage(self.enemy, self, self, dmg, DMG_SLASH);
}

void Knight_Attack()
{
    if (self.frame < KN_FR_ATTACK1 || self.frame > KN_FR_ATTACK11)
        self.frame = KN_FR_ATTACK1;

    float fi = self.frame - KN_FR_ATTACK1;

    if (fi == 0)
        Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, KN_SND_SWORD1);

    if (fi >= 5 && fi <= 7)
        Knight_Slash();

    AI_Charge(Knight_AttackCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > KN_FR_ATTACK11)
    {
        self.frame     = KN_FR_RUN1;
        self.think     = Knight_Run;
        self.nextthink = time + KN_THINK_RATE;
        return;
    }
    self.think     = Knight_Attack;
    self.nextthink = time + KN_THINK_RATE;
}

void Knight_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > KN_FR_PAIN3)
    {
        self.frame     = KN_FR_RUN1;
        self.think     = Knight_Run;
        self.nextthink = time + KN_THINK_RATE;
        return;
    }
    self.think     = Knight_PainThink;
    self.nextthink = time + KN_THINK_RATE;
}

void Knight_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + KN_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, KN_SND_PAIN);
    self.frame     = KN_FR_PAIN1;
    self.think     = Knight_PainThink;
    self.nextthink = time + KN_THINK_RATE;
}

void Knight_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == KN_FR_DEATH3)
        Monster_BecomeCorpse('-16 -16 -24', '16 16 -8');

    if (self.frame >= KN_FR_DEATH10)
    {
        self.frame = KN_FR_DEATH10;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Knight_DieThink;
    self.nextthink = time + KN_THINK_RATE;
}

void Knight_Die()
{
    if (self.health < -40)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, KN_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = KN_FR_DEATH1;

    self.think     = Knight_DieThink;
    self.nextthink = time + KN_THINK_RATE;
}

void Knight_Precache()
{
    precache_model(KN_MODEL);
    precache_model(KN_HEAD_MODEL);
    Gib_Q1Precache();

    precache_sound(KN_SND_DEATH);
    precache_sound(KN_SND_PAIN);
    precache_sound(KN_SND_SIGHT);
    precache_sound(KN_SND_SWORD1);
    precache_sound(KN_SND_SWORD2);
    precache_sound(KN_SND_IDLE);
    precache_sound(KN_SND_GIB);
}

void monster_knight()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Knight_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = KN_HEALTH;
    self.max_health  = KN_HEALTH;
    self.view_ofs    = '0 0 24';

    setmodel(self, KN_MODEL);
    setsize(self, '-16 -16 -24', '16 16 40');

    self.th_stand   = Knight_Stand;
    self.th_walk    = Knight_Walk;
    self.th_run     = Knight_Run;
    self.th_die     = Knight_Die;
    self.monster_gibHead = KN_HEAD_MODEL;
    self.th_pain    = Knight_Pain;
    self.th_melee   = Knight_Attack;
    self.sightSound = Knight_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
