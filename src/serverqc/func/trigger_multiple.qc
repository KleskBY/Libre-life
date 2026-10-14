
#define	SF_TRIGGER_ALLOWMONSTERS	1
#define	SF_TRIGGER_NOCLIENTS		2
#define SF_TRIGGER_PUSHABLES		4


void Trigger_ToggleUse()
{
	if (self.solid == SOLID_NOT)
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
	if(self.nextthink > time) return;
	if (!Master_IsTriggered(self.master, pActivator))
		return;
	if(self.classname == "trigger_secret")
	{
		if(pActivator.classname != "player")
			return;
		found_secrets = found_secrets + 1;
	}
	if(self.noise)
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
	
	self.enemy = pActivator;
	activator = pActivator;
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
		Spent_Mark(self);
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


void Trigger_MultipleUse()
{
	Trigger_ActivateMultiTrigger(activator);
}

// Fired when a health-based trigger_multiple is shot to 0 hp.
// self.enemy = attacker (set by T_Damage before th_die is called).
void Trigger_MultiKilled()
{
	self.takedamage = DAMAGE_NO;
	Trigger_ActivateMultiTrigger(self.enemy);
	// If wait > 0 the trigger resets, restoring health and takedamage so it can be shot again
	if (self.wait > 0)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
	}
}

void trigger_multiple()
{
	Spent_Capture(self);
	if (self.wait < 0 && Spent_IsSpent(self)) { remove(self); return; }

	if (!self.wait) self.wait = 0.2;
	InitTrigger();
	self.touch = Trigger_MultipleTouch;
	self.use = Trigger_MultipleUse;
	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = Trigger_MultiKilled;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin(self, self.origin);	// relink so bbox is solid to shots
	}
};
