void Ladder_Sound()
{
	if(time + random(0, 0.1) > other.footstep_finished || other.footstep_finished == 0) 
	{
		other.footstep_finished = time + 0.5;
	}
}

void Ladder_Touch()
{
	if(other.movetype == MOVETYPE_NOCLIP) return;
	if(!IsAlive(other)) return;
	if(clienttype(other) == CLIENTTYPE_BOT) return;
	if(other.classname != "player") return;
	
	float sv_maxspeed = cvar("sv_maxspeed");
	float sv_friction = cvar("sv_friction");
	float sv_accelerate = cvar("sv_accelerate");
	
	if(vlen(other.velocity) > 50) Ladder_Sound();
	
	if(!(other.flags & FL_LADDERJUMP) && !(other.flags & FL_JUMPRELEASED))
	{
		other.flags = other.flags | FL_LADDERJUMP;
	}
	else if((other.flags & FL_LADDERJUMP) && (other.flags & FL_JUMPRELEASED))
	{
		other.flags = other.flags - (other.flags & FL_LADDERJUMP);
	}
	
	if(other.lastTouch > time) return;
	other.movetype = MOVETYPE_FLY;
	if(other.button2 && !(other.flags & FL_LADDERJUMP) && !(other.flags & FL_ONGROUND)) 
	{
		vector center = (self.absmin + self.absmax) * 0.5;
		vector jumpdir = other.origin - center;
		jumpdir_z = 0; 
		jumpdir = normalize(jumpdir);
		jumpdir_x = rint(jumpdir_x);
		jumpdir_y = rint(jumpdir_y);
		other.velocity = other.velocity + (jumpdir * 190);
		other.velocity_z = other.velocity_z + 85;
		other.lastTouch = time + 0.2;
		
		return;
	}

	
	other.velocity = other.velocity * (1 - frametime * sv_friction);
	makevectors(other.v_angle);
	vector wishvel = v_forward * other.movement_x + v_right * other.movement_y + '0 0 1' * other.movement_z;
	
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	float climbSpeed = 200;					// maximum climb speed
	if (climbSpeed > sv_maxspeed) climbSpeed = sv_maxspeed;
	if (other.crouching) climbSpeed = climbSpeed * 0.333;	// PLAYER_DUCKING_MULTIPLIER
	if (wishspeed > climbSpeed) wishspeed = climbSpeed;
	if (time >= other.teleport_time)
	{
		float f = wishspeed - (other.velocity * wishdir);
		if (f > 0)
		{
			other.velocity = other.velocity + wishdir * min(f, sv_accelerate * frametime * wishspeed);
		}
	}
	other.velocity_z  = other.velocity_z + 4.25;//5.71;
	other.velocity_x = other.velocity_x * 0.7;
	other.velocity_y = other.velocity_y * 0.7;
};


void func_ladder()
{
	InitTrigger();
	self.touch = Ladder_Touch;
};