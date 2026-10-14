
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

		if (self.swim_flag < time)	// treading water stroke
		{
			self.swim_flag = time + 1;
			Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 100, "player/pl_wade1.wav", "player/pl_wade2.wav");
		}
		return;
	}

	if (!(self.flags & FL_ONGROUND)) return;
	if (!JUMP_AUTO && !(self.flags & FL_JUMPRELEASED)) return;

	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	
	self.button2 = 0;
	self.lastTouch = time;
	Sound_Play(self, CHAN_BODY, 1, Sound_Radius(500), PITCH_NORM, "player/pl_jump2.wav");

	if (self.player_longJump && self.button3 && (time - self.duckStartTime) < 1.0 && vlen(self.velocity) > 50)
	{
		makevectors(self.v_angle);
		self.velocity_x = v_forward_x * 560;
		self.velocity_y = v_forward_y * 560;
		self.velocity_z = 299.33;	// sqrt(2 * 800 * 56)
		self.punchangle_x = -5;
	}
	else
		self.velocity_z = self.velocity_z + 270;
	
	// Add ground entity velocity for momentum if on a vehicle
	if(self.groundentity.classname == "train" || self.groundentity.classname == "func_vehicle")
	{
		self.velocity = self.velocity + self.groundentity.velocity;
	}
};