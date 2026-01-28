.float dmgtime;
#define AIRTIME 12

void WaterMove()
{
	if (self.movetype == MOVETYPE_NOCLIP) return;
	if (self.health < 0) return;
	if (self.waterlevel != 3)
	{
		// not underwater
		// play 'up for air' sound
		if (self.air_finished < time)
			sound(self, CHAN_VOICE, "player/pl_wade1.wav", 1, ATTN_NORM);
		else if (self.air_finished < time + 9)
			sound(self, CHAN_VOICE, "player/pl_wade2.wav", 1, ATTN_NORM);
			
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
			// TODO: play leave water sound
			self.flags = self.flags - FL_INWATER;
		}
		return;
	}
	
	// make bubbles
	float air = rint(self.air_finished - time);
	if (!RandomInt(0, 0x1f) && RandomInt(0, AIRTIME - 1) >= air)
	{
		switch (RandomInt(0,3))
			{
			case 0:	sound(self, CHAN_BODY, "player/pl_swim1.wav", 0.8, ATTN_NORM); break;
			case 1:	sound(self, CHAN_BODY, "player/pl_swim2.wav", 0.8, ATTN_NORM); break;
			case 2:	sound(self, CHAN_BODY, "player/pl_swim3.wav", 0.8, ATTN_NORM); break;
			case 3:	sound(self, CHAN_BODY, "player/pl_swim4.wav", 0.8, ATTN_NORM); break;
		}
	}

	//damage if in lava or slime
	if (self.watertype == CONTENT_LAVA)
	{
		if (self.dmgtime < time)
		{
			if (self.radsuit_finished > time) self.dmgtime = time + 1;
			else self.dmgtime = time + 0.2;
			T_Damage (self, world, world, 10 * self.waterlevel);
		}
	}
	else if (self.watertype == CONTENT_SLIME)
	{
		if (self.dmgtime < time && self.radsuit_finished < time)
		{
			self.dmgtime = time + 1;
			T_Damage (self, world, world, 4 * self.waterlevel);
		}
	}
	
	if (!(self.flags & FL_INWATER) && self.movetype != MOVETYPE_BOUNCE) // player enter water
	{	
		sound (self, CHAN_BODY, "misc/h2ohit1.wav", 1, ATTN_NORM);
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

void Player_Swim()
{
	WaterMove();
	CheckWaterJump();
}