// CREATE SERVER UI

entity win_create;

// Mirrors of the gamemode values in gamedefs.qc (not compiled into the menu VM).
float CS_MODE_COOP = 1;
float CS_MODE_DM   = 2;

// Cooperative is capped for now; the server enforces the same number through
// mp_coop_maxplayers in ClientConnect.
#define CS_COOP_MAX_PLAYERS 4

float create_page;
float CREATE_SERVER = 0;
float CREATE_GAME   = 1;

float UI_Create_MaxPlayerCap()
{
	if (cvar("ui_cs_mode") == 0) return CS_COOP_MAX_PLAYERS;
	return 32;
}

void UI_SelectCreatePage()
{
	create_page = stof(ui_exec);
}

// Map entities: classname "csmap", one per maps/*.bsp found in the search path
// (this includes maps inside .pk3 archives).
.string cs_map;         // bare map name, no path / extension
.float  cs_kind;        // CSMAP_* category, drives the filter dropdown

float CSMAP_HL = 0;     // Half-Life campaign (c#a*, t0a*, hldemo*)
float CSMAP_MP = 1;     // multiplayer / everything else
float CSMAP_Q1 = 2;     // Quake (e#m*, start)

float UI_cs_scanned;    // one-shot scan flag
float UI_cs_count;      // total maps found (unfiltered)
float UI_cs_scroll;     // first visible row
string UI_cs_selected;  // selected map name ("" = none)

float UI_Create_IsDigit(string s, float i)
{
	float c = str2chr(s, i);
	return (c >= 48 && c <= 57);
}

float UI_Create_Classify(string nm)
{
	float len = strlen(nm);

	if (nm == "start") return CSMAP_Q1;
	// e<digit>m<digit>
	if (len >= 4 && substring(nm, 0, 1) == "e" && UI_Create_IsDigit(nm, 1) && substring(nm, 2, 1) == "m")
		return CSMAP_Q1;

	// c<digit>a... (campaign chapters) / t0a... (hazard course) / hldemo...
	if (len >= 3 && substring(nm, 0, 1) == "c" && UI_Create_IsDigit(nm, 1) && substring(nm, 2, 1) == "a")
		return CSMAP_HL;
	if (len >= 3 && substring(nm, 0, 3) == "t0a") return CSMAP_HL;
	if (len >= 6 && substring(nm, 0, 6) == "hldemo") return CSMAP_HL;

	return CSMAP_MP;
}

string UI_Create_KindName(float kind)
{
	if (kind == CSMAP_HL) return "Half-Life";
	if (kind == CSMAP_Q1) return "Quake";
	return "Deathmatch";
}

// Filter dropdown (ui_cs_filter): 0 = All, 1 = Half-Life, 2 = Deathmatch, 3 = Quake
float UI_Create_PassesFilter(entity m)
{
	float f = cvar("ui_cs_filter");
	if (f <= 0) return TRUE;
	if (f == 1) return (m.cs_kind == CSMAP_HL);
	if (f == 2) return (m.cs_kind == CSMAP_MP);
	return (m.cs_kind == CSMAP_Q1);
}

void UI_Create_AddMap(string nm)
{
	if (strlen(nm) <= 0) return;
	// b_*.bsp are Quake's brush-model pickups, not playable levels.
	if (substring(nm, 0, 2) == "b_") return;

	entity m = find(world, cs_map, nm);
	if (m) return; // same map present in both a pk3 and the gamedir

	m = spawn();
	m.classname = "csmap";
	m.cs_map = strzone(nm);
	m.cs_kind = UI_Create_Classify(nm);
	UI_cs_count = UI_cs_count + 1;
}

void UI_Create_ScanMaps()
{
	UI_cs_scanned = 1;
	UI_cs_count = 0;

	float h = search_begin("maps/*.bsp", TRUE, TRUE);
	if (h >= 0)
	{
		float n = search_getsize(h);
		for (float i = 0; i < n; i++)
		{
			string full = search_getfilename(h, i);
			// "maps/name.bsp" -> "name"
			float slash = strstrofs(full, "/", 0);
			string nm = substring(full, slash + 1, strlen(full) - (slash + 1) - 4);
			UI_Create_AddMap(strtolower(nm));
		}
		search_end(h);
	}

	// Search builtin missing or the search path is empty: keep the dialog usable.
	if (UI_cs_count <= 0)
	{
		UI_Create_AddMap("c0a0");
		UI_Create_AddMap("t0a0");
		UI_Create_AddMap("crossfire");
		UI_Create_AddMap("stalkyard");
		UI_Create_AddMap("boot_camp");
		UI_Create_AddMap("undertow");
		UI_Create_AddMap("e1m1");
	}
}

void UI_Create_StartServer()
{
	ui_clicked = FALSE;
	ui_mouse1_held = FALSE;
	if (strlen(UI_cs_selected) <= 0) return;

	float mode = cvar("ui_cs_mode");
	float maxp = rint(cvar("ui_cs_maxplayers"));
	if (maxp < 2) maxp = 2;
	if (maxp > UI_Create_MaxPlayerCap()) maxp = UI_Create_MaxPlayerCap();

	// combat.qc treats teamplay != 0 as "no damage between team-mates", so the
	// friendly-fire checkbox is the inverse of it.
	float ff = cvar("ui_cs_friendlyfire");

	float gm = CS_MODE_COOP;
	float coop = 1, dm = 0, tp = (ff ? 0 : 1);
	if (mode == 1) { gm = CS_MODE_DM; coop = 0; dm = 1; tp = 0; }

	cmd("disconnect\n");
	cmd(strcat("maxplayers ", ftos(maxp), "\n"));
	cmd(strcat("gamemode ", ftos(gm), "\n"));
	cmd(strcat("coop ", ftos(coop), "; deathmatch ", ftos(dm), "; teamplay ", ftos(tp), "\n"));
	cmd(strcat("sv_public ", (cvar("ui_cs_public") ? "1" : "0"), "\n"));
	cmd(strcat("password \"", cvar_string("ui_cs_password"), "\"\n"));
	cmd(strcat("sv_cheats ", (cvar("ui_cs_cheats") ? "1" : "0"), "\n"));
	cmd(strcat("map ", UI_cs_selected, "\n"));

	m_toggle(0);
}

void UI_Create_MapTable(vector pos, vector size)
{
	if (!UI_cs_scanned) UI_Create_ScanMaps();

	float row_h = ui_font_size * 1.15;
	float header_h = ui_font_size * 1.2;

	UI_FrameInput(pos, size);
	drawfill(pos, [size_x, header_h, 0], '0 0 0', 0.22, 0);

	float col_name = size_x * 0.55;

	UI_Text("Map", pos + [ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Type", pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');

	vector list_pos = pos + [0, header_h, 0];
	vector list_size = [size_x, size_y - header_h, 0];

	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;

	// count filtered rows first so the scrollbar / clamping is accurate
	float total = 0;
	entity m = find(world, classname, "csmap");
	while (m)
	{
		if (UI_Create_PassesFilter(m)) total = total + 1;
		m = find(m, classname, "csmap");
	}

	float maxscroll = total - visible;
	if (maxscroll < 0) maxscroll = 0;

	float can_input = !UI_IsBehindWindow();
	float over_list = can_input && UI_MouseInRect(list_pos, list_pos + list_size);
	if (over_list) UI_cs_scroll = UI_ScrollList(UI_cs_scroll, list_pos, list_size, maxscroll);
	if (UI_cs_scroll < 0) UI_cs_scroll = 0;
	if (UI_cs_scroll > maxscroll) UI_cs_scroll = maxscroll;

	float start = UI_cs_scroll;
	float end = start + visible;

	float r = 0, idx = 0;
	m = find(world, classname, "csmap");
	while (m)
	{
		if (UI_Create_PassesFilter(m))
		{
			if (idx >= start && idx < end)
			{
				vector row_pos = list_pos + [0, row_h * r, 0];
				vector row_size = [list_size_x, row_h, 0];
				float hover = can_input && UI_MouseInRectSize(row_pos, row_size);

				if (UI_cs_selected == m.cs_map)
					drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.70, 0);
				else if (hover)
					drawfill(row_pos, row_size, '1 1 1', 0.05, 0);

				UI_Text(m.cs_map, row_pos + [ui_font_size * 0.4, ui_font_size * 0.10, 0]);
				UI_Text(UI_Create_KindName(m.cs_kind),
						row_pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');

				if (hover && ui_clicked)
				{
					// click selects, clicking the selected row starts the server
					if (UI_cs_selected == m.cs_map) UI_Create_StartServer();
					else UI_cs_selected = m.cs_map;
					ui_clicked = 0;
				}

				r = r + 1;
			}
			idx = idx + 1;
		}
		m = find(m, classname, "csmap");
	}

	if (total <= 0)
		UI_Text("No maps found.", list_pos + [ui_font_size * 0.4, ui_font_size * 0.4, 0], UI_TEXT_INACTIVE);

	UI_DrawScrollbar(list_pos + [list_size_x - ui_font_size * 0.6, 0, 0], list_size_y, total, visible, UI_cs_scroll);
}

void UI_DrawCreateContents()
{
	vector pos = win_create.ui_win_pos;
	vector size = win_create.ui_win_size;

	float fs = ui_font_size;
	vector base = pos + [fs * 0.5, fs * 2, 0];

	// tab strip
	vector tab_size = [fs * 4, fs, 0];
	float tab_step = fs * 4.1;
	vector tab_ofs = base + [0, 1, 0];

	UI_Button2("Server", tab_ofs, tab_size, UI_SelectCreatePage, ftos(CREATE_SERVER));
	UI_Button2("Game", tab_ofs + [tab_step, 0, 0], tab_size, UI_SelectCreatePage, ftos(CREATE_GAME));

	UI_Frame(base + [0, fs, 0], size - [fs * 1, fs * 5, 0], FALSE);
	drawfill(tab_ofs + [1, tab_size_y - 1, 0] + [tab_step * create_page, 0, 0], [tab_size_x, 2, 0],
			 UI_WINDOW_BACKGROUND, UI_WINDOW_BACKGROUND_ALPHA, 0);

	vector in = base + [fs * 0.8, fs * 1.8, 0];
	float rcol = fs * 18;          // right column x offset
	float rw = fs * 10.5;          // right column width

	if (create_page == CREATE_SERVER)
	{
		UI_Text("Server name", in, UI_TEXT_HIGHLIGHTED);
		UI_InputText("hostname", in + [0, fs * 1.1, 0], 17, "");

		UI_Create_MapTable(in + [0, fs * 2.9, 0], [fs * 17, fs * 13.5, 0]);

		UI_Text("Game mode", in + [rcol, 0, 0], UI_TEXT_HIGHLIGHTED);
		UI_Dropdown("ui_cs_mode", in + [rcol, fs * 0.9, 0], rw, "Cooperative|Deathmatch");

		UI_Text("Show maps", in + [rcol, fs * 3, 0], UI_TEXT_HIGHLIGHTED);
		UI_Dropdown("ui_cs_filter", in + [rcol, fs * 3.9, 0], rw, "All|Half-Life|Deathmatch|Quake");

		UI_Text("Network", in + [rcol, fs * 6, 0], UI_TEXT_HIGHLIGHTED);
		UI_Dropdown("ui_cs_public", in + [rcol, fs * 6.9, 0], rw, "LAN only|Internet");

		float capMax = UI_Create_MaxPlayerCap();
		if (cvar("ui_cs_maxplayers") > capMax) cvar_set("ui_cs_maxplayers", ftos(capMax));
		UI_Text(strcat("Max players: ", ftos(rint(cvar("ui_cs_maxplayers")))),
		        in + [rcol, fs * 9, 0], UI_TEXT_HIGHLIGHTED);
		UI_Slider(in + [rcol, fs * 10.1, 0], [rw, 2, 0], "ui_cs_maxplayers", 2, capMax, 1);

		UI_Text("Password (optional)", in + [rcol, fs * 12, 0], UI_TEXT_HIGHLIGHTED);
		UI_InputText("ui_cs_password", in + [rcol, fs * 12.9, 0], 10, "");

		if (cvar("ui_cs_public") && strlen(cvar_string("steam_steamid")) < 3)
		{
			UI_Text(strcat("Forward UDP port ", ftos(cvar("port"))), in + [rcol, fs * 14.6, 0], UI_TEXT_INACTIVE);
			UI_Text("to be listed online.", in + [rcol, fs * 15.7, 0], UI_TEXT_INACTIVE);
		}
	}
	else
	{
		UI_Text("Skill", in, UI_TEXT_HIGHLIGHTED);
		UI_Dropdown("skill", in + [0, fs * 0.9, 0], rw, "Easy|Medium|Hard");

		UI_Text("Frag limit", in + [0, fs * 3, 0], UI_TEXT_HIGHLIGHTED);
		UI_Slider(in + [0, fs * 4.1, 0], [rw, 2, 0], "fraglimit", 0, 100, 1);

		UI_Text("Time limit (minutes)", in + [0, fs * 6, 0], UI_TEXT_HIGHLIGHTED);
		UI_Slider(in + [0, fs * 7.1, 0], [rw, 2, 0], "timelimit", 0, 60, 1);

		UI_Text("Options", in + [rcol, 0, 0], UI_TEXT_HIGHLIGHTED);
		UI_Checkbox("Friendly fire", in + [rcol, fs * 1.1, 0], "ui_cs_friendlyfire");
		UI_Checkbox("Allow cheats", in + [rcol, fs * 2.6, 0], "ui_cs_cheats");
	}

	// selected map readout + buttons
	vector button_size = [fs * 3.5, fs * 1.25, 0];
	vector btn_base = pos + size - button_size - [fs * 0.8, fs * 0.5, 0];

	string sel = UI_cs_selected;
	if (strlen(sel) <= 0) sel = "<none>";
	UI_Text(strcat("Map: ", sel), pos + [fs * 0.8, size_y - fs * 1.4, 0], '0.85 0.85 0.85');

	UI_Button2("Start", btn_base - [fs * 4.0, 0, 0], button_size, UI_Create_StartServer, "");
	UI_Button2("Cancel", btn_base, button_size, UI_ToggleWindow, "Create server");
}
