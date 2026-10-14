

#define TB_FR_WALK1     0
#define TB_FR_WALK25    24
#define TB_FR_RUN1      25
#define TB_FR_RUN25     49
#define TB_FR_JUMP1     50
#define TB_FR_JUMP5     54
#define TB_FR_JUMP6     55
#define TB_FR_FLY1      56
#define TB_FR_FLY4      59
#define TB_FR_EXP       60

#define TB_MODEL        "progs/tarbaby.mdl"

#define TB_SND_DEATH    "blob/death1.wav"
#define TB_SND_HIT      "blob/hit1.wav"
#define TB_SND_LAND     "blob/land1.wav"
#define TB_SND_SIGHT    "blob/sight1.wav"

#define TB_HEALTH        80
#define TB_LEAP_DMG_MIN  10
#define TB_LEAP_DMG_MAX  20
#define TB_LEAP_VEL_FWD  600
#define TB_LEAP_VEL_UP   200
#define TB_BLAST_DMG     120
#define TB_BLAST_RADIUS  150
#define TB_THINK_RATE    0.1

void Tarbaby_Stand();
void Tarbaby_Walk();
void Tarbaby_Run();
void Tarbaby_Jump();
void Tarbaby_Fly();
void Tarbaby_Die();
void Tarbaby_DieExplode();
void Tarbaby_JumpTouch();

void Tarbaby_SightSound()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, TB_SND_SIGHT);
}

void Tarbaby_Stand()
{
    if (Monster_YieldIfDead()) return;
    self.frame     = TB_FR_WALK1;
    self.think     = Tarbaby_Stand;
    self.nextthink = time + TB_THINK_RATE;

    AI_Stand();
}

void Tarbaby_Walk()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - TB_FR_WALK1;
    if (fi < 0 || fi > 24) { self.frame = TB_FR_WALK1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > TB_FR_WALK25) self.frame = TB_FR_WALK1;
    self.think     = Tarbaby_Walk;
    self.nextthink = time + TB_THINK_RATE;

    if (fi < 10) AI_Face();
    else         AI_Walk(2);
}

void Tarbaby_Run()
{
    if (Monster_YieldIfDead()) return;
    float fi = self.frame - TB_FR_RUN1;
    if (fi < 0 || fi > 24) { self.frame = TB_FR_RUN1; fi = 0; }

    self.frame = self.frame + 1;
    if (self.frame > TB_FR_RUN25) self.frame = TB_FR_RUN1;
    self.think     = Tarbaby_Run;
    self.nextthink = time + TB_THINK_RATE;

    if (fi < 10) AI_Face();
    else         AI_Run(2);
}

void Tarbaby_JumpTouch()
{
    if (other.takedamage && other.classname != self.classname)
    {
        if (vlen(self.velocity) > 400)
        {
            float dmg = TB_LEAP_DMG_MIN + random() * (TB_LEAP_DMG_MAX - TB_LEAP_DMG_MIN);
            T_Damage(other, self, self, dmg, DMG_SLASH);
            Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, TB_SND_HIT);
        }
    }
    else
    {
        Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, TB_SND_LAND);
    }

    if (!checkbottom(self))
    {
        if (self.flags & FL_ONGROUND)
        {
            self.touch     = SUB_Null;
            self.movetype  = MOVETYPE_STEP;
            self.think     = Tarbaby_Run;
            self.frame     = TB_FR_RUN1;
            self.nextthink = time + 0.1;
        }
        return;
    }

    self.touch     = SUB_Null;
    self.think     = Tarbaby_Jump;
    self.frame     = TB_FR_JUMP1;
    self.nextthink = time + 0.1;
}

void Tarbaby_Fly()
{
    if (self.frame < TB_FR_FLY1 || self.frame > TB_FR_FLY4)
    {
        self.frame = TB_FR_FLY1;
        self.cnt   = 0;
    }
    else
    {
        self.frame = self.frame + 1;
    }

    if (self.frame > TB_FR_FLY4)
    {
        self.frame = TB_FR_FLY1;
        self.cnt   = self.cnt + 1;
        if (self.cnt >= 4)
        {
            self.frame     = TB_FR_JUMP5;
            self.cnt       = 0;
            self.think     = Tarbaby_Jump;
            self.nextthink = time + TB_THINK_RATE;
            return;
        }
    }

    self.think     = Tarbaby_Fly;
    self.nextthink = time + TB_THINK_RATE;
}

void Tarbaby_Jump()
{
    if (self.frame < TB_FR_JUMP1 || self.frame > TB_FR_JUMP6)
        self.frame = TB_FR_JUMP1;

    float fi = self.frame - TB_FR_JUMP1;

    if (fi <= 3)
    {
        AI_Face();
    }
    else if (fi == 4)
    {
        self.movetype = MOVETYPE_BOUNCE;
        self.touch    = Tarbaby_JumpTouch;
        makevectors(self.angles);
        self.origin_z = self.origin_z + 1;
        self.velocity = v_forward * TB_LEAP_VEL_FWD + [0, 0, TB_LEAP_VEL_UP];
        self.velocity_z = self.velocity_z + random() * 150;
        if (self.flags & FL_ONGROUND)
            self.flags = self.flags - FL_ONGROUND;
        self.cnt = 0;
    }

    self.frame = self.frame + 1;
    if (self.frame > TB_FR_JUMP6)
    {
        self.frame     = TB_FR_FLY1;
        self.think     = Tarbaby_Fly;
        self.nextthink = time + TB_THINK_RATE;
        return;
    }

    self.think     = Tarbaby_Jump;
    self.nextthink = time + TB_THINK_RATE;
}

void Tarbaby_DieExplode()
{
    T_RadiusDamage(self, self, TB_BLAST_DMG, TB_BLAST_RADIUS, DMG_BLAST);
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, TB_SND_DEATH);

    if (vlen(self.velocity) > 0.1)
        self.origin = self.origin - 8 * normalize(self.velocity);

	te_tarexplosion(self.origin);

    remove(self);
}

void Tarbaby_Die()
{
    self.takedamage = DAMAGE_NO;
    self.frame      = TB_FR_EXP;
    self.think      = Tarbaby_DieExplode;
    self.nextthink  = time + TB_THINK_RATE;
}

void Tarbaby_Precache()
{
    precache_model(TB_MODEL);
    precache_sound(TB_SND_DEATH);
    precache_sound(TB_SND_HIT);
    precache_sound(TB_SND_LAND);
    precache_sound(TB_SND_SIGHT);
}

void monster_tarbaby()
{
    self.q1_monster = TRUE;
    if (cvar("gamemode") == MODE_DM)
    {
        remove(self);
        return;
    }

    Tarbaby_Precache();

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.yaw_speed   = 20;
    self.health      = TB_HEALTH;
    self.max_health  = TB_HEALTH;
    self.view_ofs    = '0 0 16';

    setmodel(self, TB_MODEL);
    setsize(self, '-16 -16 -24', '16 16 40');

    self.th_stand   = Tarbaby_Stand;
    self.th_walk    = Tarbaby_Walk;
    self.th_run     = Tarbaby_Run;
    self.th_die     = Tarbaby_Die;
    self.th_melee   = Tarbaby_Jump;
    self.th_missile = Tarbaby_Jump;
    self.sightSound = Tarbaby_SightSound;

    Monster_InitTakeDamage();
    WalkMonster_Start();
}

void monster_spawn_blob() { monster_tarbaby(); }
