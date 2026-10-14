//   monstertype          classname of monster to spawn (e.g. "monster_headcrab")
//   monstercount         total monsters to make (-1 = unlimited).
// Uses this name, not the stock 'count' field.
// m_imaxlivechildren cap on simultaneously alive children (-1 = no cap)
// delay seconds between auto spawns while active
// If set, children get it as their targetname
// Spawnflags:
//   1 = StartOn      (targetnamed maker begins spawning at map start)
//   4 = Cyclic       (each USE drops exactly one monster; 2 kept as legacy alias)
//   8 = MonsterClip  (children get SF_MONSTER_HITMONSTERCLIP)

#define SF_MONSTERMAKER_STARTON		1
#define SF_MONSTERMAKER_CYCLIC		2	// legacy repo value
#define SF_MONSTERMAKER_CYCLIC_HL	4
#define SF_MONSTERMAKER_MONSTERCLIP	8	// children get SF_MONSTER_HITMONSTERCLIP

.string monstertype;
.float  mm_active;	// toggle-mode spawn loop running
.float  mm_ground;

void Headcrab_Precache();
void Zombie_Precache();
void Barnacle_Precache();
void Houndeye_Precache();
void ISlave_Precache();
void BSquid_Precache();
void Cockroach_Precache();
void HGrunt_Precache();
void HAssn_Precache();
void Barney_Precache();
void Scientist_Precache();
void Garg_Precache();
void Con_Precache();
void Icky_Precache();
void SNARK_Precache();

void MonsterMaker_PrecacheChild(string mtype)
{
	if      (mtype == "monster_headcrab")    Headcrab_Precache();
	else if (mtype == "monster_zombie")      Zombie_Precache();
	else if (mtype == "monster_barnacle")    Barnacle_Precache();
	else if (mtype == "monster_houndeye")    Houndeye_Precache();
	else if (mtype == "monster_alien_slave") ISlave_Precache();
	else if (mtype == "monster_bullchicken") BSquid_Precache();
	else if (mtype == "monster_cockroach")   Cockroach_Precache();
	else if (mtype == "monster_human_grunt")    HGrunt_Precache();
	else if (mtype == "monster_human_assassin") HAssn_Precache();
	else if (mtype == "monster_barney")         Barney_Precache();
	else if (mtype == "monster_scientist")      Scientist_Precache();
	else if (mtype == "monster_gargantua")      Garg_Precache();
	else if (mtype == "monster_alien_controller") Con_Precache();
	else if (mtype == "monster_ichthyosaur")    Icky_Precache();
	else if (mtype == "monster_snark")          SNARK_Precache();
}

float MonsterMaker_SpawnBlocked()
{
	if (!self.mm_ground)
	{
		traceline(self.origin, self.origin - '0 0 2048', TRUE, self);
		self.mm_ground = trace_endpos_z;
	}

	vector bmins = self.origin - '34 34 0';
	vector bmaxs = self.origin + '34 34 0';
	bmins_z = self.mm_ground;
	bmaxs_z = self.origin_z;

	entity e = nextent(world);
	while (e)
	{
		if (e.flags & (FL_CLIENT | FL_MONSTER))
		{
			if (!(e.absmin_x > bmaxs_x || e.absmax_x < bmins_x
			   || e.absmin_y > bmaxs_y || e.absmax_y < bmins_y
			   || e.absmin_z > bmaxs_z || e.absmax_z < bmins_z))
				return TRUE;
		}
		e = nextent(e);
	}
	return FALSE;
}

void MonsterMaker_MakeMonster()
{
	if (!self.monstertype) return;

	// Don't spawn if too many of mine are already out.
	if (self.m_imaxlivechildren > 0
	    && self.monster_liveChildren >= self.m_imaxlivechildren)
		return;

	if (MonsterMaker_SpawnBlocked())
		return;

	entity maker = self;
	entity e = spawn();
	setorigin(e, self.origin);
	e.angles    = self.angles;
	e.classname = self.monstertype;
	e.owner      = maker;   // so monster-death can decrement maker.monster_liveChildren
	e.spawnflags = e.spawnflags | SF_MONSTER_FALL_TO_GROUND;	// keep maker origin
	if (maker.spawnflags & SF_MONSTERMAKER_MONSTERCLIP)
		e.spawnflags = e.spawnflags | SF_MONSTER_HITMONSTERCLIP;

	e.targetname = maker.netname;

	// Spawn by name, the same lookup the engine does for a BSP classname.
	string spawnFn = maker.monstertype;
	if (!isfunction(spawnFn))
	{
		print("monstermaker: no spawn function for monstertype '", spawnFn, "'\n");
		remove(e);
		return;
	}
	self = e;
	callfunction(spawnFn);
	self = maker;
	if (wasfreed(e)) return;    // spawn function declined (deathmatch-only, spent)

	if (self.target != "")
		SUB_FireTargets(self.target, self, self, USE_TOGGLE, 0);

	self.monster_numMonsters++;
	self.monster_liveChildren++;

	// Count exhausted: disable forever, but keep the edict for death notices
	if (self.monstercount > 0 && self.monster_numMonsters >= self.monstercount)
	{
		self.mm_active = FALSE;
		self.use   = SUB_Null;
		self.usehl = __NULL__;
		self.nextthink = -1;
	}
}

// Always re-arm on delay while active, spawn one per tick.
void MonsterMaker_Think()
{
	if (!self.mm_active) return;
	self.nextthink = time + self.delay;
	MonsterMaker_MakeMonster();
}

void MonsterMaker_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.spawnflags & (SF_MONSTERMAKER_CYCLIC | SF_MONSTERMAKER_CYCLIC_HL))
	{
		// CyclicUse: exactly one monster per fire, no loop.
		MonsterMaker_MakeMonster();
		return;
	}

	// ToggleUse: flip the delay-driven spawn loop (honor explicit ON/OFF).
	if (useTypeArg == USE_ON  && self.mm_active)  return;
	if (useTypeArg == USE_OFF && !self.mm_active) return;

	if (self.mm_active)
	{
		self.mm_active = FALSE;
		self.nextthink = -1;
	}
	else
	{
		self.mm_active = TRUE;
		self.think = MonsterMaker_Think;
		self.nextthink = time;
	}
}

void MonsterMaker_Use()
{
	MonsterMaker_UseHL(activator, world, USE_TOGGLE, 0);
}

void monstermaker()
{
	MonsterMaker_PrecacheChild(self.monstertype);

	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.use      = MonsterMaker_Use;
	self.usehl    = MonsterMaker_UseHL;
	self.think    = MonsterMaker_Think;

	// Uses 'monstercount' keyvalue, NOT the stock 'count' field.
	if (!self.monstercount) self.monstercount = -1;	// unlimited by default
	self.monster_numMonsters  = 0;
	self.monster_liveChildren = 0;
	self.mm_ground       = 0;

	if (self.targetname != "")
	{
		if (self.spawnflags & SF_MONSTERMAKER_STARTON)
		{
			self.mm_active = TRUE;
			self.nextthink = time + self.delay;
		}
		else
			self.mm_active = FALSE;
	}
	else
	{
		self.mm_active = TRUE;
		self.nextthink = time + self.delay;
	}
}
