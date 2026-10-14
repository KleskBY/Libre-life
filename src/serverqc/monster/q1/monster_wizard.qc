
#define WZ_FR_HOVER1     0
#define WZ_FR_HOVER8     7
#define WZ_FR_FLY1       15
#define WZ_FR_FLY14      28
#define WZ_FR_MAGATT1    29
#define WZ_FR_MAGATT5    34
#define WZ_FR_MAGATT13   41
#define WZ_FR_PAIN1      42
#define WZ_FR_PAIN4      45
#define WZ_FR_DEATH1     46
#define WZ_FR_DEATH3     48
#define WZ_FR_DEATH8     53

#define WZ_MODEL         "progs/wizard.mdl"
#define WZ_HEAD_MODEL    "progs/h_wizard.mdl"
#define WZ_SPIKE_MODEL   "progs/w_spike.mdl"

#define WZ_SND_ATTACK    "wizard/wattack.wav"
#define WZ_SND_HIT       "wizard/hit.wav"
#define WZ_SND_DEATH     "wizard/wdeath.wav"
#define WZ_SND_IDLE1     "wizard/widle1.wav"
#define WZ_SND_IDLE2     "wizard/widle2.wav"
#define WZ_SND_PAIN      "wizard/wpain.wav"
#define WZ_SND_SIGHT     "wizard/wsight.wav"
#define WZ_SND_GIB       "player/udeath.wav"

#define WZ_HEALTH        80
#define WZ_SPIKE_DMG     9
#define WZ_SPIKE_SPEED   600
#define WZ_PAIN_COOLDOWN 1
#define WZ_THINK_RATE    0.1

void Wiz_Stand();
void Wiz_Walk();
void Wiz_Run();
void Wiz_Attack();
void Wiz_Pain(entity attacker, float damage);
void Wiz_Die();
void Wiz_DieThink();
void Wiz_FireSpike(vector handOffset);
void Wiz_Spike_Touch();

void Wiz_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, WZ_SND_SIGHT);
}

void Wiz_IdleSound()
{
    if (self.waitmin >= time) return;
    self.waitmin = time + 2;
    float r = random() * 5;
    if (r > 4.5) Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, WZ_SND_IDLE1);
    else if (r < 1.5) Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, WZ_SND_IDLE2);
}

void Wiz_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - WZ_FR_HOVER1;
    if (fi < 0 || fi > 7) { self.frame = WZ_FR_HOVER1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > WZ_FR_HOVER8) self.frame = WZ_FR_HOVER1;
    self.think     = Wiz_Stand;
    self.nextthink = time + WZ_THINK_RATE;

    AI_Stand();
}

void Wiz_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - WZ_FR_HOVER1;
    if (fi < 0 || fi > 7) { self.frame = WZ_FR_HOVER1; fi = 0; }

    if (fi == 0) Wiz_IdleSound();

    self.frame = self.frame + 1;
    if (self.frame > WZ_FR_HOVER8) self.frame = WZ_FR_HOVER1;
    self.think     = Wiz_Walk;
    self.nextthink = time + WZ_THINK_RATE;

    AI_Walk(8);
}

void Wiz_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - WZ_FR_FLY1;
    if (fi < 0 || fi > 13) { self.frame = WZ_FR_FLY1; fi = 0; }

    if (fi == 0) Wiz_IdleSound();

    self.frame = self.frame + 1;
    if (self.frame > WZ_FR_FLY14) self.frame = WZ_FR_FLY1;
    self.think     = Wiz_Run;
    self.nextthink = time + WZ_THINK_RATE;

    AI_Run(16);
}

void Wiz_Spike_Touch()
{
    if (other == self.owner) return;
    if (other.solid == SOLID_TRIGGER) return;

    if (other.takedamage)
        T_Damage(other, self, self.owner, WZ_SPIKE_DMG, DMG_GENERIC);

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, WZ_SND_HIT);
    remove(self);
}

void Wiz_FireSpike(vector handOffset)
{
    if (!self.enemy) return;

    makevectors(self.angles);

    vector org = self.origin
               + handOffset_x * v_forward
               + handOffset_y * v_right
               + handOffset_z * '0 0 1';

    vector dir = normalize(self.enemy.origin + self.enemy.view_ofs - org);

    entity m = spawn();
    m.owner     = self;
    m.classname = "wizspike";
    m.movetype  = MOVETYPE_FLYMISSILE;
    m.solid     = SOLID_BBOX;
    m.touch     = Wiz_Spike_Touch;
    m.think     = SUB_Remove;
    m.nextthink = time + 5;

    setmodel(m, WZ_SPIKE_MODEL);
    setsize(m, VEC_ORIGIN, VEC_ORIGIN);
    setorigin(m, org);

    m.velocity = dir * WZ_SPIKE_SPEED;
    m.angles   = vectoangles(m.velocity);
}

void Wiz_Attack()
{
    if (self.frame < WZ_FR_MAGATT1 || self.frame > WZ_FR_MAGATT5)
        self.frame = WZ_FR_MAGATT1;

    float fi = self.frame - WZ_FR_MAGATT1;

    if (fi == 0)
    {
        Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, WZ_SND_ATTACK);
        Wiz_FireSpike('14  14 30');
    }
    else if (fi == 5)
    {
        Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, WZ_SND_ATTACK);
        Wiz_FireSpike('14 -14 30');
    }
    else
    {
        AI_Face();
    }

    self.frame = self.frame + 1;
    if (self.frame > WZ_FR_MAGATT5)
    {
        self.attack_finished = time + 2;
        self.frame     = WZ_FR_FLY1;
        self.think     = Wiz_Run;
        self.nextthink = time + WZ_THINK_RATE;
        return;
    }
    self.think     = Wiz_Attack;
    self.nextthink = time + WZ_THINK_RATE;
}

void Wiz_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > WZ_FR_PAIN4)
    {
        self.frame     = WZ_FR_FLY1;
        self.think     = Wiz_Run;
        self.nextthink = time + WZ_THINK_RATE;
        return;
    }
    self.think     = Wiz_PainThink;
    self.nextthink = time + WZ_THINK_RATE;
}

void Wiz_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + WZ_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, WZ_SND_PAIN);
    if (random() * 70 > damage) return;

    self.frame     = WZ_FR_PAIN1;
    self.think     = Wiz_PainThink;
    self.nextthink = time + WZ_THINK_RATE;
}

void Wiz_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == WZ_FR_DEATH3)
        Monster_BecomeCorpse('-16 -16 -24', '16 16 -8');

    if (self.frame >= WZ_FR_DEATH8)
    {
        self.frame = WZ_FR_DEATH8;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Wiz_DieThink;
    self.nextthink = time + WZ_THINK_RATE;
}

void Wiz_Die()
{
    if (self.health < -40)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, WZ_SND_DEATH);

    self.velocity_x = -200 + 400 * random();
    self.velocity_y = -200 + 400 * random();
    self.velocity_z = 100 + 100 * random();
    self.flags = self.flags - (self.flags & FL_ONGROUND);
    self.flags = self.flags - (self.flags & FL_FLY);
    self.movetype   = MOVETYPE_TOSS;
    self.takedamage = DAMAGE_NO;
    self.frame      = WZ_FR_DEATH1;

    self.think     = Wiz_DieThink;
    self.nextthink = time + WZ_THINK_RATE;
}

void Wiz_Precache()
{
    precache_model(WZ_MODEL);
    precache_model(WZ_HEAD_MODEL);
    Gib_Q1Precache();
    precache_model(WZ_SPIKE_MODEL);
    precache_model("progs/gib2.mdl");

    precache_sound(WZ_SND_ATTACK);
    precache_sound(WZ_SND_HIT);
    precache_sound(WZ_SND_DEATH);
    precache_sound(WZ_SND_IDLE1);
    precache_sound(WZ_SND_IDLE2);
    precache_sound(WZ_SND_PAIN);
    precache_sound(WZ_SND_SIGHT);
    precache_sound(WZ_SND_GIB);
}

void monster_wizard()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Wiz_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_FLY;
    self.yaw_speed   = 10;
    self.health      = WZ_HEALTH;
    self.max_health  = WZ_HEALTH;
    self.view_ofs    = '0 0 25';

    setmodel(self, WZ_MODEL);
    setsize(self, '-16 -16 -24', '16 16 40');

    self.th_stand   = Wiz_Stand;
    self.th_walk    = Wiz_Walk;
    self.th_run     = Wiz_Run;
    self.th_die     = Wiz_Die;
    self.monster_gibHead  = WZ_HEAD_MODEL;
    self.monster_gibPiece = "progs/gib2.mdl";
    self.th_pain    = Wiz_Pain;
    self.th_missile = Wiz_Attack;
    self.sightSound = Wiz_SightSound;

    Monster_InitTakeDamage();
    FlyMonster_Start();
}
