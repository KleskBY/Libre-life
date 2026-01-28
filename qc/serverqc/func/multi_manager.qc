
#define MAX_MULTI_TARGETS  		16
#define SF_MULTIMAN_CLONE		0x80000000
#define SF_MULTIMAN_THREAD		0x00000001


void() MultiManager_ManagerUse;
.string targets[MAX_MULTI_TARGETS];
.float delays[MAX_MULTI_TARGETS];

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

entity(entity src) MultiManager_Clone =
{
    entity c = spawn();
    c.classname = "multi_manager";
    c.solid = SOLID_NOT;


    // Copy data
    c.spawnflags = src.spawnflags | SF_MULTIMAN_CLONE;
    c.wait = src.wait;

    c.count = src.count;
	for(float i = 0; i < MAX_MULTI_TARGETS; i = i + 1)
	{
		c.targets[i] = src.targets[i];
		c.delays[i] = src.delays[i];
	}
	
	// Copy basic routing
    c.use = src.use;
    c.think = src.use;
	c.nextthink = time + 0.1;

    return c;
};

void MultiManager_ManagerThink()
{
	if(self.timer < time)
	{
		if(MultiManager_IsClone())
		{
			remove(self);
			return;
		}
		else self.use = MultiManager_ManagerUse;
	}
	else self.nextthink = time + 0.1;
};

void MultiManager_ManagerUse()
{
	if(MultiManager_ShouldClone())
	{
		MultiManager_Clone(self);
		return;
	}
	self.use = SUB_Null; // disable re-use until done
	self.think = MultiManager_ManagerThink;
	self.nextthink = time;
	self.timer = 0;
	for(float i = 0; i < MAX_MULTI_TARGETS; i++)
	{
		if(self.targets[i])
		{
			self.target = self.targets[i];
			self.delay = self.delays[i];
			if(self.delay > self.timer) self.timer = self.delay;
			SUB_UseTargets();
		}
	}

};

void MultiManager_PushBackTarget(string targ, float dl)
{
	for(float i = 0; i < MAX_MULTI_TARGETS; i++)
	{
		if(!self.targets[i] || strlen(self.targets[i]) < 3)
		{
			// break;
			self.delays[i] = dl;
			self.targets[i] = strzone(targ);
			self.count = self.count + 1;
			return;
		}
	}
};

void multi_manager()
{
    self.solid = SOLID_NOT;
    self.use = MultiManager_ManagerUse;
    self.think = MultiManager_ManagerThink;
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
		else if(StringContains(key, "*")) continue;
		self.target = key;
		MultiManager_PushBackTarget(key, dl);
		// print(etos(self), " >", key, " = ", argv(i+1), "\n");
	}
	
	
};
