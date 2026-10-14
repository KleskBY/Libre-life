
#define ARMY_FR_STAND1     0
#define ARMY_FR_STAND8     7
#define ARMY_FR_DEATH1     8
#define ARMY_FR_DEATH3     10
#define ARMY_FR_DEATH10    17
#define ARMY_FR_PAIN1      40
#define ARMY_FR_PAIN6      45
#define ARMY_FR_RUN1       73
#define ARMY_FR_RUN8       80
#define ARMY_FR_SHOOT1     81
#define ARMY_FR_SHOOT5     85
#define ARMY_FR_SHOOT9     89
#define ARMY_FR_PROWL1     90
#define ARMY_FR_PROWL24    113

#define ARMY_MODEL         "progs/soldier.mdl"
#define ARMY_HEAD_MODEL    "progs/h_guard.mdl"

#define ARMY_SND_DEATH     "soldier/death1.wav"
#define ARMY_SND_IDLE      "soldier/idle.wav"
#define ARMY_SND_PAIN1     "soldier/pain1.wav"
#define ARMY_SND_PAIN2     "soldier/pain2.wav"
#define ARMY_SND_FIRE      "soldier/sattck1.wav"
#define ARMY_SND_SIGHT     "soldier/sight1.wav"
#define ARMY_SND_GIB       "player/udeath.wav"

#define ARMY_HEALTH        30
#define ARMY_BULLET_DMG    4
#define ARMY_BULLET_COUNT  4
#define ARMY_BULLET_RANGE  2048
#define ARMY_BULLET_SPREAD 0.1
#define ARMY_PAIN_COOLDOWN 0.6
#define ARMY_THINK_RATE    0.1

float Army_WalkStep(float fi)
{
    switch (fi)
    {
        case 0:  return 1;
        case 1:  return 1;
        case 2:  return 1;
        case 3:  return 1;
        case 4:  return 2;
        case 5:  return 3;
        case 6:  return 4;
        case 7:  return 4;
        case 8:  return 2;
        case 9:  return 2;
        case 10: return 2;
        case 11: return 1;
        case 12: return 0;
        case 13: return 1;
        case 14: return 1;
        case 15: return 1;
        case 16: return 3;
        case 17: return 3;
        case 18: return 3;
        case 19: return 3;
        case 20: return 2;
        case 21: return 1;
        case 22: return 1;
        case 23: return 1;
    }
    return 0;
}

float Army_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 11;
        case 1: return 15;
        case 2: return 10;
        case 3: return 10;
        case 4: return 8;
        case 5: return 15;
        case 6: return 10;
        case 7: return 8;
    }
    return 0;
}

void Army_Stand();
void Army_Walk();
void Army_Run();
void Army_Attack();
void Army_Pain(entity attacker, float damage);
void Army_Die();
void Army_DieThink();
void Army_FireBullets();

void Army_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, ARMY_SND_SIGHT);
}

// Movement
void Army_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - ARMY_FR_STAND1;
    if (fi < 0 || fi > 7) { self.frame = ARMY_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > ARMY_FR_STAND8) self.frame = ARMY_FR_STAND1;
    self.think     = Army_Stand;
    self.nextthink = time + ARMY_THINK_RATE;

    AI_Stand();
}

void Army_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - ARMY_FR_PROWL1;
    if (fi < 0 || fi > 23) { self.frame = ARMY_FR_PROWL1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, ARMY_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > ARMY_FR_PROWL24) self.frame = ARMY_FR_PROWL1;
    self.think     = Army_Walk;
    self.nextthink = time + ARMY_THINK_RATE;

    AI_Walk(Army_WalkStep(fi));
}

void Army_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - ARMY_FR_RUN1;
    if (fi < 0 || fi > 7) { self.frame = ARMY_FR_RUN1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, ARMY_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > ARMY_FR_RUN8) self.frame = ARMY_FR_RUN1;
    self.think     = Army_Run;
    self.nextthink = time + ARMY_THINK_RATE;

    AI_Run(Army_RunStep(fi));
}

//Attack
void Army_FireBullets()
{
    if (!self.enemy) return;

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, ARMY_SND_FIRE);

    vector aim = self.enemy.origin - self.enemy.velocity * 0.2;
    vector src = self.origin + '0 0 16';
    vector base = normalize(aim - src);

    float i;
    for (i = 0; i < ARMY_BULLET_COUNT; i = i + 1)
    {
        vector dir = base;
        dir_x = dir_x + (random() - 0.5) * 2 * ARMY_BULLET_SPREAD;
        dir_y = dir_y + (random() - 0.5) * 2 * ARMY_BULLET_SPREAD;
        dir = normalize(dir);

        vector end = src + dir * ARMY_BULLET_RANGE;

        ClearMultiDamage();
        traceline(src, end, FALSE, self);
        if (trace_fraction != 1.0)
        {
            v_forward = dir;
            Combat_TraceAttack(ARMY_BULLET_DMG, dir, DMG_BULLET);
        }
        ApplyMultiDamage();
    }
}

void Army_Attack()
{
    if (self.frame < ARMY_FR_SHOOT1 || self.frame > ARMY_FR_SHOOT9)
        self.frame = ARMY_FR_SHOOT1;

    if (self.frame == ARMY_FR_SHOOT5)
    {
        AI_Face();
        Army_FireBullets();
        self.effects = self.effects | EF_MUZZLEFLASH;
    }
    else
    {
        AI_Face();
    }

    self.frame = self.frame + 1;
    if (self.frame > ARMY_FR_SHOOT9)
    {
        self.frame     = ARMY_FR_RUN1;
        self.think     = Army_Run;
        self.nextthink = time + ARMY_THINK_RATE;
        return;
    }
    self.think     = Army_Attack;
    self.nextthink = time + ARMY_THINK_RATE;
}

void Army_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > ARMY_FR_PAIN6)
    {
        self.frame     = ARMY_FR_RUN1;
        self.think     = Army_Run;
        self.nextthink = time + ARMY_THINK_RATE;
        return;
    }
    self.think     = Army_PainThink;
    self.nextthink = time + ARMY_THINK_RATE;
}

void Army_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + ARMY_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, ARMY_SND_PAIN1, ARMY_SND_PAIN2);

    self.frame     = ARMY_FR_PAIN1;
    self.think     = Army_PainThink;
    self.nextthink = time + ARMY_THINK_RATE;
}

void Army_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == ARMY_FR_DEATH3)
        Monster_BecomeCorpse('-16 -16 -24', '16 16 -8');

    if (self.frame >= ARMY_FR_DEATH10)
    {
        self.frame = ARMY_FR_DEATH10;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Army_DieThink;
    self.nextthink = time + ARMY_THINK_RATE;
}

void Army_Die()
{
    if (self.health < -35)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, ARMY_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = ARMY_FR_DEATH1;

    self.think     = Army_DieThink;
    self.nextthink = time + ARMY_THINK_RATE;
}


void Army_Precache()
{
    precache_model(ARMY_MODEL);
    precache_model(ARMY_HEAD_MODEL);
    Gib_Q1Precache();

    precache_sound(ARMY_SND_DEATH);
    precache_sound(ARMY_SND_IDLE);
    precache_sound(ARMY_SND_PAIN1);
    precache_sound(ARMY_SND_PAIN2);
    precache_sound(ARMY_SND_FIRE);
    precache_sound(ARMY_SND_SIGHT);
    precache_sound(ARMY_SND_GIB);
}

void monster_army()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Army_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = ARMY_HEALTH;
    self.max_health  = ARMY_HEALTH;
    self.view_ofs    = '0 0 24';
    self.monster_gibHead = ARMY_HEAD_MODEL;

    setmodel(self, ARMY_MODEL);
    setsize(self, '-16 -16 -24', '16 16 40');

    self.th_stand   = Army_Stand;
    self.th_walk    = Army_Walk;
    self.th_run     = Army_Run;
    self.th_die     = Army_Die;
    self.th_pain    = Army_Pain;
    self.th_missile = Army_Attack;
    self.sightSound = Army_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
