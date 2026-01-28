

void Trigger_TeleportTouch()
{
	// Only teleport monsters or clients
	if (!(other.flags & FL_CLIENT | FL_MONSTER ))
		return;
    
	if (!UTIL_IsMasterTriggered(self.master, other))
		return;
 	
	// no monsters allowed!
	if (!(self.spawnflags & SF_TRIGGER_ALLOWMONSTERS ))
	{
		if (other.flags & FL_MONSTER)
		{
			return;
		}
	}

	// no clients allowed
	if (self.spawnflags & SF_TRIGGER_NOCLIENTS)
	{
		if (other.classname == "player")
		{
			return;
		}
	}
	
	entity pentTarget = find(world, targetname, self.target);
	if (!pentTarget)
	   return;	
	
	vector tmp = pentTarget.origin;

	if (other.classname == "player")
	{
		tmp_z -= other.mins_z;// make origin adjustments in case the teleportee is a player. (origin in center, not at feet)
	}

	tmp_z++;
	if (self.flags & FL_ONGROUND) self.flags = self.flags - FL_ONGROUND;
	setorigin(other, tmp);

	other.angles = pentTarget.angles;

	if (other.classname == "player")
	{
		other.v_angle = pentTarget.angles;
	}

	other.fixangle = TRUE;
	other.velocity = '0 0 0';
}


void trigger_teleport()
{
	InitTrigger();
	self.touch = Trigger_TeleportTouch;
};