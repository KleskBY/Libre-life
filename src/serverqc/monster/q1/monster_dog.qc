
#define DOG_FR_ATTACK1     0
#define DOG_FR_ATTACK4     3       // bite hits on this frame
#define DOG_FR_ATTACK8     7
#define DOG_FR_DEATH1      8
#define DOG_FR_DEATH9      16
#define DOG_FR_DEATHB1     17
#define DOG_FR_DEATHB9     25
#define DOG_FR_PAIN1       26
#define DOG_FR_PAIN6       31
#define DOG_FR_LEAP1       60
#define DOG_FR_LEAP2       61
#define DOG_FR_LEAP9       68
#define DOG_FR_STAND1      69
#define DOG_FR_STAND9      77
#define DOG_FR_RUN1        48
#define DOG_FR_RUN12       59
#define DOG_FR_WALK1       78
#define DOG_FR_WALK8       85

#define DOG_MODEL          "progs/dog.mdl"
#define DOG_HEAD_MODEL     "progs/h_dog.mdl"

#define DOG_SND_ATTACK     "dog/dattack1.wav"
#define DOG_SND_DEATH      "dog/ddeath.wav"
#define DOG_SND_PAIN       "dog/dpain1.wav"
#define DOG_SND_SIGHT      "dog/dsight.wav"
#define DOG_SND_IDLE       "dog/idle.wav"
#define DOG_SND_GIB        "player/udeath.wav"

// Tunables
#define DOG_HEALTH         25
#define DOG_BITE_DMG_MIN   3       // matches Q1 (random()*3*8)
#define DOG_BITE_DMG_MAX   24
#define DOG_BITE_REACH     100
#define DOG_LEAP_DMG_MIN   10
#define DOG_LEAP_DMG_MAX   20
#define DOG_LEAP_VEL_FWD   300
#define DOG_LEAP_VEL_UP    200
#define DOG_LEAP_MIN_DIST  80
#define DOG_LEAP_MAX_DIST  150
#define DOG_PAIN_COOLDOWN  1
#define DOG_THINK_RATE     0.1

// Per-frame stride tables
float Dog_RunStep(float fi)
{
    switch (fi)
    {
        case 0:  return 16;
        case 1:  return 32;
        case 2:  return 32;
        case 3:  return 20;
        case 4:  return 64;
        case 5:  return 32;
        case 6:  return 16;
        case 7:  return 32;
        case 8:  return 32;
        case 9:  return 20;
        case 10: return 64;
        case 11: return 32;
    }
    return 0;
}

void Dog_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, DOG_SND_SIGHT);
}

void Dog_Stand();
void Dog_Walk();
void Dog_Run();
void Dog_Attack();
void Dog_Leap();
void Dog_Pain(entity attacker, float damage);
void Dog_Die();
void Dog_DieThink();
void Dog_Bite();
void Dog_JumpTouch();
float Dog_CheckAttack();

// Idle / locomotion
void Dog_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - DOG_FR_STAND1;
    if (fi < 0 || fi > 8) { self.frame = DOG_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > DOG_FR_STAND9) self.frame = DOG_FR_STAND1;
    self.think     = Dog_Stand;
    self.nextthink = time + DOG_THINK_RATE;

    AI_Stand();
}

void Dog_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - DOG_FR_WALK1;
    if (fi < 0 || fi > 7) { self.frame = DOG_FR_WALK1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, DOG_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > DOG_FR_WALK8) self.frame = DOG_FR_WALK1;
    self.think     = Dog_Walk;
    self.nextthink = time + DOG_THINK_RATE;

    AI_Walk(8);
}

void Dog_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - DOG_FR_RUN1;
    if (fi < 0 || fi > 11) { self.frame = DOG_FR_RUN1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, DOG_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > DOG_FR_RUN12) self.frame = DOG_FR_RUN1;
    self.think     = Dog_Run;
    self.nextthink = time + DOG_THINK_RATE;

    AI_Run(Dog_RunStep(fi));
}

// Bite (melee)
void Dog_Bite()
{
    if (!self.enemy) return;
    if (!CanDamage(self.enemy, self)) return;
    if (vlen(self.enemy.origin - self.origin) > DOG_BITE_REACH) return;

    float dmg = DOG_BITE_DMG_MIN + random() * (DOG_BITE_DMG_MAX - DOG_BITE_DMG_MIN);
    T_Damage(self.enemy, self, self, dmg, DMG_SLASH);
}

void Dog_Attack()
{
    if (self.frame < DOG_FR_ATTACK1 || self.frame > DOG_FR_ATTACK8)
        self.frame = DOG_FR_ATTACK1;

    float fi = self.frame - DOG_FR_ATTACK1;
    if (fi == 3)
    {
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, DOG_SND_ATTACK);
        Dog_Bite();
    }
    AI_Charge(10);

    self.frame = self.frame + 1;
    if (self.frame > DOG_FR_ATTACK8)
    {
        self.frame     = DOG_FR_RUN1;
        self.think     = Dog_Run;
        self.nextthink = time + DOG_THINK_RATE;
        return;
    }
    self.think     = Dog_Attack;
    self.nextthink = time + DOG_THINK_RATE;
}

// Leap (missile/jump)
void Dog_JumpTouch()
{
    if (self.health <= 0) return;

    if (other.takedamage && vlen(self.velocity) > 300)
    {
        float dmg = DOG_LEAP_DMG_MIN + random() * (DOG_LEAP_DMG_MAX - DOG_LEAP_DMG_MIN);
        T_Damage(other, self, self, dmg, DMG_SLASH);
    }

    if (!checkbottom(self))
    {
        if (self.flags & FL_ONGROUND)
        {
            self.touch     = SUB_Null;
            self.think     = Dog_Leap;
            self.frame     = DOG_FR_LEAP1;
            self.nextthink = time + 0.1;
        }
        return;
    }

    self.touch     = SUB_Null;
    self.think     = Dog_Run;
    self.frame     = DOG_FR_RUN1;
    self.nextthink = time + 0.1;
}

void Dog_Leap()
{
    if (self.frame < DOG_FR_LEAP1 || self.frame > DOG_FR_LEAP9)
        self.frame = DOG_FR_LEAP1;

    float fi = self.frame - DOG_FR_LEAP1;

    if (fi == 0)
    {
        AI_Face();
    }
    else if (fi == 1)
    {
        AI_Face();
        self.touch = Dog_JumpTouch;
        makevectors(self.angles);
        self.origin_z = self.origin_z + 1;
        self.velocity = v_forward * DOG_LEAP_VEL_FWD + [0, 0, DOG_LEAP_VEL_UP];
        if (self.flags & FL_ONGROUND)
            self.flags = self.flags - FL_ONGROUND;
    }

    self.frame = self.frame + 1;
    if (self.frame > DOG_FR_LEAP9)
        self.frame = DOG_FR_LEAP9;     // hold final airborne pose

    self.think     = Dog_Leap;
    self.nextthink = time + DOG_THINK_RATE;
}

void Dog_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > DOG_FR_PAIN6)
    {
        self.frame     = DOG_FR_RUN1;
        self.think     = Dog_Run;
        self.nextthink = time + DOG_THINK_RATE;
        return;
    }
    self.think     = Dog_PainThink;
    self.nextthink = time + DOG_THINK_RATE;
}

void Dog_Pain(entity attacker, float damage)
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + DOG_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, DOG_SND_PAIN);
    self.frame     = DOG_FR_PAIN1;
    self.think     = Dog_PainThink;
    self.nextthink = time + DOG_THINK_RATE;
}

// Death
void Dog_DieThink()
{
    // Deferred one tick so Combat_Killed still sees FL_MONSTER on its way out.
    if (self.solid != SOLID_CORPSE)
        Monster_BecomeCorpse('-24 -24 -24', '24 24 -8');

    self.frame = self.frame + 1;
    if (self.frame >= DOG_FR_DEATH9)
    {
        self.frame = DOG_FR_DEATH9;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Dog_DieThink;
    self.nextthink = time + DOG_THINK_RATE;
}

void Dog_Die()
{
    if (self.health < -35)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, DOG_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = DOG_FR_DEATH1;

    self.think     = Dog_DieThink;
    self.nextthink = time + DOG_THINK_RATE;
}

// Hooked via self.checkAttack so AI_Run can call it instead of CheckAttack.
float Dog_CheckJump()
{
    // Don't jump uphill out of reach, or downhill onto something tiny.
    if (self.origin_z + self.mins_z >
        self.enemy.origin_z + self.enemy.mins_z + 0.75 * self.enemy.size_z)
        return FALSE;
    if (self.origin_z + self.maxs_z <
        self.enemy.origin_z + self.enemy.mins_z + 0.25 * self.enemy.size_z)
        return FALSE;

    vector dist = self.enemy.origin - self.origin;
    dist_z = 0;
    float d = vlen(dist);

    if (d < DOG_LEAP_MIN_DIST) return FALSE;
    if (d > DOG_LEAP_MAX_DIST) return FALSE;
    return TRUE;
}

float Dog_CheckAttack()
{
    if (enemy_range == RANGE_MELEE)
    {
        self.attack_state = AS_MELEE;
        return TRUE;
    }
    if (Dog_CheckJump())
    {
        self.attack_state = AS_MISSILE;
        return TRUE;
    }
    return FALSE;
}

// Spawn
void Dog_Precache()
{
    precache_model(DOG_MODEL);
    precache_model(DOG_HEAD_MODEL);
    Gib_Q1Precache();

    precache_sound(DOG_SND_ATTACK);
    precache_sound(DOG_SND_DEATH);
    precache_sound(DOG_SND_PAIN);
    precache_sound(DOG_SND_SIGHT);
    precache_sound(DOG_SND_IDLE);
    precache_sound(DOG_SND_GIB);
}

void monster_dog()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Dog_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = DOG_HEALTH;
    self.max_health  = DOG_HEALTH;
    self.view_ofs    = '0 0 16';

    setmodel(self, DOG_MODEL);
    setsize(self, '-24 -24 -24', '24 24 12');

    self.th_stand   = Dog_Stand;
    self.th_walk    = Dog_Walk;
    self.th_run     = Dog_Run;
    self.th_die     = Dog_Die;
    self.monster_gibHead  = DOG_HEAD_MODEL;
    self.monster_gibPiece = "progs/gib3.mdl";
    self.th_pain    = Dog_Pain;
    self.th_melee   = Dog_Attack;
    self.th_missile = Dog_Leap;
    self.checkAttack = Dog_CheckAttack;
    self.sightSound  = Dog_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
