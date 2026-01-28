#define SF_MULTI_INIT	1
#define MS_MAX_TARGETS 	32

.entity m_rgEntities[MS_MAX_TARGETS];
.float m_rgTriggered[MS_MAX_TARGETS];

// void MultiSource_PushBackTarget()
// {
	// ms_target[self.count]
// }

float MultiSource_IsTriggered(entity ms, entity ac)
{
	// Is everything triggered?
	float i = 0;

	// Still initializing?
	if (ms.spawnflags & SF_MULTI_INIT )
		return FALSE;

	while (i < ms.count)
	{
		if (ms.m_rgTriggered[i] == 0)
			break;
		i++;
	}

	if (i == ms.count)
	{
		// if (!m_globalstate || gGlobalState.EntityGetState( m_globalstate ) == GLOBAL_ON )
			return 1;
	}
	
	return 0;
}


void MultiSource_Register()
{
	self.count = 0;
	self.think = SUB_Null;

	// search for all entities which target this multisource (pev->targetname)
	entity t = find(world, target, self.targetname);
	while(t && self.count < MS_MAX_TARGETS)
	{
		self.m_rgEntities[self.count++] = t;
		t = find(t, target, self.targetname);
	}
	
	t = find(world, classname, "multi_manager");
	while (t && self.count < MS_MAX_TARGETS)
	{
		if (MultiManager_HasTarget(t, self.targetname))
			self.m_rgEntities[self.count++] = t;

		t = find(t, classname, "multi_manager");
	}

	if(self.spawnflags & SF_MULTI_INIT) self.spawnflags = self.spawnflags - SF_MULTI_INIT;
}

void MultiSource_Use()
{
	float i = 0;

	// Find the entity in our list
	while (i < self.count)
		if (self.m_rgEntities[i++] == activator)
			break;

	// if we didn't find it, report error and leave
	if (i > self.count)
	{
		//dprint("MultiSrc:Used by non member ", activator.classname, "\n");
		// ALERT(at_console, "MultiSrc:Used by non member %s.\n", STRING(pCaller->pev->classname));
		return;	
	}

	// CONSIDER: a Use input to the multisource always toggles.  Could check useType for ON/OFF/TOGGLE

	self.m_rgTriggered[i-1] ^= 1;

	// 
	if (MultiSource_IsTriggered(self, activator))
	{
		// ALERT( at_aiconsole, "Multisource %s enabled (%d inputs)\n", STRING(pev->targetname), m_iTotal );
		// USE_TYPE useType = USE_TOGGLE;
		// if ( m_globalstate )
			// useType = USE_ON;
		// SUB_UseTargets( NULL, useType, 0 );
		SUB_UseTargets();
	}
}

void multisource()
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.spawnflags = self.spawnflags | SF_MULTI_INIT;
    self.think = MultiSource_Register;
    self.nextthink = time + 0.1;
    self.use = MultiSource_Use;
}
