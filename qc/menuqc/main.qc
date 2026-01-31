




//Quit window
entity win_quit;
void UI_DrawQuitContents()
{
	vector base = win_quit.UI_win_pos + [font_size * 0.6, font_size * 2.0];
	UI_Text("Do you wish to stop playing now?", base + [font_size * .5]);
	UI_Button2("Quit game", base + [font_size * 2.5, font_size * 2], [font_size * 4, font_size * 1.25], UI_Cmd, "quit\n");
	UI_Button2("Cancel", base + [font_size * 7.5, font_size * 2], [font_size * 4, font_size * 1.25], UI_ToggleWindow, "Quit game");
}

//New game window
entity win_new;
void UI_DrawNewContents()
{
	vector base = win_new.UI_win_pos + [font_size * 0.6, font_size * 2.0];
	UI_Button2("Play Half-life", base + [font_size * 1, font_size * 7], [font_size * 11, font_size * 1.25], UI_Cmd, "maxplayers 1; map pod1\n");
	UI_Button2("Play Half-life: Uplink", base + [font_size * 1, font_size * 9], [font_size * 11, font_size * 1.25], UI_Cmd, "echo 1\n");
	UI_Button2("Cancel", base + [font_size * 9, font_size * 12], [font_size * 3, font_size * 1.25], UI_ToggleWindow, "New Game");

	UI_Text("Select Difficulty", base + [font_size * 1]);
	UI_Dropdown("skill", base + [font_size * 1, font_size * 1], font_size * 11, "Easy|Medium|Hard");
}

void UI_UpdateSaves();
void UI_InitWindows()
{
	win_settings = UI_CreateWindow("Options", [font_size * 26, font_size * 20]);
	win_settings.UI_win_draw = UI_DrawSettingsContents;
	
	win_quit = UI_CreateWindow("Quit game", [font_size * 15, font_size * 6]);
	win_quit.UI_win_draw = UI_DrawQuitContents;
	
	win_new = UI_CreateWindow("New Game", [font_size * 14, font_size * 16]);
	win_new.UI_win_draw = UI_DrawNewContents;
	
	win_loadgame = UI_CreateWindow("Load Game", [font_size * 28, font_size * 22, 0]);
	win_loadgame.UI_win_draw = UI_DrawLoadGameContents;
	
	win_savegame = UI_CreateWindow("Save Game", [font_size * 28, font_size * 22, 0]);
	win_savegame.UI_win_draw = UI_DrawSaveGameContents;
	
	win_servers = UI_CreateWindow("Servers", [font_size * 28, font_size * 18, 0]);
	win_servers.UI_win_draw = UI_DrawServersContents;

	UI_list_selected = -1;
	UI_UpdateSaves();
}


void RegisterCvars()
{
	registercvar("ui_display_mode", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_lighting", "3", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_raw", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_invert_mouse", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_autoaim", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_effects", "2", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_resolution", "2", CVAR_TYPEFLAG_SAVED);
};




//Main (functions called by engine)
float menu_enabled;

void(float a, float b) m_draw = 
{
	if(!menu_enabled) return;
	UI_UpdateMouse();
	UI_GetRelative();
	
	if (clientstate() != CS_CONNECTED) drawpic('0 0 0', "gfx/background", vid, '1 1 1', 1, 0);
	else drawfill('0 0 0', vid, '0 0 0', 0.45, 0);
	
	if (clientstate() != CS_CONNECTED || isdemo())
		UI_MenuButton("New game", [font_size * 2, vid_y - font_size * 14], UI_ToggleWindow, "New Game");
	else
	{
		UI_MenuButton("New game", [font_size * 2, vid_y - font_size * 16], UI_ToggleWindow, "New Game");
		UI_MenuButton("Save game", [font_size * 2, vid_y - font_size * 14], UI_ToggleWindow, "Save Game");
	}
	UI_MenuButton("Load game", [font_size * 2, vid_y - font_size * 12], UI_ToggleWindow, "Load Game");
	UI_MenuButton("Find server", [font_size * 2, vid_y - font_size * 10], UI_ToggleWindow, "Servers");
	UI_MenuButton("Create server", [font_size * 2, vid_y - font_size * 8], UI_ToggleWindow, "Create server");
	UI_MenuButton("Options", [font_size * 2, vid_y - font_size * 6], UI_ToggleWindow, "Options");
	if (clientstate() != CS_CONNECTED || isdemo()) UI_MenuButton("Quit", [font_size * 2, vid_y - font_size * 4], UI_ToggleWindow, "Quit game");
	else UI_MenuButton("Leave", [font_size * 2, vid_y - font_size * 4], UI_Cmd, "disconnect\n");
	
	UI_DrawWindows();
	UI_DrawCursor();
	
	UI_wheel = 0;
	clicked = 0;
};


void() m_display = 
{
	setkeydest(KEY_MENU);
	setmousetarget(MT_MENU);
};

void() m_hide = 
{
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);
};


void(float n) m_toggle = 
{
	UI_UpdateSaves();
	menu_enabled = !menu_enabled;
	if (menu_enabled) 
	{
		m_display();
		menu_enabled = 1;
	}
	else m_hide();
 };

void(float key, float ascii) m_keydown = 
{
	if(UI_ProcessKeybind(key)) return;
	if(UI_ProcessKeybind2(key)) return;
	if (key == K_ESCAPE) m_toggle(1);
	if (key == K_MOUSE1) { clicked = 1; mouse1_held = 1; }

	if (key == K_MWHEELUP) UI_wheel = UI_wheel + 1;
	if (key == K_MWHEELDOWN) UI_wheel = UI_wheel - 1;
};

void(float key, float ascii) m_keyup = 
{
 	if (key == K_MOUSE1) mouse1_held = 0;
};


void() m_init = 
{
	precache_pic("gfx/background");
	precache_pic("gfx/cursor");
	// cmd("playvideo valve_10_fps\n");
	cmd("r_font_disable_freetype 0\n");					//Enable freetype support
	cmd("utf8_enable 1\n");								//Enable support for non-latin characters
	cmd("r_font_postprocess_outline 0\n");				//Some outline
	cmd("r_font_postprocess_blur 0\n");					//Some blur
	cmd("r_textshadow 0\n");							//Font shadow
	cmd("loadfont default gfx/font 24 scale 1\n");	//Loading font for default text
	cmd("loadfont console gfx/font 24 scale 1.2\n");	//Loading font for console text
	cmd("loadfont infobar gfx/font 24 scale 1.2\n");	//Loading font for infobar (text at the bottom of the screen. Execute cmd: "infobar 1 string")
	cmd("loadfont notify gfx/font 24 scale 1.2\n");		//Loading font for text in left upper corner 
	cmd("loadfont chat gfx/font 24 scale 1.2\n");		//Loading font for chat input
	cmd("loadfont menu gfx/font 24 scale 1\n");		//Font for menuqc
	cmd("loadfont sbar gfx/font 32 scale 1.2\n");		//Font for sbar (health, armor, ammo, etc.)
	cmd("loadfont centerprint gfx/font 32 scale 1.2\n");//Font for centerprint (cmd: "cprint string")
	drawfont = FONT_MENU;
	
	menu_page = 0;
	UI_GetRelative();
	mouse_pos = [ vid_x / 2, vid_y / 2];

	UI_InitWindows();
	RegisterCvars();
};
void() m_shutdown = {};
