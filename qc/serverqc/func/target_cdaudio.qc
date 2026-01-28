
// This plays a CD track when fired or when the player enters it's radius

void TargetCDAudio_Use()
{
	PlayCDTrack(self.health);
	remove(self);
}

void TargetCDAudio_Think()
{	
	entity pClient = find(world, classname, "player");
	if (!pClient) return;
	self.nextthink = time + 0.5;
	if (vlen(pClient.origin - self.origin) <= self.radius)
		TargetCDAudio_Use();
}

void target_cdaudio()
{
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.think = TargetCDAudio_Think;
	self.use = TargetCDAudio_Use;
	if(self.radius > 0) self.nextthink = time + 1;
}