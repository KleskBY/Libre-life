
#define FN_FR_STAND1     0
#define FN_FR_STAND13    12
#define FN_FR_WALK1      13
#define FN_FR_WALK8      20
#define FN_FR_RUN1       21
#define FN_FR_RUN6       26
#define FN_FR_LEAP1      27
#define FN_FR_LEAP4      30   // jump impulse fires here
#define FN_FR_LEAP10     36
#define FN_FR_LEAP11     37   // landing recovery start
#define FN_FR_LEAP12     38
#define FN_FR_PAIN1      39
#define FN_FR_PAIN6      44
#define FN_FR_DEATH1     45
#define FN_FR_DEATH6     50   // become non-solid here
#define FN_FR_DEATH9     53
#define FN_FR_ATTACK1    54
#define FN_FR_ATTACK15   68

#define FN_MODEL         "progs/demon.mdl"
#define FN_HEAD_MODEL    "progs/h_demon.mdl"

#define FN_SND_DEATH     "demon/ddeath.wav"
#define FN_SND_HIT       "demon/dhit2.wav"
#define FN_SND_JUMP      "demon/djump.wav"
#define FN_SND_PAIN      "demon/dpain1.wav"
#define FN_SND_IDLE      "demon/idle1.wav"
#define FN_SND_SIGHT     "demon/sight2.wav"
#define FN_SND_GIB       "player/udeath.wav"


#define FN_HEALTH        200
#define FN_CLAW_DMG_MIN  10     // Q1: 10 + 5*random()
#define FN_CLAW_DMG_MAX  15
#define FN_CLAW_REACH    100
#define FN_LEAP_DMG_MIN  40     // Q1: 40 + 10*random()
#define FN_LEAP_DMG_MAX  50
#define FN_LEAP_VEL_FWD  600
#define FN_LEAP_VEL_UP   250
#define FN_LEAP_MIN_DIST 100
#define FN_LEAP_MAX_DIST 200
#define FN_PAIN_COOLDOWN 1
#define FN_THINK_RATE    0.1


float Fiend_WalkStep(float fi)
{
    switch (fi)
    {
        case 0: return 8;
        case 1: return 6;
        case 2: return 6;
        case 3: return 7;
        case 4: return 4;
        case 5: return 6;
        case 6: return 10;
        case 7: return 10;
    }
    return 0;
}

float Fiend_RunStep(float fi)
{
    switch (fi)
    {
        case 0: return 20;
        case 1: return 15;
        case 2: return 36;
        case 3: return 20;
        case 4: return 15;
        case 5: return 36;
    }
    return 0;
}

float Fiend_AttackCharge(float fi)
{
    switch (fi)
    {
        case 0:  return 4;
        case 1:  return 0;
        case 2:  return 0;
        case 3:  return 1;
        case 4:  return 2;
        case 5:  return 1;
        case 6:  return 6;
        case 7:  return 8;
        case 8:  return 4;
        case 9:  return 2;
        case 10: return 0;
        case 11: return 5;
        case 12: return 8;
        case 13: return 4;
        case 14: return 4;
    }
    return 0;
}

void Fiend_Stand();
void Fiend_Walk();
void Fiend_Run();
void Fiend_Attack();
void Fiend_Leap();
void Fiend_LeapRecover();
void Fiend_Pain(entity attacker, float damage);
void Fiend_Die();
void Fiend_DieThink();
void Fiend_Claw(float side);
void Fiend_JumpTouch();
float Fiend_CheckAttack();

void Fiend_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FN_SND_SIGHT);
}

void Fiend_Stand()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - FN_FR_STAND1;
    if (fi < 0 || fi > 12) { self.frame = FN_FR_STAND1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > FN_FR_STAND13) self.frame = FN_FR_STAND1;
    self.think     = Fiend_Stand;
    self.nextthink = time + FN_THINK_RATE;

    AI_Stand();
}

void Fiend_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - FN_FR_WALK1;
    if (fi < 0 || fi > 7) { self.frame = FN_FR_WALK1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, FN_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > FN_FR_WALK8) self.frame = FN_FR_WALK1;
    self.think     = Fiend_Walk;
    self.nextthink = time + FN_THINK_RATE;

    AI_Walk(Fiend_WalkStep(fi));
}

void Fiend_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - FN_FR_RUN1;
    if (fi < 0 || fi > 5) { self.frame = FN_FR_RUN1; fi = 0; }

    if (fi == 0 && random() < 0.2)
        Sound_Play(self, CHAN_VOICE, 1, ATTN_IDLE, PITCH_NORM, FN_SND_IDLE);

    self.frame = self.frame + 1;
    if (self.frame > FN_FR_RUN6) self.frame = FN_FR_RUN1;
    self.think     = Fiend_Run;
    self.nextthink = time + FN_THINK_RATE;

    AI_Run(Fiend_RunStep(fi));
}

void Fiend_Claw(float side)
{
    if (!self.enemy) return;
    if (!CanDamage(self.enemy, self)) return;

    AI_Face();
    walkmove(self.ideal_yaw, 12);   // close the gap a bit

    if (vlen(self.enemy.origin - self.origin) > FN_CLAW_REACH) return;

    float dmg = FN_CLAW_DMG_MIN + random() * (FN_CLAW_DMG_MAX - FN_CLAW_DMG_MIN);
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, FN_SND_HIT);
    T_Damage(self.enemy, self, self, dmg, DMG_SLASH);
}

void Fiend_Attack()
{
    if (self.frame < FN_FR_ATTACK1 || self.frame > FN_FR_ATTACK15)
        self.frame = FN_FR_ATTACK1;

    float fi = self.frame - FN_FR_ATTACK1;

    if (fi == 4)  Fiend_Claw( 200);
    if (fi == 10) Fiend_Claw(-200);

    AI_Charge(Fiend_AttackCharge(fi));

    self.frame = self.frame + 1;
    if (self.frame > FN_FR_ATTACK15)
    {
        self.frame     = FN_FR_RUN1;
        self.think     = Fiend_Run;
        self.nextthink = time + FN_THINK_RATE;
        return;
    }
    self.think     = Fiend_Attack;
    self.nextthink = time + FN_THINK_RATE;
}

//Jump
void Fiend_LeapRecover()
{
    self.frame = self.frame + 1;
    if (self.frame >= FN_FR_LEAP12)
    {
        self.frame     = FN_FR_RUN1;
        self.think     = Fiend_Run;
        self.nextthink = time + FN_THINK_RATE;
        return;
    }
    self.think     = Fiend_LeapRecover;
    self.nextthink = time + FN_THINK_RATE;
}

void Fiend_JumpTouch()
{
    if (self.health <= 0) return;

    if (other.takedamage && vlen(self.velocity) > 400)
    {
        float dmg = FN_LEAP_DMG_MIN + random() * (FN_LEAP_DMG_MAX - FN_LEAP_DMG_MIN);
        T_Damage(other, self, self, dmg, DMG_SLASH);
    }

    if (!checkbottom(self))
    {
        if (self.flags & FL_ONGROUND)
        {
            self.touch     = SUB_Null;
            self.think     = Fiend_Leap;
            self.frame     = FN_FR_LEAP1;
            self.nextthink = time + 0.1;
        }
        return;
    }

    self.touch     = SUB_Null;
    self.frame     = FN_FR_LEAP11;
    self.think     = Fiend_LeapRecover;
    self.nextthink = time + 0.1;
}

void Fiend_Leap()
{
    if (self.frame < FN_FR_LEAP1 || self.frame > FN_FR_LEAP10)
        self.frame = FN_FR_LEAP1;

    float fi = self.frame - FN_FR_LEAP1;

    if (fi <= 2)
    {
        AI_Face();
    }
    else if (fi == 3)
    {
        AI_Face();
        self.touch    = Fiend_JumpTouch;
        makevectors(self.angles);
        self.origin_z = self.origin_z + 1;
        self.velocity = v_forward * FN_LEAP_VEL_FWD + [0, 0, FN_LEAP_VEL_UP];
        if (self.flags & FL_ONGROUND)
            self.flags = self.flags - FL_ONGROUND;
    }

    self.frame = self.frame + 1;
    if (self.frame > FN_FR_LEAP10)
    {
        self.frame     = FN_FR_LEAP1;
        self.think     = Fiend_Leap;
        self.nextthink = time + 3;
        return;
    }

    self.think     = Fiend_Leap;
    self.nextthink = time + FN_THINK_RATE;
}


void Fiend_PainThink()
{
    self.frame = self.frame + 1;
    if (self.frame > FN_FR_PAIN6)
    {
        self.frame     = FN_FR_RUN1;
        self.think     = Fiend_Run;
        self.nextthink = time + FN_THINK_RATE;
        return;
    }
    self.think     = Fiend_PainThink;
    self.nextthink = time + FN_THINK_RATE;
}

void Fiend_Pain(entity attacker, float damage)
{
    if (self.touch == Fiend_JumpTouch) return;
    if (self.pain_finished > time) return;
    self.pain_finished = time + FN_PAIN_COOLDOWN;

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FN_SND_PAIN);

    if (random() * 200 > damage) return;

    self.frame     = FN_FR_PAIN1;
    self.think     = Fiend_PainThink;
    self.nextthink = time + FN_THINK_RATE;
}

void Fiend_DieThink()
{
    self.frame = self.frame + 1;

    if (self.frame == FN_FR_DEATH6)
        Monster_BecomeCorpse('-32 -32 -24', '32 32 -4');

    if (self.frame >= FN_FR_DEATH9)
    {
        self.frame = FN_FR_DEATH9;
        self.think = SUB_Null;
        self.nextthink = 0;
        return;
    }
    self.think     = Fiend_DieThink;
    self.nextthink = time + FN_THINK_RATE;
}

void Fiend_Die()
{
    if (self.health < -80)
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FN_SND_DEATH);
    self.takedamage = DAMAGE_NO;
    self.frame      = FN_FR_DEATH1;

    self.think     = Fiend_DieThink;
    self.nextthink = time + FN_THINK_RATE;
}

float Fiend_CheckJump()
{
    if (self.origin_z + self.mins_z >
        self.enemy.origin_z + self.enemy.mins_z + 0.75 * self.enemy.size_z)
        return FALSE;
    if (self.origin_z + self.maxs_z <
        self.enemy.origin_z + self.enemy.mins_z + 0.25 * self.enemy.size_z)
        return FALSE;

    vector dist = self.enemy.origin - self.origin;
    dist_z = 0;
    float d = vlen(dist);

    if (d < FN_LEAP_MIN_DIST) return FALSE;
    if (d > FN_LEAP_MAX_DIST && random() < 0.9) return FALSE;
    return TRUE;
}

float Fiend_CheckAttack()
{
    if (enemy_range == RANGE_MELEE)
    {
        self.attack_state = AS_MELEE;
        return TRUE;
    }
    if (Fiend_CheckJump())
    {
        self.attack_state = AS_MISSILE;
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, FN_SND_JUMP);
        return TRUE;
    }
    return FALSE;
}


void Fiend_Precache()
{
    precache_model(FN_MODEL);
    precache_model(FN_HEAD_MODEL);
    Gib_Q1Precache();

    precache_sound(FN_SND_DEATH);
    precache_sound(FN_SND_HIT);
    precache_sound(FN_SND_JUMP);
    precache_sound(FN_SND_PAIN);
    precache_sound(FN_SND_IDLE);
    precache_sound(FN_SND_SIGHT);
    precache_sound(FN_SND_GIB);
}

void monster_demon1()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    Fiend_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = FN_HEALTH;
    self.max_health  = FN_HEALTH;
    self.view_ofs    = '0 0 32';

    setmodel(self, FN_MODEL);
    setsize(self, '-32 -32 -24', '32 32 64');

    self.th_stand    = Fiend_Stand;
    self.th_walk     = Fiend_Walk;
    self.th_run      = Fiend_Run;
    self.th_die      = Fiend_Die;
    self.monster_gibHead  = FN_HEAD_MODEL;
    self.monster_gibPiece = "progs/gib1.mdl";
    self.th_pain     = Fiend_Pain;
    self.th_melee    = Fiend_Attack;
    self.th_missile  = Fiend_Leap;
    self.checkAttack = Fiend_CheckAttack;
    self.sightSound  = Fiend_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}
