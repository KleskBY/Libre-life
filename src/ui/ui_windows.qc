
//////////////////////////   WINDOWS  ///////////////////////////////

entity UI_CreateWindow(string name, vector size)
{
	entity w = spawn();
	w.classname = "window";
	w.ui_win_name = name;
	w.ui_win_size = size;
	w.ui_win_size_mult = [size_x / ui_font_size, size_y / ui_font_size, 0];
	w.ui_win_pos = [ (ui_vid_x - size_x) * 0.5, (ui_vid_y - size_y) * 0.5, 0 ];
	w.ui_win_open = 0;
	w.ui_win_draggable = 1;
	ui_z_counter = ui_z_counter + 1;
	w.ui_win_z = ui_z_counter;
	w.ui_win_next = ui_windows;
	ui_windows = w;
	return w;
}

entity UI_FindWindow(string name)
{
	for (entity w = ui_windows; w; w = w.ui_win_next)
		if (w.ui_win_name == name)
			return w;
	return world;
}

void UI_BringToFront(entity w)
{
	if (!w) return;
	ui_z_counter = ui_z_counter + 1;
	w.ui_win_z = ui_z_counter;
	ui_active_window = w;
}

void UI_OpenWindow(string name)
{
	entity w = UI_FindWindow(name);
	if (!w) return;
	w.ui_win_open = 1;
	UI_BringToFront(w);
}

void UI_CloseWindow(string name)
{
	entity w = UI_FindWindow(name);
	if (!w) return;
	w.ui_win_open = 0;

	if (ui_active_window == w)
	{
		ui_active_window = world;
		ui_win_dragging = 0;
	}
}

void UI_ToggleWindowByName(string name)
{
	entity w = UI_FindWindow(name);
	if (!w) return;

	if (w.ui_win_open) UI_CloseWindow(name);
	else UI_OpenWindow(name);
}

void UI_ToggleWindow()
{
	UI_ToggleWindowByName(ui_exec);
}

entity UI_GetTopOpenWindow()
{
	entity best = world;
	float bestZ = -99999999;

	for (entity w = ui_windows; w; w = w.ui_win_next)
	{
		if (!w.ui_win_open) continue;
		if (w.ui_win_z > bestZ)
		{
			bestZ = w.ui_win_z;
			best = w;
		}
	}
	return best;
}

float UI_PointInRect(vector p, vector a, vector b)
{
	if (p_x < a_x || p_x > b_x) return 0;
	if (p_y < a_y || p_y > b_y) return 0;
	return 1;
}

void UI_DrawWindowFrame(entity w, string title)
{
	vector pos = w.ui_win_pos;
	vector size = w.ui_win_size;
	UI_Frame(pos, size, FALSE);

	UI_Text(title, pos + [ui_font_size * UI_WIN_TITLE_X_PAD, ui_font_size * UI_WIN_TITLE_Y_PAD, 0]);

	// close button (top-right)
	vector cpos = pos + [size_x - ui_font_size * UI_WIN_CLOSE_PAD, 0, 0];
	UI_Button2("x", cpos + [ui_font_size * 0.35, ui_font_size * 0.25, 0], [ui_font_size, ui_font_size], UI_ToggleWindow, w.ui_win_name);

	if (w.ui_win_open)
	{
		vector br = pos + size;
		if (UI_PointInRect(ui_mouse_pos, pos, br) && ui_clicked && !UI_IsBehindWindow())
		{
			UI_BringToFront(w);
		}
	}
	else return;

	if (w.ui_win_draggable)
	{
		if (UI_IsBehindWindow()) return;
		vector barA = pos;
		vector barB = pos + [size_x, ui_font_size * UI_WIN_TITLEBAR_H_MULT, 0];

		if (!ui_win_dragging && ui_clicked && UI_PointInRect(ui_mouse_pos, barA, barB))
		{
			UI_BringToFront(w);
			ui_active_window = w;
			ui_win_dragging = 1;
			ui_win_drag_offset = ui_mouse_pos - w.ui_win_pos;

			ui_clicked = 0;
		}

		if (ui_win_dragging && ui_active_window == w)
		{
			if (!ui_mouse1_held)
			{
				ui_win_dragging = 0;
			}
			else
			{
				w.ui_win_pos = ui_mouse_pos - ui_win_drag_offset;

				if (w.ui_win_pos_x < 0) w.ui_win_pos_x = 0;
				if (w.ui_win_pos_y < 0) w.ui_win_pos_y = 0;
				if (w.ui_win_pos_x + size_x > ui_vid_x) w.ui_win_pos_x = ui_vid_x - size_x;
				if (w.ui_win_pos_y + size_y > ui_vid_y) w.ui_win_pos_y = ui_vid_y - size_y;
			}
		}
	}
}

float UI_MouseInWindow(entity w)
{
	vector a = w.ui_win_pos;
	vector b = w.ui_win_pos + w.ui_win_size;
	if (ui_mouse_pos_x < a_x || ui_mouse_pos_x > b_x) return 0;
	if (ui_mouse_pos_y < a_y || ui_mouse_pos_y > b_y) return 0;
	return 1;
}

entity UI_TopWindowUnderMouse()
{
	entity best = world;
	float bestZ = -99999999;

	for (entity w = ui_windows; w; w = w.ui_win_next)
	{
		if (!w.ui_win_open) continue;
		if (!UI_MouseInWindow(w)) continue;

		if (w.ui_win_z > bestZ)
		{
			bestZ = w.ui_win_z;
			best = w;
		}
	}
	return best;
}


entity UI_FindNextWindowToDraw(float lastZ)
{
	entity best = world;
	float bestZ = 99999999;

	for (entity w = ui_windows; w; w = w.ui_win_next)
	{
		if (!w.ui_win_open) continue;

		float z = w.ui_win_z;
		if (z > lastZ && z < bestZ)
		{
			bestZ = z;
			best = w;
		}
	}
	return best;
}

float UI_WindowCount()
{
	float window_count;
	entity w = find(world, classname, "window");
	while (w)
	{
		window_count = window_count + 1;
		w = find(w, classname, "window");
	}
	return window_count;
}

void UI_RefreshWindowSizes()
{
	for (entity w = ui_windows; w; w = w.ui_win_next)
	{
		w.ui_win_size_x = rint(w.ui_win_size_mult_x * ui_font_size);
		w.ui_win_size_y = rint(w.ui_win_size_mult_y * ui_font_size);

		w.ui_win_pos_x = rint((ui_vid_x - w.ui_win_size_x) * 0.5);
		w.ui_win_pos_y = rint((ui_vid_y - w.ui_win_size_y) * 0.5);

		if (w.ui_win_pos_x < 0) w.ui_win_pos_x = 0;
		if (w.ui_win_pos_y < 0) w.ui_win_pos_y = 0;
	}
}

void UI_DrawWindows()
{
	// topmost open window (drawn last)
	ui_top_window = UI_GetTopOpenWindow();

	ui_input_window = world;
	ui_input_blocked = 0;

	entity under = UI_TopWindowUnderMouse();
	if (under)
	{
		ui_input_blocked = 1;
		ui_input_window = under;
	}

	float z = -99999999;
	float wcount = UI_WindowCount();
	for (float guard = 0; guard < wcount; guard++)
	{
		entity w = UI_FindNextWindowToDraw(z);
		if (!w) break;
		z = w.ui_win_z;
		ui_draw_window = w;
		drawsetcliparea(w.ui_win_pos_x, w.ui_win_pos_y, w.ui_win_size_x, w.ui_win_size_y);
		UI_DrawWindowFrame(w, w.ui_win_name);

		// Reserve click for dropdown overlay if mouse is in open dropdown list area
		float _reserved_click = 0;
		if (ui_dropdown_open && ui_dropdown_owner == w && ui_clicked)
		{
			float _vis = UI_DROPDOWN_VISIBLE;
			if (_vis > ui_dropdown_count) _vis = ui_dropdown_count;
			vector _lpos = ui_dropdown_pos + [0, ui_dropdown_row_h, 0];
			vector _lsz  = [ui_dropdown_width, ui_dropdown_row_h * _vis, 0];
			if (UI_MouseInRectSize(_lpos, _lsz))
			{
				_reserved_click = ui_clicked;
				ui_clicked = 0;
			}
		}

		if (w.ui_win_draw)
			w.ui_win_draw();
		drawresetcliparea();

		// Draw the open dropdown list as an overlay (no clip, always on top).
		if (ui_dropdown_open && ui_dropdown_owner == w)
		{
			if (_reserved_click) ui_clicked = _reserved_click;
			UI_DrawDropdownOverlay();
		}

		ui_draw_window = world;
	}

}
