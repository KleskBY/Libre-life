
// LOAD GAME UI state
string UI_load_rows;          // rows encoded: "slot^name^type^elapsed^stamp;..."
float UI_load_count;
float UI_load_scroll;         // first visible row
string SelectedSave;
float UI_MAX_SLOTS = 50;

// table behavior
entity UI_Saves;
.string filename;
.string title;
.string kills;
.entity chain;

string UI_LoadGame_ReadTitle(string filename)
{
	string title = "";
	float h = fopen(filename, FILE_READ);
	if (h < 0) return title;

	string line1 = fgets(h);
	string line2 = fgets(h);
	fclose(h);

	title = line2;
	title = strreplace("_", " ", title);
	return title;
}

void UI_LoadSelectedGame()
{
	clicked = FALSE;
	mouse1_held = FALSE;
	string cmdline = strcat("maxplayers 1; sv_cheats 1; deathmatch 0; coop 0; maxplayers 1; r_ambient 3; load ", SelectedSave, "\n");
	cmd(cmdline);
	m_toggle(1);

}

void UI_LoadGame_ClearSaves()
{
	entity s = find(world, classname, "save");
	while (s)
	{
		entity next = find(s, classname, "save");
		remove(s);
		s = next;
	}
	UI_Saves = world;
}
void UI_UpdateSaves()
{
	UI_LoadGame_ClearSaves();
	UI_load_rows = "";
	UI_load_count = 0;

	string fn;
	string save_name;
	string save_kills;
	for (float i = UI_MAX_SLOTS; i >= 0; i--)
	{
		fn = strzone(strcat(ftos(i), ".sav"));
		save_name = strzone(UI_LoadGame_ReadTitle(fn));
		
		if (strlen(save_name) <= 0)
			continue;
				
		save_kills = strzone(substring(save_name, -17, 17));
		save_name = strzone(substring(save_name, 0, 22));

		entity save = world;
		save = find(save, filename, fn);
		if(!save) 
		{
			save = spawn();
			save.chain = UI_Saves;
			UI_Saves = save;
		}
		save.classname = "save";
		save.filename = fn;
		save.title = save_name;
		save.kills = save_kills;

		UI_load_count = UI_load_count + 1;
	}
}


void UI_LoadGame_Table(vector pos, vector size)
{
	float row_h = font_size * 1.15;
	float header_h = font_size * 1.2;

	UI_FrameInput(pos, size);
	drawfill(pos, [size_x, header_h, 0], '0 0 0', 0.22, 0);

	float col_name = size_x * 0.5;
	float col_type = size_x * 0.25;
	float col_elapsed = size_x * 0.25;

	UI_Text("Saved Game",   pos + [font_size * 0.4, font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Progress",         pos + [col_name + font_size * 0.4, font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("File", pos + [col_name + col_type + font_size * 0.4, font_size * 0.12, 0], '0.85 0.85 0.85');

	// list area
	vector list_pos = pos + [0, header_h, 0];
	vector list_size = [size_x, size_y - header_h, 0];
	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;

	// Scroll
	float maxscroll = UI_load_count - visible;
	if (maxscroll < 0) maxscroll = 0;
	float over_list = UI_MouseInRect(list_pos, list_pos + list_size) && !UI_IsBehindWindow();
	if(over_list) UI_load_scroll = UI_ScrollList(UI_load_scroll, list_pos, list_size, maxscroll);


	float r, idx;
	float start = UI_load_scroll;
	float end = start + visible;
	entity s = find(world, classname, "save");
	while (s)
	{
		if (idx >= start && idx < end)
		{
			vector row_pos = list_pos + [0, row_h * r, 0];
			vector row_size = [list_size_x, row_h, 0];

			float hover = !UI_IsBehindWindow() && UI_MouseInRectSize(row_pos, row_size);
			if (SelectedSave == s.filename)
				drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.70, 0);
			else if (hover)
				drawfill(row_pos, row_size, '1 1 1', 0.05, 0);

			UI_Text(s.title, row_pos + [font_size * 0.4, font_size * 0.10, 0]);
			UI_Text(s.kills, row_pos + [col_name + font_size * 0.4, font_size * 0.10, 0], '0.9 0.9 0.9');
			UI_Text(s.filename, row_pos + [col_name + col_type + font_size * 0.4, font_size * 0.10, 0], '0.9 0.9 0.9');
			
			if (!UI_IsBehindWindow() && hover && clicked)
			{
				if(SelectedSave == s.filename)
				{
					UI_LoadSelectedGame();
				}
				else SelectedSave = s.filename;
				clicked = 0;
			}
			
			r = r + 1;
		}
		idx = idx + 1;
		s = find(s, classname, "save");
	}

	UI_Scrollbar(UI_load_count, visible, list_size, list_pos, maxscroll);
}




entity win_loadgame;
void UI_DrawLoadGameContents()
{
	vector pos = win_loadgame.UI_win_pos;
	vector size = win_loadgame.UI_win_size;

	vector base = pos + [font_size * 0.8, font_size * 2.0, 0];

	UI_Text("Select a saved game in the list below, then press Load game!", base, '0.85 0.85 0.85');

	vector panel_pos = base + [0, font_size * 1.3, 0];
	vector panel_size = [size_x - font_size * 1.6, size_y - font_size * 5.5, 0];
	UI_LoadGame_Table(panel_pos, panel_size);

	vector button_size = [font_size * 3, font_size * 1.25];
	base = win_loadgame.UI_win_pos + win_loadgame.UI_win_size - button_size - [font_size * 0.8, font_size * 0.5];
	UI_Button2("Cancel", base - [font_size * 3.5 ], button_size,  UI_ToggleWindow, "Load Game");
	UI_Button2("Load", base, button_size, UI_LoadSelectedGame, "");
}
