
#define	SF_TRIGGER_ALLOWMONSTERS	1// monsters allowed to fire this trigger
#define	SF_TRIGGER_NOCLIENTS		2// players not allowed to fire this trigger
#define SF_TRIGGER_PUSHABLES		4// only pushables can fire this trigger


void Trigger_ToggleUse()
{
	if (self.solid == SOLID_NOT) // if the trigger is off, turn it on
	{
		self.solid = SOLID_TRIGGER;
		force_retouch++; // force_retouch = 2; // Force retouch
	}
	else
	{
		self.solid = SOLID_NOT;
	}
	setorigin(self, self.origin);
}


void Trigger_MultiWaitOver()
{
	self.think = SUB_Null;
}

void Trigger_ActivateMultiTrigger(entity pActivator)
{
	if(self.nextthink > time) return; // still waiting for reset time
	if (!UTIL_IsMasterTriggered(self.master, pActivator))
		return;
	if(self.classname == "trigger_secret")	
	{
		if(!self.enemy || self.enemy.classname != "player")
			return;
		found_secrets = found_secrets + 1;
	}
	if(self.noise)
		sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	
	self.enemy = pActivator;
	SUB_UseTargets();
	
	if(self.message && pActivator.classname == "player")
		centerprint(pActivator, self.message);
		
	if(self.wait > 0)
	{
		self.think = Trigger_MultiWaitOver;
		self.nextthink = time + self.wait;
	}
	else
	{
		self.touch = SUB_Null;
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
	}
}

void Trigger_MultipleTouch()
{
	if 	( 
		((other.flags & FL_CLIENT) && !(self.spawnflags & SF_TRIGGER_NOCLIENTS)) ||
		((other.flags & FL_MONSTER) && (self.spawnflags & SF_TRIGGER_ALLOWMONSTERS)) ||
		((self.spawnflags & SF_TRIGGER_PUSHABLES) && other.classname == "func_pushable")
		)
	{
		Trigger_ActivateMultiTrigger(other);
	}
}


void trigger_multiple()
{
	if (!self.wait) self.wait = 0.2;
	InitTrigger();
	ASSERT(self.health == 0, "trigger_multiple with health");
	self.touch = Trigger_MultipleTouch;
};