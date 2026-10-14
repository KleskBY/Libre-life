// SCROLLVIEW / LIST
float ui_list_selected;
float ui_list_scroll;

float UI_KEYBIND_COUNT = 17;
string ui_keybind_labels[17];
string ui_keybind_commands[17];

void UI_InitKeybinds()
{
	ui_keybind_labels[0]  = ("Move forward");    ui_keybind_commands[0]  = ("+forward");
	ui_keybind_labels[1]  = ("Move back");       ui_keybind_commands[1]  = ("+back");
	ui_keybind_labels[2]  = ("Strafe left");     ui_keybind_commands[2]  = ("+moveleft");
	ui_keybind_labels[3]  = ("Strafe right");    ui_keybind_commands[3]  = ("+moveright");
	ui_keybind_labels[4]  = ("Look left");       ui_keybind_commands[4]  = ("+left");
	ui_keybind_labels[5]  = ("Look right");      ui_keybind_commands[5]  = ("+right");
	ui_keybind_labels[6]  = ("Jump");            ui_keybind_commands[6]  = ("+jump");
	ui_keybind_labels[7]  = ("Crouch");          ui_keybind_commands[7]  = ("+button3");
	ui_keybind_labels[8]  = ("Attack");          ui_keybind_commands[8]  = ("+attack");
	ui_keybind_labels[9]  = ("Attack 2");        ui_keybind_commands[9]  = ("+button6");
	ui_keybind_labels[10] = ("Next weapon");     ui_keybind_commands[10] = ("impulse 10");
	ui_keybind_labels[11] = ("Previous weapon"); ui_keybind_commands[11] = ("impulse 12");
	ui_keybind_labels[12] = ("Use");             ui_keybind_commands[12] = ("+use");
	ui_keybind_labels[13] = ("Reload");          ui_keybind_commands[13] = ("reload");
	ui_keybind_labels[14] = ("Heal");            ui_keybind_commands[14] = ("heal");
	ui_keybind_labels[15] = ("Flashlight");      ui_keybind_commands[15] = ("flashlight");
	ui_keybind_labels[16] = ("Chat");            ui_keybind_commands[16] = ("messagemode");
}

float UI_ScrollList(float list, vector list_pos, vector list_size, float maxscroll)
{
	if (ui_wheel == 0) return list;

	list = list - ui_wheel; // wheel up => smaller index
	if (list < 0) list = 0;
	if (list > maxscroll) list = maxscroll;
	ui_wheel = 0;
	return list;
}

// Shared scrollbar: a vertical track with a grabbable knob.
// sb_pos = top-left of track, bar_h = track height,
// count = total items, visible = visible items, scroll = current scroll offset.
//
// UI_ScrollbarInput runs BEFORE a list draws its rows, so a press on the bar is
// consumed there and does not also hit the row behind it. Each list passes its
// own id, so two bars on screen never share one drag.

#define UI_SB_HIT_PAD 0.5     // extra grab width either side, in font sizes

float ui_sb_dragId;           // list being dragged, 0 when none
float ui_sb_grabOffset;       // cursor y minus knob top at the moment of the grab

float UI_ScrollbarKnobH(float bar_h, float count, float visible)
{
	float h = bar_h * (visible / count);
	if (h < ui_font_size * UI_SCROLLBAR_KNOB_MIN) h = ui_font_size * UI_SCROLLBAR_KNOB_MIN;
	if (h > bar_h) h = bar_h;
	return h;
}

float UI_ScrollbarHit(vector sb_pos, float bar_h)
{
	float pad = ui_font_size * UI_SB_HIT_PAD;
	float w = ui_font_size * UI_SCROLLBAR_TRACK_WIDTH;
	return UI_MouseInRectSize([sb_pos_x - pad, sb_pos_y, 0], [w + pad * 2, bar_h, 0]);
}

float UI_ScrollbarInput(float id, vector sb_pos, float bar_h, float count, float visible, float scroll)
{
	if (!ui_mouse1_held && ui_sb_dragId == id) ui_sb_dragId = 0;
	if (count <= visible) return scroll;

	float maxscroll = count - visible;
	float knob_h = UI_ScrollbarKnobH(bar_h, count, visible);
	float travel = bar_h - knob_h;
	float knob_y = sb_pos_y + travel * (scroll / maxscroll);
	float can_input = !UI_IsBehindWindow();

	if (can_input && ui_clicked && UI_ScrollbarHit(sb_pos, bar_h))
	{
		// On the knob it keeps its grip; on the track the knob jumps under the
		// cursor and the drag carries on from there.
		float on_knob = ui_mouse_pos_y >= knob_y && ui_mouse_pos_y <= knob_y + knob_h;
		ui_sb_grabOffset = on_knob ? ui_mouse_pos_y - knob_y : knob_h * 0.5;
		ui_sb_dragId = id;
		ui_clicked = 0;
	}

	if (ui_sb_dragId != id) return scroll;
	if (travel <= 0) return scroll;

	float t = (ui_mouse_pos_y - ui_sb_grabOffset - sb_pos_y) / travel;
	if (t < 0) t = 0;
	if (t > 1) t = 1;
	return rint(t * maxscroll);
}

void UI_DrawScrollbar(vector sb_pos, float bar_h, float count, float visible, float scroll)
{
	if (count <= visible) return;

	float knob_h = UI_ScrollbarKnobH(bar_h, count, visible);
	float maxscroll = count - visible;
	if (maxscroll < 1) maxscroll = 1;
	float y = (bar_h - knob_h) * (scroll / maxscroll);

	float hot = ui_sb_dragId || (!UI_IsBehindWindow() && UI_ScrollbarHit(sb_pos, bar_h));
	vector knob_color = hot ? UI_SCROLLBAR_KNOB_COLOR * 1.5 : UI_SCROLLBAR_KNOB_COLOR;
	float knob_alpha = hot ? 1 : UI_SCROLLBAR_KNOB_ALPHA;

	drawfill(sb_pos, [ui_font_size * UI_SCROLLBAR_TRACK_WIDTH, bar_h, 0], UI_SCROLLBAR_TRACK_COLOR, UI_SCROLLBAR_TRACK_ALPHA, 0);
	drawfill(sb_pos + [0, y, 0], [ui_font_size * UI_SCROLLBAR_TRACK_WIDTH, knob_h, 0], knob_color, knob_alpha, 0);
}

void UI_KeybindList(vector pos, vector size, float count)
{
	float row_h = ui_font_size * 1.2;
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

	UI_Text("MOVEMENT", header_pos + [ui_font_size * 0.4, ui_font_size * 0.15, 0], UI_TEXT_HIGHLIGHTED);
	UI_Text("KEY/BUTTON", header_pos + [col1 + ui_font_size * 0.4, ui_font_size * 0.15, 0], UI_TEXT_HIGHLIGHTED);
	UI_Text("ALTERNATE", header_pos + [col1 + col2 + ui_font_size * 0.4, ui_font_size * 0.15, 0], UI_TEXT_HIGHLIGHTED);

	// list metrics
	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;
	
	// Scroll
	float maxscroll = count - visible;
	if (maxscroll < 0) maxscroll = 0;
	float over_list = UI_MouseInRect(list_pos, list_pos + list_size) && !UI_IsBehindWindow();
	if(over_list) ui_list_scroll = UI_ScrollList(ui_list_scroll, list_pos, list_size, maxscroll);

	vector sb_pos = list_pos + [list_size_x - ui_font_size * 0.6, 0, 0];
	ui_list_scroll = UI_ScrollbarInput(UI_SB_ID_KEYBINDS, sb_pos, list_size_y, count, visible, ui_list_scroll);

	for (float r = 0; r < visible; r++)
	{
		float i = ui_list_scroll + r;
		if (i >= count) break;

		vector row_pos = list_pos + [0, row_h * r, 0];
		vector row_size = [list_size_x, row_h, 0];
		float row_hover = UI_MouseInRectSize(row_pos, row_size);
		if (i == ui_list_selected)
			drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.75, 0);
		else if (row_hover)
			drawfill(row_pos, row_size, '1 1 1', 0.06, 0);

		vector label_pos = row_pos + [ui_font_size * 0.4, ui_font_size * 0.15, 0];
		vector keybind_pos = row_pos + [col1 + ui_font_size * 0.4, ui_font_size * 0.15, 0];
		vector keybind2_pos = row_pos + [col1 + col2 + ui_font_size * 0.4, ui_font_size * 0.15, 0];
		if (i < UI_KEYBIND_COUNT)
		{
			UI_Text(ui_keybind_labels[i], label_pos);
			UI_Keybind(keybind_pos, ui_keybind_commands[i]);
			UI_Keybind2(keybind2_pos, ui_keybind_commands[i]);
		}

		if (over_list && row_hover && ui_clicked)
		{
			ui_list_selected = i;
			ui_clicked = 0;
		}
	}

	UI_DrawScrollbar(sb_pos, list_size_y, count, visible, ui_list_scroll);
}
