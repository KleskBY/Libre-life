

#define SH_FR_STAND1    0
#define SH_FR_STAND17   16
#define SH_FR_WALK1     17
#define SH_FR_WALK12    28
#define SH_FR_RUN1      29
#define SH_FR_RUN6      34
#define SH_FR_SMASH1    35
#define SH_FR_SMASH10   44
#define SH_FR_SMASH12   46
#define SH_FR_SWINGR1   47
#define SH_FR_SWINGR7   53
#define SH_FR_SWINGR9   55
#define SH_FR_SWINGL1   56
#define SH_FR_SWINGL7   62
#define SH_FR_SWINGL9   64
#define SH_FR_MAGIC1    65
#define SH_FR_MAGIC6    70
#define SH_FR_MAGIC9    73
#define SH_FR_MAGIC10   74
#define SH_FR_MAGIC11   75
#define SH_FR_MAGIC12   76
#define SH_FR_PAIN1     77
#define SH_FR_PAIN6     82
#define SH_FR_DEATH1    83
#define SH_FR_DEATH3    85
#define SH_FR_DEATH11   93

#define SH_MODEL        "progs/shambler.mdl"
#define SH_HEAD_MODEL   "progs/h_shams.mdl"
#define SH_LIGHT_MODEL  "progs/s_light.mdl"
#define SH_BOLT_MODEL   "progs/bolt.mdl"

#define SH_SND_ATTACK   "shambler/sattck1.wav"
#define SH_SND_BOOM     "shambler/sboom.wav"
#define SH_SND_DEATH    "shambler/sdeath.wav"
#define SH_SND_PAIN     "shambler/shurt2.wav"
#define SH_SND_IDLE     "shambler/sidle.wav"
#define SH_SND_SIGHT    "shambler/ssight.wav"
#define SH_SND_MELEE1   "shambler/melee1.wav"
#define SH_SND_MELEE2   "shambler/melee2.wav"
#define SH_SND_SMACK    "shambler/smack.wav"
#define SH_SND_GIB      "player/udeath.wav"

#define SH_HEALTH         300
#define SH_SMASH_DMG_MIN  20
#define SH_SMASH_DMG_MAX  60
#define SH_SMASH_REACH    100
#define SH_CLAW_DMG_MIN   10
#define SH_CLAW_DMG_MAX   30
#define SH_CLAW_REACH     100
#define SH_LIGHT_DMG      10
#define SH_LIGHT_RANGE    600
#define SH_PAIN_COOLDOWN  2
#define SH_THINK_RATE     0.1

float Sham_WalkStep(float fi)
{
    switch (fi)
    {
        case 0:  return 10;
        case 1:  return 9;
        case 2:  return 9;
        case 3:  return 5;
        case 4:  return 6;
        case 5:  return 12;
        case 6:  return 8;
        case 7:  return 3;
        case 8:  return 13;
        case 9:  return 9;
        case 10: return 7;
        case 11: return 7;
    }
    return 0;
}

float Sham_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 20;
        case 1: return 24;
        case 2: return 20;
        case 3: return 20;
        case 4: return 24;
        case 5: return 20;
    }
    return 0;
}

float Sham_SmashCharge(float fi)
{
    switch (fi)
    {
        case 0:  return 2;
        case 1:  return 6;
        case 2:  return 6;
        case 3:  return 5;
        case 4:  return 4;
        case 5:  return 1;
        case 6:  return 0;
        case 7:  return 0;
        case 8:  return 0;
        case 9:  return 0;
        case 10: return 5;
        case 11: return 4;
    }
    return 0;
}

float Sham_SwingRCharge(float fi)
{
    switch (fi)
    {
        case 0: return 1;
        case 1: return 8;
        case 2: return 14;
        case 3: return 7;
        case 4: return 3;
        case 5: return 6;
        case 6: return 6;
        case 7: return 3;
        case 8: return 11;
    }
    return 0;
}

float Sham_SwingLCharge(float fi)
{
    switch (fi)
    {
        case 0: return 5;
        case 1: return 3;
        case 2: return 7;
        case 3: return 3;
        case 4: return 7;
        case 5: return 9;
        case 6: return 5;
        case 7: return 4;
        case 8: return 8;
    }
    return 0;
}

void Sham_Stand();
void Sham_Walk();
void Sham_Run();
void Sham_Smash();
void Sham_SwingR();
void Sham_SwingL();
void Sham_Magic();
void Sham_Melee();
void Sham_Pain(entity attacker, float damage);
void Sham_Die();
void Sham_DieThink();
void Sham_CastLightning();
void Sham_LightningDamage(vector p1, vector p2, entity from, float damage);

void Sham_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_SIGHT);
}

void Sham_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - SH_FR_STAND1;
    if (fi < 0 || fi > 16) { self.frame = SH_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_STAND17) self.frame = SH_FR_STAND1;
    self.think     = Sham_Stand;
    self.nextthink = time + SH_THINK_RATE;

    AI_Stand();
}

void Sham_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - SH_FR_WALK1;
    if (fi < 0 || fi > 11) { self.frame = SH_FR_WALK1; fi = 0; }

    if (fi == 11 && random() > 0.8)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, SH_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_WALK12) self.frame = SH_FR_WALK1;
    self.think     = Sham_Walk;
    self.nextthink = time + SH_THINK_RATE;

    AI_Walk(Sham_WalkStep(fi));
}

void Sham_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - SH_FR_RUN1;
    if (fi < 0 || fi > 5) { self.frame = SH_FR_RUN1; fi = 0; }

    if (fi == 5 && random() > 0.8)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, SH_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_RUN6) self.frame = SH_FR_RUN1;
    self.think     = Sham_Run;
    self.nextthink = time + SH_THINK_RATE;

    AI_Run(Sham_RunStep(fi));
}

void Sham_Smash()
{
    if (self.frame < SH_FR_SMASH1 || self.frame > SH_FR_SMASH12)
        self.frame = SH_FR_SMASH1;

    float fi = self.frame - SH_FR_SMASH1;

    if (fi == 0)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_MELEE1);

    if (fi == 9)
    {
        if (self.enemy && CanDamage(self.enemy, self) && vlen(self.enemy.origin - self.origin) <= SH_SMASH_REACH)
        {
            T_Damage(self.enemy, self, self, Math_RandomInt(SH_SMASH_DMG_MIN,SH_SMASH_DMG_MAX), DMG_SLASH);
            Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_SMACK);
        }
    }

    AI_Charge(Sham_SmashCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_SMASH12)
    {
        self.frame     = SH_FR_RUN1;
        self.think     = Sham_Run;
        self.nextthink = time + SH_THINK_RATE;
        return;
    }
    self.think     = Sham_Smash;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_Claw(float side)
{
    if (!self.enemy) return;
    if (vlen(self.enemy.origin - self.origin) > SH_CLAW_REACH) return;
    T_Damage(self.enemy, self, self, Math_RandomInt(SH_CLAW_DMG_MIN, SH_CLAW_DMG_MAX), DMG_SLASH);
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_SMACK);
}

void Sham_SwingR()
{
    if (self.frame < SH_FR_SWINGR1 || self.frame > SH_FR_SWINGR9)
        self.frame = SH_FR_SWINGR1;

    float fi = self.frame - SH_FR_SWINGR1;

    if (fi == 0) Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_MELEE1);
    if (fi == 6) Sham_Claw(-250);

    AI_Charge(Sham_SwingRCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_SWINGR9)
    {
        if (random() < 0.5)
        {
            self.frame = SH_FR_SWINGL1;
            self.think = Sham_SwingL;
        }
        else
        {
            self.frame = SH_FR_RUN1;
            self.think = Sham_Run;
        }
        self.nextthink = time + SH_THINK_RATE;
        return;
    }
    self.think     = Sham_SwingR;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_SwingL()
{
    if (self.frame < SH_FR_SWINGL1 || self.frame > SH_FR_SWINGL9)
        self.frame = SH_FR_SWINGL1;

    float fi = self.frame - SH_FR_SWINGL1;

    if (fi == 0) Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_MELEE2);
    if (fi == 6) Sham_Claw(250);

    AI_Charge(Sham_SwingLCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_SWINGL9)
    {
        if (random() < 0.5)
        {
            self.frame = SH_FR_SWINGR1;
            self.think = Sham_SwingR;
        }
        else
        {
            self.frame = SH_FR_RUN1;
            self.think = Sham_Run;
        }
        self.nextthink = time + SH_THINK_RATE;
        return;
    }
    self.think     = Sham_SwingL;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_Melee()
{
    float r = random();
    if (r > 0.6 || self.health == self.max_health)
    {
        self.frame = SH_FR_SMASH1;
        self.think = Sham_Smash;
    }
    else if (r > 0.3)
    {
        self.frame = SH_FR_SWINGR1;
        self.think = Sham_SwingR;
    }
    else
    {
        self.frame = SH_FR_SWINGL1;
        self.think = Sham_SwingL;
    }
    self.nextthink = time + SH_THINK_RATE;
}


void Sham_LightningDamage(vector p1, vector p2, entity from, float damage)
{
    vector lineDir = normalize(p2 - p1);
    float length = vlen(p2 - p1);

    entity head = findradius((p1 + p2) * 0.5, length * 0.5 + 32);
    while (head)
    {
        if (head != from && head.takedamage)
        {
            vector toHead = head.origin - p1;
            float t = toHead * lineDir;
            if (t < 0) t = 0;
            if (t > length) t = length;
            vector closest = p1 + lineDir * t;
            float d = vlen(head.origin - closest);
            if (d < 32)
            {
                T_Damage(head, from, from, damage, DMG_SHOCK);
            }
        }
        head = head.chain;
    }
}

void Sham_CastLightning()
{
    if (!self.enemy) return;

    self.effects = self.effects | EF_MUZZLEFLASH;
    AI_Face();

    vector org = self.origin + '0 0 40';
    vector dir = normalize(self.enemy.origin + '0 0 16' - org);

    traceline(org, org + dir * SH_LIGHT_RANGE, TRUE, self);
	te_lightning1(self, org, trace_endpos);
    Sham_LightningDamage(org, trace_endpos, self, SH_LIGHT_DMG);
}


void Sham_Magic()
{
    if (self.frame < SH_FR_MAGIC1 || self.frame > SH_FR_MAGIC12)
        self.frame = SH_FR_MAGIC1;

    float fi = self.frame - SH_FR_MAGIC1;

    if (fi == 0)
    {
        AI_Face();
        Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, SH_SND_ATTACK);
    }
    else if (fi == 5)
    {
        Sham_CastLightning();
        Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, SH_SND_BOOM);
    }
    else if (fi == 8 || fi == 9)
    {
        Sham_CastLightning();
    }
    else if (fi == 10 && skill == 3)
    {
        Sham_CastLightning();
    }
    else
    {
        AI_Face();
    }

    self.frame = self.frame + 1;
    if (self.frame > SH_FR_MAGIC12)
    {
        self.frame     = SH_FR_RUN1;
        self.think     = Sham_Run;
        self.nextthink = time + SH_THINK_RATE;
        return;
    }
    self.think     = Sham_Magic;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > SH_FR_PAIN6)
    {
        self.frame     = SH_FR_RUN1;
        self.think     = Sham_Run;
        self.nextthink = time + SH_THINK_RATE;
        return;
    }
    self.think     = Sham_PainThink;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_Pain(entity attacker, float damage)
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_PAIN);

    if (self.health <= 0) return;
    if (random() * 400 > damage) return;
    if (self.pain_finished > time) return;
    self.pain_finished = time + SH_PAIN_COOLDOWN;

    self.frame     = SH_FR_PAIN1;
    self.think     = Sham_PainThink;
    self.nextthink = time + SH_THINK_RATE;
}


void Sham_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == SH_FR_DEATH3)
        Monster_BecomeCorpse('-32 -32 -24', '32 32 0');

    if (self.frame >= SH_FR_DEATH11)
    {
        self.frame = SH_FR_DEATH11;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Sham_DieThink;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_Die()
{
    if (self.health < -60)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, SH_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = SH_FR_DEATH1;

    self.think     = Sham_DieThink;
    self.nextthink = time + SH_THINK_RATE;
}

void Sham_Precache()
{
    precache_model(SH_MODEL);
    precache_model(SH_HEAD_MODEL);
    precache_model(SH_LIGHT_MODEL);
    precache_model(SH_BOLT_MODEL);
    Gib_Q1Precache();

    precache_sound(SH_SND_ATTACK);
    precache_sound(SH_SND_BOOM);
    precache_sound(SH_SND_DEATH);
    precache_sound(SH_SND_PAIN);
    precache_sound(SH_SND_IDLE);
    precache_sound(SH_SND_SIGHT);
    precache_sound(SH_SND_MELEE1);
    precache_sound(SH_SND_MELEE2);
    precache_sound(SH_SND_SMACK);
    precache_sound(SH_SND_GIB);
}

void monster_shambler()
{
    self.q1_monster = TRUE;
    if (cvar("gamemode") == MODE_DM)
    {
        remove(self);
        return;
    }

    Sham_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = SH_HEALTH;
    self.max_health  = SH_HEALTH;
    self.view_ofs    = '0 0 40';

    setmodel(self, SH_MODEL);
    setsize(self, '-32 -32 -24', '32 32 64');

    self.th_stand   = Sham_Stand;
    self.th_walk    = Sham_Walk;
    self.th_run     = Sham_Run;
    self.th_die     = Sham_Die;
    self.monster_gibHead = SH_HEAD_MODEL;
    self.th_pain    = Sham_Pain;
    self.th_melee   = Sham_Melee;
    self.th_missile = Sham_Magic;
    self.sightSound = Sham_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
