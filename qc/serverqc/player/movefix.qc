void BetterNoclip() 
{
	if(self.movetype == MOVETYPE_NOCLIP && !self.button2 && !self.button3) //noclip
	{
		if(self.button4) self.velocity = self.velocity * 4;
	}
}

void ResetMovetypeAfterLadder()
{
	if(self.movetype == MOVETYPE_FLY && other.lastTouch < time)
	{
		self.movetype = MOVETYPE_WALK;
	}
}
void Player_FixMovement()
{
	if(self.groundentity && self.groundentity.classname == "func_conveyor")
	{
		self.velocity = self.velocity + self.groundentity.speed * self.groundentity.movedir * frametime * 2;
	}
	BetterNoclip();
	ResetMovetypeAfterLadder();
	self.angles_x = 0; // Fix ugly vertical model lean
}