#define SF_MULTIMAN_INIT	1
#define MS_MAX_TARGETS 	32

.entity multisource_entities[MS_MAX_TARGETS];
.float multisource_triggered[MS_MAX_TARGETS];


float MultiSource_IsTriggered(entity ms, entity ac)
{
	float i = 0;

	// Still initializing?
	if (ms.spawnflags & SF_MULTIMAN_INIT )
		return FALSE;

	while (i < ms.count)
	{
		if (ms.multisource_triggered[i] == 0)
			break;
		i++;
	}

	if (i == ms.count)
	{
		if (!ms.globalstate || ms.globalstate == ""
			|| GlobalState_Get(ms.globalstate) == GLOBAL_ON)
			return 1;
	}

	return 0;
}


void MultiSource_Register()
{
	self.count = 0;
	self.think = SUB_Null;

	entity t = find(world, target, self.targetname);
	while(t && self.count < MS_MAX_TARGETS)
	{
		self.multisource_entities[self.count++] = t;
		t = find(t, target, self.targetname);
	}
	
	t = find(world, classname, "multi_manager");
	while (t && self.count < MS_MAX_TARGETS)
	{
		if (MultiManager_HasTarget(t, self.targetname))
			self.multisource_entities[self.count++] = t;

		t = find(t, classname, "multi_manager");
	}

	if(self.spawnflags & SF_MULTIMAN_INIT) self.spawnflags = self.spawnflags - SF_MULTIMAN_INIT;
}

void MultiSource_Use()
{
	float i = 0;

	while (i < self.count)
		if (self.multisource_entities[i++] == activator)
			break;

	if (i > self.count)
	{
		dprint("MultiSrc:Used by non member ");
		dprint(activator.classname);
		dprint("\n");
		return;
	}

	if(i > 0) self.multisource_triggered[i-1] = !self.multisource_triggered[i-1]; // self.multisource_triggered[i-1] ^= 1;
	if (MultiSource_IsTriggered(self, activator))
	{
		float ut = self.globalstate ? USE_ON : USE_TOGGLE;
		SUB_UseTargetsHL(world, ut, 0);
	}
}

void MultiSource_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	float i = 0;

	while (i < self.count)
		if (self.multisource_entities[i++] == pCaller)
			break;

	if (i > self.count)
	{
		dprint("MultiSrc:Used by non member ");
		dprint(pCaller.classname);
		dprint("\n");
		return;
	}

	if (i > 0) self.multisource_triggered[i-1] = !self.multisource_triggered[i-1];

	if (MultiSource_IsTriggered(self, pCaller))
	{
		// USE_ON when a globalstate is named, USE_TOGGLE otherwise
		float ut = self.globalstate ? USE_ON : USE_TOGGLE;
		SUB_UseTargetsHL(pActivator, ut, 0);
	}
}

void multisource()
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.spawnflags = self.spawnflags | SF_MULTIMAN_INIT;
    self.think = MultiSource_Register;
    self.nextthink = time + 0.1;
    self.use = MultiSource_Use;
    self.usehl = MultiSource_UseHL;
}
