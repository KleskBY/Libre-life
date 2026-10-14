
float UI_Save_FindFreeSlot()
{
	for (float i = 0; i < UI_MAX_SLOTS; i++)
	{
		float h = fopen(strcat(ftos(i), ".sav"), FILE_READ);
		if (h < 0) return i;
		fclose(h);
	}
	return -1; // none free
}


void UI_SaveSelectedGame()
{
	ui_clicked = FALSE;
	ui_mouse1_held = FALSE;
	if (strlen(ui_selectedSave) <= 0) return;

	string cmdline = strcat("gamesave ", ui_selectedSave, "\n");
	cmd(cmdline);
	m_toggle(1);
	UI_UpdateSaves();
}


void UI_SaveGame_Table(vector pos, vector size)
{
	float row_h = ui_font_size * 1.15;
	float header_h = ui_font_size * 1.2;

	UI_FrameInput(pos, size);
	drawfill(pos, [size_x, header_h, 0], '0 0 0', 0.22, 0);

	float col_name = size_x * 0.5;
	float col_type = size_x * 0.25;
	float col_elapsed = size_x * 0.25;

	UI_Text("Saved Game", pos + [ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Progress",  pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("File",      pos + [col_name + col_type + ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');

	vector list_pos = pos + [0, header_h, 0];
	vector list_size = [size_x, size_y - header_h, 0];

	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;

	float freeSlot = UI_Save_FindFreeSlot();
	float hasNew = (freeSlot >= 0);

	// total rows includes optional "New saved game"
	float total = ui_load_count + hasNew;

	float maxscroll = total - visible;
	if (maxscroll < 0) maxscroll = 0;

	float over_list = UI_MouseInRect(list_pos, list_pos + list_size) && !UI_IsBehindWindow();
	if (over_list) ui_load_scroll = UI_ScrollList(ui_load_scroll, list_pos, list_size, maxscroll);

	if (ui_load_scroll < 0) ui_load_scroll = 0;
	if (ui_load_scroll > maxscroll) ui_load_scroll = maxscroll;

	float start = ui_load_scroll;
	float end = start + visible;

	float r = 0;
	float idx = 0;

	// helper: draw one row
	// Row 0: New saved game
	while (idx < total)
	{
		if (idx >= start && idx < end)
		{
			vector row_pos = list_pos + [0, row_h * r, 0];
			vector row_size = [list_size_x, row_h, 0];
			float hover = !UI_IsBehindWindow() && UI_MouseInRectSize(row_pos, row_size);

			if (hasNew && idx == 0)
			{
				string newSlotStr = ftos(freeSlot);
				string fileLabel = strcat(newSlotStr, ".sav"); // display only

				if (ui_selectedSave == newSlotStr)
					drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.70, 0);
				else if (hover)
					drawfill(row_pos, row_size, '1 1 1', 0.05, 0);

				UI_Text("New saved game", row_pos + [ui_font_size * 0.4, ui_font_size * 0.10, 0]);
				UI_Text("-",              row_pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');
				UI_Text(fileLabel,        row_pos + [col_name + col_type + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');

				if (hover && ui_clicked)
				{
					// select / double click saves immediately (same behavior you used)
					if (ui_selectedSave == newSlotStr) UI_SaveSelectedGame();
					else ui_selectedSave = newSlotStr;
					ui_clicked = 0;
				}

				r = r + 1;
			}
			else
			{
				float realIndex = idx - hasNew; // subtract 1 if "New" exists
				float cur = 0;

				entity s = find(world, classname, "save");
				while (s)
				{
					if (cur == realIndex) break;
					cur = cur + 1;
					s = find(s, classname, "save");
				}

				if (s)
				{
					// IMPORTANT: for save selection, ui_selectedSave should be slot number, not filename
					// If your save entity doesn't have slot, derive it from filename "N.sav"
					string slotStr = substring(s.filename, 0, strstrofs(s.filename, ".", 0));

					if (ui_selectedSave == slotStr)
						drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.70, 0);
					else if (hover)
						drawfill(row_pos, row_size, '1 1 1', 0.05, 0);

					UI_Text(s.title,    row_pos + [ui_font_size * 0.4, ui_font_size * 0.10, 0]);
					UI_Text(s.save_killStats,    row_pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');
					UI_Text(s.filename, row_pos + [col_name + col_type + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');

					if (hover && ui_clicked)
					{
						if (ui_selectedSave == slotStr) UI_SaveSelectedGame();
						else ui_selectedSave = slotStr;
						ui_clicked = 0;
					}
				}

				r = r + 1;
			}
		}

		idx = idx + 1;
	}

}


void UI_SaveGame_Table2(vector pos, vector size)
{
	float row_h = ui_font_size * 1.15;
	float header_h = ui_font_size * 1.2;

	UI_FrameInput(pos, size);
	drawfill(pos, [size_x, header_h, 0], '0 0 0', 0.22, 0);

	float col_name = size_x * 0.5;
	float col_type = size_x * 0.25;
	float col_elapsed = size_x * 0.25;

	UI_Text("Saved Game",   pos + [ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Progress",         pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("File", pos + [col_name + col_type + ui_font_size * 0.4, ui_font_size * 0.12, 0], '0.85 0.85 0.85');

	// list area
	vector list_pos = pos + [0, header_h, 0];
	vector list_size = [size_x, size_y - header_h, 0];
	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;

	// Scroll
	float maxscroll = ui_load_count - visible;
	if (maxscroll < 0) maxscroll = 0;
	float over_list = UI_MouseInRect(list_pos, list_pos + list_size) && !UI_IsBehindWindow();
	if(over_list) ui_load_scroll = UI_ScrollList(ui_load_scroll, list_pos, list_size, maxscroll);

	float r, idx;
	float start = ui_load_scroll;
	float end = start + visible;
	entity s = find(world, classname, "save");
	while (s)
	{
		if (idx >= start && idx < end)
		{
			vector row_pos = list_pos + [0, row_h * r, 0];
			vector row_size = [list_size_x, row_h, 0];

			float hover = !UI_IsBehindWindow() && UI_MouseInRectSize(row_pos, row_size);
			if (ui_selectedSave == s.filename)
				drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.70, 0);
			else if (hover)
				drawfill(row_pos, row_size, '1 1 1', 0.05, 0);

			UI_Text(s.title, row_pos + [ui_font_size * 0.4, ui_font_size * 0.10, 0]);
			UI_Text(s.save_killStats, row_pos + [col_name + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');
			UI_Text(s.filename, row_pos + [col_name + col_type + ui_font_size * 0.4, ui_font_size * 0.10, 0], '0.9 0.9 0.9');
			
			if (!UI_IsBehindWindow() && hover && ui_clicked)
			{
				if(ui_selectedSave == s.filename)
				{
					UI_SaveSelectedGame();
				}
				else ui_selectedSave = s.filename;
				ui_clicked = 0;
			}
			
			r = r + 1;
		}
		idx = idx + 1;
		s = find(s, classname, "save");
	}

}


entity win_savegame;
void UI_DrawSaveGameContents()
{
	vector pos = win_savegame.ui_win_pos;
	vector size = win_savegame.ui_win_size;
	vector base = pos + [ui_font_size * 0.8, ui_font_size * 2.0, 0];

	UI_Text("Select 'New saved game' in the list to create a new file.", base, '0.85 0.85 0.85');

	vector panel_pos = base + [0, ui_font_size * 1.3, 0];
	vector panel_size = [size_x - ui_font_size * 1.6, size_y - ui_font_size * 5.5, 0];
	UI_SaveGame_Table(panel_pos, panel_size);

	vector button_size = [ui_font_size * 3, ui_font_size * 1.25, 0];
	vector btn_base = pos + size - button_size - [ui_font_size * 0.8, ui_font_size * 0.5, 0];

	UI_Button2("Cancel", btn_base - [ui_font_size * 3.5, 0, 0], button_size, UI_ToggleWindow, "Save Game");
	UI_Button2("Save",   btn_base,                         button_size, UI_SaveSelectedGame, "");
}
