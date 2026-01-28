
.float crouching;
.float running;
.float stamina;

float PLAYER_STAMINA_DECREASE = 9;
float PLAYER_STAMINA_REGEN = 6;

void PlayerStanceCrouch()
{
	self.crouching = 1;
	self.running = 0;
	setsize(self, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX);
	self.view_ofs = DUCK_VIEW_OFS;
};

void PlayerStanceWalk()
{
	self.crouching = 0;
	setsize(self, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
	self.view_ofs = STAND_VIEW_OFS;
};

void Player_Stance()
{
	//Crouch
	if(self.button3) // holding crouch button
	{
		if(!self.crouching)
		{
			PlayerStanceCrouch();
		}
	}
	else if(self.crouching)
	{
		vector tempvec = [0, 0, PLAYER_STAND_SIZE_MAX_z];
		traceline(self.origin, self.origin + tempvec, FALSE, self);
		if(trace_fraction == 1)
		{
			tracebox(self.origin, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX - '0 0 12', self.origin + tempvec, FALSE, self);
			if (trace_fraction == 1)
			{
				PlayerStanceWalk();
			}
		}
	}
	
	//Sprint
	if(self.button4 && !self.button0)
	{
		if(!self.crouching && !self.running /*&& self.stamina > 30*/)
		{
			self.running = TRUE;
		}
	}
	else if(!self.crouching && self.running)
	{
		self.running = FALSE;
	}	
}