
float CSQC_InputEvent(float flEventType, float flKey, float flCharacter) 
{
	return Input_Update(flEventType, flKey, flCharacter);
};

void CSQC_UpdateView(float flWidth, float flHeight) 
{
	View_Update(flWidth, flHeight);
};

float lastQuickSave;
float CSQC_ConsoleCommand(string strCommand) 
{
	float argc = tokenize(strCommand);
	string command = argv(0); // /say
	if(strCommand == "inventory")
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
	else if(strCommand == "flashlight")
	{
		Flashlight_Toggle();
		return TRUE;
	}
	else if(strCommand == "quicksave")
	{
		lastQuickSave = gettime(GETTIME_REALTIME);
		localcmd("save quick");
		return TRUE;
	}
    return FALSE;
}
void CSQC_Parse_StuffCmd(string msg)
{
	if(isdemo()) return;
	localcmd(msg);
}

void Music_Init()
{
	if(mapname == "maps/e1m1.bsp") return;
	else if(mapname == "maps/e1m2.bsp")
	{
		localcmd("cd loop 4\n");
	}
	else if(mapname == "maps/e1m3.bsp")
	{
		localcmd("cd loop 2\n");
	}
	else if(mapname == "maps/e1m7.bsp")
	{
		localcmd("cd loop 4\n");
	}
	else if(mapname == "maps/lobby.bsp")
	{
		localcmd("cd loop 5\n");
	}
	else localcmd("cd loop 6\n");
}

void CSQC_Init(void) 
{
	completedTime = 0;
	Precache();
	RegisterCustomCvars();
	cvar_set("r_drawviewmodel", "1");
	cvar_set("r_viewscale", "1");
	Music_Init();
}

void CSQC_Shutdown(void) 
{
}

void CSQC_Ent_Update(float isnew)
{	
}

void CSQC_Ent_Remove()
{
	remove(self);
}
