
#define GARG_MODEL              "models/garg.iqm"
#define GARG_EYE_SPRITE         "sprites/gargeye1.spr"
#define GARG_GIB_MODEL_PREFIX   "models/metalplategibs_green"   // 01..11
#define GARG_STOMP_BUZZ         "weapons/mine_charge.wav"

#define GARG_HEALTH             Skill_GetValue("sk_gargantua_health", 800)
#define GARG_DMG_SLASH          Skill_GetValue("sk_gargantua_dmg_slash", 30)
#define GARG_DMG_FIRE           Skill_GetValue("sk_gargantua_dmg_fire", 5)       // per 0.1s flame tick
#define GARG_DMG_STOMP          Skill_GetValue("sk_gargantua_dmg_stomp", 100)
#define GARG_ATTACKDIST         80
#define GARG_FLAME_LENGTH       330
#define GARG_FLAME_TIME         4.5     // sweep duration
#define GARG_FLAME_COOLDOWN     6
#define GARG_STOMP_COOLDOWN     12
#define GARG_SIGHT_RANGE        2048
#define GARG_FOV                -0.2

#define GARG_DAMAGE_MASK  (DMG_ENERGYBEAM | DMG_CRUSH | DMG_MORTAR | DMG_BLAST)

#define GARG_FR_IDLE3           0
#define GARG_FR_IDLE2           1
#define GARG_FR_IDLE1           2
#define GARG_FR_IDLE4           3
#define GARG_FR_WALK            4
#define GARG_FR_RUN             5
#define GARG_FR_SHOOTFLAMES1    6
#define GARG_FR_SHOOTFLAMES2    7
#define GARG_FR_ATTACK          8
#define GARG_FR_STOMP           9
#define GARG_FR_180LEFT         10
#define GARG_FR_180RIGHT        11
#define GARG_FR_FLINCHLIGHT     12
#define GARG_FR_FLINCHHEAVY     13
#define GARG_FR_DIE             14
#define GARG_FR_BITEHEAD        15
#define GARG_FR_THROWBODY       16
#define GARG_FR_SMASH           17
#define GARG_FR_ROLLCAR         18
#define GARG_FR_KICKCAR         19
#define GARG_FR_PUSHCAR         20
#define GARG_FR_BUST            21

// Combat substates
#define GARGS_RUN       0
#define GARGS_SLASH     1
#define GARGS_FLAME     2
#define GARGS_STOMP     3

.float  garg_state;
.float  garg_stateEnd;      // substate end time
.float  garg_hitTime;       // pending melee-hit / stomp-release timestamp (0 = done)
.float  garg_seeTime;       // stomp gate: must see enemy continuously past this
.float  garg_flameTime;
.float  garg_flameEnd;      // current sweep ends
.float  garg_flameX;        // flame aim offsets relative to body (bone ctrl port)
.float  garg_flameY;
.float  garg_painSndTime;
.float  garg_stepTime;
.float  garg_idleSndTime;
.entity garg_eyeGlow;
.float  garg_eyeTarget;     // brightness target (0 or 200)

float Garg_FrameByName(string name)
{
    if (name == "idle1")         return GARG_FR_IDLE1;
    if (name == "idle2")         return GARG_FR_IDLE2;
    if (name == "idle3")         return GARG_FR_IDLE3;
    if (name == "idle4")         return GARG_FR_IDLE4;
    if (name == "walk")          return GARG_FR_WALK;
    if (name == "run")           return GARG_FR_RUN;
    if (name == "shootflames1")  return GARG_FR_SHOOTFLAMES1;
    if (name == "shootflames2")  return GARG_FR_SHOOTFLAMES2;
    if (name == "Attack")        return GARG_FR_ATTACK;
    if (name == "attack")        return GARG_FR_ATTACK;    // map scripts use lowercase
    if (name == "stomp")         return GARG_FR_STOMP;
    if (name == "180left")       return GARG_FR_180LEFT;
    if (name == "180right")      return GARG_FR_180RIGHT;
    if (name == "Flinchlight")   return GARG_FR_FLINCHLIGHT;
    if (name == "flinchlight")   return GARG_FR_FLINCHLIGHT;
    if (name == "Flinchheavy")   return GARG_FR_FLINCHHEAVY;
    if (name == "flinchheavy")   return GARG_FR_FLINCHHEAVY;
    if (name == "die")           return GARG_FR_DIE;
    if (name == "bitehead")      return GARG_FR_BITEHEAD;
    if (name == "throwbody")     return GARG_FR_THROWBODY;
    if (name == "smash")         return GARG_FR_SMASH;
    if (name == "rollcar")       return GARG_FR_ROLLCAR;
    if (name == "kickcar")       return GARG_FR_KICKCAR;
    if (name == "pushcar")       return GARG_FR_PUSHCAR;
    if (name == "bust")          return GARG_FR_BUST;
    return -1;
}

void Garg_PlayFrame(float fr)
{
    if (self.frame == fr) return;
    self.frame      = fr;
    self.frame1time = time;
    self.framerate  = 1;
}

void Garg_EyeUpdate()
{
    entity glow = self.garg_eyeGlow;
    if (!glow) return;

    glow.renderamt = Math_Approach(self.garg_eyeTarget, glow.renderamt, 26);
    {
        entity stemp = self;
        self = glow;
        Render_Apply(self);
        self = stemp;
    }
}

// Runs on the glow sprite, so it tracks the head while a script owns the garg
// and goes away with it when a killtarget removes the garg.
void Garg_EyeGlowThink()
{
    entity garg = self.owner;
    if (!garg || wasfreed(garg) || garg.garg_eyeGlow != self)
    {
        remove(self);
        return;
    }
    makevectors([0, garg.angles_y, 0]);
    setorigin(self, garg.origin + '0 0 100' + v_forward * 40);
    self.nextthink = time + 0.05;
}

float Garg_IsPrey(entity e)
{
    if (e == self) return FALSE;
    if (e.health <= 0) return FALSE;
    if (e.flags & FL_NOTARGET) return FALSE;
    if (e.flags & FL_CLIENT) return TRUE;
    if (!(e.flags & FL_MONSTER)) return FALSE;

    if (e.classname == "monster_gargantua")   return FALSE;
    if (e.classname == "monster_headcrab")    return FALSE;
    if (e.classname == "monster_babycrab")    return FALSE;
    if (e.classname == "monster_zombie")      return FALSE;
    if (e.classname == "monster_houndeye")    return FALSE;
    if (e.classname == "monster_alien_slave") return FALSE;
    if (e.classname == "monster_bullchicken") return FALSE;
    if (e.classname == "monster_barnacle")    return FALSE;
    if (e.classname == "monster_leech")       return FALSE;
    if (e.classname == "monster_cockroach")   return FALSE;
    if (e.classname == "monster_gman")        return FALSE;
    if (e.classname == "monster_generic")     return FALSE;
    if (e.classname == "monster_furniture")   return FALSE;
    if (e.classname == "monster_tripmine")    return FALSE;
    return TRUE;    // players' side: barney, scientist, grunts, turrets...
}

float Garg_CanSee(entity tgt)
{
    if (!tgt) return FALSE;
    traceline(self.origin + '0 0 96', tgt.origin + tgt.view_ofs, TRUE, self);
    return (trace_fraction == 1.0 || trace_ent == tgt);
}

entity Garg_FindEnemy()
{
    if (self.spawnflags & SF_MONSTER_PRISONER) return world;

    entity head = findradius(self.origin, GARG_SIGHT_RANGE);
    entity best = world;
    float bestDist = GARG_SIGHT_RANGE + 1;
    while (head)
    {
        if (Garg_IsPrey(head) && Garg_CanSee(head))
        {
            float d = vlen(head.origin - self.origin);
            if (d < bestDist) { best = head; bestDist = d; }
        }
        head = head.chain;
    }
    return best;
}

void Garg_FaceEnemy()
{
    if (!self.enemy) return;
    vector to = self.enemy.origin - self.origin;
    to_z = 0;
    if (vlen(to) > 1)
    {
        self.ideal_yaw = vectoyaw(normalize(to));
        ChangeYaw();
    }
}

float Garg_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
    if (self.health > 0)
    {
        if (!(dmgType & GARG_DAMAGE_MASK))
            damage = damage * 0.01;
    }
    return Monster_TakeDamage(inflictor, attacker, damage, dmgType);
}

void Garg_TraceAttack(entity attacker, float flDamage, vector vecDir, float bitsDamageType)
{
    if (self.health <= 0)
    {
        Monster_TraceAttack(attacker, flDamage, vecDir, bitsDamageType);
        return;
    }

    // Pain growl only for damage classes that actually hurt (throttled).
    if ((bitsDamageType & (GARG_DAMAGE_MASK | DMG_BLAST)) && self.garg_painSndTime < time)
    {
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_pain1.wav", "garg/gar_pain2.wav", "garg/gar_pain3.wav");
        self.garg_painSndTime = time + random(2.5, 4);
    }

    if (!(bitsDamageType & GARG_DAMAGE_MASK))
    {
        // Armor plating: sparks, no wound.
        if (random() < 0.5)
            te_spark(trace_endpos, -vecDir, Math_RandomInt(2, 5));
        flDamage = 0;
    }

    Monster_TraceAttack(attacker, flDamage, vecDir, bitsDamageType);
}

// Melee swipe (GARG_AE_SLASH_LEFT)
void Garg_SlashHit()
{
    makevectors(self.angles);
    vector start = self.origin + '0 0 64';
    vector end   = start + v_forward * (GARG_ATTACKDIST + 10) - v_up * (GARG_ATTACKDIST + 10) * 0.3;

    tracebox(start, '-16 -16 -16', '16 16 16', end, FALSE, self);
    entity hit = trace_ent;

    if (hit && hit.takedamage)
    {
        T_Damage(hit, self, self, GARG_DMG_SLASH, DMG_SLASH);
        if (hit.flags & (FL_MONSTER | FL_CLIENT))
        {
            hit.punchangle = '-30 -30 30';
            hit.velocity = hit.velocity - v_right * 100;
        }
        Sound_Emit(self, CHAN_WEAPON,
            (random() < 0.33) ? "zombie/claw_strike1.wav" :
            (random() < 0.5)  ? "zombie/claw_strike2.wav" : "zombie/claw_strike3.wav",
            1, ATTN_NORM, 50 + Math_RandomInt(0, 15), 0);
    }
    else
    {
        Sound_Emit(self, CHAN_WEAPON,
            (random() < 0.5) ? "zombie/claw_miss1.wav" : "zombie/claw_miss2.wav",
            1, ATTN_NORM, 50 + Math_RandomInt(0, 15), 0);
    }
}

// Flame sweep (FlameCreate/FlameUpdate/FlameDamage/FlameDestroy)
vector Garg_FlameGunPos(float side)
{
    makevectors([0, self.angles_y, 0]);
    return self.origin + '0 0 85' + v_forward * 40 + v_right * (side * 30);
}

// Cylinder damage along the beam with falloff past 64u (FlameDamage port).
void Garg_FlameDamage(vector vstart, vector vend)
{
    vector mid = (vstart + vend) * 0.5;
    float searchRadius = vlen(vstart - mid);
    vector aim = normalize(vend - vstart);

    entity e = findradius(mid, searchRadius);
    while (e)
    {
        if (e.takedamage && e != self && e.classname != "monster_gargantua")
        {
            vector spot = (e.absmin + e.absmax) * 0.5;
            float d = aim * (spot - mid);
            if (d > searchRadius) d = searchRadius;
            if (d < -searchRadius) d = searchRadius;
            vector src = mid + aim * d;

            traceline(src, spot, FALSE, self);
            if (trace_fraction == 1.0 || trace_ent == e)
            {
                float dist = vlen(src - trace_endpos);
                float dmg = GARG_DMG_FIRE;
                if (dist > 64)
                {
                    dmg = dmg - (dist - 64) * 0.4;
                    if (dmg <= 0) { e = e.chain; continue; }
                }
                T_Damage(e, self, self, dmg, DMG_BURN);
            }
        }
        e = e.chain;
    }
}

void Garg_FlameUpdate()
{
    float wantX = 0, wantY = 0;
    float cancel = FALSE;

    if (self.enemy && self.enemy.health > 0)
    {
        vector org = self.origin + '0 0 64';
        vector dir = ((self.enemy.absmin + self.enemy.absmax) * 0.5) - org;
        vector ang = vectoangles(dir);
        wantX = ang_x;
        if (wantX > 180) wantX = wantX - 360;
        wantY = ang_y - self.angles_y;
        while (wantY < -180) wantY = wantY + 360;
        while (wantY > 180)  wantY = wantY - 360;
        if (wantY < -45) wantY = -45;
        if (wantY > 45)  wantY = 45;
        if (vlen(dir) > 400) cancel = TRUE;
        if (fabs(wantY) >= 45 && fabs(ang_y - self.angles_y) > 60) cancel = TRUE;
    }

    if (cancel)
    {
        self.garg_flameEnd  = self.garg_flameEnd - 0.5;
        self.garg_flameTime = self.garg_flameTime - 0.5;
    }

    self.garg_flameX = Math_Approach(wantX, self.garg_flameX, 4);
    self.garg_flameY = MiniTurret_ApproachAngle(self.garg_flameY, wantY, 8);

    // Fire the two beams. v_angle pitch: vectoangles gave +up; makevectors
    float aimYaw   = self.angles_y + self.garg_flameY;
    float aimPitch = self.garg_flameX;
    makevectors([-aimPitch, aimYaw, 0]);
    vector fwd = v_forward;

    float side;
    for (side = -1; side <= 1; side = side + 2)
    {
        vector src = Garg_FlameGunPos(side);
        traceline(src, src + fwd * GARG_FLAME_LENGTH, FALSE, self);

        te_beam(self, src, trace_endpos);
        te_customflash(trace_endpos, 64, 0.15, '1 0.5 0.3');

        if (trace_fraction != 1.0)
            te_spark(trace_endpos, trace_plane_normal, Math_RandomInt(2, 6));

        Garg_FlameDamage(src, trace_endpos);
    }
}

void Garg_FlameStop()
{
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, "garg/gar_flameoff1.wav");
    Sound_Stop(self, CHAN_BODY);
}

// Stomp shockwave (CStomp port)
void Garg_StompThink()
{
    float dt = 0.05;
    self.nextthink = time + dt;

    // Damage sweep for this frame.
    vector vstart = self.origin + '0 0 30';
    vector vend   = vstart + self.movedir * self.speed * dt;
    tracebox(vstart, '-16 -16 -16', '16 16 16', vend, FALSE, self);
    if (trace_ent && trace_ent != self.owner && trace_ent.takedamage)
        T_Damage(trace_ent, self, (self.owner ? self.owner : self), GARG_DMG_STOMP, DMG_SONIC);

    // Accelerate speed and framerate
    self.speed     = self.speed + dt * self.framerate;
    self.framerate = self.framerate + dt * 1500;

    // Advance and leave a sprite trail.
    setorigin(self, self.origin + self.movedir * self.speed * dt);
    traceline(self.origin, self.origin - '0 0 500', TRUE, self);
    entity spr = Sprite_Create(GARG_EYE_SPRITE, trace_endpos, FALSE);
    spr.velocity  = [random(-100, 100), random(-100, 100), 120];
    spr.movetype  = MOVETYPE_NOCLIP;
    spr.scale     = 0.5;
    spr.think     = SUB_Remove;
    spr.nextthink = time + 0.3;

    // Life runs out with distance traveled.
    self.scale = self.scale - dt * self.speed;
    if (self.scale <= 0)
    {
        Sound_Stop(self, CHAN_BODY);
        remove(self);
    }
}

void Garg_StompAttack()
{
    makevectors(self.angles);
    vector vstart = self.origin + '0 0 60' + v_forward * 35;
    vector aim;
    if (self.enemy)
    {
        aim = ((self.enemy.absmin + self.enemy.absmax) * 0.5) - vstart;
        aim_z = 0;
        aim = normalize(aim);
    }
    else
        aim = v_forward;

    traceline(vstart, vstart + aim * 1024, TRUE, self);

    entity st = spawn();
    st.classname = "garg_stomp";
    st.owner     = self;
    st.solid     = SOLID_NOT;
    st.movetype  = MOVETYPE_NONE;
    setorigin(st, vstart);
    st.movedir   = aim;
    st.scale     = vlen(trace_endpos - vstart);   // life = distance
    st.speed     = 0;
    st.framerate = 30;
    st.think     = Garg_StompThink;
    st.nextthink = time;
    Sound_Emit(st, CHAN_BODY, GARG_STOMP_BUZZ, 1, ATTN_NORM, 55, 0);

    EnvShake_ScreenShake(self.origin, 12, 100, 2, 1000);
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100 + Math_RandomInt(-10, 10), "garg/gar_stomp1.wav");
}

// Footsteps / idle noises
void Garg_StepSounds()
{
    if (time < self.garg_stepTime) return;
    self.garg_stepTime = time + 0.6;
    Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 100 + Math_RandomInt(-10, 10), "garg/gar_step1.wav", "garg/gar_step2.wav");
    EnvShake_ScreenShake(self.origin, 4, 3, 1, 750);
}

// Combat brain
void Garg_Combat()
{
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Garg_Combat;
        self.nextthink = time + 0.2;
        return;
    }

    self.nextthink = time + 0.1;
    self.think = Garg_Combat;

    if (!self.enemy || self.enemy.health <= 0)
    {
        self.enemy = Garg_FindEnemy();
        if (!self.enemy)
        {
            self.think = self.th_stand;
            self.nextthink = time + 0.1;
            return;
        }
    }

    self.monster_state = MONSTERSTATE_COMBAT;

    float canSee = Garg_CanSee(self.enemy);
    float dist   = vlen(self.enemy.origin - self.origin);

    // Eye + stomp gate: losing sight pushes the
    // stomp permission 5s out.
    if (!canSee)
    {
        self.garg_seeTime = time + 5;
        self.garg_eyeTarget = 0;
    }
    else
        self.garg_eyeTarget = 200;
    Garg_EyeUpdate();

    float s = self.garg_state;

    if (s == GARGS_SLASH)
    {
        Garg_FaceEnemy();
        Garg_PlayFrame(GARG_FR_ATTACK);
        if (self.garg_hitTime && time >= self.garg_hitTime)
        {
            self.garg_hitTime = 0;
            Garg_SlashHit();
        }
        if (time >= self.garg_stateEnd)
            self.garg_state = GARGS_RUN;
        return;
    }

    if (s == GARGS_STOMP)
    {
        Garg_FaceEnemy();
        Garg_PlayFrame(GARG_FR_STOMP);
        if (self.garg_hitTime && time >= self.garg_hitTime)
        {
            self.garg_hitTime = 0;
            Garg_StompAttack();
            self.garg_seeTime = time + GARG_STOMP_COOLDOWN;
        }
        if (time >= self.garg_stateEnd)
            self.garg_state = GARGS_RUN;
        return;
    }

    if (s == GARGS_FLAME)
    {
        Garg_FaceEnemy();
        Garg_PlayFrame(GARG_FR_SHOOTFLAMES2);
        Garg_FlameUpdate();
        if (time >= self.garg_flameEnd)
        {
            Garg_FlameStop();
            self.garg_flameX = 0;
            self.garg_flameY = 0;
            self.garg_state = GARGS_RUN;
        }
        return;
    }

    Garg_FaceEnemy();

    makevectors([0, self.angles_y, 0]);
    vector flat = self.enemy.origin - self.origin;
    flat_z = 0;
    float dot = (vlen(flat) > 1) ? normalize(flat) * v_forward : 1;

    // Swipe (dot 0.7, dist <= 80)
    if (dist <= GARG_ATTACKDIST && dot >= 0.7)
    {
        self.garg_state    = GARGS_SLASH;
        self.garg_stateEnd = time + 1.5;    // Attack: 55f @ 36fps
        self.garg_hitTime  = time + 0.42;
        Garg_PlayFrame(GARG_FR_ATTACK);
        if (random() < 0.3)
            Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_attack1.wav", "garg/gar_attack2.wav", "garg/gar_attack3.wav");
        return;
    }

    // Flame sweep (dot 0.8, 80 < dist <= 330, cooldown)
    if (canSee && time > self.garg_flameTime && dot >= 0.8
        && dist > GARG_ATTACKDIST && dist <= GARG_FLAME_LENGTH)
    {
        self.garg_state     = GARGS_FLAME;
        self.garg_flameEnd  = time + GARG_FLAME_TIME;
        self.garg_flameTime = time + GARG_FLAME_TIME + GARG_FLAME_COOLDOWN;
        self.garg_flameX    = 0;
        self.garg_flameY    = 0;
        Garg_PlayFrame(GARG_FR_SHOOTFLAMES1);
        Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, "garg/gar_flameon1.wav");
        Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "garg/gar_flamerun1.wav");
        if (random() < 0.3)
            Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_attack1.wav", "garg/gar_attack2.wav", "garg/gar_attack3.wav");
        return;
    }

    // Stomp (dot 0.7, dist > 80, sight held past seeTime)
    if (canSee && time > self.garg_seeTime && dot >= 0.7 && dist > GARG_ATTACKDIST)
    {
        self.garg_state    = GARGS_STOMP;
        self.garg_stateEnd = time + 1.5;    // stomp: 21f @ 14fps
        self.garg_hitTime  = time + 0.7;
        Garg_PlayFrame(GARG_FR_STOMP);
        return;
    }

    // Chase.
    Garg_PlayFrame(GARG_FR_RUN);
    self.goalentity = self.enemy;
    if (!Monster_SlideStep(12))         // wall slide owns the think when active
    {
        movetogoal(12);
        Monster_StuckCheck(12);
    }
    Garg_StepSounds();
}

// Idle / walk
void Garg_Stand()
{
    if (Monster_YieldIfDead()) return;
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Garg_Stand;
        self.nextthink = time + 0.2;
        return;
    }

    Garg_PlayFrame(GARG_FR_IDLE1);
    self.monster_state = MONSTERSTATE_IDLE;
    self.garg_eyeTarget = 0;
    Garg_EyeUpdate();

    entity threat = Garg_FindEnemy();
    if (threat)
    {
        self.enemy = threat;
        Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_alert1.wav", "garg/gar_alert2.wav", "garg/gar_alert3.wav");
        self.garg_state = GARGS_RUN;
        self.garg_seeTime = time + 5;
        self.think = Garg_Combat;
        self.nextthink = time + 0.1;
        return;
    }

    if (time > self.garg_idleSndTime && random() < 0.05
        && !(self.spawnflags & SF_MONSTER_GAG))
    {
        if (random() < 0.5)
            Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_idle1.wav", "garg/gar_idle2.wav", "garg/gar_idle3.wav", "garg/gar_idle4.wav", "garg/gar_idle5.wav");
        else
            Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_breathe1.wav", "garg/gar_breathe2.wav", "garg/gar_breathe3.wav");
        self.garg_idleSndTime = time + random(4, 8);
    }

    self.think = Garg_Stand;
    self.nextthink = time + 0.3;
}

void Garg_Walk()
{
    if (Monster_YieldIfDead()) return;
    // Schedule FIRST so a mid-think death lets th_die win the think.
    self.think     = Garg_Walk;
    self.nextthink = time + 0.1;

    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Garg_Walk;
        self.nextthink = time + 0.2;
        return;
    }
    Garg_PlayFrame(GARG_FR_WALK);
    AI_Walk(6);
    Garg_StepSounds();
}

// Pain / death
void Garg_Pain(entity attacker, float damage)
{
    if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us

    // Growl handled in TraceAttack (throttled). Aggro if idle.
    if (!(self.spawnflags & SF_MONSTER_PRISONER)
        && attacker && attacker.health > 0 && Garg_IsPrey(attacker))
    {
        if (!self.enemy || self.enemy.health <= 0)
        {
            self.enemy = attacker;
            if (self.think != Garg_Combat)
            {
                self.garg_state = GARGS_RUN;
                self.think = Garg_Combat;
                self.nextthink = time + 0.1;
            }
        }
    }
}

// Metal-plate gib shower (explosion approximation)
void Garg_ExplodeGibs()
{
    float i;
    for (i = 1; i <= 11; i = i + 1)
    {
        entity g = spawn();
        g.classname = "garg_gib";
        g.movetype  = MOVETYPE_BOUNCE;
        g.solid     = SOLID_NOT;
        setmodel(g, sprintf("%s%02g.iqm", GARG_GIB_MODEL_PREFIX, i));
        setsize(g, '0 0 0', '0 0 0');
        setorigin(g, self.origin + '0 0 64');
        g.velocity  = randomvec() * random(300, 500);
        if (g.velocity_z < 0) g.velocity_z = -g.velocity_z;
        g.avelocity = [random(-400, 400), random(-400, 400), 0];
        g.think     = SUB_Remove;
        g.nextthink = time + random(8, 12);
    }
}

void Garg_DeathExplodeThink()
{
    // 1.6s into the die anim: burst into plates and vanish
    te_explosion(self.origin + '0 0 64');
    Garg_ExplodeGibs();
    if (self.garg_eyeGlow) { remove(self.garg_eyeGlow); self.garg_eyeGlow = world; }
    remove(self);
}

// Staged no-damage explosion chain
void Garg_DeathFXThink()
{
    te_explosion(self.origin + [random(-70, 70), random(-70, 70), 32 + self.count * 15]);
    self.count = self.count + 1;
    if (self.count >= 4)
    {
        remove(self);
        return;
    }
    self.nextthink = time + 0.6;
}

void Garg_Die()
{
    Monster_ExitScriptedSequence();

    self.takedamage  = DAMAGE_NO;
    self.solid       = SOLID_NOT;
    self.deadflag    = DEAD_DYING;
    self.use         = SUB_Null;
    self.usehl       = __NULL__;
    self.flags       = self.flags - (self.flags & FL_MONSTER);

    if (self.garg_state == GARGS_FLAME)
        Garg_FlameStop();

    self.garg_eyeTarget = 0;
    Garg_EyeUpdate();

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, "garg/gar_pain1.wav", "garg/gar_pain2.wav", "garg/gar_pain3.wav");
    Garg_PlayFrame(GARG_FR_DIE);

    // Streak column + staged explosions around the body (DeathEffect).
    makevectors(self.angles);
    te_teleport(self.origin + v_forward * 100);

    entity fx = spawn();
    fx.classname = "garg_deathfx";
    setorigin(fx, self.origin);
    fx.count     = 0;
    fx.think     = Garg_DeathFXThink;
    fx.nextthink = time + 0.1;

    self.think     = Garg_DeathExplodeThink;
    self.nextthink = time + 1.6;
}

void Garg_Precache()
{
    precache_model(GARG_MODEL);
    precache_model(GARG_EYE_SPRITE);
    precache_model("sprites/xbeam3.spr");
    float i;
    for (i = 1; i <= 11; i = i + 1)
        precache_model(sprintf("%s%02g.iqm", GARG_GIB_MODEL_PREFIX, i));

    precache_sound(GARG_STOMP_BUZZ);
    precache_sound("zombie/claw_strike1.wav");
    precache_sound("zombie/claw_strike2.wav");
    precache_sound("zombie/claw_strike3.wav");
    precache_sound("zombie/claw_miss1.wav");
    precache_sound("zombie/claw_miss2.wav");
    precache_sound("garg/gar_flameoff1.wav");
    precache_sound("garg/gar_flameon1.wav");
    precache_sound("garg/gar_flamerun1.wav");
    precache_sound("garg/gar_step1.wav");
    precache_sound("garg/gar_step2.wav");
    precache_sound("garg/gar_idle1.wav");
    precache_sound("garg/gar_idle2.wav");
    precache_sound("garg/gar_idle3.wav");
    precache_sound("garg/gar_idle4.wav");
    precache_sound("garg/gar_idle5.wav");
    precache_sound("garg/gar_alert1.wav");
    precache_sound("garg/gar_alert2.wav");
    precache_sound("garg/gar_alert3.wav");
    precache_sound("garg/gar_pain1.wav");
    precache_sound("garg/gar_pain2.wav");
    precache_sound("garg/gar_pain3.wav");
    precache_sound("garg/gar_attack1.wav");
    precache_sound("garg/gar_attack2.wav");
    precache_sound("garg/gar_attack3.wav");
    precache_sound("garg/gar_stomp1.wav");
    precache_sound("garg/gar_breathe1.wav");
    precache_sound("garg/gar_breathe2.wav");
    precache_sound("garg/gar_breathe3.wav");
}

void monster_gargantua()
{
    if (Monster_RemoveIfSpent()) return;    // killed on a previous visit
    if (RemoveInDeathmatch()) return;

    Garg_Precache();

    setmodel(self, GARG_MODEL);
    setsize(self, '-32 -32 0', '32 32 64');	// Bounding box definition; model is way bigger

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.health      = GARG_HEALTH;
    self.max_health  = self.health;
    self.yaw_speed   = YAW_HL(60);	// Sets yaw speed for various actions
    self.view_ofs    = '0 0 96';
    self.monster_bloodColor        = BLOOD_COLOR_GREEN;
    self.monster_fieldOfView     = GARG_FOV;
    self.monster_state      = MONSTERSTATE_IDLE;
    self.monster_idealState = MONSTERSTATE_IDLE;
    self.flags               = self.flags | FL_MONSTER;

    self.frameByName = Garg_FrameByName;

    self.th_stand = Garg_Stand;
    self.th_walk  = Garg_Walk;
    self.th_run   = Garg_Combat;
    self.th_pain  = Garg_Pain;
    self.th_die   = Garg_Die;
    self.th_gib   = Garg_Die;       // never gibs from damage (GIB_NEVER)

    Monster_InitTakeDamage();
    self.takeDmgFn   = Garg_TakeDamage;
    self.traceAttack = Garg_TraceAttack;

    self.garg_seeTime   = time + 5;
    self.garg_flameTime = time + 2;
    self.garg_state     = GARGS_RUN;

    // Eye glow sprite (gargeye1, kRenderGlow, ramps in EyeUpdate).
    self.garg_eyeGlow = Sprite_Create(GARG_EYE_SPRITE, self.origin + '0 0 100', FALSE);
    self.garg_eyeGlow.classname  = "garg_eye";
    self.garg_eyeGlow.owner      = self;
    self.garg_eyeGlow.rendermode = 3;           // kRenderGlow
    self.garg_eyeGlow.rendercolor = '255 255 255';
    self.garg_eyeGlow.renderamt  = 0;
    self.garg_eyeGlow.scale      = 1;
    self.garg_eyeGlow.think      = Garg_EyeGlowThink;
    self.garg_eyeGlow.nextthink  = time + 0.05;
    {
        entity stemp = self;
        self = self.garg_eyeGlow;
        Render_Apply(self);
        self = stemp;
    }

    self.think     = Garg_Stand;
    self.nextthink = time + 0.1 + random() * 0.5;
    total_monsters = total_monsters + 1;

    Garg_PlayFrame(GARG_FR_IDLE1);
}
