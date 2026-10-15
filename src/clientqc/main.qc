
float CSQC_InputEvent(float flEventType, float flKey, float flCharacter)
{
	return Input_Update(flEventType, flKey, flCharacter);
};

// FTE calls this; Zircon does not export it, and Player_UpdateSpeeds drives the cl_*speed cvars instead: the latch stops both paths applying
void CSQC_Input_Frame()
{
	if (!g_hlSpeedsViaInput)
	{
		g_hlSpeedsViaInput = TRUE;
		cvar_set("cl_forwardspeed", ftos(HL_CMD_SPEED));
		cvar_set("cl_backspeed",    ftos(HL_CMD_SPEED));
		cvar_set("cl_sidespeed",    ftos(HL_CMD_SPEED));
	}
	Player_ClampMoveHL();
	Player_ApplyRecoilInput();	// the only place an input_angles write survives on FTE
};

void Save_ConsumePendingLoad();

void CSQC_UpdateView(float flWidth, float flHeight)
{
	PlayerProps_Init();
	Save_ConsumePendingLoad();
	View_Update(flWidth, flHeight);
};

float lastQuickSave;
float lastAutoSave;

#define AUTOSAVE_MIN_INTERVAL 5

void Save_StampPointer(string slot)
{
	cvar_set("g_lastSaveSlot", slot);
	cvar_set("g_lastSaveMap",  mapname);
	cvar_set("g_lastSaveTime", ftos(gettime(GETTIME_REALTIME)));
}

void Save_WriteGlobalCompanion(string slot)
{
	localcmd(strcat("cmd gs_writesave ", slot, "\n"));
}

void Save_ConsumePendingLoad()
{
	string pend = cvar_string("g_pendingLoad");
	if (pend == "") return;
	if (mapname == "") return;
	cvar_set("g_pendingLoad", "");
	Save_StampPointer(pend);
	localcmd(strcat("cmd gs_restore ", pend, "\n"));
}

float CSQC_ConsoleCommand(string strCommand)
{
	float argc = tokenize(strCommand);
	string command = argv(0); // /say
	if(command == "obit")   // obit "<killer>" "<victim>" <weaponID>
	{
		Obituary_Push(argv(1), argv(2), stof(argv(3)));
		return TRUE;
	}
	else if(command == "ntag")   // ntag <roster>
	{
		Nametag_Parse(argv(1));
		return TRUE;
	}
	else if(command == "sbrow")  // sbrow <slot> <kills> <deaths>
	{
		ScoreTable_SetRow(stof(argv(1)), stof(argv(2)), stof(argv(3)));
		return TRUE;
	}
	else if(command == "sbdel")  // sbdel <slot>
	{
		ScoreTable_RemoveRow(stof(argv(1)));
		return TRUE;
	}
	else if(command == "inventory")
	{
		showInventory = !showInventory;
		return TRUE;
	}
	else if(command == "lookat")
	{
		string arg1 = argv(1);
		string arg2 = argv(2);
		string arg3 = argv(3);

		LookAtPos_x = stof(arg1);
		LookAtPos_y = stof(arg2);
		LookAtPos_z = stof(arg3);
		LookAtTime = time + 1;
		return TRUE;
	}
	else if(command == "cam") //cam x y z pitch yaw
	{
		entity cam = find(world, classname, "cam");
		if (!cam)
		{
			cam = spawn();
			cam.classname = "cam";
		}
		vector newOrigin = [stof(argv(1)), stof(argv(2)), stof(argv(3))];
		vector newAngles = [stof(argv(4)), stof(argv(5)), 0];
		if (cam.cam_active)
		{
			cam.cam_prev_origin = cam.origin;
			cam.cam_prev_angles = cam.angles;
			cam.cam_prev_time   = cam.cam_recv_time;
		}
		else
		{
			cam.cam_prev_origin = newOrigin;
			cam.cam_prev_angles = newAngles;
			cam.cam_prev_time   = time;
		}
		cam.origin        = newOrigin;
		cam.angles        = newAngles;
		cam.cam_recv_time = time;
		cam.cam_active    = 1;
		return TRUE;
	}
	else if(command == "camend")
	{
		entity ce = find(world, classname, "cam");
		if (ce) ce.cam_active = 0;
		return TRUE;
	}
	else if(command == "flashlight")
	{
		Flashlight_Toggle();
		return TRUE;
	}
	else if(command == "bot_add" || command == "bot_kick")
	{
		localcmd(strcat("cmd ", command, " \"", argv(1), "\"\n"));
		return TRUE;
	}
	else if(command == "hudmsg")
	{
		return HudMessage_Parse(strCommand);
	}
	else if(command == "scrfade")
	{
		return Fade_Parse(strCommand);
	}
	else if(command == "shockwave")
	{
		return Shockwave_Parse();
	}
	else if(command == "quicksave")
	{
		lastQuickSave = gettime(GETTIME_REALTIME);
		localcmd("save quick\n");
		Save_StampPointer("quick");
		Save_WriteGlobalCompanion("quick");
		return TRUE;
	}
	else if(command == "autosave") //trigger_autosave
	{
		if (cvar_string("hub_restore_pending") != "") return TRUE;
		float now = gettime(GETTIME_REALTIME);
		if (now - lastAutoSave < AUTOSAVE_MIN_INTERVAL) return TRUE;
		lastAutoSave = now;
		localcmd("save autosave\n");
		Save_StampPointer("autosave");
		Save_WriteGlobalCompanion("autosave");
		return TRUE;
	}
	else if(command == "gamesave") //UI_SaveSelectedGame
	{
		string sslot = argv(1);
		if (sslot == "") return TRUE;
		localcmd(strcat("save ", sslot, "\n"));
		Save_StampPointer(sslot);
		Save_WriteGlobalCompanion(sslot);
		return TRUE;
	}
	else if(command == "quickload") //Save_ConsumePendingLoad
	{
		cvar_set("g_pendingLoad", "quick");
		localcmd("load quick\n");
		return TRUE;
	}
	else if(command == "+invnext")
	{
		HUD_CycleWeapon(+1);
		return TRUE;
	}
	else if(command == "+invprev")
	{
		HUD_CycleWeapon(-1);
		return TRUE;
	}
	else if(command == "-invnext" || command == "-invprev")
	{
		return TRUE;
	}
    return FALSE;
}
void CSQC_Parse_StuffCmd(string msg)
{
	if(isdemo()) return;
	localcmd(msg);
}

void CSQC_Init(void)
{
	completedTime = 0;
	PlayerProps_Init();
	Precache();
	RegisterCustomCvars();
	Weapon_RegistryInit();

	registercommand("inventory");
	registercommand("lookat");
	registercommand("cam");
	registercommand("camend");
	registercommand("flashlight");
	registercommand("quicksave");
	registercommand("autosave");
	registercommand("gamesave");
	registercommand("quickload");
	registercommand("hudmsg");
	registercommand("scrfade");
	registercommand("shockwave");
	registercommand("+invnext");
	registercommand("+invprev");
	registercommand("-invnext");
	registercommand("-invprev");
	registercommand("sbrow");
	registercommand("sbdel");
	registercommand("obit");
	registercommand("ntag");
	registercommand("bot_add");
	registercommand("bot_kick");

	// Rows pushed before this VM existed (changelevel reload, late csprogs load) were lost; ask for a full resend.
	localcmd("cmd sbsync\n");

	cvar_set("r_drawviewmodel", "1");
	cvar_set("r_viewscale", "1");
	cvar_set("cl_weather_rain", "0");
	cvar_set("cl_weather_snow", "0");
}

void CSQC_Shutdown(void) 
{
}

void CSQC_Ent_Update(float isnew)
{
	float t = ReadByte();
	if (t == ENT_CAMERA)
	{
		float active = ReadByte();
		self.classname  = "cam";
		self.cam_active = active;
		if (!active) return;

		vector newOrigin;
		newOrigin_x = ReadCoord();
		newOrigin_y = ReadCoord();
		newOrigin_z = ReadCoord();
		vector newAngles;
		newAngles_x = ReadAngle();
		newAngles_y = ReadAngle();
		newAngles_z = 0;

		if (isnew)
		{
			self.cam_prev_origin = newOrigin;
			self.cam_prev_angles = newAngles;
			self.cam_prev_time   = time;
		}
		else
		{
			self.cam_prev_origin = self.origin;
			self.cam_prev_angles = self.angles;
			self.cam_prev_time   = self.cam_recv_time;
		}
		self.origin        = newOrigin;
		self.angles        = newAngles;
		self.cam_recv_time = time;
	}
}


void CSQC_Ent_Remove()
{
	remove(self);
}
