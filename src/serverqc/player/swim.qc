.float dmgtime;
#define AIRTIME 12

void WaterMove()
{
	if (self.movetype == MOVETYPE_NOCLIP) return;
	if (self.health < 0) return;
	if (self.waterlevel != 3)
	{
		// not underwater
		if (self.air_finished < time)
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "player/pl_wade1.wav");
		else if (self.air_finished < time + 9)
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "player/pl_wade2.wav");
			
		self.air_finished = time + AIRTIME;
		self.dmg = 2;
	}
	else if (self.air_finished < time) // drown!
	{	
		if (self.pain_finished < time)
		{
			self.dmg = self.dmg + 1;
			if (self.dmg > 5) self.dmg = 5;
			Combat_TakeDamage(self, world, world, self.dmg, DMG_DROWN);
			self.pain_finished = time + 1;
		}
	}
	
	if (!self.waterlevel)
	{
		if (self.flags & FL_INWATER)
		{
			// leave-water splash
			Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, 100, "player/pl_wade3.wav", "player/pl_wade4.wav");
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}
	
	// make bubbles
	float air = rint(self.air_finished - time);
	if (!Math_RandomInt(0, 0x1f) && Math_RandomInt(0, AIRTIME - 1) >= air)
	{
		Sound_Play(self, CHAN_BODY, 0.8, ATTN_NORM, 100, "player/pl_swim1.wav", "player/pl_swim2.wav",
		                                "player/pl_swim3.wav", "player/pl_swim4.wav");
	}

	//damage if in lava or slime (envirosuit blocks slime; lava still hurts)
	if (self.watertype == CONTENT_LAVA)
	{
		if (self.dmgtime < time)
		{
			self.dmgtime = time + 0.2;
			T_Damage (self, world, world, 10 * self.waterlevel, DMG_BURN);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{
		if (!((self.items & IT_SUIT) && self.radsuit_finished > time))
		{
			if (self.dmgtime < time)
			{
				self.dmgtime = time + 1;
				T_Damage (self, world, world, 4 * self.waterlevel, DMG_ACID);
			}
		}
	}
	
	if (!(self.flags & FL_INWATER) && self.movetype != MOVETYPE_BOUNCE) // player enter water
	{	
		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, "misc/h2ohit1.wav");
		self.flags = self.flags + FL_INWATER;
		self.dmgtime = 0;
	}
	
	if (!(self.flags & FL_WATERJUMP)) self.velocity = self.velocity - 0.8 * self.waterlevel * frametime * self.velocity;
}

void CheckWaterJump()
{
	if (self.waterlevel != 2) return;

	// check for a jump-out-of-water
	makevectors (self.angles);
	vector start = self.origin;
	start_z = start_z + 8; 
	v_forward_z = 0;
	normalize(v_forward);
	vector end = start + v_forward*24;
	traceline (start, end, TRUE, self);
	if (trace_fraction < 1)
	{	// solid at waist
		start_z = start_z + self.maxs_z - 8;
		end = start + v_forward*24;
		self.movedir = trace_plane_normal * -50;
		traceline (start, end, TRUE, self);
		if (trace_fraction == 1)
		{	// open at eye level
			self.flags = self.flags | FL_WATERJUMP;
			self.velocity_z = 225;
			self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
			self.teleport_time = time + 2;	// safety net
			return;
		}
	}
}

void Player_BrushWaterExit()
{
	if (!self.brushWaterMode)
		return;
	if (self.waterBrushTouchTime >= time - frametime * 2)
		return;

	self.brushWaterMode = 0;
	self.waterlevel = 0;
	self.watertype = CONTENT_EMPTY;
	if (self.movetype == MOVETYPE_FLY)
		self.movetype = MOVETYPE_WALK;
}

void Player_Swim()
{
	Player_BrushWaterExit();
	WaterMove();
	CheckWaterJump();
}