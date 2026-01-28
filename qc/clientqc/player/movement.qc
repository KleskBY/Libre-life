
//Settings
float FRICTION = 8;
float ACCELERATION = 1;
vector MAX_VELOCITY = '1 7 1'; 
float GRAVITY = 800;
float JUMP_FORCE = 250;
float STEP_HEIGHT = 16;

float PlayerGrounded;
float lastJump;
float StopMovementTimer;

void ApplyFriction()
{
	if (player.velocity_x || player.velocity_z)
	{
		float f = 1 - frametime * FRICTION;
		player.velocity_x = player.velocity_x * f;
		player.velocity_y = player.velocity_y * f;
	}
}

void ApplyAcceleration()
{
	makevectors(input_angles);
	vector wishvel = v_forward * input_movevalues_x + v_right * input_movevalues_y;
	wishvel_z = 0;
	wishvel = normalize(wishvel);
	player.velocity = player.velocity + wishvel * ACCELERATION * cvar("cl_forwardspeed") * 10 * frametime;
}


void PlayerJump()
{
	if (lastJump + 0.2 > time) return;
	lastJump = time;
	PlayerGrounded = false;
	player.velocity_z = player.velocity_z + JUMP_FORCE;
};

void CheckGroundCollision()
{
	tracebox(player.origin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, player.origin - [0, 0, STEP_HEIGHT], false, self);
	if(trace_fraction == 1)
	{
		PlayerGrounded = false;
	}
	else
	{
		PlayerGrounded = true;
		if(trace_fraction != 1 && player.velocity_z <= 0)
		{
			player.origin_z = trace_endpos_z + (fabs(PLAYER_STAND_SIZE_MIN_z) / 2);
		}
	}
};

void CheckCeilingCollision()
{
	tracebox(player.origin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, player.origin + [0, 0, STEP_HEIGHT], false, self);
	// traceline(self.origin, self.origin + '0 0 32', 1, self); 
	if (trace_fraction != 1)
	{
		player.velocity_z = 0;
	}
	traceline(player.origin, player.origin + '0 0 32', 1, self); 
	if (trace_fraction != 1)
	{
		player.velocity_z = 0;
	}

};

void StopMovement()
{
	player.origin = pmove_org;
	StopMovementTimer = time + 0.2;
}



void Player_Movement2()
{
	if(!frametime) StopMovement();
	if(intermission) StopMovement();
	if(!Player_IsAlive()) StopMovement();
	// if(player.origin_z < -1000 || vlen(pmove_org - player.origin) > 180) StopMovement(); //check if we teleported
	if(StopMovementTimer > time) 
	{
		player.origin = pmove_org;
		return;
	}
	
	ApplyFriction();
	ApplyAcceleration();
	CheckGroundCollision();
	
	if (PlayerGrounded)
	{
		if (lastJump + 0.1 < time) player.velocity_z = 0;
		if (input_buttons & 2) PlayerJump();
	}
	else player.velocity_z = player.velocity_z - GRAVITY * frametime;
	
	//check if we hit ceiling with the jump
	if(player.velocity_z > 0) 
	{
		CheckCeilingCollision();
	}
	
		
	vector targetOrigin = player.origin + player.velocity * frametime;
	tracebox(player.origin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, targetOrigin, false, self);
	if (trace_fraction == 1) //No collision with the wall
	{
		player.origin = targetOrigin;
	}
	else //else try to step up
	{
		// tracebox(self.origin, [-16, -16, 0], [16, 16, 16], targetOrigin, false, self);
		// if (trace_fraction == 1)
		// {
			// self.origin = targetOrigin + '0 0 6';
		// }
	
		tracebox(player.origin + [0, 0, STEP_HEIGHT], PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, targetOrigin + [0, 0, STEP_HEIGHT], false, self);
		if (trace_fraction == 1) //No collision with the wall
		{
			tracebox(targetOrigin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, targetOrigin + [0, 0, STEP_HEIGHT], false, self);
			if (trace_fraction == 1) player.origin = targetOrigin + [0, 0, STEP_HEIGHT];
		}
		else 
		{
			//bounce of the wall using collision normal
			player.velocity = player.velocity - trace_plane_normal * vdot(player.velocity, trace_plane_normal) * 1.5;
			player.velocity = player.velocity * 0.95;
			targetOrigin = player.origin + player.velocity * frametime;
			tracebox(self.origin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, targetOrigin, false, self);
			if (trace_fraction == 1)
			{
				self.origin = targetOrigin;
			}
		}
	}
	
	string pstr = "cmd p ";
	pstr = strcat(pstr, ftos(player.origin_x));
	pstr = strcat(pstr, " ");
	pstr = strcat(pstr, ftos(player.origin_y));
	pstr = strcat(pstr, " ");
	pstr = strcat(pstr, ftos(player.origin_z));
	pstr = strcat(pstr, "\n");
	localcmd(pstr);
	setproperty(VF_ORIGIN, player.origin + [0, 0, playerHeight]);
}


void Player_Movement()
{
	// string pstr = "cmd p ";
	// pstr = strcat(pstr, ftos(pmove_org_x));
	// pstr = strcat(pstr, " ");
	// pstr = strcat(pstr, ftos(pmove_org_y));
	// pstr = strcat(pstr, " ");
	// pstr = strcat(pstr, ftos(pmove_org_z));
	// pstr = strcat(pstr, "\n");
	// localcmd(pstr);
	// setproperty(VF_ORIGIN, pmove_org + [0, 0, playerHeight]);
}
