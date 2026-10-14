
////////////////////////   UI ELEMENTS   ////////////////////////////

void UI_Text(string txt, vector pos, vector color = '1 1 1')
{
	drawstring(pos, txt, [ui_font_size, ui_font_size], color, 0.9, 0);
}

void UI_TextCentered(string txt, vector pos, vector color = '1 1 1')
{
	vector font_v = [ui_font_size, ui_font_size];
	float w = stringwidth(txt, true, font_v);
	float vertical_offs = 0.5;
	if(txt == "x") vertical_offs = 0.52;
	drawstring(pos - [w * 0.5, ui_font_size * vertical_offs, 0], txt, font_v, color, 0.9, 0);
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

	drawfill(pos, [size_x, 1], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos, [1, size_y], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [0, size_y - 1], [size_x, 1], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [size_x - 1, 0], [1, size_y], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
}

void UI_FrameInput(vector pos, vector size)
{
	drawfill(pos, size, UI_DROPDOWN_BACKGROUND, UI_DROPDOWN_BACKGROUND_ALPHA, 0);

	drawfill(pos, [size_x], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos, [0, size_y], UI_WINDOW_BACKGROUND * 0.75, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [0, size_y], [size_x], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
	drawfill(pos + [size_x], [0, size_y + 1], UI_WINDOW_BACKGROUND * 1.25, UI_WINDOW_BACKGROUND_ALPHA, 0);
}

// Returns minimum button width to comfortably fit txt (1× font_size padding each side)
float UI_ButtonMinWidth(string txt)
{
	return stringwidth(txt, true, [ui_font_size, ui_font_size]) + ui_font_size * 2;
}

void UI_ImageButton(string pic, vector pos, vector size, void() func, string ex)
{
	drawpic(pos, pic, size, '1 1 1', 1, 0);
	if (UI_IsBehindWindow()) return;

	if (UI_CheckMouse(pos, pos + size))
	{
		if (ui_clicked)
		{
			UI_PlaySound("sound/misc/menu2.wav");
			ui_exec = ex;
			func();
			ui_clicked = 0;
		}
	}
}

void UI_ActivateButton(void() func, string ex)
{
	if(ui_clicked)
	{
		ui_exec = ex;
		#ifdef MENUQC
		if(strstrofs(ex, "connect", 0) >= 0)
		{
			m_toggle(0);
		}
		#endif
		func();
		ui_clicked = FALSE;
		ui_mouse1_held = FALSE;
	}
}

void UI_Button(string txt, vector pos, void() func, string ex)
{
	float txt_len = stringwidth(txt, true, [ui_font_size, ui_font_size]);
	vector pos2 = pos + [ui_font_size, ui_font_size];
 	pos2_x = pos_x + txt_len;

	if(!UI_IsBehindWindow() && UI_CheckMouse(pos, pos2))
	{
		if(UI_BUTTON_JITTER) pos = pos + [random(-0.5, 0.5), random(-0.5, 0.5)];
		drawstring(pos, txt, [ui_font_size, ui_font_size], '0.7 0.7 0.7', 0.7, 0);
		UI_ActivateButton(func, ex);
	}
	else drawstring(pos, txt, [ui_font_size, ui_font_size], '1 1 1', 0.9, 0);
}

void UI_Button2(string txt, vector pos, vector size, void() func, string ex)
{
	UI_Frame(pos, size, FALSE);
	if(!UI_IsBehindWindow() && UI_MouseInRectSize(pos, size))
	{
		UI_TextCentered(txt, pos + size / 2, '.7 .7 .7');
		UI_ActivateButton(func, ex);
	}
	else UI_TextCentered(txt, pos + size / 2);
}


void UI_MenuButton(string txt, vector pos, void() func, string ex)
{
	float old_ui_font_size = ui_font_size;
	ui_font_size = ui_font_size * UI_MENU_BUTTON_SCALE;
	float txt_len = stringwidth(txt, true, [ui_font_size, ui_font_size]);
	vector pos2 = pos + [ui_font_size, ui_font_size];
 	pos2_x = pos_x + txt_len;

	if(!UI_IsBehindWindow() && UI_CheckMouse(pos, pos2))
	{
		if(UI_BUTTON_JITTER) pos = pos + [random(-0.5, 0.5), random(-0.5, 0.5)];
		drawstring(pos, txt, [ui_font_size, ui_font_size], '1 0.8 0', 1, 0);
		if(ui_clicked)
		{
			UI_PlaySound("sound/misc/menu2.wav");
			UI_ActivateButton(func, ex);
		}
		else if (ui_last_highlighted != txt)
		{
			ui_last_highlighted = txt;
			UI_PlaySound("sound/misc/menu1.wav");
		}
	}
	else drawstring(pos, txt, [ui_font_size, ui_font_size], '0.93 0.68 0', 1, 0);
	ui_font_size = old_ui_font_size;
}


void UI_Checkbox(string txt, vector pos, string variable)
{
	float checked = cvar(variable);
	string setcmd = strcat(variable, " ", ftos(!checked), "\n");
	UI_FrameInput(pos, [ui_font_size, ui_font_size] * 0.9);
	if (checked == 1) drawfill(pos + [ui_font_size, ui_font_size] * 0.2, [ui_font_size, ui_font_size] * 0.5, UI_TEXT_HIGHLIGHTED, .75, FALSE);
	UI_Button("      ", pos, UI_Cmd, setcmd);
	UI_Button(txt, pos + [ui_font_size * 1.5], UI_Cmd, setcmd);
}

float UI_SliderDecimals(float step)
{
	if (step <= 0) return 2;
	if (step >= 1) return 0;
	float t = step * 10;
	if (t - rint(t) < 0.0001 && rint(t) - t < 0.0001) return 1;
	t = step * 100;
	if (t - rint(t) < 0.0001 && rint(t) - t < 0.0001) return 2;
	return 3;
}

float UI_SliderSnap(float val, float minVal, float maxVal, float step)
{
	if (step > 0) val = minVal + rint((val - minVal) / step) * step;
	if (val <= minVal) val = minVal; // <= not <, so a negative zero is replaced
	if (val >= maxVal) val = maxVal;
	return val;
}

string UI_SliderFormat(float val, float step)
{
	float dec = UI_SliderDecimals(step);
	string s;
	if (dec <= 0) s = ftos(rint(val));
	else if (dec == 1) s = sprintf("%.1f", val);
	else if (dec == 2) s = sprintf("%.2f", val);
	else s = sprintf("%.3f", val);
	if (stof(s) == 0 && substring(s, 0, 1) == "-") s = substring(s, 1, -1); // rint(-0.3) is negative zero, printed "-0"
	return s;
}

void UI_Slider(vector pos, vector size, string variable, float min, float max, float step)
{
	float val = UI_SliderSnap(cvar(variable), min, max, step);

	float range = max - min;
	if (range <= 0) range = 1;

	float coef = size_x / range;

	UI_FrameInput(pos, size);

	string printedVal = UI_SliderFormat(val, step);

	if (!UI_IsBehindWindow() && UI_CheckMouse(pos, pos + size))
	{
		if (ui_mouse1_held)
		{
			ui_mouse_pos_y = pos_y;
			float raw = UI_SliderSnap((ui_mouse_pos_x - pos_x) / coef + min, min, max, step);
			string newValStr = UI_SliderFormat(raw, step);

			if (newValStr != printedVal) cmd(strcat(variable, " ", newValStr, "\n"));
			val = raw;
			printedVal = newValStr;
		}
	}

	float cord = coef * (val - min);
	vector handle_size = [4, ui_font_size];
	UI_Frame(pos + [cord] - handle_size * 0.5, handle_size, FALSE);

	float txt_len = stringwidth(printedVal, true, [ui_font_size, ui_font_size]);
	UI_Text(printedVal, pos + [cord - txt_len / 2, ui_font_size]);
};

float UI_ProcessKeybind(float key)
{
	if(strlen(ui_binding_bind) == 0) return FALSE;
	string selectedKey = "bind ";
	cmd(strcat(selectedKey, keynumtostring(key), " \"", ui_binding_bind, "\""));
	ui_binding_bind = "";
	return TRUE;
}

float UI_ProcessKeybind2(float key)
{
	if(strlen(ui_binding_bind2) == 0) return FALSE;
	string selectedKey = "bind ";
	cmd(strcat(selectedKey, keynumtostring(key), " \"", ui_binding_bind2, "\""));
	ui_binding_bind2 = "";
	return TRUE;
}

void UI_Keybind(vector pos, string bindname)
{
	tokenize(findkeysforcommand(bindname, 0));
	string fw_key = "NONE";
	if (argv(0) != "-1") fw_key = keynumtostring(stof(argv(0)));
	if(strlen(ui_binding_bind) == 0 || ui_binding_bind != bindname)
		UI_Button(fw_key, pos, UI_Bind, bindname);
	else
	{
		UI_FrameInput(pos, [ui_font_size * 4, ui_font_size * 0.9]);
		UI_Button("...", pos, UI_Cmd, "");
	}
}

void UI_Keybind2(vector pos, string bindname)
{
	tokenize(findkeysforcommand(bindname, 0));
	string fw_key = "NONE";
	if(strlen(ui_binding_bind) != 0 && ui_binding_bind == bindname)
	{
		if (argv(0) != "-1") fw_key = keynumtostring(stof(argv(0)));
	}
	else if (argv(1) != "-1") fw_key = keynumtostring(stof(argv(1)));
	if(strlen(ui_binding_bind2) == 0 || ui_binding_bind2 != bindname)
		UI_Button(fw_key, pos, UI_Bind2, bindname);
	else
	{
		UI_FrameInput(pos, [ui_font_size * 4, ui_font_size * 0.9]);
		UI_Button("...", pos, UI_Cmd, "");
	}
}


float UI_ProcessTextInput(float key, float ascii)
{
	if (strlen(ui_selected_input_field) == 0) return FALSE;

	if (key == K_ESCAPE || key == K_ENTER)
	{
		ui_selected_input_field = "";
		return TRUE;
	}

	string val = cvar_string(ui_selected_input_field);

	if (key == K_BACKSPACE)
	{
		if (strlen(val) > 0)
			cvar_set(ui_selected_input_field, substring(val, 0, strlen(val) - 1));
		return TRUE;
	}

	if (ascii >= 32 && ascii < 127)
	{
		if (strlen(val) < ui_selected_input_max_length)
			cvar_set(ui_selected_input_field, strcat(val, chr2str(ascii)));
		return TRUE;
	}

	return FALSE;
}

void UI_InputText(string cvar_name, vector pos, float max_length, string name)
{
	float offset = ui_font_size * strlen(name);
	float txt_len = ui_font_size * strlen(name) + ui_font_size * max_length;
	vector pos2 = pos + [ui_font_size, ui_font_size];
 	pos2_x = pos_x + txt_len;

	float is_selected = (ui_selected_input_field == cvar_name);
	float hovering = UI_CheckMouse(pos, pos2);

	if (hovering && ui_clicked && !UI_IsBehindWindow())
	{
		ui_selected_input_field = cvar_name;
		ui_selected_input_max_length = max_length;
		is_selected = TRUE;
		ui_clicked = 0;
	}

	if (is_selected && ui_clicked && !hovering)
		ui_selected_input_field = "";

	string val = cvar_string(cvar_name);

	if (is_selected)
	{
		drawstring(pos, name, [ui_font_size, ui_font_size], '.7 .7 .7', .7, 0);
		drawfill([pos_x + offset, pos_y], [ui_font_size * max_length, ui_font_size], '0.1 0.1 0.1', 0.8, 0);
		UI_Text(val, [pos_x + offset, pos_y]);
		float f = rint(UI_GetTime() * UI_CURSOR_BLINK_RATE) % UI_CURSOR_BLINK_MOD;
		if(f < UI_CURSOR_BLINK_THRESHOLD) UI_Text("_", [pos_x + offset + stringwidth(val, true, [ui_font_size, ui_font_size]), pos_y]);
	}
	else
	{
		drawstring(pos, name, [ui_font_size, ui_font_size], '1 1 1', .9, 0);
		drawfill([pos_x + offset, pos_y], [ui_font_size * max_length, ui_font_size], '0.1 0.1 0.1', 0.5, 0);
		UI_Text(val, [pos_x + offset, pos_y]);
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
	UI_Button(">", [pos_x + ui_font_size * size, pos_y], UI_Cmd, strcat(val, " ", ftos(idx + 1), "\n"));
	UI_Button(draw, [pos_x + ((size / 2) * ui_font_size) - (stringwidth(draw, 1, [ui_font_size, ui_font_size]) / 2), pos_y], UI_Cmd, "");
	return draw;
}

