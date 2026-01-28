
float JUMP_AUTO = 0;
float JUMP_COOLDOWN = 0.05;
void Player_Jump()
{	
	if(!self.button2) 
	{
		self.flags = self.flags | FL_JUMPRELEASED;
		return;
	}
	if (self.flags & FL_WATERJUMP) return;
	if(self.lastTouch + JUMP_COOLDOWN > time) return;
	if(clienttype(self) == CLIENTTYPE_BOT && self.lastTouch + 1 > time) return;
	
	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER) self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME) self.velocity_z = 80;
		else self.velocity_z = 50;

		if (self.swim_flag < time) // play swiming sound
		{
			self.swim_flag = time + 1;
			//TODO: play swiming sound here
		}
		return;
	}

	if (!(self.flags & FL_ONGROUND)) return;
	if (!JUMP_AUTO && !(self.flags & FL_JUMPRELEASED)) return;

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	
	self.button2 = 0;
	self.lastTouch = time;
	sound (self, CHAN_BODY, "player/jump1.wav", 1, SoundRadius(500));
	self.velocity_z = self.velocity_z + 270;
	
	//If we are standing on a train, add it's velocity to player (for momentum)
	if(self.groundentity.classname == "train" || self.groundentity.classname == "func_vehicle")
	{
		self.velocity = self.velocity + self.groundentity.velocity;
	}
};