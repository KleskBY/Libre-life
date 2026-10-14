
//////////////////////////   GLOBALS  ///////////////////////////////

entity world; //NULL
.string classname;

vector ui_vid_res;
vector ui_vid;
float ui_vx_rel;
float ui_vy_rel;
float ui_font_size;

float ui_clicked;
float ui_mouse1_held;
float ui_mouse2_clicked;
float ui_ctrl_held;
float ui_shift_held;
float ui_wheel;

string ui_last_highlighted;
string ui_selected_input_field;
float ui_selected_input_max_length;

string ui_exec;
float ui_menu_page;
float ui_show_cursor;

string ui_binding_bind;
string ui_binding_bind2;

vector ui_mouse_pos;
vector ui_last_mouse_pos;

entity ui_windows;              // head of linked list
entity ui_active_window;        // currently focused / dragged
entity ui_top_window;           // topmost open window
entity ui_input_window;         // which window receives clicks this frame
entity ui_draw_window;          // window currently being drawn (for routing)
float ui_win_dragging;
vector ui_win_drag_offset;
float ui_input_blocked;
float ui_z_counter;

// Window entity fields
.entity ui_win_next;
.string ui_win_name;
.vector ui_win_pos;
.vector ui_win_size;
.vector ui_win_size_mult;       // size in ui_font_size units (set at creation, never changes)
.float ui_win_open;
.float ui_win_draggable;
.float ui_win_z;                // for draw order (higher draws later)
.void() ui_win_draw;            // window content callback

float UI_ProcessKeybind(float key);
float UI_ProcessKeybind2(float key);
float UI_ProcessTextInput(float key, float ascii);
void UI_RefreshWindowSizes();

float ui_fte;

/////////////////////////   FUNCTIONS  //////////////////////////////

void UI_GetRelative()
{
	float old_font_size = ui_font_size;
	ui_vid = [ stof(cvar_string("vid_conwidth")), stof(cvar_string("vid_conheight")) ];
	ui_vid_res = [ cvar("vid_width"), cvar("vid_height") ];
	if(ui_vid_x == 0) //FTE BYPASS
	{
		cmd("vid_conwidth 640\n");
		ui_vid_x = 640;
	}
	ui_font_size = rint(ui_vid_x * 0.02);
	ui_vx_rel = ui_vid_x / 960;
	ui_vy_rel = ui_vid_y / 540;
	if (ui_vid_res_y > 0 && (ui_vid_res_x / ui_vid_res_y) > 1.9)
	{
		ui_vx_rel = ui_vid_x / 1134;
		ui_vy_rel = ui_vid_y / 540;
	}
	if (ui_font_size != old_font_size && old_font_size > 0)
		UI_RefreshWindowSizes();
}

float UI_GetTime()
{
	#ifdef CSQC
		return time;
	#else
		return gettime();
	#endif
}

float UI_IsBehindWindow()
{
	if (ui_input_blocked)
	{
		if (ui_draw_window != ui_input_window)
		{
			return TRUE;
		}
	}
	return FALSE;
}

string UI_Bind2String(string bindname)
{
	if(strlen(bindname) < 3) return "";
	tokenize(findkeysforcommand(bindname, 0));
	string fw_key = "NONE";
	if (argv(0) != "-1") fw_key = keynumtostring(stof(argv(0)));
	return fw_key;
}

float UI_TextWidth(string txt)
{
	return stringwidth(txt, true, [ui_font_size, ui_font_size]);
}

float UI_InputEvent(float evtype, float key, float ascii, float devid)
{
	// key down
	if (evtype == 0)
	{
		if (key == K_MOUSE1)
		{
			ui_clicked = 1;
			ui_mouse1_held = 1;
			if (ui_show_cursor) return TRUE;
		}
		if (key == K_MOUSE2)
		{
			ui_mouse2_clicked = 1;
			if (ui_show_cursor) return TRUE;
		}
		if (key == K_MWHEELUP)
		{
			ui_wheel = ui_wheel + 1;
			if (ui_show_cursor) return TRUE;
		}
		if (key == K_MWHEELDOWN)
		{
			ui_wheel = ui_wheel - 1;
			if (ui_show_cursor) return TRUE;
		}
		if (key == K_CTRL) ui_ctrl_held = TRUE;
		if (key == K_SHIFT) ui_shift_held = TRUE;

		if (UI_ProcessKeybind(key)) return TRUE;
		if (UI_ProcessKeybind2(key)) return TRUE;
		if (UI_ProcessTextInput(key, ascii)) return TRUE;
		return FALSE;
	}

	// key up
	if (evtype == 1)
	{
		if (key == K_MOUSE1) ui_mouse1_held = 0;
		if (key == K_CTRL) ui_ctrl_held = FALSE;
		if (key == K_SHIFT) ui_shift_held = FALSE;
		return FALSE;
	}

	// mouse delta
	if (evtype == 2)
	{
		ui_mouse_pos = ui_mouse_pos + [key, ascii];
		return ui_show_cursor;
	}

	// mouse absolute
	if (evtype == 3)
	{
		if (devid != 0) return FALSE;
		ui_mouse_pos = ui_mouse_pos + [key, ascii];
		return ui_show_cursor;
	}

	return FALSE;
}


/////////////////////////	MOUSE	/////////////////////////////////

void UI_UpdateMouse()
{
	if(!ui_fte) ui_mouse_pos = ui_mouse_pos + getmousepos() * (cvar("sensitivity") / 3);
 	if (ui_mouse_pos_x < 0) ui_mouse_pos_x = 0;
 	if (ui_mouse_pos_x > ui_vid_x) ui_mouse_pos_x = ui_vid_x;
 	if (ui_mouse_pos_y < 0) ui_mouse_pos_y = 0;
 	if (ui_mouse_pos_y > ui_vid_y) ui_mouse_pos_y = ui_vid_y;
	if (!ui_mouse1_held) ui_last_mouse_pos = ui_mouse_pos;
 }

vector UI_FixedVector(vector vctr)
{
	return [rint(vctr_x * ui_vx_rel), rint(vctr_y * ui_vy_rel)];
}

float UI_MouseInRect(vector a, vector b)
{
	if (ui_mouse_pos_x < a_x || ui_mouse_pos_x > b_x) return 0;
	if (ui_mouse_pos_y < a_y || ui_mouse_pos_y > b_y) return 0;
	return 1;
}

float UI_MouseInRectSize(vector pos, vector size)
{
	return UI_MouseInRect(pos, pos + size);
}

float UI_CheckMouse(vector pos, vector pos2)
{
	pos -= UI_FixedVector('5 2 0');
 	pos2 += UI_FixedVector('5 5 0');
	if (ui_mouse_pos_x >= pos_x && ui_mouse_pos_x <= pos2_x)
	{
		if (ui_mouse_pos_y >= pos_y && ui_mouse_pos_y <= pos2_y)
			return 1;
	}
	return 0;
}

void UI_DrawCursor()
{
	#ifdef MENUQC
	ui_show_cursor = true;
	#endif
	if (ui_show_cursor) drawpic(ui_mouse_pos, "gfx/cursor", UI_FixedVector('24 24 0'), ' 1 1 1', 1, 0);
}

////////////////////////   UI FUNCTION   ////////////////////////////

void UI_Cmd()
{
	cmd(ui_exec);
}
void UI_Page()
{
	ui_menu_page = stof(ui_exec);
}
void UI_Bind()
{
	ui_binding_bind = ui_exec;

	string unbindOldKeyCmd = "unbind ";
	tokenize(findkeysforcommand(ui_binding_bind, 0));
	if (argv(0) != "-1")
	{
		string fw_key = keynumtostring(stof(argv(0)));
		cmd(strcat(unbindOldKeyCmd, fw_key), "\n");
	}
}

void UI_Bind2()
{
	ui_binding_bind2 = ui_exec;

	string unbindOldKeyCmd = "unbind ";
	tokenize(findkeysforcommand(ui_binding_bind2, 0));
	if (argv(1) != "-1")
	{
		string fw_key = keynumtostring(stof(argv(1)));
		cmd(strcat(unbindOldKeyCmd, fw_key), "\n");
	}
}

void UI_PlaySound(string snd)
{
	#ifdef CSQC
		Sound_Local(snd);
	#else
		localsound(snd);   // menuqc builtin #65
	#endif
}

void UI_InitKeybinds();
void UI_Init()
{
	if(cvar_string("qws_name") == "FTE")
	{
		ui_fte = TRUE;
	}
	UI_InitKeybinds();
}