
#define SHAL_FRAME_ATTACK1     0
#define SHAL_FRAME_ATTACK9     8
#define SHAL_FRAME_ATTACK11    10
#define SHAL_FRAME_PAIN1       11
#define SHAL_FRAME_PAIN5       15
#define SHAL_FRAME_DEATH1      16
#define SHAL_FRAME_DEATH7      22
#define SHAL_FRAME_WALK1       23
#define SHAL_FRAME_WALK12      34

#define SHAL_MODEL             "progs/shalrath.mdl"
#define SHAL_HEAD_MODEL        "progs/h_shal.mdl"
#define SHAL_MISSILE_MODEL     "progs/v_spike.mdl"
#define SHAL_EXPLOSION_MODEL   "progs/s_explod.spr"

#define SHAL_SND_ATTACK        "shalrath/attack.wav"
#define SHAL_SND_LAUNCH        "shalrath/attack2.wav"
#define SHAL_SND_DEATH         "shalrath/death.wav"
#define SHAL_SND_IDLE          "shalrath/idle.wav"
#define SHAL_SND_PAIN          "shalrath/pain.wav"
#define SHAL_SND_SIGHT         "shalrath/sight.wav"
#define SHAL_SND_GIB           "player/udeath.wav"
#define SHAL_SND_EXPLODE       "weapons/explode3.wav"

#define SHAL_HEALTH            120
#define SHAL_MISSILE_DMG       30
#define SHAL_MISSILE_RADIUS    150
#define SHAL_MISSILE_SPEED     400
#define SHAL_MISSILE_HOMING_E  250
#define SHAL_MISSILE_HOMING_N  280
#define SHAL_MISSILE_HOMING_H  350
#define SHAL_PAIN_COOLDOWN     3
#define SHAL_THINK_RATE        0.1


float Shal_WalkStep(float frameOffset)
{
    switch (frameOffset)
    {
        case 0:  return 6;
        case 1:  return 4;
        case 2:  return 0;
        case 3:  return 0;
        case 4:  return 0;
        case 5:  return 0;
        case 6:  return 5;
        case 7:  return 6;
        case 8:  return 5;
        case 9:  return 0;
        case 10: return 4;
        case 11: return 5;
    }
    return 0;
}

void Shal_Stand();
void Shal_Walk();
void Shal_Run();
void Shal_Attack();
void Shal_Pain(entity attacker, float damage);
void Shal_Die();
void Shal_DieThink();
void Shal_FireMissile();
void Shal_Missile_Home();
void Shal_Missile_Touch();

void Shal_Stand()
{
    if (Monster_YieldIfDead()) return;
    self.frame = SHAL_FRAME_WALK1;
    self.think = Shal_Stand;
    self.nextthink = time + SHAL_THINK_RATE;
    AI_Stand();
}

void Shal_Walk()
{
    if (Monster_YieldIfDead()) return;
    self.think = Shal_Walk;
    self.nextthink = time + SHAL_THINK_RATE;
	
    float fi = self.frame - SHAL_FRAME_WALK1;
    if (fi < 0 || fi > 11) { self.frame = SHAL_FRAME_WALK1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, SHAL_SND_IDLE);

    AI_Walk(Shal_WalkStep(fi));

    self.frame = self.frame + 1;
    if (self.frame > SHAL_FRAME_WALK12) self.frame = SHAL_FRAME_WALK1;


}

void Shal_Run()
{
    if (Monster_YieldIfDead()) return;
    self.think = Shal_Run;
    self.nextthink = time + SHAL_THINK_RATE;
	
    float fi = self.frame - SHAL_FRAME_WALK1;
    if (fi < 0 || fi > 11) { self.frame = SHAL_FRAME_WALK1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, SHAL_SND_IDLE);

    AI_Run(Shal_WalkStep(fi));

    self.frame = self.frame + 1;
    if (self.frame > SHAL_FRAME_WALK12) self.frame = SHAL_FRAME_WALK1;


}

void Shal_Attack()
{

    self.think = Shal_Attack;
    self.nextthink = time + SHAL_THINK_RATE;
    if (self.frame < SHAL_FRAME_ATTACK1 || self.frame > SHAL_FRAME_ATTACK11)
    {
        self.frame = SHAL_FRAME_ATTACK1;
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SHAL_SND_ATTACK);
    }

    float fi = self.frame - SHAL_FRAME_ATTACK1;
    if (fi == 8) Shal_FireMissile();
    else         AI_Face();

    self.frame = self.frame + 1;
    if (self.frame > SHAL_FRAME_ATTACK11)
    {
        self.frame = SHAL_FRAME_WALK1;
        self.think = Shal_Run;
        self.nextthink = time + SHAL_THINK_RATE;
        return;
    }

}

void Shal_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > SHAL_FRAME_PAIN5)
    {
        self.frame = SHAL_FRAME_WALK1;
        self.think = Shal_Run;
        self.nextthink = time + SHAL_THINK_RATE;
        return;
    }
    self.think = Shal_PainThink;
    self.nextthink = time + SHAL_THINK_RATE;
}

void Shal_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + SHAL_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SHAL_SND_PAIN);
    self.frame = SHAL_FRAME_PAIN1;
    self.think = Shal_PainThink;
    self.nextthink = time + SHAL_THINK_RATE;
}

void Shal_DieThink()
{
    // Delay one tick so Combat_Killed still sees FL_MONSTER on its way out.
    if (self.solid != SOLID_CORPSE)
        Monster_BecomeCorpse('-32 -32 -24', '32 32 -4');

    self.frame = self.frame + 1;
    if (self.frame >= SHAL_FRAME_DEATH7)
    {
        self.frame = SHAL_FRAME_DEATH7;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think = Shal_DieThink;
    self.nextthink = time + SHAL_THINK_RATE;
}

void Shal_Die()
{
    if (self.health < -90)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SHAL_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame = SHAL_FRAME_DEATH1;

    self.think = Shal_DieThink;
    self.nextthink = time + SHAL_THINK_RATE;
}

void Shal_Missile_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    T_RadiusDamage(self, self.owner, SHAL_MISSILE_DMG, SHAL_MISSILE_RADIUS, DMG_BLAST);
    te_explosion(self.origin);
    Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(2000), PITCH_NORM, SHAL_SND_EXPLODE);
    remove(self);
}

void Shal_Missile_Home()
{
    if (!self.enemy || self.enemy.health <= 0)
    {
        remove(self);
        return;
    }

    vector dst = self.enemy.origin + '0 0 10';
    vector dir = normalize(dst - self.origin);

    float speed;
    if      (skill >= 3) speed = SHAL_MISSILE_HOMING_H;
    else if (skill >= 2) speed = SHAL_MISSILE_HOMING_N;
    else                 speed = SHAL_MISSILE_HOMING_E;

    self.velocity = dir * speed;
    self.angles   = vectoangles(dir);

    self.think = Shal_Missile_Home;
    self.nextthink = time + 0.2;
}

void Shal_FireMissile()
{
    if (!self.enemy || self.enemy.health <= 0) return;

    self.effects = self.effects | EF_MUZZLEFLASH;
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, SHAL_SND_LAUNCH);

    vector spawnPos = self.origin + '0 0 10';
    vector dst      = self.enemy.origin + '0 0 10';
    vector dir      = normalize(dst - spawnPos);

    float dist     = vlen(self.enemy.origin - self.origin);
    float flytime  = dist * 0.002;
    if (flytime < 0.1) flytime = 0.1;

    entity m       = spawn();
    m.owner        = self;
    m.movetype     = MOVETYPE_FLYMISSILE;
    m.solid        = SOLID_BBOX;
    m.classname    = "shalrath_missile";
    setmodel(m, SHAL_MISSILE_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, spawnPos);

    m.velocity     = dir * SHAL_MISSILE_SPEED;
    m.avelocity    = '300 300 300';
    m.angles       = vectoangles(dir);

    m.enemy        = self.enemy;
    m.touch        = Shal_Missile_Touch;
    m.think        = Shal_Missile_Home;
    m.nextthink    = time + flytime;
}

void Shal_Precache()
{
    precache_model(SHAL_MODEL);
    precache_model(SHAL_HEAD_MODEL);
    precache_model(SHAL_MISSILE_MODEL);
    precache_model(SHAL_EXPLOSION_MODEL);
    Gib_Q1Precache();

    precache_sound(SHAL_SND_ATTACK);
    precache_sound(SHAL_SND_LAUNCH);
    precache_sound(SHAL_SND_DEATH);
    precache_sound(SHAL_SND_IDLE);
    precache_sound(SHAL_SND_PAIN);
    precache_sound(SHAL_SND_SIGHT);
    precache_sound(SHAL_SND_GIB);
    precache_sound(SHAL_SND_EXPLODE);
}

void monster_shalrath()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Shal_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = SHAL_HEALTH;
    self.max_health  = SHAL_HEALTH;
    self.view_ofs    = '0 0 24';

    setmodel(self, SHAL_MODEL);
    setsize(self, '-32 -32 -24', '32 32 48');

    self.th_stand   = Shal_Stand;
    self.th_walk    = Shal_Walk;
    self.th_run     = Shal_Run;
    self.th_die     = Shal_Die;
    self.monster_gibHead = SHAL_HEAD_MODEL;
    self.th_pain    = Shal_Pain;
    self.th_missile = Shal_Attack;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
