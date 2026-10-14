
void env_glow()
{
	self.solid			= SOLID_NOT;
	self.movetype		= MOVETYPE_NONE;
	self.effects		= EF_ADDITIVE;
	self.frame			= 0;

	precache_model(self.model);
	setmodel(self, self.model);

	self.maxFrame = MODEL_FRAMES(self.modelindex) - 1;
	if (self.maxFrame > 1.0 && self.framerate != 0)
		self.nextthink	= time + 0.1;

	self.lastTime = time;
}

void Glow_Animate(float frames)
{ 
	if (self.maxFrame > 0)
		self.frame = mod(self.frame + frames, self.maxFrame);
}

void Glow_Think()
{
	Glow_Animate(self.framerate * (time - self.lastTime));
	self.nextthink		= time + 0.1;
	self.lastTime		= time;
}

