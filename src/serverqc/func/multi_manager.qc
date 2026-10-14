
#define MAX_MULTI_TARGETS  		16
#define SF_MULTIMAN_CLONE		0x80000000
#define SF_MULTIMAN_THREAD		0x00000001


void() MultiManager_Use;
void MultiManager_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg);
.string targets[MAX_MULTI_TARGETS];
.float delays[MAX_MULTI_TARGETS];   // sorted ascending at spawn
.float multi_index;                 // next target to fire
.float multi_startTime;             // time of the Use that started this run

float(entity e, string targetname) MultiManager_HasTarget =
{
	for(float i = 0; i < MAX_MULTI_TARGETS; i++)
	{
		if(e.targets[i] == targetname) return TRUE;
	}
    return FALSE;
};

float MultiManager_IsClone()
{
    return (self.spawnflags & SF_MULTIMAN_CLONE) != 0;
}

float MultiManager_ShouldClone()
{
    if (MultiManager_IsClone())
        return FALSE;
    return (self.spawnflags & SF_MULTIMAN_THREAD) != 0;
}

entity MultiManager_Clone()
{
    entity c = spawn();
    c.classname  = "multi_manager";
    c.solid      = SOLID_NOT;
    c.spawnflags = self.spawnflags | SF_MULTIMAN_CLONE;
    c.count      = self.count;
	for (float i = 0; i < MAX_MULTI_TARGETS; i = i + 1)
	{
		c.targets[i] = self.targets[i];
		c.delays[i]  = self.delays[i];
	}
    return c;
}

// Every target fires as USE_TOGGLE, whatever use type started the manager:
// a USE_OFF relay into a multi_manager must still start a monstermaker.
void MultiManager_Think()
{
	if (!self.multi_startTime)  // saved by the old implementation mid-run: just re-arm
	{
		self.use   = MultiManager_Use;
		self.usehl = MultiManager_UseHL;
		return;
	}

	entity me = self;
	float elapsed = time - me.multi_startTime;
	while (me.multi_index < me.count)
	{
		float i = me.multi_index;
		if (me.delays[i] > elapsed)
			break;
		me.multi_index = i + 1;
		SUB_FireTargets(me.targets[i], me.enemy, me, USE_TOGGLE, 0);
		if (wasfreed(me))
			return;     // a target killtargeted this manager
	}

	if (me.multi_index >= me.count)
	{
		me.think = SUB_Null;
		if (MultiManager_IsClone())
		{
			remove(me);
			return;
		}
		me.use   = MultiManager_Use;
		me.usehl = MultiManager_UseHL;
		return;
	}

	float next = me.multi_index;
	me.nextthink = me.multi_startTime + me.delays[next];
}

void MultiManager_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (MultiManager_ShouldClone())
	{
		entity c = MultiManager_Clone();
		entity s = self;
		self = c;
		MultiManager_UseHL(pActivator, pCaller, useTypeArg, useValueArg);
		self = s;
		return;
	}

	self.enemy           = pActivator;
	self.multi_index     = 0;
	self.multi_startTime = time;

	self.use   = SUB_Null;  // disabled until every target has fired
	self.usehl = __NULL__;

	self.think     = MultiManager_Think;
	self.nextthink = time;
}

void MultiManager_Use()
{
	MultiManager_UseHL(activator, world, useType, 0);
}

void MultiManager_PushBackTarget(string targ, float dl)
{
	for(float i = 0; i < MAX_MULTI_TARGETS; i++)
	{
		if(!self.targets[i])
		{
			self.delays[i] = dl;
			self.targets[i] = strzone(targ);
			self.count = self.count + 1;
			return;
		}
	}
};

// Stable bubble sort by delay, so equal delays keep their map key order.
void MultiManager_SortTargets()
{
	float swapped = TRUE;
	while (swapped)
	{
		swapped = FALSE;
		for (float i = 1; i < self.count; i = i + 1)
		{
			float j = i - 1;
			if (self.delays[i] < self.delays[j])
			{
				string tn = self.targets[i];
				float  td = self.delays[i];
				self.targets[i] = self.targets[j];
				self.delays[i]  = self.delays[j];
				self.targets[j] = tn;
				self.delays[j]  = td;
				swapped = TRUE;
			}
		}
	}
}

void multi_manager()
{
    self.solid = SOLID_NOT;
    self.use = MultiManager_Use;
    self.usehl = MultiManager_UseHL;
    self.think = MultiManager_Think;
    self.nextthink = -1;

	string key;
	float dl;
	for (float i = 1; i < (tokenize(__fullspawndata) - 1); i += 2)
	{
		key = argv(i);
		dl =  stof(argv(i + 1));
		if(key == "targetname") continue;
		else if(key == "origin") continue;
		else if(key == "classname") continue;
		else if(key == "model") continue;
		else if(key == "wait") continue;
		else if(StringContains(key, "*")) continue;

		float hashIdx = strstrofs(key, "#", 0);
		if (hashIdx >= 0)
			key = substring(key, 0, hashIdx);

		MultiManager_PushBackTarget(key, dl);
	}

	MultiManager_SortTargets();
};
