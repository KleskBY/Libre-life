
/////////////////////////////////////////////////////////////////////
//////////////////////////   WINDOWS  ///////////////////////////////
/////////////////////////////////////////////////////////////////////

entity UI_CreateWindow(string name, vector size)
{
	entity w = spawn();
	w.classname = "window";
	w.UI_win_name = name;
	w.UI_win_size = size;
	w.UI_win_pos = [ (vid_x - size_x) * 0.5, (vid_y - size_y) * 0.5, 0 ];
	w.UI_win_open = 0;
	w.UI_win_draggable = 1;
	UI_z_counter = UI_z_counter + 1;
	w.UI_win_z = UI_z_counter;
	w.UI_win_next = UI_windows;
	UI_windows = w;
	return w;
}


entity UI_FindWindow(string name)
{
	for (entity w = UI_windows; w; w = w.UI_win_next)
		if (w.UI_win_name == name)
			return w;
	return world;
}


void UI_BringToFront(entity w)
{
	if (!w) return;
	UI_z_counter = UI_z_counter + 1;
	w.UI_win_z = UI_z_counter;
	UI_active_window = w;
}


void UI_OpenWindow(string name)
{
	entity w = UI_FindWindow(name);
	if (!w) return;
	w.UI_win_open = 1;
	UI_BringToFront(w);
}

void UI_CloseWindow(string name)
{
	entity w = UI_FindWindow(name);
	if (!w) return;
	w.UI_win_open = 0;

	if (UI_active_window == w)
	{
		UI_active_window = world;
		UI_win_dragging = 0;
	}
}

void UI_ToggleWindowByName(string name)
{
	entity w = UI_FindWindow(name);
	if (!w) return;

	if (w.UI_win_open) UI_CloseWindow(name);
	else UI_OpenWindow(name);
}

void UI_ToggleWindow()
{
	UI_ToggleWindowByName(exec);
}


entity UI_GetTopOpenWindow()
{
	entity best = world;
	float bestZ = -99999999;

	for (entity w = UI_windows; w; w = w.UI_win_next)
	{
		if (!w.UI_win_open) continue;
		if (w.UI_win_z > bestZ)
		{
			bestZ = w.UI_win_z;
			best = w;
		}
	}
	return best;
}


float UI_PointInRect(vector p, vector a, vector b)
{
	// a = top-left, b = bottom-right
	if (p_x < a_x || p_x > b_x) return 0;
	if (p_y < a_y || p_y > b_y) return 0;
	return 1;
}

void UI_DrawWindowFrame(entity w, string title)
{
	vector pos = w.UI_win_pos;
	vector size = w.UI_win_size;
	UI_Frame(pos, size, FALSE);
	//drawfill(pos, [size_x, font_size * 1.6, 0], '0.08 0.08 0.08', 0.85, 0); //title background

	UI_Text(title, pos + [font_size * 0.6, font_size * 0.3, 0]);

	// close button hitbox (top-right)
	vector cpos = pos + [size_x - font_size * 1.6, 0, 0];
	UI_Button2("x", cpos + [font_size * 0.35, font_size * 0.25, 0], [font_size, font_size], UI_ToggleWindow, title); // visual only

	// focus / bring to front when clicked anywhere inside window
	if (w.UI_win_open)
	{
		vector br = pos + size;
		if (UI_PointInRect(mouse_pos, pos, br) && clicked)
		{
			UI_BringToFront(w);
		}
	}
	else return;

	if (w.UI_win_draggable) // drag (title bar area)
	{
		if (UI_IsBehindWindow()) return;
		vector barA = pos;
		vector barB = pos + [size_x, font_size * 1.6, 0];

		if (!UI_win_dragging && mouse1_held && UI_PointInRect(mouse_pos, barA, barB))
		{
			UI_BringToFront(w);
			UI_active_window = w;
			UI_win_dragging = 1;
			UI_win_drag_offset = mouse_pos - w.UI_win_pos;

			// prevent a titlebar click from also triggering a control
			clicked = 0;
		}

		if (UI_win_dragging && UI_active_window == w)
		{
			if (!mouse1_held)
			{
				UI_win_dragging = 0;
			}
			else
			{
				w.UI_win_pos = mouse_pos - UI_win_drag_offset;

				// clamp to screen (optional)
				if (w.UI_win_pos_x < 0) w.UI_win_pos_x = 0;
				if (w.UI_win_pos_y < 0) w.UI_win_pos_y = 0;
				if (w.UI_win_pos_x + size_x > vid_x) w.UI_win_pos_x = vid_x - size_x;
				if (w.UI_win_pos_y + size_y > vid_y) w.UI_win_pos_y = vid_y - size_y;
			}
		}
	}
}

float UI_MouseInWindow(entity w)
{
	vector a = w.UI_win_pos;
	vector b = w.UI_win_pos + w.UI_win_size;
	if (mouse_pos_x < a_x || mouse_pos_x > b_x) return 0;
	if (mouse_pos_y < a_y || mouse_pos_y > b_y) return 0;
	return 1;
}

entity UI_TopWindowUnderMouse()
{
	entity best = world;
	float bestZ = -99999999;

	for (entity w = UI_windows; w; w = w.UI_win_next)
	{
		if (!w.UI_win_open) continue;
		if (!UI_MouseInWindow(w)) continue;

		if (w.UI_win_z > bestZ)
		{
			bestZ = w.UI_win_z;
			best = w;
		}
	}
	return best;
}


entity UI_FindNextWindowToDraw(float lastZ)
{
	entity best = world;
	float bestZ = 99999999;

	for (entity w = UI_windows; w; w = w.UI_win_next)
	{
		if (!w.UI_win_open) continue;

		float z = w.UI_win_z;
		if (z >= lastZ && z < bestZ)
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

void UI_DrawWindows()
{
	// topmost open window (drawn last)
	UI_top_window = UI_GetTopOpenWindow();

	// If mouse is over ANY window, block background clicks and lower windows.
	// Input goes only to the top window.
	UI_input_window = world;
	UI_input_blocked = 0;

	entity under = UI_TopWindowUnderMouse(); // you already have this
	if (under)
	{
		UI_input_blocked = 1;
		UI_input_window = UI_top_window;
	}

	// draw open windows by increasing z (older first), newest last on top
	float z = -99999999;
	for (float guard = 0; guard < UI_WindowCount(); guard++)
	{
		entity w = UI_FindNextWindowToDraw(z);
		if (!w) break;
		z = w.UI_win_z + 0.0001;
		UI_draw_window = w;
		UI_DrawWindowFrame(w, w.UI_win_name);
		if (w.UI_win_draw)
			w.UI_win_draw();
		UI_draw_window = world;
	}

}
