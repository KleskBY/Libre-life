
#define EN_FR_STAND1     0
#define EN_FR_STAND7     6
#define EN_FR_WALK1      7
#define EN_FR_WALK16     22
#define EN_FR_RUN1       23
#define EN_FR_RUN8       30
#define EN_FR_ATTACK1    31
#define EN_FR_ATTACK10   40
#define EN_FR_DEATH1     41
#define EN_FR_DEATH3     43
#define EN_FR_DEATH14    54
#define EN_FR_PAIN1      66
#define EN_FR_PAIN4      69


#define EN_MODEL         "progs/enforcer.mdl"
#define EN_HEAD_MODEL    "progs/h_mega.mdl"
#define EN_LASER_MODEL   "progs/laser.mdl"

#define EN_SND_DEATH     "enforcer/death1.wav"
#define EN_SND_FIRE      "enforcer/enfire.wav"
#define EN_SND_HIT       "enforcer/enfstop.wav"
#define EN_SND_IDLE      "enforcer/idle1.wav"
#define EN_SND_PAIN1     "enforcer/pain1.wav"
#define EN_SND_PAIN2     "enforcer/pain2.wav"
#define EN_SND_SIGHT1    "enforcer/sight1.wav"
#define EN_SND_SIGHT2    "enforcer/sight2.wav"
#define EN_SND_SIGHT3    "enforcer/sight3.wav"
#define EN_SND_SIGHT4    "enforcer/sight4.wav"
#define EN_SND_GIB       "player/udeath.wav"

#define EN_HEALTH        80
#define EN_LASER_DMG     15
#define EN_LASER_SPEED   600
#define EN_PAIN_COOLDOWN 1
#define EN_THINK_RATE    0.1


float Enf_WalkStep(float fi)
{
    switch (fi)
    {
        case 0:  return 2;
        case 1:  return 4;
        case 2:  return 4;
        case 3:  return 3;
        case 4:  return 1;
        case 5:  return 2;
        case 6:  return 2;
        case 7:  return 1;
        case 8:  return 2;
        case 9:  return 4;
        case 10: return 4;
        case 11: return 1;
        case 12: return 2;
        case 13: return 3;
        case 14: return 4;
        case 15: return 2;
    }
    return 0;
}

float Enf_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 18;
        case 1: return 14;
        case 2: return 7;
        case 3: return 12;
        case 4: return 14;
        case 5: return 14;
        case 6: return 7;
        case 7: return 11;
    }
    return 0;
}

void Enf_Stand();
void Enf_Walk();
void Enf_Run();
void Enf_Attack();
void Enf_Pain(entity attacker, float damage);
void Enf_Die();
void Enf_DieThink();
void Enf_FireLaser();
void Enf_Laser_Touch();

void Enf_SightSound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, EN_SND_SIGHT1, EN_SND_SIGHT2, EN_SND_SIGHT3, EN_SND_SIGHT4);
}

void Enf_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - EN_FR_STAND1;
    if (fi < 0 || fi > 6) { self.frame = EN_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > EN_FR_STAND7) self.frame = EN_FR_STAND1;
    self.think     = Enf_Stand;
    self.nextthink = time + EN_THINK_RATE;

    AI_Stand();
}

void Enf_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - EN_FR_WALK1;
    if (fi < 0 || fi > 15) { self.frame = EN_FR_WALK1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, EN_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > EN_FR_WALK16) self.frame = EN_FR_WALK1;
    self.think     = Enf_Walk;
    self.nextthink = time + EN_THINK_RATE;

    AI_Walk(Enf_WalkStep(fi));
}

void Enf_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - EN_FR_RUN1;
    if (fi < 0 || fi > 7) { self.frame = EN_FR_RUN1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, EN_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > EN_FR_RUN8) self.frame = EN_FR_RUN1;
    self.think     = Enf_Run;
    self.nextthink = time + EN_THINK_RATE;

    AI_Run(Enf_RunStep(fi));
}

void Enf_Laser_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_STATIC, PITCH_NORM, EN_SND_HIT);

    if (other.takedamage)
    {
        T_Damage(other, self, self.owner, EN_LASER_DMG, DMG_ENERGYBEAM);
    }
    else
    {
        vector org = self.origin - 8 * normalize(self.velocity);
		te_gunshot(org);
    }

    remove(self);
}

void Enf_FireLaser()
{
    if (!self.enemy) return;

    self.effects = self.effects | EF_MUZZLEFLASH;
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, EN_SND_FIRE);

    makevectors(self.angles);
    vector org = self.origin + v_forward * 30 + v_right * 8.5 + '0 0 16';
    vector dir = normalize(self.enemy.origin - self.origin);

    entity m = spawn();
    m.owner     = self;
    m.classname = "enforcer_laser";
    m.movetype  = MOVETYPE_FLY;
    m.solid     = SOLID_BBOX;
    m.effects   = m.effects | EF_DIMLIGHT;
    m.touch     = Enf_Laser_Touch;
    m.think     = SUB_Remove;
    m.nextthink = time + 5;

    setmodel(m, EN_LASER_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, org);

    m.velocity = dir * EN_LASER_SPEED;
    m.angles   = vectoangles(m.velocity);
}

void Enf_Attack()
{
    if (self.frame < EN_FR_ATTACK1 || self.frame > EN_FR_ATTACK10)
        self.frame = EN_FR_ATTACK1;

    float fi = self.frame - EN_FR_ATTACK1;

    if (fi == 5 || fi == 9)
        Enf_FireLaser();
    else
        AI_Face();

    self.frame = self.frame + 1;
    if (self.frame > EN_FR_ATTACK10)
    {
        self.frame     = EN_FR_RUN1;
        self.think     = Enf_Run;
        self.nextthink = time + EN_THINK_RATE;
        return;
    }
    self.think     = Enf_Attack;
    self.nextthink = time + EN_THINK_RATE;
}

void Enf_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > EN_FR_PAIN4)
    {
        self.frame     = EN_FR_RUN1;
        self.think     = Enf_Run;
        self.nextthink = time + EN_THINK_RATE;
        return;
    }
    self.think     = Enf_PainThink;
    self.nextthink = time + EN_THINK_RATE;
}

void Enf_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + EN_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, EN_SND_PAIN1, EN_SND_PAIN2);

    self.frame     = EN_FR_PAIN1;
    self.think     = Enf_PainThink;
    self.nextthink = time + EN_THINK_RATE;
}

void Enf_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == EN_FR_DEATH3)
        Monster_BecomeCorpse('-16 -16 -24', '16 16 -8');

    if (self.frame >= EN_FR_DEATH14)
    {
        self.frame = EN_FR_DEATH14;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Enf_DieThink;
    self.nextthink = time + EN_THINK_RATE;
}

void Enf_Die()
{
    if (self.health < -35)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, EN_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = EN_FR_DEATH1;

    self.think     = Enf_DieThink;
    self.nextthink = time + EN_THINK_RATE;
}


void Enf_Precache()
{
    precache_model(EN_MODEL);
    precache_model(EN_HEAD_MODEL);
    precache_model(EN_LASER_MODEL);
    Gib_Q1Precache();

    precache_sound(EN_SND_DEATH);
    precache_sound(EN_SND_FIRE);
    precache_sound(EN_SND_HIT);
    precache_sound(EN_SND_IDLE);
    precache_sound(EN_SND_PAIN1);
    precache_sound(EN_SND_PAIN2);
    precache_sound(EN_SND_SIGHT1);
    precache_sound(EN_SND_SIGHT2);
    precache_sound(EN_SND_SIGHT3);
    precache_sound(EN_SND_SIGHT4);
    precache_sound(EN_SND_GIB);
}

void monster_enforcer()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Enf_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = EN_HEALTH;
    self.max_health  = EN_HEALTH;
    self.view_ofs    = '0 0 24';

    setmodel(self, EN_MODEL);
    setsize(self, '-16 -16 -24', '16 16 40');

    self.th_stand   = Enf_Stand;
    self.th_walk    = Enf_Walk;
    self.th_run     = Enf_Run;
    self.th_die     = Enf_Die;
    self.monster_gibHead = EN_HEAD_MODEL;
    self.th_pain    = Enf_Pain;
    self.th_missile = Enf_Attack;
    self.sightSound = Enf_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
