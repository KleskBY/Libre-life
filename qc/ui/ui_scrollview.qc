	string UI_keybind_rows =
"Move forward^+forward^;"
"Move back^+back^;"
"Turn left^+moveleft^;"
"Turn right^+moveright^;"
"Strafe left^+left^;"
"Strafe right^+right^;"
"Jump^+jump^;"
"Crouch^+button3^;"
"Attack^+attack^;"
"Aim^+button5^;"
"Next weapon^impulse 10^;"
"Previous weapon^impulse 12^;"
"Use^+use^;"
"Reload^reload^;"
"Heal^heal^;"
"Chat^messagemode^";

// SCROLLVIEW / LIST
float UI_list_selected;
float UI_list_scroll;

float UI_ScrollList(float list, vector list_pos, vector list_size, float maxscroll)
{
	if (UI_wheel == 0) return list;

	list = list - UI_wheel; // wheel up => smaller index
	if (list < 0) list = 0;
	if (list > maxscroll) list = maxscroll;
	UI_wheel = 0;
	return list;
}

void UI_Scrollbar(float count, float visible, vector list_size, vector list_pos, float maxscroll)
{
	if (count < visible) return;

	float bar_h = list_size_y;
	float knob_h = bar_h * (visible / count);
	if (knob_h < font_size * 0.8) knob_h = font_size * 0.8;

	float t = (maxscroll > 0) ? (UI_list_scroll / maxscroll) : 0;
	float y = (bar_h - knob_h) * t;

	vector sb_pos = list_pos + [list_size_x - font_size * 0.6, 0, 0];
	drawfill(sb_pos, [font_size * 0.3, bar_h, 0], '0 0 0', 0.25, 0);
	drawfill(sb_pos + [0, y, 0], [font_size * 0.3, knob_h, 0], '1 1 1', 0.18, 0);
}

void UI_KeybindList(vector pos, vector size, float count)
{
	float row_h = font_size * 1.2;
	float header_h = row_h;

	vector header_pos = pos;
	vector header_size = [size_x, header_h];

	vector list_pos = pos + [0, header_h];
	vector list_size = [size_x, size_y - header_h];

	// background + header
	UI_FrameInput(pos, size);
	drawfill(header_pos + [0, header_h - 1], [size_x, 1], '0 0 0', 0.25, 0);
	// drawfill(header_pos, header_size, '0 0 0', 0.25, 0);

	float col1 = size_x * 0.40; // action
	float col2 = size_x * 0.30; // key
	float col3 = size_x * 0.30; // alt

	UI_Text("MOVEMENT", header_pos + [font_size * 0.4, font_size * 0.15, 0], UI_TEST_HIGHLIGHTED);
	UI_Text("KEY/BUTTON", header_pos + [col1 + font_size * 0.4, font_size * 0.15, 0], UI_TEST_HIGHLIGHTED);
	UI_Text("ALTERNATE", header_pos + [col1 + col2 + font_size * 0.4, font_size * 0.15, 0], UI_TEST_HIGHLIGHTED);

	// list metrics
	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;
	
	// if (UI_list_id != list_id) // switching lists resets per-list state
	// {
		// UI_list_id = list_id;
		// UI_list_scroll = 0;
		// UI_list_selected = -1;
	// }

	// Scroll
	float maxscroll = count - visible;
	if (maxscroll < 0) maxscroll = 0;
	float over_list = UI_MouseInRect(list_pos, list_pos + list_size) && !UI_IsBehindWindow();
	if(over_list) UI_list_scroll = UI_ScrollList(UI_list_scroll, list_pos, list_size, maxscroll);

	for (float r = 0; r < visible; r++)
	{
		float i = UI_list_scroll + r;
		if (i >= count) break;

		vector row_pos = list_pos + [0, row_h * r, 0];
		vector row_size = [list_size_x, row_h, 0];
		float row_hover = UI_MouseInRectSize(row_pos, row_size);
		if (i == UI_list_selected)
			drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.75, 0);
		else if (row_hover)
			drawfill(row_pos, row_size, '1 1 1', 0.06, 0);

		// displayed bindings (ugly hack bc i hit tempstring limit)
		vector label_pos = row_pos + [font_size * 0.4, font_size * 0.15, 0];
		vector keybind_pos = row_pos + [col1 + font_size * 0.4, font_size * 0.15, 0];
		vector keybind2_pos = row_pos + [col1 + col2 + font_size * 0.4, font_size * 0.15, 0];
		if(i == 0)
		{
			UI_Text("Move forward", label_pos);
			UI_Keybind(keybind_pos, "+forward");
			UI_Keybind2(keybind2_pos, "+forward");
		}
		else if(i == 1)
		{
			UI_Text("Move back", label_pos);
			UI_Keybind(keybind_pos, "+back");
			UI_Keybind2(keybind2_pos, "+back");
		}
		else if(i == 2)
		{
			UI_Text("Strafe left", label_pos);
			UI_Keybind(keybind_pos, "+moveleft");
			UI_Keybind2(keybind2_pos, "+moveleft");
		}
		else if(i == 3)
		{
			UI_Text("Strafe right", label_pos);
			UI_Keybind(keybind_pos, "+moveright");
			UI_Keybind2(keybind2_pos, "+moveright");
		}
		else if(i == 4)
		{
			UI_Text("Look left", label_pos);
			UI_Keybind(keybind_pos, "+left");
			UI_Keybind2(keybind2_pos, "+left");
		}
		else if(i == 5)
		{
			UI_Text("Look right", label_pos);
			UI_Keybind(keybind_pos, "+right");
			UI_Keybind2(keybind2_pos, "+right");
		}
		else if(i == 6)
		{
			UI_Text("Jump", label_pos);
			UI_Keybind(keybind_pos, "+jump");
			UI_Keybind2(keybind2_pos, "+jump");
		}
		else if(i == 7)
		{
			UI_Text("Crouch", label_pos);
			UI_Keybind(keybind_pos, "+button3");
			UI_Keybind2(keybind2_pos, "+button3");
		}
		else if(i == 8)
		{
			UI_Text("Attack", label_pos);
			UI_Keybind(keybind_pos, "+attack");
			UI_Keybind2(keybind2_pos, "+attack");
		}
		else if(i == 9)
		{
			UI_Text("Aim", label_pos);
			UI_Keybind(keybind_pos, "+button5");
			UI_Keybind2(keybind2_pos, "+button5");
		}
		else if(i == 10)
		{
			UI_Text("Next weapon", label_pos);
			UI_Keybind(keybind_pos, "impulse 10");
			UI_Keybind2(keybind2_pos, "impulse 10");
		}
		else if(i == 11)
		{
			UI_Text("Previous weapon", label_pos);
			UI_Keybind(keybind_pos, "impulse 12");
			UI_Keybind2(keybind2_pos, "impulse 12");
		}
		else if(i == 12)
		{
			UI_Text("Use", label_pos);
			UI_Keybind(keybind_pos, "+use");
			UI_Keybind2(keybind2_pos, "+use");
		}
		else if(i == 13)
		{
			UI_Text("Reload", label_pos);
			UI_Keybind(keybind_pos, "reload");
			UI_Keybind2(keybind2_pos, "reload");
		}
		else if(i == 14)
		{
			UI_Text("Heal", label_pos);
			UI_Keybind(keybind_pos, "heal");
			UI_Keybind2(keybind2_pos, "heal");
		}
		else if(i == 15)
		{
			UI_Text("Flashlight", label_pos);
			UI_Keybind(keybind_pos, "flashlight");
			UI_Keybind2(keybind2_pos, "flashlight");
		}
		else if(i == 16)
		{
			UI_Text("Chat", label_pos);
			UI_Keybind(keybind_pos, "messagemode");
			UI_Keybind2(keybind2_pos, "messagemode");
		}
		
		if (over_list && row_hover && clicked)
		{
			UI_list_selected = i;
			clicked = 0;
		}
	}

	// if (over_list && clicked) clicked = 0;

	UI_Scrollbar(count, visible, list_size, list_pos, maxscroll);
}
