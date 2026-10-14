
//DROPDOWN
float ui_dropdown_open;
string ui_dropdown_cvar;
string ui_dropdown_items;
float ui_dropdown_count;
vector ui_dropdown_pos;
float ui_dropdown_width;
float ui_dropdown_row_h;
entity ui_dropdown_owner;
float ui_dropdown_scroll;


float UI_ListCount(string items)
{
	if (strlen(items) <= 0) return 0;

	float count = 1;
	for (float i = 0; i < strlen(items); i++)
	{
		if (substring(items, i, 1) == "|")
			count = count + 1;
	}
	return count;
}

string UI_ListGet(string items, float idx)
{
	string s = items;

	for (float i = 0; i < idx; i++)
	{
		float sep = strstrofs(s, "|", 0);
		if (sep < 0) return "";
		s = substring(s, sep + 1, strlen(s) - (sep + 1));
	}

	float sep0 = strstrofs(s, "|", 0);
	if (sep0 < 0) return s;
	return substring(s, 0, sep0);
}

void UI_DropdownClose()
{
	ui_dropdown_open = 0;
	ui_dropdown_cvar = "";
	ui_dropdown_items = "";
	ui_dropdown_count = 0;
	ui_dropdown_owner = world;
	ui_dropdown_scroll = 0;
}

void UI_DropdownOpen(string cvar_name, string items, vector pos, float width, float row_h)
{
	ui_dropdown_open = 1;
	ui_dropdown_cvar = cvar_name;
	ui_dropdown_items = items;
	ui_dropdown_count = UI_ListCount(items);
	ui_dropdown_pos = pos;
	ui_dropdown_width = width;
	ui_dropdown_row_h = row_h;

	ui_dropdown_owner = ui_draw_window;

	float idx = cvar(cvar_name);
	if (idx < 0) idx = 0;
	if (idx > ui_dropdown_count - 1) idx = ui_dropdown_count - 1;

	ui_dropdown_scroll = idx - (UI_DROPDOWN_VISIBLE * 0.5);
	if (ui_dropdown_scroll < 0) ui_dropdown_scroll = 0;

	float maxscroll = ui_dropdown_count - UI_DROPDOWN_VISIBLE;
	if (maxscroll < 0) maxscroll = 0;
	if (ui_dropdown_scroll > maxscroll) ui_dropdown_scroll = maxscroll;

	ui_clicked = 0;
}

string UI_Dropdown(string cvar_name, vector pos, float width, string items)
{
	float idx = cvar(cvar_name);
	float count = UI_ListCount(items);
	if (count <= 0) count = 1;
	if (idx < 0) idx = 0;
	if (idx > (count - 1)) idx = count - 1;

	string cur = UI_ListGet(items, idx);

	if (UI_IsBehindWindow())
	{
		UI_FrameInput(pos, [width, ui_font_size * UI_DROPDOWN_HEADER_H_MULT]);
		UI_Text(cur, pos + [ui_font_size * UI_DROPDOWN_TEXT_PAD, ui_font_size * 0.2]);
		UI_Text("▼", pos + [width - ui_font_size * UI_DROPDOWN_ARROW_PAD, ui_font_size * UI_EDITOR_TEXT_Y_OFFSET]);
		return cur;
	}

	float header_h = ui_font_size * UI_DROPDOWN_HEADER_H_MULT;
	vector header_size = [width, header_h, 0];

	float header_hover = UI_MouseInRectSize(pos, header_size);

	UI_FrameInput(pos, header_size);
	UI_Text(cur, pos + [ui_font_size * UI_DROPDOWN_TEXT_PAD, ui_font_size * 0.2, 0]);
	UI_Text("▼", pos + [width - ui_font_size * UI_DROPDOWN_ARROW_PAD, ui_font_size * UI_EDITOR_TEXT_Y_OFFSET, 0], UI_SYN_DEFAULT);

	float is_open = (ui_dropdown_open && ui_dropdown_cvar == cvar_name && ui_dropdown_owner == ui_draw_window);
	if (ui_dropdown_open && !is_open)
		return cur;

	if (header_hover && ui_clicked)
	{
		if (is_open) UI_DropdownClose();
		else UI_DropdownOpen(cvar_name, items, pos, width, header_h);
		ui_clicked = 0;
		return cur;
	}

	// List is drawn as a post-pass overlay by UI_DrawDropdownOverlay() in ui_windows.qc
	return cur;
}

// Called by UI_DrawWindows after all window content is drawn, so the list always renders
// on top and catches clicks before any element drawn earlier in the frame.
void UI_DrawScrollbar(vector sb_pos, float bar_h, float count, float visible, float scroll);
float UI_ScrollbarInput(float id, vector sb_pos, float bar_h, float count, float visible, float scroll);
void UI_DrawDropdownOverlay()
{
	if (!ui_dropdown_open) return;

	float count  = ui_dropdown_count;
	float row_h  = ui_dropdown_row_h;
	vector pos   = ui_dropdown_pos;
	float width  = ui_dropdown_width;

	vector list_pos  = pos + [0, row_h, 0];

	float visible = UI_DROPDOWN_VISIBLE;
	if (visible < 1) visible = 1;
	if (visible > count) visible = count;

	float maxscroll = count - visible;
	if (maxscroll < 0) maxscroll = 0;
	if (ui_dropdown_scroll < 0) ui_dropdown_scroll = 0;
	if (ui_dropdown_scroll > maxscroll) ui_dropdown_scroll = maxscroll;

	vector list_size = [width, row_h * visible, 0];

	float in_header = UI_MouseInRectSize(pos, [width, row_h, 0]);
	float in_list   = UI_MouseInRect(list_pos, list_pos + list_size);

	if (ui_wheel != 0 && (in_header || in_list))
	{
		ui_dropdown_scroll = ui_dropdown_scroll - ui_wheel;
		if (ui_dropdown_scroll < 0) ui_dropdown_scroll = 0;
		if (ui_dropdown_scroll > maxscroll) ui_dropdown_scroll = maxscroll;
		ui_wheel = 0;
	}

	UI_Frame(list_pos, list_size, 0);

	ui_dropdown_scroll = UI_ScrollbarInput(UI_SB_ID_DROPDOWN, list_pos + [width - ui_font_size * 0.4, 0, 0],
	                                       list_size_y, count, visible, ui_dropdown_scroll);

	float start = ui_dropdown_scroll;
	for (float r = 0; r < visible; r++)
	{
		float i = start + r;
		vector row_pos  = list_pos + [0, row_h * r, 0];
		vector row_size = [width, row_h, 0];
		float row_hover = UI_MouseInRectSize(row_pos, row_size);

		if (row_hover)
			drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.9, 0);

		string item = UI_ListGet(ui_dropdown_items, i);
		UI_Text(item, row_pos + [ui_font_size * UI_DROPDOWN_TEXT_PAD, ui_font_size * 0.2, 0], UI_SYN_DEFAULT);

		if (row_hover && ui_clicked)
		{
			cmd(strcat(ui_dropdown_cvar, " ", ftos(i), "\n"));
			UI_PlaySound("sound/misc/menu2.wav");
			UI_DropdownClose();
			ui_clicked = 0;
			return;
		}
	}

	// Scrollbar
	UI_DrawScrollbar(list_pos + [width - ui_font_size * 0.4, 0, 0], list_size_y, count, visible, ui_dropdown_scroll);

	if (ui_clicked && (in_header || in_list))
		ui_clicked = 0;

	if (ui_clicked && !in_header && !in_list)
		UI_DropdownClose();
}
