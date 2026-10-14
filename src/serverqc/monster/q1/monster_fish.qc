

#define FISH_FR_ATTACK1     0
#define FISH_FR_ATTACK18    17
#define FISH_FR_DEATH1      18
#define FISH_FR_DEATH21     38
#define FISH_FR_SWIM1       39
#define FISH_FR_SWIM18      56
#define FISH_FR_PAIN1       57
#define FISH_FR_PAIN9       65

#define FISH_MODEL          "progs/fish.mdl"

#define FISH_SND_DEATH      "fish/death.wav"
#define FISH_SND_BITE       "fish/bite.wav"
#define FISH_SND_IDLE       "fish/idle.wav"

#define FISH_HEALTH         25
#define FISH_BITE_DMG_MIN   1
#define FISH_BITE_DMG_MAX   6
#define FISH_BITE_REACH     60
#define FISH_THINK_RATE     0.1


void Fish_Stand();
void Fish_Walk();
void Fish_Run();
void Fish_Attack();
void Fish_Pain(entity attacker, float damage);
void Fish_Die();
void Fish_DieThink();
void Fish_Bite();

void Fish_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FISH_SND_IDLE);
}

void Fish_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - FISH_FR_SWIM1;
    if (fi < 0 || fi > 17) { self.frame = FISH_FR_SWIM1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > FISH_FR_SWIM18) self.frame = FISH_FR_SWIM1;
    self.think     = Fish_Stand;
    self.nextthink = time + FISH_THINK_RATE;

    AI_Stand();
}

void Fish_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - FISH_FR_SWIM1;
    if (fi < 0 || fi > 17) { self.frame = FISH_FR_SWIM1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > FISH_FR_SWIM18) self.frame = FISH_FR_SWIM1;
    self.think     = Fish_Walk;
    self.nextthink = time + FISH_THINK_RATE;

    AI_Walk(8);
}

void Fish_Run()
{
    if (Monster_YieldIfDead()) return;
    // Q1 run cycle steps through swim every-other frame, approximated with a +2 step
    float fi = self.frame - FISH_FR_SWIM1;
    if (fi < 0 || fi > 16) { self.frame = FISH_FR_SWIM1; fi = 0; }

    if (fi == 0 && random() < 0.5)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FISH_SND_IDLE);

    self.frame = self.frame + 2;
    if (self.frame > FISH_FR_SWIM18 - 1) self.frame = FISH_FR_SWIM1;
    self.think     = Fish_Run;
    self.nextthink = time + FISH_THINK_RATE;

    AI_Run(12);
}

void Fish_Bite()
{
    if (!self.enemy) return;
    if (vlen(self.enemy.origin - self.origin) > FISH_BITE_REACH) return;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FISH_SND_BITE);
    float dmg = Math_RandomInt(FISH_BITE_DMG_MIN, FISH_BITE_DMG_MAX);
    T_Damage(self.enemy, self, self, dmg, DMG_SLASH);
}

// 18-frame attack with three bite chances (Q1 frames 3, 9, 15).
void Fish_Attack()
{
    if (self.frame < FISH_FR_ATTACK1 || self.frame > FISH_FR_ATTACK18)
        self.frame = FISH_FR_ATTACK1;

    float fi = self.frame - FISH_FR_ATTACK1;
    if (fi == 2 || fi == 8 || fi == 14) Fish_Bite();
    else                                AI_Charge(10);

    self.frame = self.frame + 1;
    if (self.frame > FISH_FR_ATTACK18)
    {
        self.frame     = FISH_FR_SWIM1;
        self.think     = Fish_Run;
        self.nextthink = time + FISH_THINK_RATE;
        return;
    }
    self.think     = Fish_Attack;
    self.nextthink = time + FISH_THINK_RATE;
}

void Fish_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > FISH_FR_PAIN9)
    {
        self.frame     = FISH_FR_SWIM1;
        self.think     = Fish_Run;
        self.nextthink = time + FISH_THINK_RATE;
        return;
    }
    self.think     = Fish_PainThink;
    self.nextthink = time + FISH_THINK_RATE;
}

void Fish_Pain(entity attacker, float damage)
{
    self.frame     = FISH_FR_PAIN1;
    self.think     = Fish_PainThink;
    self.nextthink = time + FISH_THINK_RATE;
}

void Fish_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame >= FISH_FR_DEATH21)
    {
        self.frame = FISH_FR_DEATH21;
        Monster_BecomeCorpse('-16 -16 -24', '16 16 -8');
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Fish_DieThink;
    self.nextthink = time + FISH_THINK_RATE;
}

void Fish_Die()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FISH_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = FISH_FR_DEATH1;

    self.think     = Fish_DieThink;
    self.nextthink = time + FISH_THINK_RATE;
}


void Fish_Precache()
{
    precache_model(FISH_MODEL);
    Gib_Q1Precache();
    precache_sound(FISH_SND_DEATH);
    precache_sound(FISH_SND_BITE);
    precache_sound(FISH_SND_IDLE);
}

void monster_fish()
{
    self.q1_monster = TRUE;
    if (cvar("gamemode") == MODE_DM)
    {
        remove(self);
        return;
    }

    Fish_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = FISH_HEALTH;
    self.max_health  = FISH_HEALTH;
    self.view_ofs    = '0 0 10';

    setmodel(self, FISH_MODEL);
    setsize(self, '-16 -16 -24', '16 16 24');

    self.th_stand   = Fish_Stand;
    self.th_walk    = Fish_Walk;
    self.th_run     = Fish_Run;
    self.th_die     = Fish_Die;
    self.th_pain    = Fish_Pain;
    self.th_melee   = Fish_Attack;
    self.sightSound = Fish_SightSound;

    Monster_InitTakeDamage();
    SwimMonster_Start();
}
