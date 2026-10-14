#define ROACH_MODEL                 "models/roach.iqm"

#define ROACH_DIE_SOUND             "roach/rch_die.wav"
#define ROACH_WALK_SOUND            "roach/rch_walk.wav"
#define ROACH_SMASH_SOUND           "roach/rch_smash.wav"

#define ROACH_IDLE                  0
#define ROACH_BORED                 1
#define ROACH_SCARED_BY_ENT         2
#define ROACH_SCARED_BY_LIGHT       3
#define ROACH_SMELL_FOOD            4
#define ROACH_EAT                   5

#define ROACH_ANIM_IDLE             0
#define ROACH_ANIM_WALK             1

#define ROACH_THINK_RATE            0.1
#define ROACH_PVS_SLEEP_MIN         1.0
#define ROACH_PVS_SLEEP_RAND        0.5
#define ROACH_LIGHT_INIT_DELAY      1.0
#define ROACH_SCARE_RADIUS          150
#define ROACH_SMELL_RADIUS          256
#define ROACH_MIN_WANDER_DIST       128
#define ROACH_MAX_WANDER_DIST       511
#define ROACH_WALK_SPEED            36

.float  roach_mode;
.float  roach_lastLightLevel;
.float  roach_nextSmellTime;
.float  roach_lightReady;
.float  roach_lightInitAt;
.float  roach_hasDest;
.vector roach_dest;

float Cockroach_HasClientInPVS()
{
    entity client = checkclient();
    if (!client) return FALSE;
    if (client == world) return FALSE;
    if (client.classname == "observer") return FALSE;
    return TRUE;
}

float Cockroach_LightLevel()
{
    vector sample = getlight(self.origin + '0 0 4');
    return vlen(sample);
}

float Cockroach_FVisible(entity target)
{
    traceline(self.origin + self.view_ofs, target.origin + target.view_ofs, TRUE, self);
    if (trace_inopen && trace_inwater) return FALSE;
    return (trace_fraction == 1 || trace_ent == target);
}

entity Cockroach_FindFood()
{
    entity e = findradius(self.origin, ROACH_SMELL_RADIUS);
    entity best = world;
    float bestDist = ROACH_SMELL_RADIUS + 1;

    while (e)
    {
        if (e != self)
        {
            if (e.classname == "gib"
                || ((e.flags & (FL_CLIENT | FL_MONSTER)) && !IsAlive(e)))
            {
                if (fabs(e.origin_z - self.origin_z) <= 16)
                {
                    float dist = vlen(e.origin - self.origin);
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

float Cockroach_SeeFear()
{
    entity e = findradius(self.origin, ROACH_SCARE_RADIUS);
    while (e)
    {
        if (e != self && e.classname != "monster_cockroach" && IsAlive(e))
        {
            if (e.flags & (FL_CLIENT | FL_MONSTER))
            {
                if (!(e.flags & FL_NOTARGET) && Cockroach_FVisible(e))
                    return TRUE;
            }
        }
        e = e.chain;
    }
    return FALSE;
}

void Cockroach_SetIdle()
{
    self.roach_hasDest = FALSE;
    self.roach_mode = ROACH_IDLE;
    self.frame = ROACH_ANIM_IDLE;
    self.roach_lastLightLevel = Cockroach_LightLevel();
}

void Cockroach_PlayWalkSound()
{
    Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 80 + Math_RandomInt(0, 39), ROACH_WALK_SOUND);
}

void Cockroach_PickNewDest(float mode)
{
    vector dest;
    entity food;

    self.roach_mode = mode;

    if (mode == ROACH_SMELL_FOOD)
    {
        food = Cockroach_FindFood();
        if (food)
        {
            dest = food.origin;
            dest_x = dest_x + random(-2, 3);
            dest_y = dest_y + random(-2, 3);
            dest_z = self.origin_z;
            self.roach_dest = dest;
            self.roach_hasDest = TRUE;
            self.frame = ROACH_ANIM_WALK;
            return;
        }
    }

    do
    {
        vector dir = normalize([random(-1, 1), random(-1, 1), 0]);
        if (!vlen(dir)) dir = '1 0 0';
        float dist = random(ROACH_MIN_WANDER_DIST, ROACH_MAX_WANDER_DIST);
        dest = self.origin + dir * dist;
        dest_z = self.origin_z;
    }
    while (vlen(dest - self.origin) < ROACH_MIN_WANDER_DIST);

    self.roach_dest = dest;
    self.roach_hasDest = TRUE;
    self.frame = ROACH_ANIM_WALK;

    if (Math_RandomInt(0, 9) == 1)
        Cockroach_PlayWalkSound();
}

void Cockroach_Move(float interval)
{
    if (!self.roach_hasDest)
        return;

    float flWaypointDist = vlen(self.roach_dest - self.origin);
    float step = ROACH_WALK_SPEED * interval;

    self.ideal_yaw = vectoyaw(self.roach_dest - self.origin);
    ChangeYaw();

    if (Math_RandomInt(0, 7) == 1)
    {
        if (!walkmove(self.ideal_yaw, 4))
        {
            Cockroach_PickNewDest(self.roach_mode);
            return;
        }
    }

    walkmove(self.ideal_yaw, step);

    if (flWaypointDist <= step)
    {
        self.roach_hasDest = FALSE;
        self.frame = ROACH_ANIM_IDLE;
        self.roach_lastLightLevel = Cockroach_LightLevel();

        if (self.roach_mode == ROACH_SMELL_FOOD)
            self.roach_mode = ROACH_EAT;
        else
            self.roach_mode = ROACH_IDLE;
    }

    if (Math_RandomInt(0, 149) == 1
        && self.roach_mode != ROACH_SCARED_BY_LIGHT
        && self.roach_mode != ROACH_SMELL_FOOD)
    {
        Cockroach_PickNewDest(ROACH_BORED);
    }
}

void Cockroach_Think()
{
    if (Monster_IsBarnacled())
    {
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    if (!Cockroach_HasClientInPVS())
    {
        self.nextthink = time + random(ROACH_PVS_SLEEP_MIN, ROACH_PVS_SLEEP_MIN + ROACH_PVS_SLEEP_RAND);
        return;
    }

    self.nextthink = time + ROACH_THINK_RATE;

    if (!self.roach_lightReady)
    {
        if (time < self.roach_lightInitAt)
            return;

        self.roach_lastLightLevel = Cockroach_LightLevel();
        self.roach_lightReady = TRUE;
    }

    if (self.roach_mode == ROACH_IDLE || self.roach_mode == ROACH_EAT)
    {
        if (Math_RandomInt(0, 3) == 1)
        {
            if (Cockroach_SeeFear())
            {
                self.roach_nextSmellTime = time + random(30, 45);
                Cockroach_PickNewDest(ROACH_SCARED_BY_ENT);
            }
            else if (Math_RandomInt(0, 149) == 1)
            {
                float wasEating = (self.roach_mode == ROACH_EAT);
                Cockroach_PickNewDest(ROACH_BORED);
                if (wasEating)
                    self.roach_nextSmellTime = time + random(30, 45);
            }
        }

        if (self.roach_mode == ROACH_IDLE)
        {
            if (Cockroach_LightLevel() > self.roach_lastLightLevel + 8)
            {
                Cockroach_PickNewDest(ROACH_SCARED_BY_LIGHT);
            }
            else if (time >= self.roach_nextSmellTime)
            {
                entity food = Cockroach_FindFood();
                if (food)
                    Cockroach_PickNewDest(ROACH_SMELL_FOOD);
            }
        }
    }
    else if (self.roach_mode == ROACH_SCARED_BY_LIGHT)
    {
        if (Cockroach_LightLevel() <= self.roach_lastLightLevel)
            Cockroach_SetIdle();
    }

    if (self.roach_hasDest)
        Cockroach_Move(ROACH_THINK_RATE);
}

void Cockroach_Touch()
{
    if (!(other.flags & FL_CLIENT)) return;
    if (vlen(other.velocity) <= 0) return;

    particle(self.origin + '0 0 2', '0 0 0', BLOOD_COLOR_YELLOW, 12);
    T_Damage(self, other, other, self.health, DMG_CRUSH);
}

void Cockroach_Die()
{
    self.solid = SOLID_NOT;

    if (Math_RandomInt(0, 4) == 1)
        Sound_Play(self, CHAN_VOICE, 0.8, ATTN_NORM, 80 + Math_RandomInt(0, 39), ROACH_DIE_SOUND);
    else
        Sound_Play(self, CHAN_BODY, 0.7, ATTN_NORM, 80 + Math_RandomInt(0, 39), ROACH_SMASH_SOUND);

    remove(self);
}

void Cockroach_Precache()
{
    precache_model(ROACH_MODEL);
    precache_sound(ROACH_DIE_SOUND);
    precache_sound(ROACH_WALK_SOUND);
    precache_sound(ROACH_SMASH_SOUND);
}

void monster_cockroach()
{
	if (Monster_RemoveIfSpent()) return;
	if(RemoveInDeathmatch()) return;

    Cockroach_Precache();

    setmodel(self, ROACH_MODEL);
    setsize(self, '-1 -1 0', '1 1 2');

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    self.health = 1;
    self.max_health = self.health;
    self.monster_bloodColor = BLOOD_COLOR_YELLOW;
    self.view_ofs = '0 0 1';
    self.yaw_speed = YAW_HL(120);
    self.frame = ROACH_ANIM_IDLE;
    self.deadflag = DEAD_NO;
    self.flags = self.flags | FL_MONSTER;

    self.touch = Cockroach_Touch;
    self.th_die = Cockroach_Die;
    self.takeDmgFn = Monster_TakeDamage;
    self.takedamage = DAMAGE_AIM;

    self.roach_mode = ROACH_IDLE;
    self.roach_nextSmellTime = time;
    self.roach_lightReady = FALSE;
    self.roach_lightInitAt = time + ROACH_LIGHT_INIT_DELAY;
    self.roach_hasDest = FALSE;

    setorigin(self, self.origin);
    droptofloor();

    self.think = Cockroach_Think;
    self.nextthink = time + ROACH_THINK_RATE;

    total_monsters = total_monsters + 1;
}
