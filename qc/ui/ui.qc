
/////////////////////////////////////////////////////////////////////
//////////////////////////   GLOBALS  ///////////////////////////////
/////////////////////////////////////////////////////////////////////

entity world; //NULL
.string classname;
vector vid_res;
vector vid;
float vy_rel;
float vx_rel;
float font_size;
float menu_page;

string lastHighlighted;
float clicked;
float showCursor;
string exec;
float mouse1_held;
string bindingBind;
string bindingBind2;
string selected_input_field;
float selected_input_max_length;

// Window system globals
entity UI_windows;              // head of linked list
entity UI_active_window;        // currently focused / dragged
float UI_win_dragging;
vector UI_win_drag_offset;
float UI_input_blocked;
float UI_z_counter;
entity UI_top_window;
entity UI_input_window;       // which window is allowed to receive clicks right now
entity UI_draw_window;        // window currently being drawn (for routing)

.entity UI_win_next;
.string UI_win_name;
.vector UI_win_pos;
.vector UI_win_size;
.float UI_win_open;
.float UI_win_draggable;
.float UI_win_z;                // for draw order (higher draws later)
.void() UI_win_draw;            // window content callback

/////////////////////////////////////////////////////////////////////
/////////////////////////   FUNCTIONS  //////////////////////////////
/////////////////////////////////////////////////////////////////////

void UI_GetRelative()
{
	vid = [ stof(cvar_string("vid_conwidth")), stof(cvar_string("vid_conheight")) ];
	vid_res = [ cvar("vid_width"), cvar("vid_height") ];
	if(vid_x == 0) //FTE BYPASS
	{
		cmd("vid_conwidth 640\n");
		vid_x = 640;
	}
	font_size = vid_x * 0.02;
	vx_rel = vid_x / 960;
	vy_rel = vid_y / 540;
	if ( ((vid_res_x == 2560) && (vid_res_y == 1440)) || ((vid_res_x == 2560) && (vid_res_y == 1080)) ||
		((vid_res_x == 3440) && (vid_res_y == 1440)) || ((vid_res_x == 5120) && (vid_res_y == 2160)) ||
		((vid_res_x == 4096) && (vid_res_y == 2160)) || ((vid_res_x == 3840) && (vid_res_y == 1600)) )
	{
		vx_rel = vid_x / 1134;
		vy_rel = vid_y / 540;
	}
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
	if (UI_input_blocked)
	{
		if (UI_draw_window != UI_input_window)
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
	return stringwidth(txt, true, [font_size, font_size]);
}



/////////////////////////////////////////////////////////////////////
/////////////////////////	MOUSE	/////////////////////////////////
/////////////////////////////////////////////////////////////////////

vector mouse_pos;
vector last_mouse_pos;
void UI_UpdateMouse()
{
 	mouse_pos = mouse_pos + getmousepos();
 	if (mouse_pos_x < 0) mouse_pos_x = 0;
 	if (mouse_pos_x > vid_x) mouse_pos_x = vid_x;
 	if (mouse_pos_y < 0) mouse_pos_y = 0;
 	if (mouse_pos_y > vid_y) mouse_pos_y = vid_y;
	if (!mouse1_held) last_mouse_pos = mouse_pos;
 }

vector UI_FixedVector(vector vctr)
{
	return [rint(vctr_x * vx_rel), rint(vctr_y * vy_rel)];
}

float UI_MouseInRect(vector a, vector b)
{
	if (mouse_pos_x < a_x || mouse_pos_x > b_x) return 0;
	if (mouse_pos_y < a_y || mouse_pos_y > b_y) return 0;
	return 1;
}

float UI_MouseInRectSize(vector pos, vector size)
{
	return UI_MouseInRect(pos, pos + size);
}

float UI_CheckMouse(vector pos, vector pos2)
{
	pos -= UI_FixedVector('5 2 0');
 	pos2 += UI_FixedVector('5 5 0'); //'5 12 0'
	// drawfill(pos, pos2 - pos, '.1 .1 .1', .75, 0); //for debug
	if (mouse_pos_x >= pos_x && mouse_pos_x <= pos2_x)
	{
		if (mouse_pos_y >= pos_y && mouse_pos_y <= pos2_y)
			return 1;
	}
	return 0;
}

void UI_DrawCursor()
{
	#ifdef MENUQC
	showCursor = true;
	#endif
	if (showCursor) drawpic(mouse_pos, "gfx/cursor", UI_FixedVector('24 24 0'), ' 1 1 1', 1, 0);
}

/////////////////////////////////////////////////////////////////////
////////////////////////   UI FUNCTION   ////////////////////////////
/////////////////////////////////////////////////////////////////////

void UI_Cmd()
{
	cmd(exec);
}
void UI_Page()
{
	menu_page = stof(exec);
}
void UI_Bind()
{
	bindingBind = exec;
	
	string unbindOldKeyCmd = "unbind ";
	tokenize(findkeysforcommand(bindingBind, 0));
	if (argv(0) != "-1") 
	{
		string fw_key = keynumtostring(stof(argv(0)));
		cmd(strcat(unbindOldKeyCmd, fw_key), "\n");
	}
}

void UI_Bind2()
{
	bindingBind2 = exec;
	
	string unbindOldKeyCmd = "unbind ";
	tokenize(findkeysforcommand(bindingBind2, 0));
	if (argv(1) != "-1") 
	{
		string fw_key = keynumtostring(stof(argv(1)));
		cmd(strcat(unbindOldKeyCmd, fw_key), "\n");
	}
}
