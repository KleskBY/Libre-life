

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
		change = Math_NormalizeAngle(change);
		change = Math_ClampAngle(change);
		float diff = fabs(change_y);
	
		float aim_smooth = LookAtSpeed;
		
		if (change_y < -aim_smooth) change_y = -aim_smooth;
		if (change_y > aim_smooth) change_y = aim_smooth;
		input_angles_y = input_angles_y + (change_y * 15 * frametime);
		input_angles_x = Math_Lerp(input_angles_x, need_angles_x, aim_smooth * frametime);

		setproperty(VF_CL_VIEWANGLES, input_angles); 
	}
}

float lastHealth;
void HealthBlur()
{
	cvar_set("r_glsl_postprocess_uservec1", ftos(Math_Lerp(cvar("r_glsl_postprocess_uservec1"), 1, 6 * frametime)));
	if(time < 1) return;
	if(lastHealth == playerHealth) return;
	if(lastHealth > playerHealth)
	{
		float delta_health = fabs((lastHealth - playerHealth) * 1.5);
		if(delta_health < 110) cvar_set("r_glsl_postprocess_uservec1", ftos(delta_health));
	}
	
	//black and white when low hp
	#ifdef DEATH_SATURATION
	float saturation = 0.1 + (40 + lastHealth) / 100;
	if(saturation < 0.1) saturation = 0.1;
	if(saturation > 1.1) saturation = 1.1;
	cvar_set("r_glsl_saturation", ftos(saturation));
	#endif
	
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
		playerOrigin = Math_LerpVector(playerOrigin, pmove_org, 27 * frametime);
		setproperty(VF_ORIGIN, playerOrigin + [0, 0, playerHeight]);
	}
};

#define HL_CMD_SPEED        400	// cl_forwardspeed/backspeed/sidespeed
#define HL_MOVESPEEDKEY     0.52	// cl_movespeedkey, applied while the walk key is held
#define HL_DUCK_MULTIPLIER  0.333	// DUCKING_MULTIPLIER
#define HL_USE_MULTIPLIER   0.333	// PM_CheckParamters: +use on the ground
#define HL_MAXSPEED         320	// sv_maxspeed fallback
#define CS_FL_ONGROUND      512

float playerCmdSpeed;
float g_hlSpeedsViaInput;	// set once CSQC_Input_Frame proves the engine calls it

float Player_SpeedCap()
{
	float cap = cvar("sv_maxspeed");
	if (cap <= 0) cap = HL_MAXSPEED;
	if (isUsing && (playerFlags & CS_FL_ONGROUND)) cap = cap * HL_USE_MULTIPLIER;
	return cap;
}

void Player_ClampMoveHL()
{
	if (isWalking) input_movevalues = input_movevalues * HL_MOVESPEEDKEY;

	float cap = Player_SpeedCap();
	float spd = vlen(input_movevalues);
	if (spd > cap) input_movevalues = input_movevalues * (cap / spd);

	if (isCrouching) input_movevalues = input_movevalues * HL_DUCK_MULTIPLIER;
};

void Player_UpdateSpeeds()
{
	if (g_hlSpeedsViaInput) return;

	float cmdSpeed = HL_CMD_SPEED;
	if (isWalking) cmdSpeed = cmdSpeed * HL_MOVESPEEDKEY;

	float cap = Player_SpeedCap();
	if (cmdSpeed > cap) cmdSpeed = cap;
	if (isCrouching) cmdSpeed = cmdSpeed * HL_DUCK_MULTIPLIER;

	if (cmdSpeed == playerCmdSpeed) return;
	playerCmdSpeed = cmdSpeed;

	string s = ftos(cmdSpeed);
	cvar_set("cl_forwardspeed", s);
	cvar_set("cl_backspeed", s);
	cvar_set("cl_sidespeed", s);
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

// cl_thirdperson: an authoring aid for looking at the player model, not a
// gameplay mode. 1 parks the engine chase camera behind the player; 2 circles
// the player instead, which is the only way to check a weapon grip or a walk
// cycle from the front, since the chase camera is anchored behind the view and
// can only ever show the back. Distance and orbit rate are live-tunable with
// cl_thirdperson_dist and cl_thirdperson_speed.
#define TP_CHASE_BACK   64
#define TP_CHASE_UP     16
#define TP_CHASE_BACK_DEFAULT  128   // engine defaults, restored on switch-off
#define TP_CHASE_UP_DEFAULT    12
#define TP_ORBIT_DIST   96
#define TP_ORBIT_HEIGHT 28
#define TP_ORBIT_SPEED  36      // degrees per second

float tp_orbitYaw;
float tp_wasOn;

void ThirdPerson_Orbit()
{
	float dist = cvar("cl_thirdperson_dist");
	if (dist <= 0) dist = TP_ORBIT_DIST;
	float speed = cvar("cl_thirdperson_speed");
	if (speed == 0) speed = TP_ORBIT_SPEED;

	tp_orbitYaw = tp_orbitYaw + speed * frametime;
	if (tp_orbitYaw >= 360) tp_orbitYaw = tp_orbitYaw - 360;
	if (tp_orbitYaw < 0)    tp_orbitYaw = tp_orbitYaw + 360;

	// makevectors rather than sin/cos: it keeps the yaw in the engine's own
	// convention and there is no PI in scope on this side.
	makevectors([0, tp_orbitYaw, 0]);
	vector focus = pmove_org + [0, 0, playerHeight * 0.5];
	vector cam   = focus - v_forward * dist + [0, 0, TP_ORBIT_HEIGHT];

	vector ang = vectoangles(focus - cam);
	ang_x = -ang_x;   // vectoangles reports pitch up positive, the view wants down positive

	setproperty(VF_ORIGIN, cam);
	setproperty(VF_ANGLES, ang);
}

void ThirdPerson_Update()
{
	float tp = cvar("cl_thirdperson");
	if (!tp)
	{
		// Release chase_active only on the frame this switches off, so a
		// chase_active set by hand at the console keeps working. Both modes
		// overwrite chase_back/chase_up, so put those back at the same time
		// or a later hand-set chase_active inherits the debug framing.
		if (tp_wasOn)
		{
			cvar_set("chase_active", "0");
			cvar_set("chase_back", ftos(TP_CHASE_BACK_DEFAULT));
			cvar_set("chase_up",   ftos(TP_CHASE_UP_DEFAULT));
		}
		tp_wasOn = FALSE;
		return;
	}
	tp_wasOn = TRUE;

	// chase_active is what makes the engine draw the player model and drop the
	// viewmodel, so it stays on for both modes. Its own camera placement does
	// not matter in orbit mode, since VF_ORIGIN and VF_ANGLES overwrite it.
	cvar_set("chase_active", "1");
	if (tp == 2)
	{
		cvar_set("chase_back", "0");
		cvar_set("chase_up", "0");
		ThirdPerson_Orbit();
		return;
	}
	cvar_set("chase_back", ftos(TP_CHASE_BACK));
	cvar_set("chase_up",   ftos(TP_CHASE_UP));
}

float CameraOverride()
{
	entity cam = find(world, classname, "cam");
	if (!cam || !cam.cam_active) return FALSE;

	float interval = cam.cam_recv_time - cam.cam_prev_time;
	float t;
	if (interval <= 0)
		t = 1;
	else
		t = (time - cam.cam_prev_time) / interval;
	if (t < 0) t = 0;
	if (t > 2) t = 2;

	vector pos = cam.cam_prev_origin + (cam.origin - cam.cam_prev_origin) * t;

	float dy = cam.angles_y - cam.cam_prev_angles_y;
	if (dy < -180) dy += 360;
	if (dy >  180) dy -= 360;
	vector ang;
	ang_x = cam.cam_prev_angles_x + (cam.angles_x - cam.cam_prev_angles_x) * t;
	ang_y = cam.cam_prev_angles_y + dy * t;
	ang_z = 0;

	setproperty(VF_ORIGIN,         pos);
	setproperty(VF_ANGLES,         ang);
	setproperty(VF_CL_VIEWANGLES,  ang);
	input_angles = ang;
	return TRUE;
}

// Hook for a downstream game's aim recoil, called from CSQC_Input_Frame, which is the only place FTE keeps an input_angles write. Core kicks the view nowhere, so this is empty here.
void Player_ApplyRecoilInput()
{
}

void Player_Update()
{
	if (CameraOverride())
	{
		Flashlight_Draw();
		return;
	}
	InterpolateCamera();
	ThirdPerson_Update();
	Flashlight_Draw();
	HealthBlur();
	Player_UpdateSpeeds();
	LookAt();

	// input_movevalues = normalize(input_movevalues) * cvar("cl_forwardspeed"); //clamp strafe speed
	// setproperty(VF_CL_VIEWANGLES, input_angles + [ view_punchangle_x * 3 * frametime, view_punchangle_y * 3 * frametime]); //recoil
}

void Player_GetFields()
{
	playerHealth 	= Stat_GetInt(STAT_HEALTH);
	playerArmor		= Stat_GetInt(STAT_ARMOR);
	playerAmmo 		= Stat_GetInt(STAT_AMMO);
	playerClip		= Stat_GetInt(STAT_CLIP);
	playerWeapon	= Stat_GetInt(STAT_ACTIVEWEAPON);
	playerWeaponBits = Stat_GetInt(STAT_WEAPONS);
	playerHasSuit	= (playerWeaponBits & WEAPON_SUIT) != 0;
	playerFlashBattery = Stat_GetInt(STAT_FLASHBAT);
	playerFlashOn	= Stat_GetInt(STAT_FLASHLIGHT);
	playerTrainHud	= Stat_GetInt(STAT_TRAIN);
	playerHeight	= Stat_GetInt(STAT_VIEWHEIGHT);
	playerFrame		= Stat_GetInt(STAT_WEAPONFRAME);
	playerFlags		= Stat_GetInt(STAT_PLAYERFLAGS);
	isCrouching 	= (playerHeight <= PLAYER_DUCK_VIEW_MAX);
};
