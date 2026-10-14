
#define SF_MONSTER_TURRET_AUTOACTIVATE    32
#define SF_MONSTER_TURRET_STARTINACTIVE   64

#define MINITURRET_MODEL                  "models/miniturret.iqm"

#define MINITURRET_FIRE_SOUND1            "weapons/hks1.wav"
#define MINITURRET_FIRE_SOUND2            "weapons/hks2.wav"
#define MINITURRET_FIRE_SOUND3            "weapons/hks3.wav"

#define MINITURRET_PING_SOUND             "turret/tu_ping.wav"
#define MINITURRET_DEPLOY_SOUND           "turret/tu_deploy.wav"
#define MINITURRET_ALERT_SOUND            "turret/tu_alert.wav"
#define MINITURRET_DIE_SOUND1             "turret/tu_die.wav"
#define MINITURRET_DIE_SOUND2             "turret/tu_die2.wav"
#define MINITURRET_DIE_SOUND3             "turret/tu_die3.wav"

#define MINITURRET_RANGE                  (100 * 12)
#define MINITURRET_DAMAGE                 Skill_GetValue("sk_9mm_bullet", 5)
#define MINITURRET_TURNRATE               30
#define MINITURRET_MAXWAIT                15
#define MINITURRET_MACHINE_VOLUME         0.5
#define MINITURRET_HEALTH                 Skill_GetValue("sk_miniturret_health", 40)
#define MINITURRET_THINK_RATE             0.1
#define MINITURRET_AUTO_THINK_RATE        0.3
#define MINITURRET_DEPLOY_TIME            0.8
#define MINITURRET_RETIRE_TIME            0.8
#define MINITURRET_DEPLOY_HEIGHT          32
#define MINITURRET_RETRACT_HEIGHT         16
#define MINITURRET_DEFAULT_MIN_PITCH      -15
#define MINITURRET_VIEW_Z                 12.75

#define MINITURRET_ANIM_NONE              0
#define MINITURRET_ANIM_FIRE              1
#define MINITURRET_ANIM_SPIN              2
#define MINITURRET_ANIM_DEPLOY            3
#define MINITURRET_ANIM_RETIRE            4
#define MINITURRET_ANIM_DIE               5

#define MINITURRET_STATE_OFF              0
#define MINITURRET_STATE_DEPLOY           1
#define MINITURRET_STATE_SEARCH           2
#define MINITURRET_STATE_ACTIVE           3
#define MINITURRET_STATE_RETIRE           4
#define MINITURRET_STATE_DEAD             5

// Map-entity keyvalue fields (named to match BSP entity definitions).
.float maxsleep;
.float orientation;
.float turnrate;

// Per-variant overrides used by monster_turret / monster_sentry. 0 = default.
.float turret_noDisplayPitch;
                               // render yaw only, aim pitch lives in v_angle
.float turret_range;
.float turret_damage;
.float turret_minPitch;
.float turret_halfWidth;
.float turret_retractZ;
.float turret_deployZ;
.float turret_viewZ;

#define MiniTurret_Range()      (self.turret_range    ? self.turret_range    : MINITURRET_RANGE)
#define MiniTurret_Damage()     (self.turret_damage   ? self.turret_damage   : MINITURRET_DAMAGE)
#define MiniTurret_MinPitch()   (self.turret_minPitch ? self.turret_minPitch : MINITURRET_DEFAULT_MIN_PITCH)
#define MiniTurret_HalfWidth()  (self.turret_halfWidth ? self.turret_halfWidth : 16)
#define MiniTurret_RetractZ()   (self.turret_retractZ  ? self.turret_retractZ  : MINITURRET_RETRACT_HEIGHT)
#define MiniTurret_DeployZ()    (self.turret_deployZ   ? self.turret_deployZ   : MINITURRET_DEPLOY_HEIGHT)
#define MiniTurret_ViewZ()      (self.turret_viewZ     ? self.turret_viewZ     : MINITURRET_VIEW_Z)

.entity turretGlow;

void MiniTurret_SearchThink();
void MiniTurret_AutoSearchThink();
void MiniTurret_ActiveThink();
void MiniTurret_Retire();
void MiniTurret_Deploy();
void MiniTurret_DeathThink();

entity Sprite_Create(string pSpriteName, vector origin, float animate);	// env_sprite.qc
void Render_Apply(entity targ);	// util_render.qc

#define MiniTurret_AngleDelta(from, to)  Math_AngleDistance((to), (from))
float MiniTurret_ApproachAngle(float value, float target, float speed)
{
    target = Math_AngleMod(target);
    value  = Math_AngleMod(value);
    float delta = target - value;

    if (speed < 0) speed = -speed;
    if (delta < -180) delta = delta + 360;
    else if (delta > 180) delta = delta - 360;

    if (delta > speed)       value = value + speed;
    else if (delta < -speed) value = value - speed;
    else                     value = target;

    return value;
}

void MiniTurret_EyeOn()
{
    if (!self.turretGlow) return;
    self.turretGlow.renderamt = 255;
    {
        entity stemp = self;
        self = self.turretGlow;
        Render_Apply(self);
        self = stemp;
    }
}

void MiniTurret_EyeOff()
{
    if (!self.turretGlow) return;
    if (self.turretGlow.renderamt <= 0) return;
    float amt = self.turretGlow.renderamt - 30;
    if (amt < 0) amt = 0;
    self.turretGlow.renderamt = amt;
    {
        entity stemp = self;
        self = self.turretGlow;
        Render_Apply(self);
        self = stemp;
    }
}

void MiniTurret_UpdateGlowOrigin()
{
    if (!self.turretGlow) return;
    setorigin(self.turretGlow, self.origin + self.view_ofs);
}

void MiniTurret_SetRetiredBounds()
{
    float hw = MiniTurret_HalfWidth();
    float rz = MiniTurret_RetractZ();
    setsize(self, [-hw, -hw, -rz], [hw, hw, rz]);
}

// Deployed bounds extend in the direction the barrel pokes out:
void MiniTurret_SetDeployedBounds()
{
    float hw = MiniTurret_HalfWidth();
    float rz = MiniTurret_RetractZ();
    float dz = MiniTurret_DeployZ();
    if (self.orientation == 1)
        setsize(self, [-hw, -hw, -dz], [hw, hw, rz]);
    else
        setsize(self, [-hw, -hw, -rz], [hw, hw, dz]);
}


void MiniTurret_UpdateDisplayAngles()
{
    float disp_pitch;
    float disp_yaw;
    float disp_roll;

    disp_yaw  = Math_AngleMod(self.v_angle_y);   // -X barrel compensation
    disp_pitch = -self.v_angle_x;                      // entity pitch is inverted

    // makes it lean sideways. Track pitch in v_angle (firing) only.
    if (self.turret_noDisplayPitch)
        disp_pitch = 0;

    if (self.orientation == 1)
    {
        // Roll the model upside down. Roll inverts the local pitch axis, so negate pitch a second time to keep the barrel pointing at the target.
        // negate pitch a second time to keep the barrel pointing at the target.
        disp_roll  = 180;
        disp_pitch = -disp_pitch;
    }
    else
    {
        disp_roll = 0;
    }

    self.angles_x = disp_pitch;
    self.angles_y = disp_yaw;
    self.angles_z = disp_roll;
}

float MiniTurret_TargetVisible(entity target)
{
    vector eye = self.origin + self.view_ofs;
    vector targetPos = target.origin + target.view_ofs;

    traceline(eye, targetPos, TRUE, self);
    if (trace_inopen && trace_inwater) return FALSE;
    return (trace_fraction == 1 || trace_ent == target);
}

entity MiniTurret_FindBestEnemy()
{
    float rng = MiniTurret_Range();
    entity e = findradius(self.origin, rng);
    entity best = world;
    float bestDist = rng + 1;

    while (e)
    {
        if (e != self && IsAlive(e) && !(e.flags & FL_NOTARGET))
        {
            if ((e.flags & (FL_CLIENT | FL_MONSTER)) && e.classname != "monster_miniturret")
            {
                if (e.classname != "observer" && MiniTurret_TargetVisible(e))
                {
                    float dist = vlen((e.origin + e.view_ofs) - (self.origin + self.view_ofs));
                    if (dist < bestDist)
                    {
                        best = e;
                        bestDist = dist;
                    }
                }
            }
        }
        e = e.chain;
    }

    return best;
}

float MiniTurret_Move()
{
    float moved = FALSE;
    float yawDelta = fabs(MiniTurret_AngleDelta(self.v_angle_y, self.finalangle_y));
    float step = self.yaw_speed * MINITURRET_THINK_RATE;

    if (yawDelta > 30)
    {
        if (self.yaw_speed < self.speed * 10)
            self.yaw_speed = self.yaw_speed + self.speed;
    }
    else if (self.yaw_speed > 45)
    {
        self.yaw_speed = self.yaw_speed - self.speed;
    }
    else
    {
        self.yaw_speed = self.yaw_speed + self.speed;
    }

    if (self.yaw_speed < self.speed)
        self.yaw_speed = self.speed;

    step = self.yaw_speed * MINITURRET_THINK_RATE;

    if (fabs(self.finalangle_x - self.v_angle_x) > 0.01)
    {
        self.v_angle_x = Math_Approach(self.finalangle_x, self.v_angle_x, step);
        moved = TRUE;
    }

    if (yawDelta > 0.01)
    {
        self.v_angle_y = MiniTurret_ApproachAngle(self.v_angle_y, self.finalangle_y, step);
        moved = TRUE;
    }

    if (!moved)
        self.yaw_speed = self.speed;

    MiniTurret_UpdateDisplayAngles();
    return moved;
}

#define MINITURRET_TRACER_SPEED 6000
void MiniTurret_SpawnTracer(vector start, vector end)
{
    vector dir = end - start;
    float dist = vlen(dir);
    if (dist <= 0) return;
    dir = dir * (1 / dist);

    entity tr = spawn();
    tr.classname  = "miniturret_tracer";
    tr.owner      = self;
    tr.movetype   = MOVETYPE_FLY;
    tr.solid      = SOLID_NOT;
    setmodel(tr, "models/shell.iqm");
    setsize(tr, '0 0 0', '0 0 0');
    setorigin(tr, start);
    tr.angles     = vectoangles(dir);
    tr.velocity   = dir * MINITURRET_TRACER_SPEED;
    tr.modelflags = MF_TRACER2;
    tr.effects    = EF_ADDITIVE | EF_FULLBRIGHT;
    tr.think      = SUB_Remove;
    tr.nextthink  = time + dist / MINITURRET_TRACER_SPEED;
}

// World-visible muzzleflash (Weapon_Muzzleflash is viewmodel-only via
void MiniTurret_SpawnMuzzleflash(vector org, float scl)
{
    entity mf = Sprite_Create("sprites/muzzleflash.spr", org, TRUE);
    mf.movetype   = MOVETYPE_NONE;
    mf.solid      = SOLID_NOT;
    mf.owner      = self;
    mf.alpha      = 0.7;
    mf.effects    = EF_FULLBRIGHT | EF_ADDITIVE;
    mf.scale      = scl;
    setsize(mf, '0 0 0', '0 0 0');
    setorigin(mf, org);
    mf.angles_z   = random(0, 359);
    mf.think      = SUB_Remove;
    mf.nextthink  = time + 0.05;
}

// Turrets typically have zero spread (pinpoint). We add a small cone for fairer play.
#define MINITURRET_SPREAD 0.0349

void MiniTurret_Fire()
{
    // Engine quirk: vectoangles uses +pitch=UP, makevectors uses +pitch=DOWN.
    // Negate pitch to bridge the two conventions.
    makevectors([-self.v_angle_x, self.v_angle_y, self.v_angle_z]);
    vector src = self.origin + self.view_ofs + v_forward * 12;

    // Circular gaussian spread: reject-sample inside unit disc.
    float sx, sy, sz;
    do {
        sx = (random() - 0.5) + (random() - 0.5);
        sy = (random() - 0.5) + (random() - 0.5);
        sz = sx*sx + sy*sy;
    } while (sz > 1);

    vector cone = v_forward
        + sx * MINITURRET_SPREAD * v_right
        + sy * MINITURRET_SPREAD * v_up;
    vector end = src + cone * MiniTurret_Range();

    ClearMultiDamage();
    {
        float oldSolid = self.solid;
        self.solid = SOLID_BBOX;
        traceline(src, end, FALSE, self);
        self.solid = oldSolid;
    }

    if (trace_fraction != 1.0)
        Combat_TraceAttack(MiniTurret_Damage(), cone, DMG_BULLET);

    ApplyMultiDamage();

    // FX: muzzleflash at barrel, tracer streak to impact.
    MiniTurret_SpawnMuzzleflash(src, 0.5);
    MiniTurret_SpawnTracer(src, trace_endpos);

    self.effects = self.effects | EF_MUZZLEFLASH;

    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, MINITURRET_FIRE_SOUND1, MINITURRET_FIRE_SOUND2, MINITURRET_FIRE_SOUND3);
}

void MiniTurret_BeginSearch()
{
    self.state = MINITURRET_STATE_SEARCH;
    self.think = MiniTurret_SearchThink;
    self.nextthink = time + MINITURRET_THINK_RATE;
}

void MiniTurret_BeginAutoSearch()
{
    self.state = MINITURRET_STATE_OFF;
    self.think = MiniTurret_AutoSearchThink;
    self.nextthink = time + MINITURRET_AUTO_THINK_RATE;
}

void MiniTurret_Deploy()
{
    self.nextthink = time + MINITURRET_THINK_RATE;

    if (self.state != MINITURRET_STATE_DEPLOY)
    {
        self.state = MINITURRET_STATE_DEPLOY;
        self.cnt = 1;
        self.attack_finished = time + MINITURRET_DEPLOY_TIME;
        self.search_time = time + self.wait;
        self.frame = MINITURRET_ANIM_DEPLOY;
        Sound_Play(self, CHAN_BODY, MINITURRET_MACHINE_VOLUME, ATTN_NORM, PITCH_NORM, MINITURRET_DEPLOY_SOUND);
        SUB_UseTargetsHL(self.oldenemy ? self.oldenemy : self, USE_ON, 0);
    }

    MiniTurret_EyeOn();
    MiniTurret_UpdateGlowOrigin();

    if (time >= self.attack_finished)
    {
        MiniTurret_SetDeployedBounds();
        self.frame = MINITURRET_ANIM_SPIN;
        MiniTurret_BeginSearch();
    }
}

void MiniTurret_Retire()
{
    self.nextthink = time + MINITURRET_THINK_RATE;

    if (self.state != MINITURRET_STATE_RETIRE)
    {
        self.state = MINITURRET_STATE_RETIRE;
        self.attack_finished = time + MINITURRET_RETIRE_TIME;
        self.finalangle_x = 0;
        self.finalangle_y = self.ideal_yaw;
        self.frame = MINITURRET_ANIM_RETIRE;
        Sound_Play(self, CHAN_BODY, MINITURRET_MACHINE_VOLUME, ATTN_NORM, PITCH_NORM, MINITURRET_DEPLOY_SOUND);
        SUB_UseTargetsHL(self.oldenemy ? self.oldenemy : self, USE_OFF, 0);
    }

    MiniTurret_Move();
    MiniTurret_EyeOff();
    MiniTurret_UpdateGlowOrigin();

    if (time >= self.attack_finished
        && fabs(self.finalangle_x - self.v_angle_x) < 1
        && fabs(MiniTurret_AngleDelta(self.v_angle_y, self.finalangle_y)) < 1)
    {
        self.cnt = 0;
        self.enemy = world;
        self.dmg = 0;                   // clear berserk flag
        MiniTurret_SetRetiredBounds();
        self.frame = MINITURRET_ANIM_NONE;

        if (self.count)
            MiniTurret_BeginAutoSearch();
        else
        {
            self.state = MINITURRET_STATE_OFF;
            self.think = SUB_Null;
            self.nextthink = 0;
        }
    }
}

void MiniTurret_SearchThink()
{
    self.state = MINITURRET_STATE_SEARCH;
    self.nextthink = time + MINITURRET_THINK_RATE;
    self.frame = MINITURRET_ANIM_SPIN;

    if (self.enemy && !IsAlive(self.enemy))
        self.enemy = world;

    if (!self.enemy)
        self.enemy = MiniTurret_FindBestEnemy();

    if (self.enemy)
    {
        self.search_time = 0;
        self.think = MiniTurret_ActiveThink;
        self.nextthink = time + MINITURRET_THINK_RATE;
        return;
    }

    if (self.pausetime <= time)
    {
        Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, MINITURRET_PING_SOUND);
        self.pausetime = time + 1;
    }

    if (time > self.search_time)
    {
        self.think = MiniTurret_Retire;
        self.nextthink = time + MINITURRET_THINK_RATE;
        return;
    }

    self.finalangle_y = Math_AngleMod(self.finalangle_y + self.speed * MINITURRET_THINK_RATE);
    MiniTurret_Move();
    MiniTurret_EyeOff();
    MiniTurret_UpdateGlowOrigin();
}

void MiniTurret_AutoSearchThink()
{
    self.state = MINITURRET_STATE_OFF;
    self.nextthink = time + MINITURRET_AUTO_THINK_RATE;

    if (self.enemy && !IsAlive(self.enemy))
        self.enemy = world;

    if (!self.enemy)
        self.enemy = MiniTurret_FindBestEnemy();

    if (self.enemy)
    {
        self.oldenemy = self.enemy;
        Sound_Play(self, CHAN_BODY, MINITURRET_MACHINE_VOLUME, ATTN_NORM, PITCH_NORM, MINITURRET_ALERT_SOUND);
        self.think = MiniTurret_Deploy;
        self.nextthink = time + MINITURRET_THINK_RATE;
    }
}

void MiniTurret_ActiveThink()
{
    float canAttack = FALSE;
    vector eye = self.origin + self.view_ofs;
    vector targetPos;
    vector targetAngles;
    vector dirToEnemy;
    float distToEnemy;

    self.state = MINITURRET_STATE_ACTIVE;
    self.nextthink = time + MINITURRET_THINK_RATE;

    if (!self.cnt || !self.enemy)
    {
        self.enemy = world;
        self.search_time = time + self.wait;
        MiniTurret_BeginSearch();
        return;
    }

    if (!IsAlive(self.enemy))
    {
        if (!self.search_time)
            self.search_time = time + 0.5;
        else if (time > self.search_time)
        {
            self.enemy = world;
            self.search_time = time + self.wait;
            MiniTurret_BeginSearch();
            return;
        }
    }

     // shooting over heads / above corpses whose view_ofs is stale.
    {
        vector center = (self.enemy.absmin + self.enemy.absmax) * 0.5;
        vector eyePos = self.enemy.origin + self.enemy.view_ofs;
        targetPos = center * 0.75 + eyePos * 0.25;
    }
    dirToEnemy = targetPos - eye;
    distToEnemy = vlen(dirToEnemy);
    if (!MiniTurret_TargetVisible(self.enemy) || distToEnemy > MiniTurret_Range())
    {
        if (!self.search_time) self.search_time = time + 0.5;
        else if (time > self.search_time)
        {
            self.enemy = world;
            self.search_time = time + self.wait;
            MiniTurret_BeginSearch();
            return;
        }

        targetPos = self.dest;
        dirToEnemy = targetPos - eye;
    }
    else
    {
        self.dest = targetPos;
        self.search_time = 0;
    }

    targetAngles = vectoangles(dirToEnemy);
    if (targetAngles_x > 180) targetAngles_x = targetAngles_x - 360;

    // Pitch clamp based on orientation. Convention: +pitch = UP.
    // floor: limit downward pitch to minPitch (~-15°), allow full up
    // ceiling: limit upward pitch to -minPitch (~+15°), allow full down
    float minP = MiniTurret_MinPitch();
    if (self.orientation == 1)
    {
        if (targetAngles_x < -90)      targetAngles_x = -90;
        else if (targetAngles_x > -minP) targetAngles_x = -minP;
    }
    else
    {
        if (targetAngles_x > 90)       targetAngles_x = 90;
        else if (targetAngles_x < minP) targetAngles_x = minP;
    }

    self.finalangle_x = targetAngles_x;
    self.finalangle_y = Math_AngleMod(targetAngles_y);

    if (self.dmg && Math_RandomInt(0, 9) == 0)    // berserk: random spray
    {
        self.finalangle_y = random(0, 360);
        if (self.orientation == 1)
            self.finalangle_x = random(-90, -minP);
        else
            self.finalangle_x = random(minP, 90);
    }

    MiniTurret_Move();

    // Engine quirk: vectoangles uses +pitch=UP, makevectors uses +pitch=DOWN.
    makevectors([-self.v_angle_x, self.v_angle_y, self.v_angle_z]);
    if (normalize(dirToEnemy) * v_forward > 0.866)
        canAttack = TRUE;

    if (canAttack && self.enemy)
    {
        self.frame = MINITURRET_ANIM_FIRE;
        MiniTurret_Fire();
    }
    else
    {
        self.frame = MINITURRET_ANIM_SPIN;
    }

    MiniTurret_EyeOn();
    MiniTurret_UpdateGlowOrigin();
}

void MiniTurret_DeathThink()
{
    self.state = MINITURRET_STATE_DEAD;
    self.nextthink = time + MINITURRET_THINK_RATE;

    if (self.deadflag != DEAD_DEAD)
    {
        self.deadflag = DEAD_DEAD;
        self.solid = SOLID_NOT;
        self.movetype = MOVETYPE_NONE;
        self.enemy = world;
        self.cnt = 0;
        self.dmg = 0;
        self.pain_finished = time + 5;  // death sparks window

        self.frame = MINITURRET_ANIM_DIE;

        Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 100, MINITURRET_DIE_SOUND1, MINITURRET_DIE_SOUND2, MINITURRET_DIE_SOUND3);

        self.finalangle_x = MiniTurret_MinPitch();
        MiniTurret_Move();

        SUB_UseTargetsHL(self.oldenemy ? self.oldenemy : self, USE_ON, 0);
    }

    if (random() < 0.35)
        te_spark(self.origin + [random(-8, 8), random(-8, 8), random(0, 20)], randomvec(), Math_RandomInt(3, 8));

    MiniTurret_Move();
    MiniTurret_EyeOff();
    MiniTurret_UpdateGlowOrigin();

    if (time >= self.pain_finished)
    {
        if (self.turretGlow) { remove(self.turretGlow); self.turretGlow = world; }
        self.think = SUB_Null;
        self.nextthink = 0;
    }
}

float MiniTurret_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
    if (!self.cnt)                          // not deployed: absorb most damage
        damage = damage * 0.1;

    if (damage < 1 && self.health > 1)
        damage = 1;

    {
        float result = Monster_TakeDamage(inflictor, attacker, damage, dmgType);

        if (self.health > 0 && !self.deadflag && self.health <= 10 && self.cnt)
        {
            self.dmg = 1;                   // enter berserk mode
            if (self.think != MiniTurret_DeathThink)
            {
                self.think = MiniTurret_SearchThink;
                self.nextthink = time + MINITURRET_THINK_RATE;
            }
        }

        return result;
    }
}

void MiniTurret_DisarmOnDeath()
{
    self.deadflag = DEAD_DYING;              // guards act immediately
    self.flags    = self.flags - (self.flags & FL_MONSTER);
    self.use      = SUB_Null;
    self.usehl    = __NULL__;
    self.touch    = SUB_Null;                // sentry touch-wake race
    self.count    = 0;                       // no autosearch re-arm
    self.cnt      = 0;
}

void MiniTurret_Die()
{
    MiniTurret_DisarmOnDeath();
    self.think = MiniTurret_DeathThink;
    self.nextthink = time + MINITURRET_THINK_RATE;
}

void MiniTurret_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (self.deadflag) return;	// dead turrets don't re-deploy

    float currentState = self.cnt || self.state == MINITURRET_STATE_DEPLOY || self.state == MINITURRET_STATE_RETIRE;

    if (useTypeArg != USE_TOGGLE && useTypeArg != USE_SET)
    {
        if ((currentState && useTypeArg == USE_ON) || (!currentState && useTypeArg == USE_OFF))
            return;
    }

    self.oldenemy = pActivator;

    if (currentState)
    {
        self.enemy = world;
        self.count = 0;
        self.think = MiniTurret_Retire;
        self.nextthink = time + MINITURRET_THINK_RATE;
    }
    else
    {
        if (self.spawnflags & SF_MONSTER_TURRET_AUTOACTIVATE)
            self.count = 1;

        self.think = MiniTurret_Deploy;
        self.nextthink = time + MINITURRET_THINK_RATE;
    }
}

void MiniTurret_Use()
{
    MiniTurret_UseHL(activator, self, USE_TOGGLE, 0);
}

void MiniTurret_Precache()
{
    precache_model(MINITURRET_MODEL);
    precache_model("models/shell.iqm");
    precache_model("sprites/muzzleflash.spr");

    precache_sound(MINITURRET_FIRE_SOUND1);
    precache_sound(MINITURRET_FIRE_SOUND2);
    precache_sound(MINITURRET_FIRE_SOUND3);

    precache_sound(MINITURRET_PING_SOUND);
    precache_sound(MINITURRET_DEPLOY_SOUND);
    precache_sound(MINITURRET_ALERT_SOUND);
    precache_sound(MINITURRET_DIE_SOUND1);
    precache_sound(MINITURRET_DIE_SOUND2);
    precache_sound(MINITURRET_DIE_SOUND3);
}

void monster_miniturret()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

    MiniTurret_Precache();
	self.nextthink		= time + 1;
	self.movetype		= MOVETYPE_FLY;
	self.frame			= 0;
	self.solid			= SOLID_SLIDEBOX;
	self.takedamage		= DAMAGE_AIM;

    setmodel(self, MINITURRET_MODEL);
    MiniTurret_SetRetiredBounds();

    self.classname = "monster_miniturret";
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_NONE;
    self.health = MINITURRET_HEALTH;
    self.max_health = self.health;
    self.view_ofs = '0 0 12.75';
    self.deadflag = DEAD_NO;
    self.flags = self.flags | FL_MONSTER;
    self.takedamage = DAMAGE_AIM;
    self.takeDmgFn = MiniTurret_TakeDamage;
    self.th_die = MiniTurret_Die;
    self.use = MiniTurret_Use;
    self.usehl = MiniTurret_UseHL;
    self.monster_bloodColor = -1;   // DONT_BLEED: machines spark, never bleed

    self.cnt = 0;                           // not deployed
    self.dmg = 0;                           // not berserk
    self.state = MINITURRET_STATE_OFF;
    self.count = ((self.spawnflags & SF_MONSTER_TURRET_AUTOACTIVATE) && !(self.spawnflags & SF_MONSTER_TURRET_STARTINACTIVE));
    self.speed = self.turnrate ? self.turnrate : MINITURRET_TURNRATE;   // base turn rate
    self.yaw_speed = self.speed;                                         // current turn rate
    self.wait = self.maxsleep ? self.maxsleep : MINITURRET_MAXWAIT;     // idle timeout

    self.ideal_yaw = Math_AngleMod(self.angles_y);

    if (self.orientation == 1)
    {
        // Eye sits below origin so we trace from outside the ceiling brush.
        self.view_ofs_z = -MiniTurret_ViewZ();
    }

    self.v_angle = [0, self.ideal_yaw, 0];
    self.finalangle = self.v_angle;
    self.pausetime = time + 1;              // first ping delay
    self.oldenemy = world;
    self.enemy = world;

    MiniTurret_UpdateDisplayAngles();
    setorigin(self, self.origin);


    if (self.count)
        MiniTurret_BeginAutoSearch();
    else
    {
        self.think = SUB_Null;
        self.nextthink = 0;
    }

    total_monsters = total_monsters + 1;
}
