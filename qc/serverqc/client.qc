void ClientKill()
{

}

void ClientConnect()
{
}
void(vector center, float amplitude, float frequency, float duration, float radius) UTIL_ScreenShake;
void Player_Precache();
entity ChangeLevel_FindLandmark(string pLandmarkName);
void PutClientInServer()
{
	Player_Precache();
	entity spot = find(world, classname, "info_player_start");

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;
	
	self.attack_finished = time;
	self.deadflag = DEAD_NO;
	self.pausetime = 0; // paustime is set by teleporters to keep the player from moving a while
	
	if(strlen(cvar_string("landmark")) > 1)
	{
		entity landmark = ChangeLevel_FindLandmark(cvar_string("landmark"));
		if(!landmark)
		{
			self.origin = self.oldorigin = spot.origin + '0 0 1';	// 1998-07-21 Respawning where player died fix by Robert Field
			self.angles = spot.angles;
		}
		else
		{
			vector old_spot = stov(cvar_string("landmark_pos"));
			vector offset = landmark.origin - old_spot;
			vector old_pos = stov(cvar_string("landmark_player_pos"));
			vector new_pos = old_pos + offset;
			// setorigin(self, new_pos);
			self.origin = self.oldorigin = new_pos;
			self.angles = stov(cvar_string("landmark_player_angles"));
			self.velocity = stov(cvar_string("landmark_player_velocity"));
		}
	}
	else
	{
		self.origin = self.oldorigin = spot.origin + '0 0 1';	// 1998-07-21 Respawning where player died fix by Robert Field
		self.angles = spot.angles;
		self.velocity = '0 0 0';
	}
	self.fixangle = TRUE;		// turn this way immediately

	precache_model("models/v_crowbar.iqm");
	setmodel(self, "models/v_crowbar.iqm");
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	self.view_ofs = '0 0 32';
	
	
	// UTIL_ScreenShake(self.origin, 5, 2, 100, 99999);
}

void ClientDisconnect()
{

}
