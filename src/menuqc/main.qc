
//Quit window
entity win_quit;
void UI_DrawQuitContents()
{
	vector base = win_quit.ui_win_pos + [ui_font_size * 0.6, ui_font_size * 2.0];
	UI_Text("Do you wish to stop playing now?", base + [ui_font_size * .5]);
	UI_Button2("Quit game", base + [ui_font_size * 2.5, ui_font_size * 2], [ui_font_size * 4, ui_font_size * 1.25], UI_Cmd, "quit\n");
	UI_Button2("Cancel", base + [ui_font_size * 7.5, ui_font_size * 2], [ui_font_size * 4, ui_font_size * 1.25], UI_ToggleWindow, "Quit game");
}

//New game window
entity win_new;
float hasQuakeCampaign;
float hasQuakeRegistered;
float hasHazardCourse;
float hasUplinkCampaign;
float hasHalfLifeCampaign;

float UI_HasMap(string mapName)
{
	float handle = search_begin(strcat("maps/", mapName, ".bsp"), TRUE, TRUE);
	if (handle < 0) return FALSE;
	float available = search_getsize(handle) > 0;
	search_end(handle);
	return available;
}

string UI_SP_RESET = "maxplayers 1; gamemode 0; coop 0; deathmatch 0; teamplay 0; sv_public 0; ";
void UI_DrawNewContents()
{
	vector base = win_new.ui_win_pos + [ui_font_size * 0.6, ui_font_size * 2.0];
	float rowY = 4;
	if (hasQuakeCampaign)
	{
		UI_Button2(hasQuakeRegistered ? "Quake 1" : "Quake 1 Shareware", base + [ui_font_size, ui_font_size * rowY], [ui_font_size * 11, ui_font_size * 1.25], UI_Cmd, strcat(UI_SP_RESET, "map start\n"));
		rowY += 2;
	}
	if (hasHazardCourse)
	{
		UI_Button2("Hazard Course", base + [ui_font_size, ui_font_size * rowY], [ui_font_size * 11, ui_font_size * 1.25], UI_Cmd, strcat(UI_SP_RESET, "map t0a0\n"));
		rowY += 2;
	}
	if (hasUplinkCampaign)
	{
		UI_Button2("Half-Life: Uplink", base + [ui_font_size, ui_font_size * rowY], [ui_font_size * 11, ui_font_size * 1.25], UI_Cmd, strcat(UI_SP_RESET, "map hldemo1\n"));
		rowY += 2;
	}
	if (hasHalfLifeCampaign)
	{
		UI_Button2("Half-Life", base + [ui_font_size, ui_font_size * rowY], [ui_font_size * 11, ui_font_size * 1.25], UI_Cmd, strcat(UI_SP_RESET, "map c0a0\n"));
		rowY += 2;
	}
	UI_Button2("Cancel", base + [ui_font_size * 9, ui_font_size * 12], [ui_font_size * 3, ui_font_size * 1.25], UI_ToggleWindow, "New Game");

	UI_Text("Select Difficulty", base + [ui_font_size * 1]);
	UI_Dropdown("skill", base + [ui_font_size * 1, ui_font_size * 1], ui_font_size * 11, "Easy|Medium|Hard");
}

void UI_UpdateSaves();
void UI_InitWindows()
{
	win_settings = UI_CreateWindow("Options", [ui_font_size * 26, ui_font_size * 20]);
	win_settings.ui_win_draw = UI_DrawSettingsContents;
	
	win_quit = UI_CreateWindow("Quit game", [ui_font_size * 15, ui_font_size * 6]);
	win_quit.ui_win_draw = UI_DrawQuitContents;
	
	win_new = UI_CreateWindow("New Game", [ui_font_size * 14, ui_font_size * 16]);
	win_new.ui_win_draw = UI_DrawNewContents;
	
	win_loadgame = UI_CreateWindow("Load Game", [ui_font_size * 28, ui_font_size * 22, 0]);
	win_loadgame.ui_win_draw = UI_DrawLoadGameContents;
	
	win_savegame = UI_CreateWindow("Save Game", [ui_font_size * 28, ui_font_size * 22, 0]);
	win_savegame.ui_win_draw = UI_DrawSaveGameContents;
	
	win_servers = UI_CreateWindow("Servers", [ui_font_size * 28, ui_font_size * 18, 0]);
	win_servers.ui_win_draw = UI_DrawServersContents;

	win_create = UI_CreateWindow("Create server", [ui_font_size * 31, ui_font_size * 24, 0]);
	win_create.ui_win_draw = UI_DrawCreateContents;

	ui_list_selected = -1;
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
	registercvar("sv_hitmodel", "1", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_resolution", "2", CVAR_TYPEFLAG_SAVED);

	registercvar("ui_cs_mode", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_cs_filter", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_cs_public", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_cs_maxplayers", "8", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_cs_friendlyfire", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_cs_cheats", "0", CVAR_TYPEFLAG_SAVED);
	registercvar("ui_cs_password", "", 0);

	// "gamemode" is ours, not an engine cvar, and the server VM only registers it in worldspawn (after "map" runs). Otherwise, launching with "gamemode 1; map c1a0" treats "gamemode" as an unknown command, causing the map to load as single player.
	registercvar("gamemode", "0", 0);
	if (cvar_string("hostname") == "" || cvar_string("hostname") == "unnamed")
		cvar_set("hostname", "Libre-life server");

	registercvar("g_pendingLoad", "", 0);
	registercvar("g_lastSaveSlot", "", 0);
	registercvar("g_lastSaveMap", "", 0);
	registercvar("g_lastSaveTime", "0", 0);
}


//Main (functions called by engine)
float menu_enabled;

void m_draw(float a, float b)
{
	if(!menu_enabled) return;
	UI_UpdateMouse();
	UI_GetRelative();
	cvar_set("r_textshadow", "3");
	if (clientstate() != CS_CONNECTED) drawpic('0 0 0', "gfx/background", ui_vid, '1 1 1', 1, 0);
	else drawfill('0 0 0', ui_vid, '0 0 0', 0.45, 0);
	
	if (clientstate() != CS_CONNECTED || isdemo())
		UI_MenuButton("New game", [ui_font_size * 2, ui_vid_y - ui_font_size * 14], UI_ToggleWindow, "New Game");
	else
	{
		UI_MenuButton("New game", [ui_font_size * 2, ui_vid_y - ui_font_size * 16], UI_ToggleWindow, "New Game");
		UI_MenuButton("Save game", [ui_font_size * 2, ui_vid_y - ui_font_size * 14], UI_ToggleWindow, "Save Game");
	}
	UI_MenuButton("Load game", [ui_font_size * 2, ui_vid_y - ui_font_size * 12], UI_ToggleWindow, "Load Game");
	UI_MenuButton("Find server", [ui_font_size * 2, ui_vid_y - ui_font_size * 10], UI_ToggleWindow, "Servers");
	UI_MenuButton("Create server", [ui_font_size * 2, ui_vid_y - ui_font_size * 8], UI_ToggleWindow, "Create server");
	UI_MenuButton("Options", [ui_font_size * 2, ui_vid_y - ui_font_size * 6], UI_ToggleWindow, "Options");
	if (clientstate() != CS_CONNECTED || isdemo()) UI_MenuButton("Quit", [ui_font_size * 2, ui_vid_y - ui_font_size * 4], UI_ToggleWindow, "Quit game");
	else UI_MenuButton("Leave", [ui_font_size * 2, ui_vid_y - ui_font_size * 4], UI_Cmd, "disconnect\n");
	cvar_set("r_textshadow", "1");
	
	UI_DrawWindows();
	UI_DrawCursor();
	
	ui_wheel = 0;
	ui_clicked = 0;
}


void m_display()
{
	setkeydest(KEY_MENU);
	setmousetarget(MT_MENU);
}

void m_hide()
{
	setkeydest(KEY_GAME);
	setmousetarget(MT_CLIENT);
}


void m_toggle(float n)
{
	UI_UpdateSaves();
	menu_enabled = !menu_enabled;
	if (menu_enabled)
	{
		m_display();
		menu_enabled = 1;
		SyncSettingsFromEngine(); // Re-read engine state so dropdowns are accurate
	}
	else m_hide();
}

void GameCommand(string commandText)
{
	if (commandText == "resume")
	{
		menu_enabled = FALSE;
		m_hide();
		return;
	}
	if (commandText != "settings" && commandText != "menu") return;
	menu_enabled = TRUE;
	m_display();
	SyncSettingsFromEngine();
	if (commandText == "settings") UI_OpenWindow("Options");
}

const float K_TILDE = 126;
const float K_BACKQUOTE = 96;
void m_keydown(float key, float ascii)
{
	if(UI_InputEvent(0, key, ascii, 0)) return;
	if (key == K_ESCAPE || getkeybind_bindmap(key, 0) == "togglemenu") m_toggle(1);
	if (key == K_TILDE || key == K_BACKQUOTE) //FTE FIX
	{
		cmd("toggleconsole\n");
	}
}

void m_keyup(float key, float ascii)
{
 	UI_InputEvent(1, key, ascii, 0);
}

void UI_Init();
void m_init()
{
	hasQuakeCampaign = UI_HasMap("start");
	hasQuakeRegistered = UI_HasMap("e2m1");
	hasHazardCourse = UI_HasMap("t0a0");
	hasUplinkCampaign = UI_HasMap("hldemo1");
	hasHalfLifeCampaign = UI_HasMap("c0a0");
	precache_pic("gfx/background");
	precache_pic("gfx/cursor");
	cmd("playvideo valve_10_fps\n");
	cmd("r_font_disable_freetype 0\n");	// Enables freetype support
	cmd("utf8_enable 1\n");								//Enable support for non-latin characters
	cmd("r_font_postprocess_outline 0\n");				//Some outline
	cmd("r_font_postprocess_blur 0\n");					//Some blur
	cmd("r_textshadow 0\n");							//Font shadow
	cmd("loadfont default gfx/font 24 scale 1\n");		//Loading font for default text
	cmd("loadfont console gfx/font 24 scale 1.2\n");	//Loading font for console text
	cmd("loadfont infobar gfx/font 24 scale 1.2\n");	//Loading font for infobar (text at the bottom of the screen. Execute cmd: "infobar 1 string")
	cmd("loadfont notify gfx/font 24 scale 1.2\n");		//Loading font for text in left upper corner 
	cmd("loadfont chat gfx/font 24 scale 1.2\n");		//Loading font for chat input
	cmd("loadfont menu gfx/font 24 scale 1\n");			//Font for menuqc
	cmd("loadfont sbar gfx/font 32 scale 1.2\n");		//Font for sbar (health, armor, ammo, etc.)
	cmd("loadfont centerprint gfx/font 32 scale 1.2\n");//Font for centerprint (cmd: "cprint string")
	drawfont = FONT_MENU;
	
	ui_menu_page = 0;
	UI_GetRelative();
	ui_mouse_pos = [ ui_vid_x / 2, ui_vid_y / 2];

	UI_Init();
	UI_InitWindows();

	RegisterCvars();
	SyncSettingsFromEngine();
}
void m_shutdown() = {};


//FTE FIX
const float IE_KEYDOWN = 0;	/* Specifies that a key was pressed. Second argument is the scan code. Third argument is the unicode (printable) char value. Fourth argument denotes which keyboard(or mouse, if its a mouse 'scan' key) the event came from. Note that some systems may completely separate scan codes and unicode values, with a 0 value for the unspecified argument. */
const float IE_KEYUP = 1;	/* Specifies that a key was released. Arguments are the same as IE_KEYDOWN. On some systems, this may be fired instantly after IE_KEYDOWN was fired. */
const float IE_MOUSEDELTA = 2;	/* Specifies that a mouse was moved (touch screens and tablets typically give IE_MOUSEABS events instead, use in_windowed_mouse 0 to test code to cope with either). Second argument is the X displacement, third argument is the Y displacement. Fourth argument is which mouse or touch event triggered the event. */
const float IE_MOUSEABS = 3;	/* Specifies that a mouse cursor or touch event was moved to a specific location relative to the virtual screen space. Second argument is the new X position, third argument is the new Y position. Fourth argument is which mouse or touch event triggered the event. */
const float IE_ACCELEROMETER = 4;
const float IE_FOCUS = 5;	/* Specifies that input focus was given. parama says mouse focus, paramb says keyboard focus. If either are -1, then it is unchanged. */
const float IE_JOYAXIS = 6;	/* Specifies that what value a joystick/controller axis currently specifies. x=axis, y=value. Will be called multiple times, once for each axis of each active controller. */
const float IE_GYROSCOPE = 7;
float Menu_InputEvent(float evtype, float scanx, float chary, float devid)
{
	switch(evtype)
	{
	case IE_KEYDOWN:
		m_keydown(scanx, chary);
		break;
	case IE_KEYUP:
		m_keyup(scanx, chary);
		return FALSE;	//don't break things if the menu was enabled mid-game while other keys are potentially still held, or some other way.
	case IE_MOUSEDELTA:
		return UI_InputEvent(evtype, scanx, chary, devid);
	case IE_MOUSEABS:
		return UI_InputEvent(evtype, scanx, chary, devid);
	default:
		break;
	}

	return FALSE;
};
