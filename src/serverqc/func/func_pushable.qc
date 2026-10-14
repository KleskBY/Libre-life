
#define SF_PUSH_BREAKABLE       128

#define PUSH_THINK_RATE         0.02
#define PUSH_GRAVITY            800
#define PUSH_GROUND_TRACE_DIST  8
#define PUSH_PLAYER_FACTOR      1.0
#define PUSH_SPEED_CAP          400
#define PUSH_TICK_FUDGE         15	//sv_pushable_fixed_tick_fudge

.float pushable_maxSpeed;
.float pushable_soundTime;

.float buoyancy;
.float pushable_buoyancy;
#define PUSH_BUOYANCY_AREA_SCALE  0.0005
#define PUSH_WATER_DRAG   3

string PUSH_SOUND_1 = "debris/pushbox1.wav";
string PUSH_SOUND_2 = "debris/pushbox2.wav";
string PUSH_SOUND_3 = "debris/pushbox3.wav";

void Pushable_PrecacheSounds()
{
    precache_sound(PUSH_SOUND_1);
    precache_sound(PUSH_SOUND_2);
    precache_sound(PUSH_SOUND_3);
}

float Pushable_IsOnGround()
{
    vector botcenter;
    botcenter_x = self.origin_x + (self.mins_x + self.maxs_x) * 0.5;
    botcenter_y = self.origin_y + (self.mins_y + self.maxs_y) * 0.5;
    botcenter_z = self.origin_z + self.mins_z + 1;	// 1u above hull bottom

    vector dst = botcenter;
    dst_z = botcenter_z - (PUSH_GROUND_TRACE_DIST + 1);

    traceline(botcenter, dst, FALSE, self);
    if (trace_fraction < 1.0 && trace_plane_normal_z > 0.7)
    {
        self.groundentity = trace_ent;
        return TRUE;
    }
    self.groundentity = world;
    return FALSE;
}

// Returns submerged depth in world units and sets waterlevel.
float Pushable_Submersion()
{
    vector c;
    c_x = self.origin_x + (self.mins_x + self.maxs_x) * 0.5;
    c_y = self.origin_y + (self.mins_y + self.maxs_y) * 0.5;
    float bot = self.origin_z + self.mins_z + 1;
    float top = self.origin_z + self.maxs_z - 1;
    float height = top - bot;
    if (height <= 0)
    {
        self.waterlevel = 0;
        return 0;
    }

    c_z = bot;
    float cont = pointcontents(c);
    if (cont != CONTENT_WATER && cont != CONTENT_SLIME)
    {
        self.waterlevel = 0;
        return 0;
    }

    c_z = top;
    cont = pointcontents(c);
    if (cont == CONTENT_WATER || cont == CONTENT_SLIME)
    {
        self.waterlevel = 3;
        return height;
    }

    float lo = bot;
    float hi = top;
    float i;
    for (i = 0; i < 7; i = i + 1)	// 7 halvings: sub-unit surface resolution
    {
        c_z = (lo + hi) * 0.5;
        cont = pointcontents(c);
        if (cont == CONTENT_WATER || cont == CONTENT_SLIME) lo = c_z;
        else hi = c_z;
    }

    float surface = (lo + hi) * 0.5;
    self.waterlevel = (surface >= bot + height * 0.5) ? 2 : 1;
    return surface - bot;
}

void Pushable_Think()
{
    float dt = PUSH_THINK_RATE;
    vector pushStartOrigin = self.origin;
    float onGround = Pushable_IsOnGround();
    float submerged = Pushable_Submersion();
    float lift = submerged * self.pushable_buoyancy;

    if (!onGround || lift > PUSH_GRAVITY)
        self.velocity_z = self.velocity_z + (lift - PUSH_GRAVITY) * dt;
    else if (self.velocity_z < 0)
        self.velocity_z = 0;

    if (self.waterlevel > 0)
    {
        float drag = 1 - PUSH_WATER_DRAG * dt;
        if (drag < 0) drag = 0;
        self.velocity = self.velocity * drag;
    }

    entity gnd = self.groundentity;
    if (onGround && gnd != world && gnd.velocity != '0 0 0')
    {
        vector carryTarget = self.origin + gnd.velocity * dt;
        tracebox(self.origin, self.mins, self.maxs, carryTarget, FALSE, self);
        if (!trace_startsolid)
            setorigin(self, trace_endpos);
    }

    // Friction on horizontal velocity. Drop = friction * dt.
    if (onGround)
    {
        float speed = sqrt(self.velocity_x * self.velocity_x +
                           self.velocity_y * self.velocity_y);
        if (speed > 0)
        {
            float frict = 400 - self.pushable_maxSpeed;
            if (frict < 0) frict = 0;
            float drop = frict * dt;
            float newSpeed = speed - drop;
            if (newSpeed < 0) newSpeed = 0;
            float scale = newSpeed / speed;
            self.velocity_x = self.velocity_x * scale;
            self.velocity_y = self.velocity_y * scale;
        }
    }

    if (self.velocity != '0 0 0')
    {
        vector saved_origin = self.origin;
        vector saved_velocity = self.velocity;
        float remaining = dt;
        float i;
        for (i = 0; i < 3; i = i + 1)
        {
            if (self.velocity == '0 0 0') break;

            vector target = self.origin + self.velocity * remaining;
            tracebox(self.origin, self.mins, self.maxs, target, FALSE, self);

            if (trace_startsolid)
            {
                setorigin(self, saved_origin);
                self.velocity = saved_velocity;
                self.velocity_z = 0;
                break;
            }

            setorigin(self, trace_endpos);

            if (trace_fraction >= 1.0) break;	// moved full requested distance

            // Slide along contact plane: remove velocity component along normal.
            float ndot = self.velocity * trace_plane_normal;
            self.velocity = self.velocity - trace_plane_normal * ndot;

            if (self.velocity * saved_velocity <= 0)
            {
                self.velocity = '0 0 0';
                break;
            }

            remaining = remaining * (1.0 - trace_fraction);
        }
    }

    if (self.origin != pushStartOrigin)
        force_retouch = 2;

    self.nextthink = time + dt;
}

void Pushable_Move(entity toucher, float push)
{
    if ((toucher.flags & FL_ONGROUND) && toucher.groundentity == self)
    {
        if (self.waterlevel > 0)
            self.velocity_z = self.velocity_z + toucher.velocity_z * 0.1;
        return;
    }

    float playerTouch = (toucher.classname == "player") ? 1 : 0;

    // Don't push when player is holding +use; that's the pull (Use) path.
    if (push && playerTouch && (toucher.button5 || toucher.buttonuse))
        return;

    float factor;
    if (playerTouch)
    {
        if (!(toucher.flags & FL_ONGROUND))
        {
            if (self.waterlevel < 1)
                return;     // jumping/falling player can't push on dry land
            factor = 0.1;   // but a swimmer can nudge a floating crate
        }
        else
            factor = PUSH_PLAYER_FACTOR;
    }
    else
    {
        factor = 0.25;
    }

    if (!push)
        factor = factor * frametime * PUSH_TICK_FUDGE;

    float addX = toucher.velocity_x * factor;
    float addY = toucher.velocity_y * factor;
    if (push || fabs(self.velocity_x) < fabs(toucher.velocity_x - addX))
        self.velocity_x = self.velocity_x + addX;
    if (push || fabs(self.velocity_y) < fabs(toucher.velocity_y - addY))
        self.velocity_y = self.velocity_y + addY;

    // Cap horizontal speed at pushable_maxSpeed
    float length = sqrt(self.velocity_x * self.velocity_x +
                        self.velocity_y * self.velocity_y);
    if (length > self.pushable_maxSpeed && length > 0)
    {
        float k = self.pushable_maxSpeed / length;
        self.velocity_x = self.velocity_x * k;
        self.velocity_y = self.velocity_y * k;
    }

    if (playerTouch && push)
    {
        // Match player to pushable so we don't slide past
        toucher.velocity_x = self.velocity_x;
        toucher.velocity_y = self.velocity_y;
    }

    if (playerTouch && (time - self.pushable_soundTime) > 0.7)
    {
        self.pushable_soundTime = time;
        if (length > 0)
        {
            float pick = Math_RandomInt(0, 2);
            string snd = (pick == 0) ? PUSH_SOUND_1
                       : (pick == 1) ? PUSH_SOUND_2
                       :               PUSH_SOUND_3;
            Sound_Play(self, CHAN_WEAPON, 0.5, ATTN_NORM, PITCH_NORM, snd);
        }
    }
}

void Pushable_Touch()
{
    if (other == world) return;
    if (other.classname == "worldspawn") return;
    if (other.solid == SOLID_CORPSE) return;	// don't react to ragdolls/dead bodies
    Pushable_Move(other, 1);
}

void Breakable_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg);

void Pushable_Use()
{
    if (!activator || activator.classname != "player")
    {
        if (self.spawnflags & SF_PUSH_BREAKABLE)
            Breakable_UseHL(activator, activator, USE_TOGGLE, 0);
        return;
    }
    if (activator.velocity == '0 0 0') return;
    Pushable_Move(activator, 0);
}

void Pushable_UseHL(entity pActivator, entity pCaller, float utype, float uvalue)
{
    if (!pActivator || pActivator.classname != "player")
    {
        if (self.spawnflags & SF_PUSH_BREAKABLE)
            Breakable_UseHL(pActivator, pCaller, utype, uvalue);
        return;
    }
    if (pActivator.velocity == '0 0 0') return;
    Pushable_Move(pActivator, 0);
}

void Breakable_Die();
void Pushable_Die()
{
    Breakable_Die();
}

void func_pushable()
{
    Spent_Capture(self);
    if (Spent_IsSpent(self)) { remove(self); return; }

    Pushable_PrecacheSounds();

    // Breakable variant: precache materials + arm damage path
    if (self.spawnflags & SF_PUSH_BREAKABLE && self.health > 0)
    {
        // Reuse breakable material precache by setting up the same fields
        self.max_health = self.health;
        self.takedamage = DAMAGE_YES;
        self.th_die     = Pushable_Die;

        Breakable_Precache();
        self.traceAttack = Breakable_TraceAttack;
        self.takeDmgFn   = Breakable_TakeDamage;
    }
    else
    {
        self.takedamage = DAMAGE_NO;
    }

    self.solid    = SOLID_BBOX;
    // FTE networks SOLID_BBOX to predicting clients as a box centred on the origin;
    // a brush crate's bounds are in world space, so clients saw no crate under the
    // player and prediction slid them off. SOLID_BSP sends the brush hull instead.
    if (IsFTE()) self.solid = SOLID_BSP;
    self.movetype = MOVETYPE_NONE;

    self.dphitcontentsmask = DPCONTENTS_SOLID | DPCONTENTS_BODY;

    setmodel(self, self.model);
    setsize(self, self.mins, self.maxs);

    if (GlobalState_RemoveIfDead(self))
        return;

    // Clamp friction and convert to maxSpeed
    if (self.friction > 399) self.friction = 399;
    if (self.friction <   0) self.friction =   0;
    self.pushable_maxSpeed = 400 - self.friction;
    self.friction   = 0;

    // Scale the map's buoyancy key by the box cross-section (assuming a standard volume)
    self.pushable_buoyancy = self.buoyancy
                           * (self.maxs_x - self.mins_x)
                           * (self.maxs_y - self.mins_y)
                           * PUSH_BUOYANCY_AREA_SCALE;

    // Lift 1 unit so we don't start embedded in the floor
    self.origin_z = self.origin_z + 1;
    setorigin(self, self.origin);

    self.classname = "func_pushable";
    self.touch = Pushable_Touch;
    self.use   = Pushable_Use;
    self.usehl = Pushable_UseHL;
    self.object_caps = FCAP_CONTINUOUS_USE;

    self.think     = Pushable_Think;
    self.nextthink = time + PUSH_THINK_RATE;
}


void() Movable_Think =
{
    if(self.owner.buttonuse)
    {
        self.flags = self.flags - (self.flags & FL_ONGROUND);
        makevectors(self.owner.v_angle);
        vector center = (self.absmin + self.absmax) * 0.5;
        center = center - self.lastAngles;
        vector newPos = self.owner.origin + v_forward * 60 + v_up * 10;
        vector dir =  newPos - center;
        self.velocity = dir * 8;
        self.nextthink = time + 0.1;
    }
    else
    {
        self.movetype = MOVETYPE_STEP;
        self.owner = world;
    }
}

void() Movable_Touch =
{
    if(other.classname != "useprefab") return;
    if(self.owner) return;
    vector center = (self.absmin + self.absmax) * 0.5;
    self.lastAngles = center - other.origin;
    self.movetype = MOVETYPE_FLY;
    self.owner = other.owner;
    self.think = Movable_Think;
    self.nextthink = time + 0.1;
}

void() func_movable =
{
    self.solid = SOLID_BSP;
    self.movetype = MOVETYPE_STEP;
    setorigin (self, self.origin);
    setmodel (self, self.model);
    self.classname = "func_movable";
    self.touch = Movable_Touch;
}


void() Pushable_Touch2 =
{
	if(other.classname != "player") return;
	vector center = (self.absmin + self.absmax) * 0.5;
	vector dir = center - other.origin;

	dir_z = 0; 
	dir = normalize(dir);
	dir_x = rint(dir_x);
	dir_y = rint(dir_y);
	float yaw = vectoyaw(dir);
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.velocity = dir * 125;
}


void() func_pushable2 =
{
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_STEP; //MOVETYPE_TOSS
	setorigin (self, self.origin);
	setmodel (self, self.model);
	self.classname = "func_pushable";
	self.touch = Pushable_Touch2;
}

