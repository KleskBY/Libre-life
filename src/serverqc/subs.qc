
// "master" keyvalue (multisource / game_team_master gate). Declared here
// rather than in func_button.qc because Master_IsTriggered and the spawn-point validity check both need it before that file is compiled.
.string master;

void() SUB_Null = {};
void(entity attacker, float damage) SUB_null_pain = {};
void SUB_Remove() = { remove(self); };
void SUB_CalcMove(vector tdest, float tspeed, void() func);
void SUB_UseTargets();
void SUB_UseTargetsHL(entity pActivator, float useTypeArg, float useValueArg);

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/


void SUB_CalcMoveDone()
{
	setorigin(self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1) self.think1();
};

void SUB_CalcMoveEnt(entity ent, vector tdest, float tspeed, void() func)
{
	entity stemp = self;
	self = ent;
	SUB_CalcMove(tdest, tspeed, func);
	self = stemp;
}

void SUB_CalcMove(vector tdest, float tspeed, void() func)
{
	if (!tspeed) objerror("No speed is defined!");
	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;
	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	vector vdestdelta = tdest - self.origin;
	float traveltime = vlen(vdestdelta) / tspeed;
	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	self.nextthink = self.ltime + traveltime; // set nextthink to trigger a think when dest is reached
	self.velocity = vdestdelta * (1 / traveltime);
};


/*
============
After moving, set origin to exact final destination
============
*/


/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating

The calling function should make sure self.think is valid
===============
*/

//After rotating, set angle to exact final angle
void SUB_CalcAngleMoveDone()
{
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1) self.think1();
};

void SUB_CalcAngleMove(vector destangle, float tspeed, void() func)
{
	if (!tspeed) objerror("No speed is defined!");
	self.think1 = func;
	self.finalangle = destangle;
	self.think = SUB_CalcAngleMoveDone;
	if (destangle == self.angles)
	{
		self.avelocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	vector destdelta = destangle - self.angles;

	if (destdelta_x > 180)  destdelta_x = destdelta_x - 360;
	else if (destdelta_x < -180) destdelta_x = destdelta_x + 360;
	if (destdelta_y > 180)  destdelta_y = destdelta_y - 360;
	else if (destdelta_y < -180) destdelta_y = destdelta_y + 360;
	if (destdelta_z > 180)  destdelta_z = destdelta_z - 360;
	else if (destdelta_z < -180) destdelta_z = destdelta_z + 360;

	float len = vlen(destdelta);
	float traveltime = len / tspeed;
	if (traveltime < 0.1)
	{
		self.avelocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	self.nextthink = self.ltime + traveltime;
	self.avelocity = destdelta * (1 / traveltime);
};

/*
============
============
*/


void DelayThink()
{
	activator = self.enemy;
	SUB_UseTargets();
	remove(self);
};

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for(string)targetname in all entities that
match(string)self.target and call their .use function

==============================
*/


//
// SUB_FireTargets
//
void SUB_FireTargets(string targetName, entity pActivator, entity pCaller, float type_of_use, float value)
{
	if (!targetName) return;


	entity t = find(world, targetname, targetName);
	while(t)
	{
		if (!(t.flags & FL_KILLME))
		{

			if (t.usehl)
			{
				entity hself = self;
				entity hother = other;
				self = t;
				t.usehl(pActivator, pCaller, type_of_use, value);
				self = hself;
				other = hother;
			}
			else if (t.use)
			{
				// Legacy fallback: populate globals, self-swap, restore.
				entity act = activator;
				entity oself = self;
				activator = pActivator;
				useType = type_of_use;
				self = t;
				t.use();
				self = oself;
				activator = act;
			}
		}
		t = find(t, targetname, targetName);
	}

}

void SUB_UseTargets()
{
	float effectiveType = useType ? useType : USE_TOGGLE;
	SUB_UseTargetsHL(activator, effectiveType, 0);
}

// Original legacy implementation kept below for reference / fallback only;
// not reachable from the public name. Delete once nothing pokes at it.
void SUB_UseTargets_LegacyImpl()
{
	local entity t;
	local entity stemp;
	local entity otemp;
	local entity act;

	// Delay support
	if (self.delay)
	{
		t = spawn();
		t.classname   = "DelayedUse";
		t.nextthink   = time + self.delay;
		t.think       = DelayThink;

		t.enemy       = activator;
		t.message     = self.message;
		t.killtarget  = self.killtarget;
		t.target      = self.target;
		return;
	}

	// Message to player activator
	if (activator.classname == "player" && self.message != "")
	{
		centerprint(activator, self.message);

		if (!self.noise)
			Sound_Play(activator, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "misc/talk.wav");
	}

	// Kill targets (per spec: do this when we run, not only after firing targets)
	if (self.killtarget)
	{
		t = world;
		while (1)
		{
			t = find(t, targetname, self.killtarget);
			if (!t)
				break;

			GlobalState_MarkEntityDead(t);
			if (t.spent_token) Spent_Mark(t);	// persist killtarget removal
			remove(t);
		}
	}

	// Fire targets
	if (!self.target)
		return;

	act = activator;
	t = world;

	while (1)
	{
		t = find(t, targetname, self.target);
		if (!t) break;

		stemp = self;
		otemp = other;

		if (t.usehl)
		{
			self = t;
			t.usehl(act, stemp, useType, 0);
			self = stemp;
		}
		else if (t.use)
		{
			self  = t;
			other = stemp;
			self.use();
			self  = stemp;
		}

		other     = otemp;
		activator = act;
	}
};
//
// SUB_DelayThinkHL
//
void SUB_DelayThinkHL()
{
	SUB_UseTargetsHL(self.enemy, self.storedUseType, self.storedUseValue);
	remove(self);
}

//
// SUB_UseTargetsHL
//
void SUB_UseTargetsHL(entity pActivator, float useTypeArg, float useValueArg)
{
	// Delay path: stash params on a DelayedUse_HL entity and return.
	if (self.delay)
	{
		entity d = spawn();
		d.classname      = "DelayedUse_HL";
		d.nextthink      = time + self.delay;
		d.think          = SUB_DelayThinkHL;
		d.enemy          = pActivator;
		d.storedUseType  = useTypeArg;
		d.storedUseValue = useValueArg;
		d.message        = self.message;
		d.killtarget     = self.killtarget;
		d.target         = self.target;
		return;
	}

  
	// Killtarget: remove every entity whose targetname matches.
	if (self.killtarget)
	{
		entity k = world;
		while (1)
		{
			k = find(k, targetname, self.killtarget);
			if (!k) break;
			GlobalState_MarkEntityDead(k);
			if (k.spent_token) Spent_Mark(k);	// persist killtarget removal
			remove(k);
		}
	}

	// Fire targets via the shared dispatcher (self is the pCaller).
	if (self.target)
		SUB_FireTargets(self.target, pActivator, self, useTypeArg, useValueArg);
};


void SetMovedir()
{
	if (self.angles == '0 -1 0') self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0') self.movedir = '0 0 -1';
	else
	{
		makevectors(self.angles);
		self.movedir = v_forward;
	}
	self.angles = '0 0 0';
};

// trigger angles are used for one-way touches. An angle of 0 is assumed to mean no restrictions, so use a yaw of 360 instead.
.float trigger_modelindex;              // InitTrigger hides the brush model; kept for Trigger_Contains

void InitTrigger()
{
	if (self.angles != '0 0 0') SetMovedir();
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setmodel(self, self.model);
	self.trigger_modelindex = self.modelindex;
	self.modelindex = 0;
	self.model = "";
};

// The engine fires a trigger's touch anywhere inside its bounding box; HL only
// inside its brushes. One trigger_hurt spanning a whole map (c2a2a's electrified
// pit) otherwise shocks a player riding the train above it.
float Trigger_Contains(entity trig, entity e)
{
	if (!trig.trigger_modelindex) return TRUE;
	float oldSolid = trig.solid;
	trig.modelindex = trig.trigger_modelindex;
	trig.solid = SOLID_BSP;
	setorigin(trig, trig.origin);
	tracebox(e.origin, e.mins, e.maxs, e.origin, TRUE, e);
	float inside = (trace_startsolid && trace_ent == trig);
	trig.modelindex = 0;
	trig.solid = oldSolid;
	setorigin(trig, trig.origin);
	return inside;
}


float IsDeathmatch()
{
	if(deathmatch) return TRUE;
	if(cvar("gamemode") == MODE_DM) return TRUE;
	return FALSE;
}

float IsMultiplayer()
{
	if(deathmatch) return TRUE;
	if(cvar("gamemode") != MODE_SP) return TRUE;
	return FALSE;
}


float ShouldToggle(float currentState)
{
	if (useType != USE_TOGGLE && useType != USE_SET)
	{
		if ((currentState && useType == USE_ON) || (!currentState && useType == USE_OFF))
			return 0;
	}
	return 1;
}

void SetBits(.float variable, float fl)
{
	if(!(self.variable & fl)) self.variable = self.variable | fl;
}

float FBitSet(.float variable, float fl)
{
	if(self.variable & fl) return TRUE;
	return FALSE;
}

float MultiSource_IsTriggered(entity ms, entity ac);
float GameTeamMaster_IsTriggered(entity ms, entity pActivator);
float Master_IsTriggered(string sMaster, entity pActivator)
{
	if (sMaster)
	{
		entity pMaster = find(world, targetname, sMaster);
		if (pMaster)
		{
			// FCAP_MASTER-bearing classnames dispatch by type
			if (pMaster.classname == "game_team_master")
				return GameTeamMaster_IsTriggered(pMaster, pActivator);
			return MultiSource_IsTriggered(pMaster, pActivator);
		}
		dprint("Master was null or not a master!\n");
	}

	return 1;
}


void PrintMessage(entity c, string msg)
{
	
	centerprint(c, msg);
}

void PlayCDTrack(float track_num)
{
	dprint("PlayCDTrack: track="); dprint(ftos(track_num)); dprint("\n");

	WriteByte(MSG_ALL, SVC_CDTRACK);
	WriteByte(MSG_ALL, track_num);
	WriteByte(MSG_ALL, track_num);

	string path = sprintf("play music/track%03d\n", (int)track_num);
	entity p = find(world, classname, "player");
	while (p)
	{
		stuffcmd(p, path);
		p = find(p, classname, "player");
	}
}


void Message_ShowAll(string s)
{
	if (Title_SendAll(s)) return;
	bprint(s);
	bprint("\n");
}

void Message_Show(string s, entity p)
{
	if (Title_Send(s, p)) return;
	sprint(p, s);
	sprint(p, "\n");
}


float PackButtons()
{
	float btn;
	if(self.button0) btn = btn | 1;
	if(self.button1) btn = btn | 2;
	if(self.button2) btn = btn | 4;
	if(self.button3) btn = btn | 8;
	if(self.button4) btn = btn | 16;
	if(self.button5) btn = btn | 32;
	if(self.button6) btn = btn | 64;
	if(self.button7) btn = btn | 128;
	if(self.button8) btn = btn | 256;
	if(self.button9) btn = btn | 512;
	if(self.button10) btn = btn | 1024;
	if(self.button11) btn = btn | 2048;
	if(self.button12) btn = btn | 4096;
	if(self.button13) btn = btn | 8192;
	if(self.button14) btn = btn | 16384;
	if(self.button15) btn = btn | 32768;
	if(self.use) btn = btn | 65536;
	return btn;
}


void DrawLine(vector src, vector dest, string beam_mdl = "models/laserbeam.md3", float seg_len = 32, float seg_scale = 1, float lifetime = 0.15)
{
	vector dir = dest - src;
	float dist = vlen(dir);
	if (dist <= 0) return;
	dir = normalize(dir);

	float count = max(1, ceil(dist / seg_len));
	float step  = dist / count;

	for (float i = 0; i < count; i++)
	{
		entity seg = spawn();
		seg.origin   = src + dir * (step * (i + 0.5));
		seg.angles   = vectoangles(dir);
		seg.solid    = SOLID_NOT;
		seg.movetype = MOVETYPE_NONE;
		seg.effects  = EF_NOSHADOW;
		setmodel(seg, beam_mdl);
		setorigin(seg, src + dir * (step * (i + 0.5)));
		seg.scale    = (step / seg_len) * seg_scale;
		seg.think    = SUB_Remove;
		seg.nextthink = time + lifetime;
	}
}

// For CLASSIFY
#define	CLASS_NONE				0
#define CLASS_MACHINE			1
#define CLASS_PLAYER			2
#define	CLASS_HUMAN_PASSIVE		3
#define CLASS_HUMAN_MILITARY	4
#define CLASS_ALIEN_MILITARY	5
#define CLASS_ALIEN_PASSIVE		6
#define CLASS_ALIEN_MONSTER		7
#define CLASS_ALIEN_PREY		8
#define CLASS_ALIEN_PREDATOR	9
#define CLASS_INSECT			10
#define CLASS_PLAYER_ALLY		11
#define CLASS_PLAYER_BIOWEAPON	12
#define CLASS_ALIEN_BIOWEAPON	13
#define	CLASS_BARNACLE			99

#define CLASS_VEHICLE			14
float Classify(entity e)
{
	if(e.flags & FL_CLIENT) return CLASS_PLAYER;
	if(e.flags & FL_MONSTER) return CLASS_ALIEN_MONSTER;
	return CLASS_NONE;
}


float RemoveInDeathmatch()
{
	if (cvar("gamemode") == MODE_DM)
	{
		remove(self);
		return TRUE;
	}
	return FALSE;
}


entity Entity_Create(void() func, vector org, vector ang, entity creator = __NULL__)
{
	entity e = spawn();
	e.owner = creator;
	entity oldself = self;
	self = e;
	func();
	self = oldself;
	setorigin(e, org);
	e.angles = ang;
	return e;
}

// Mover-blocked debris disposal.
void Gib();   // gib.qc (compiled after this file)

// Copies a findradius result into .dmg_chain before any of it takes damage.
// A player death rebuilds .chain for every client (the scoreboard walks them
// with findchainflags), so a loop that damages while stepping .chain goes on to
// walk every client on the map. Saving the next link first is not enough: that
// entity's own link was rewritten too. Walk .dmg_chain instead.
.entity dmg_chain;
entity Chain_Freeze(entity head)
{
	for (entity e = head; e; e = e.chain) e.dmg_chain = e.chain;
	return head;
}

// The engine tests a box against a pitched or rolled SOLID_BSP with the
// feet-to-center hull offset applied in the mover's local frame, so a mover
// tipping over reports blockers it never touches (hldemo1 falling cabinets
// crushed the zombies pushing them). Point traces carry no offset and are exact.
.entity blocked_savedOwner;

float Blocked_OverlapsPusher(entity pusher, entity blocker)
{
	vector lo = blocker.absmin + '1 1 1';
	vector span = (blocker.absmax - '1 1 1') - lo;
	float nx = ceil(span_x / 8), ny = ceil(span_y / 8), nz = ceil(span_z / 8);
	if (nx < 1) nx = 1;
	if (ny < 1) ny = 1;
	if (nz < 1) nz = 1;

	for (float i = 0; i <= nx; i++)
		for (float j = 0; j <= ny; j++)
			for (float k = 0; k <= nz; k++)
			{
				vector p = lo + [span_x * i / nx, span_y * j / ny, span_z * k / nz];
				tracebox(p, '0 0 0', '0 0 0', p, TRUE, blocker);
				if (trace_startsolid && trace_ent == pusher)
					return TRUE;
			}
	return FALSE;
}

void Blocked_RestoreOwnerThink()
{
	entity b = self.enemy;
	entity pusher = self.goalentity;
	float moving = (pusher.avelocity != '0 0 0' || pusher.velocity != '0 0 0');
	if (moving && time < self.attack_finished && !wasfreed(b))
	{
		self.nextthink = time + 0.05;
		return;
	}
	if (!wasfreed(b) && b.owner == pusher)
		b.owner = b.blocked_savedOwner;
	remove(self);
}

// Call first in a pusher's blocked(). TRUE: the block was phantom and the
// engine now lets the pusher through `blocker` for a moment.
float Blocked_IgnorePhantom(entity blocker)
{
	if (!blocker || blocker == world || blocker.solid == SOLID_BSP) return FALSE;
	if (!self.angles_x && !self.angles_z && !self.avelocity_x && !self.avelocity_z)
		return FALSE;                       // yaw-only: the offset is rotation-invariant

	vector restOrigin = self.origin;
	vector restAngles = self.angles;
	self.angles = restAngles + self.avelocity * frametime;   // the pose the engine refused
	setorigin(self, restOrigin + self.velocity * frametime);
	float real = Blocked_OverlapsPusher(self, blocker);
	self.angles = restAngles;
	setorigin(self, restOrigin);
	if (real) return FALSE;

	blocker.blocked_savedOwner = blocker.owner;
	blocker.owner = self;                   // the push skips entities owned by the pusher

	entity r = spawn();
	r.classname = "blocked_restore";
	r.enemy = blocker;
	r.goalentity = self;
	r.attack_finished = time + 0.25;        // re-validated on the next block
	r.think = Blocked_RestoreOwnerThink;
	r.nextthink = time + 0.05;
	return TRUE;
}

float Blocked_DisposeDebris(entity blocker)
{
	if (!blocker || blocker == world) return FALSE;

	// Loose debris shards (func_breakable, env_shooter).
	if (blocker.classname == "gib" || blocker.classname == "breakable_gib")
	{
		remove(blocker);
		return TRUE;
	}

	// Dead body: crush-gib it. Gib_HideVictim leaves the victim SOLID_NOT
	if (blocker.deadflag != DEAD_NO || blocker.solid == SOLID_CORPSE)
	{
		entity s = self;
		self = blocker;
		Gib();
		self = s;
		return TRUE;
	}
	return FALSE;
}
