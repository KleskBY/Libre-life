
float PUSH_ONCE = 1;
#define	SF_TRIGGER_PUSH_ONCE			1
#define	SF_TRIGGER_PUSH_START_OFF	2


void Trigger_PushTouch()
{
	if(other.movetype == MOVETYPE_NONE || other.movetype == MOVETYPE_PUSH ||
	other.movetype == MOVETYPE_NOCLIP || other.movetype == MOVETYPE_FOLLOW)
		return;

	if(other.solid == SOLID_NOT || other.solid == SOLID_BSP)
		return;

	if (self.spawnflags & SF_TRIGGER_PUSH_ONCE)
	{
		other.velocity = other.velocity + (self.speed * self.movedir);
		if (other.velocity_z > 0 && (other.flags & FL_ONGROUND))
			other.flags = other.flags - FL_ONGROUND;
		remove(self);
		return;
	}

	if (self.movedir_z)
		other.velocity_z = other.velocity_z + self.movedir_z * self.speed * frametime;

	vector hdir = self.movedir;
	hdir_z = 0;
	if (hdir != '0 0 0')
	{
		float hspeed = self.speed * vlen(hdir);
		hdir = normalize(hdir);
		float along = other.velocity * hdir;
		if (along < hspeed)
		{
			float add = hspeed * frametime * 4;
			if (add > hspeed - along) add = hspeed - along;
			other.velocity = other.velocity + hdir * add;
		}
	}
};

void Trigger_PushToggleUseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	Trigger_ToggleUse();
}

void trigger_push()
{
	if(self.angles == '0 0 0') self.angles_y = 360;
	InitTrigger();
	if (!self.speed) self.speed = 100;
	self.speed = self.speed * 0.25;
	if(self.spawnflags & SF_TRIGGER_PUSH_START_OFF)
		self.solid = SOLID_NOT;
	self.use = Trigger_ToggleUse;
	self.usehl = Trigger_PushToggleUseHL;
	self.touch = Trigger_PushTouch;
	setorigin(self, self.origin);	// Initialize self in the list
		
		
};