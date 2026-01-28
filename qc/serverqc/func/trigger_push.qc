
float PUSH_ONCE = 1;
#define	SF_TRIG_PUSH_ONCE			1
#define	SF_TRIGGER_PUSH_START_OFF	2 //spawnflag that makes trigger_push spawn turned OFF


void Trigger_PushTouch()
{
	if(other.movetype == MOVETYPE_NONE || other.movetype == MOVETYPE_PUSH ||
	other.movetype == MOVETYPE_NOCLIP || other.movetype == MOVETYPE_FOLLOW)
		return;
	
	if(other.solid == SOLID_NOT || other.solid == SOLID_BSP) 
		return;
	
	other.velocity = other.velocity + (self.speed * self.movedir);
	if(other.velocity_z > 0)
		if (self.flags & FL_ONGROUND) self.flags = self.flags - FL_ONGROUND;
	if(self.spawnflags & SF_TRIG_PUSH_ONCE)
		remove(self);
};

void trigger_push()
{
	if(self.angles == '0 0 0') self.angles_y = 360;
	InitTrigger();
	if (!self.speed) self.speed = 100;
	if(self.spawnflags & SF_TRIGGER_PUSH_START_OFF) // if flagged to Start Turned Off, make trigger nonsolid.
		self.solid = SOLID_NOT;
	self.use = Trigger_ToggleUse;
	self.touch = Trigger_PushTouch;
	setorigin(self, self.origin); // Link into the list
		
		
	// precache_sound("ambience/windfly.wav");
	// self.touch = trigger_push_touch;
	// if (!self.speed) self.speed = 1000;
};