void TriggerMonsterjump_Touch()
{
	if (other.flags & (FL_MONSTER | FL_FLY | FL_SWIM) != FL_MONSTER)
		return;

	other.velocity_x = self.movedir_x * self.speed;
	other.velocity_y = self.movedir_y * self.speed;

	if (!(other.flags & FL_ONGROUND))
		return;

	other.flags = other.flags - FL_ONGROUND;
	other.velocity_z = self.height;
}

void trigger_monsterjump()
{
	if (!self.speed) self.speed = 200;
	if (!self.height) self.height = 200;
	if (self.angles == '0 0 0') self.angles = '0 360 0';
	InitTrigger();
	self.touch = TriggerMonsterjump_Touch;
}
