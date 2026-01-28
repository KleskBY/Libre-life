
/////////////////////////////////////////////////////////////////////
////////////////////////   UI ELEMENTS   ////////////////////////////
/////////////////////////////////////////////////////////////////////

void UI_Text(string txt, vector pos, vector color = '1 1 1')
{
	drawstring(pos, txt, [font_size, font_size], color, 0.9, 0);
}

void UI_TextCentered(string txt, vector pos, vector color = '1 1 1')
{
	vector font_v = [font_size, font_size];
	float w = stringwidth(txt, true, font_v);
	drawstring(pos - [w * 0.5, font_size * 0.5, 0], txt, font_v, color, 0.9, 0);
}

void UI_Image(string pic, vector pos, vector size, vector color = '1 1 1', float alpha = 1)
{
	drawpic(pos, pic, size, color, alpha, 0);
}

void UI_Frame(vector pos, vector size, float padding = 0)
{
	if(padding)
	{
		pos = pos - UI_FixedVector(UI_FRAME_PADDING);
		size = size + UI_FixedVector(UI_FRAME_PADDING) * 2;
	}
	drawfill(pos, size, UI_WINDOW_BACKGROUND, UI_WINDOW_BACKGROUND_ALPHA, 0); 
	
	//edges
	drawfill(pos, [size_x], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos, [0, size_y], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [0, size_y], [size_x], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [size_x], [0, size_y + 1], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
}

void UI_FrameInput(vector pos, vector size)
{
	drawfill(pos, size, UI_DROPDOWN_BACKGROUND, UI_DROPDOWN_BACKGROUND_ALPHA, 0); 
	
	//edges
	drawfill(pos, [size_x], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos, [0, size_y], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [0, size_y], [size_x], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [size_x], [0, size_y + 1], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
}

void UI_ImageButton(string pic, vector pos, vector size, void() func, string ex)
{
	drawpic(pos, pic, size, '1 1 1', 1, 0);
	if (UI_IsBehindWindow()) return;

	if (UI_CheckMouse(pos, pos + size))
	{
		if (clicked)
		{
			localsound("sound/misc/menu2.wav");
			exec = ex;
			func();
			clicked = 0;
		}
	}
}

void UI_ActivateButton(void() func, string ex)
{
	if(clicked)
	{
		exec = ex;
		#ifdef MENUQC
		if(strstrofs(ex, "connect", 0) >= 0)
		{
			m_toggle(0);
		}
		#endif
		func();
		clicked = FALSE;
		mouse1_held = FALSE;
	}
}

void UI_Button(string txt, vector pos, void() func, string ex)
{
	float txt_len = stringwidth(txt, true, [font_size, font_size]);
	vector pos2 = pos + [font_size, font_size];
 	pos2_x = pos_x + txt_len;
	// vector size = pos2 - pos;
	
	// UI_Frame(pos, size);

	if(!UI_IsBehindWindow() && UI_CheckMouse(pos, pos2)) 
	{
		if(UI_BUTTON_JITTER) pos = pos + [random(-0.5, 0.5), random(-0.5, 0.5)];
		drawstring(pos, txt, [font_size, font_size], '0.7 0.7 0.7', 0.7, 0);
		UI_ActivateButton(func, ex);
	}
	else drawstring(pos, txt, [font_size, font_size], '1 1 1', 0.9, 0);
}

void UI_Button2(string txt, vector pos, vector size, void() func, string ex)
{
	UI_Frame(pos, size, FALSE);
	if(!UI_IsBehindWindow() && UI_MouseInRectSize(pos, size)) 
	{
		UI_TextCentered(txt, pos + size /2 , '.7 .7 .7');
		UI_ActivateButton(func, ex);
	}
	else UI_TextCentered(txt, pos + size / 2);
}


void UI_MenuButton(string txt, vector pos, void() func, string ex)
{
	cvar_set("r_textshadow", "1");
	float old_font_size = font_size;
	font_size = font_size * 1.5;
	float txt_len = stringwidth(txt, true, [font_size, font_size]);
	vector pos2 = pos + [font_size, font_size];
 	pos2_x = pos_x + txt_len;
	vector size = pos2 - pos;
	
	if(!UI_IsBehindWindow() && UI_CheckMouse(pos, pos2))
	{
		if(UI_BUTTON_JITTER) pos = pos + [random(-0.5, 0.5), random(-0.5, 0.5)];
		drawstring(pos, txt, [font_size, font_size], '1 0.8 0', 1, 0);
		if(clicked)
		{
			localsound("sound/misc/menu2.wav");
			UI_ActivateButton(func, ex);
		}
		else if (lastHighlighted != txt)
		{
			lastHighlighted = txt;
			localsound("sound/misc/menu1.wav");
		}
	}
	else drawstring(pos, txt, [font_size, font_size], '0.93 0.68 0', 1, 0);
	font_size = old_font_size;
	cvar_set("r_textshadow", "0");
}


void UI_Checkbox(string txt, vector pos, string variable)
{
	float checked = cvar(variable);
	// if (checked == 1) mark = " X ";
	string setcmd = strcat(variable, " ", ftos(!checked), "\n");
	UI_FrameInput(pos, [font_size, font_size] * 0.9);
	if (checked == 1) drawfill(pos + [font_size, font_size] * 0.2, [font_size, font_size] * 0.5, UI_TEST_HIGHLIGHTED, .75, FALSE);
	// if (checked == 1) UI_Frame(pos + [font_size, font_size] * 0.2, [font_size, font_size] * 0.5, FALSE);
	UI_Button("      ", pos, UI_Cmd, setcmd);
	UI_Button(txt, pos + [font_size * 1.5], UI_Cmd, setcmd);
	
	// string mark = "OFF";
	// float checked = cvar(variable);
	// if (checked == 1) mark = "ON";
	// string setcmd = strcat(variable, " ", ftos(!checked), "\n");
	// UI_Button(txt, pos, UI_Cmd, setcmd);
	// UI_Button(mark, pos + [font_size * 12, 0], UI_Cmd, setcmd);
}

void UI_Slider(vector pos, vector size, string variable, float min, float max, float step)
{
	// pos = pos + [font_size];
	// size = size - [font_size];

	float val = cvar(variable);
	if (val < min) val = min;
	if (val > max) val = max;

	float range = max - min;
	if (range <= 0) range = 1; // avoid div0

	float coef = size_x / range;


	UI_FrameInput(pos, size);

	// track
	if (!UI_IsBehindWindow() && UI_CheckMouse(pos, pos + size))
	{
		// drawfill(pos + [0, font_size * 0.5 - 1], size, '30 30 30', 0.5, 0);

		if (mouse1_held) //we need to check if selected
		{
			mouse_pos_y = pos_y; // mouse_pos_y = last_mouse_pos_y;
			float raw = (mouse_pos_x - pos_x) / coef + min;
			// if (step > 0) raw = rint(raw / step) * step;

			// clamp
			if (raw < min) raw = min;
			if (raw > max) raw = max;

			string newValStr = ftos(raw);
			if (strstrofs(newValStr, ".", 1) != -1)
			{
				if (step == 1) newValStr = ftos(rint(raw));
				else newValStr = substring(newValStr, 0, strstrofs(newValStr, ".", 1) + 3);
			}

			cmd(strcat(variable, " ", newValStr, "\n"));
			val = raw;
		}
	}
	// else
	// {
		// drawfill(pos + [0, font_size * 0.5 - 1], size, COLOR_NOT_SELECTED, COLOR_NOT_SELECTED_ALPHA, 0);
	// }

	//Handle
	float cord = coef * (val - min);
	vector handle_size = [4, font_size];
	//drawfill(pos + [cord], handle_size, '10 10 10', 0.8, 0);
	UI_Frame(pos + [cord] - handle_size * 0.5, handle_size, FALSE);
	
	// minus/plus buttons
	// string minus_cmd = strcat(variable, " ", ftos(val - step), "\n");
	// UI_Button("◄", pos - [font_size], UI_Cmd, minus_cmd);
	// string plus_cmd = strcat(variable, " ", ftos(val + step), "\n");
	// UI_Button("►", pos + [size_x, 0] + [font_size, 0], UI_Cmd, plus_cmd);

	// printed value
	if(val <= min) val = min; //Ftos prints -0 for some reason
	string printedVal = ftos(val);
	if (strstrofs(printedVal, ".", 1) != -1)
		printedVal = substring(printedVal, 0, strstrofs(printedVal, ".", 0) + 2);

	float txt_len = stringwidth(printedVal, true, [font_size, font_size]);
	UI_Text(printedVal, pos + [cord - txt_len / 2, font_size]);
};

float UI_ProcessKeybind(float key)
{
	if(strlen(bindingBind) == 0) return FALSE;
	string selectedKey = "bind ";
	cmd(strcat(selectedKey, keynumtostring(key), " \"", bindingBind, "\""));
	bindingBind = "";
	return TRUE;
}

float UI_ProcessKeybind2(float key)
{
	if(strlen(bindingBind2) == 0) return FALSE;
	string selectedKey = "bind ";
	cmd(strcat(selectedKey, keynumtostring(key), " \"", bindingBind2, "\""));
	bindingBind2 = "";
	return TRUE;
}

void UI_Keybind(vector pos, string bindname)
{
	tokenize(findkeysforcommand(bindname, 0));
	string fw_key = "NONE";
	if (argv(0) != "-1") fw_key = keynumtostring(stof(argv(0)));
	if(strlen(bindingBind) == 0 || bindingBind != bindname)
		UI_Button(fw_key, pos, UI_Bind, bindname);
	else 
	{
		UI_FrameInput(pos, [font_size * 4, font_size * 0.9]);
		UI_Button("...", pos, UI_Cmd, "");	
	}
}

void UI_Keybind2(vector pos, string bindname)
{
	tokenize(findkeysforcommand(bindname, 0));
	string fw_key = "NONE";
	if(strlen(bindingBind) != 0 && bindingBind == bindname)
	{
		if (argv(0) != "-1") fw_key = keynumtostring(stof(argv(0)));
	}
	else if (argv(1) != "-1") fw_key = keynumtostring(stof(argv(1)));
	if(strlen(bindingBind2) == 0 || bindingBind2 != bindname)
		UI_Button(fw_key, pos, UI_Bind2, bindname);
	else 
	{
		UI_FrameInput(pos, [font_size * 4, font_size * 0.9]);
		UI_Button("...", pos, UI_Cmd, "");	
	}
}


void UI_InputText(string cvar_name, vector pos, float max_length, string name)
{
	float offset = font_size * strlen(name);
	float txt_len = font_size * strlen(name) + font_size * max_length; //stringwidth(txt, true, [font_size, font_size]);
	vector pos2 = pos + [font_size, font_size];
 	pos2_x = pos_x + txt_len;
	
	if(UI_CheckMouse(pos, pos2)) 
	{
		drawstring(pos, name, [font_size, font_size], '.7 .7 .7', .7, 0);
		drawfill([pos_x + offset, pos_y], [font_size * max_length, font_size], '0.1 0.1 0.1', 0.8, 0);
		selected_input_field = cvar_name;
		selected_input_max_length = max_length;
		UI_Text(cvar_string(cvar_name), [pos_x + offset, pos_y]);
		float f = rint(UI_GetTime() * 10) % 5;
		if(f < 3) UI_Text("_", [pos_x + offset + stringwidth(cvar_string(cvar_name), true, [font_size, font_size]), pos_y]);
	}
	else
	{
		drawstring(pos, name, [font_size, font_size], '1 1 1', .9, 0);
		drawfill([pos_x + offset, pos_y], [font_size * max_length, font_size], '0.1 0.1 0.1', 0.5, 0);
		UI_Text(cvar_string(cvar_name), [pos_x + offset, pos_y]);
		//selected_input_field = "";
	}
}

string UI_Combobox(vector pos, float size, string items, string val, float max_val)
{
	string list = items;
	
	float idx = cvar(val);
	if (idx < 0) { cmd(strcat(val, " ", ftos(max_val - 1), "\n")); idx = max_val - 1; }
	if (idx > (max_val - 1)) { cmd(strcat(val, " 0\n")); idx = 0; }
	
	for(float i = 0; i < idx; i++)
	{
		float sep = strstrofs(list, "|", 0);
		if (sep < 0) break;
		list = substring(list, sep + 1, strlen(list) - (sep + 1));
	}
	
	float sep0 = strstrofs(list, "|", 0);
	string draw;
	if (sep0 < 0) draw = list;
	else draw = substring(list, 0, sep0);

	UI_Button("<", pos, UI_Cmd, strcat(val, " ", ftos(idx - 1), "\n"));
	UI_Button(">", [pos_x + font_size * size, pos_y], UI_Cmd, strcat(val, " ", ftos(idx + 1), "\n"));
	UI_Button(draw, [pos_x + ((size / 2) * font_size) - (stringwidth(draw, 1, [font_size, font_size]) / 2), pos_y], UI_Cmd, "");
	return draw;
}


