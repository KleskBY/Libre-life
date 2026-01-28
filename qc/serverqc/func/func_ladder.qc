void ladder_sound()
{
	if(time + random(0, 0.1) > other.footstep_finished || other.footstep_finished == 0) 
	{
		// float r = random();
		// if (r <= 0.25) sound(other, CHAN_BODY, "footsteps/metal1.wav", 0.5, SoundRadius(800));
		// else if (r <= 0.5 && r > 0.25) sound(other, CHAN_BODY, "footsteps/metal2.wav", 0.5, SoundRadius(800));
		// else if (r <= 0.75 && r > 0.5) sound(other, CHAN_BODY, "footsteps/metal3.wav", 0.5, SoundRadius(800));
		// else sound(other, CHAN_BODY, "footsteps/metal4.wav", 0.5, SoundRadius(800));
		other.footstep_finished = time + 0.5;
	}
}

void ladder_touch()
{
	if(other.movetype == MOVETYPE_NOCLIP) return;
	if(!IsAlive(other)) return;
	if(clienttype(other) == CLIENTTYPE_BOT) return;
	if(other.classname != "player") return;
	
	float sv_maxspeed = cvar("sv_maxspeed");
	float sv_friction = cvar("sv_friction");
	float sv_accelerate = cvar("sv_accelerate");
	
	if(vlen(other.velocity) > 50) ladder_sound();
	
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
		
		// makevectors(self.angles);
		// other.velocity = other.velocity + (v_forward * 200);
		// other.velocity_z = other.velocity_z + 100;
		// other.lastTouch = time + 0.2;
		return;
	}

	
	other.velocity = other.velocity * (1 - frametime * sv_friction);
	makevectors(other.v_angle);
	vector wishvel = v_forward * other.movement_x + v_right * other.movement_y + '0 0 1' * other.movement_z;
	
	// acceleration
	vector wishdir = normalize(wishvel);
	float wishspeed = vlen(wishvel);
	if (wishspeed > sv_maxspeed) wishspeed = sv_maxspeed;
	if (other.button3 || other.button4) wishspeed = wishspeed *0.7;
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
	self.touch = ladder_touch;
};