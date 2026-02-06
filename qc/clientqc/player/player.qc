

void LookAt()
{
	makevectors(input_angles);
	vector targ = LookAtPos;
	if(targ != '0 0 0' && time < LookAtTime && fabs(time - LookAtTime) < 3)
	{
		vector direction = normalize(targ - pmove_org);

		float yaw = atan2(direction_y, direction_x) * (180.0 / M_PI);
		direction = normalize(pmove_org - targ);
		float pitch = atan2(direction_z, sqrt(direction_x * direction_x + direction_y * direction_y)) * (180.0 / M_PI);

		vector need_angles = [pitch, yaw];
		
		vector change = need_angles - input_angles;
		change = NormalizeAngle(change);
		change = ClampAngle(change);
		float diff = fabs(change_y);
	
		float aim_smooth = LookAtSpeed;
		
		if (change_y < -aim_smooth) change_y = -aim_smooth;
		if (change_y > aim_smooth) change_y = aim_smooth;
		input_angles_y = input_angles_y + (change_y * 15 * frametime);
		input_angles_x = Lerp(input_angles_x, need_angles_x, aim_smooth * frametime);

		setproperty(VF_CL_VIEWANGLES, input_angles); 
	}
}

float lastHealth;
void HealthBlur()
{
	cvar_set("r_glsl_postprocess_uservec1", ftos(Lerp(cvar("r_glsl_postprocess_uservec1"), 1, 6 * frametime)));
	if(time < 1) return;
	if(lastHealth == playerHealth) return;
	if(lastHealth > playerHealth)
	{
		float delta_health = fabs((lastHealth - playerHealth) * 1.5);
		if(delta_health < 110) cvar_set("r_glsl_postprocess_uservec1", ftos(delta_health));
	}
	
	//black and white when low hp
	// float saturation = 0.1 + (40 + lastHealth) / 100;
	// if(saturation < 0.1) saturation = 0.1;
	// if(saturation > 1.1) saturation = 1.1;
	// cvar_set("r_glsl_saturation", ftos(saturation));
	
	lastHealth = playerHealth;
}

void InterpolateCamera()
{
	if(cvar("chase_active")) return;
	float dist = vlen(playerOrigin - pmove_org);
	if(dist > 50)
	{
		playerOrigin = pmove_org;
	}
	else
	{
		playerOrigin = LerpVector(playerOrigin, pmove_org, 27 * frametime);
		setproperty(VF_ORIGIN, playerOrigin + [0, 0, playerHeight]);
	}
};

void SprintAnimation()
{
	if(isRunning && !isCrouching && !isAttacking && input_movevalues_x > 1 && Player_IsAlive())
	{
		cvar_set("cl_forwardspeed", "120");
	}
	else 
	{
		if(isCrouching)
		{
			cvar_set("cl_forwardspeed", "80");
			cvar_set("cl_backspeed", "80");
			cvar_set("cl_sidespeed", "80");
		}
		else
		{
			cvar_set("cl_forwardspeed", "210");
			cvar_set("cl_backspeed", "210");
			cvar_set("cl_sidespeed", "210");
		}
	}
	

};

void Player_CreateEntity()
{
	if(player) return;
	player = spawn();
	precache_model("progs/player.mdl");
	setmodel(player, "progs/player.mdl");
	setsize(player, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
	setorigin(player, pmove_org);	
	player.drawmask = MASK_ENGINE;	
	player.pmove_flags = PMF_ONGROUND;
	
}

float Player_IsAlive()
{
	if(playerHealth < 0 || playerHealth == 666) return false;
	return true;
};

void Player_Update()
{
	// Player_CreateEntity();
	// Player_Movement();
	InterpolateCamera();
	Flashlight_Draw();
	HealthBlur();
	SprintAnimation();
	LookAt();
	
	// input_movevalues = normalize(input_movevalues) * cvar("cl_forwardspeed"); //clamp strafe speed
	// setproperty(VF_CL_VIEWANGLES, input_angles + [ view_punchangle_x * 3 * frametime, view_punchangle_y * 3 * frametime]); //recoil
}

void Player_GetFields()
{
	playerHealth 	= getstati(STAT_HEALTH);
	playerAmmo 		= getstati(STAT_AMMO);
	playerClip		= getstati(STAT_CLIP);
	playerWeapon	= getstati(STAT_ACTIVEWEAPON);
	playerHeight	= getstati(STAT_VIEWHEIGHT);
	playerFrame		= getstati(STAT_WEAPONFRAME);
	isCrouching 	= (playerHeight == DUCK_VIEW_OFS_z);
};
