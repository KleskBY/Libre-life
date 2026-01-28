
//DROPDOWN
float UI_dropdown_open;
string UI_dropdown_cvar;        // cvar holding selected index (float)
string UI_dropdown_items;       // "Easy|Medium|Hard"
float UI_dropdown_count;
vector UI_dropdown_pos;         // header top-left
float UI_dropdown_width;        // header width in pixels
float UI_dropdown_row_h;        // row height
entity UI_dropdown_owner;       // which window owns it (UI_draw_window when opened)
// mouse wheel (accumulated per-frame)
float UI_wheel;

// dropdown scrolling
float UI_dropdown_scroll;       // first visible item index (0..count-visible)
float UI_DROPDOWN_VISIBLE = 4;  // how many rows to show when open


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

	// skip idx items
	for (float i = 0; i < idx; i++)
	{
		float sep = strstrofs(s, "|", 0);
		if (sep < 0) return ""; // out of range
		s = substring(s, sep + 1, strlen(s) - (sep + 1));
	}

	float sep0 = strstrofs(s, "|", 0);
	if (sep0 < 0) return s;
	return substring(s, 0, sep0);
}

void UI_DropdownClose()
{
	UI_dropdown_open = 0;
	UI_dropdown_cvar = "";
	UI_dropdown_items = "";
	UI_dropdown_count = 0;
	UI_dropdown_owner = world;
	UI_dropdown_scroll = 0;
}

void UI_DropdownOpen(string cvar_name, string items, vector pos, float width, float row_h)
{
	UI_dropdown_open = 1;
	UI_dropdown_cvar = cvar_name;
	UI_dropdown_items = items;
	UI_dropdown_count = UI_ListCount(items);
	UI_dropdown_pos = pos;
	UI_dropdown_width = width;
	UI_dropdown_row_h = row_h;

	// this dropdown belongs to the window currently being drawn (or world if none)
	UI_dropdown_owner = UI_draw_window;

	// ensure current selection is visible
	float idx = cvar(cvar_name);
	if (idx < 0) idx = 0;
	if (idx > UI_dropdown_count - 1) idx = UI_dropdown_count - 1;

	UI_dropdown_scroll = idx - (UI_DROPDOWN_VISIBLE * 0.5);
	if (UI_dropdown_scroll < 0) UI_dropdown_scroll = 0;

	float maxscroll = UI_dropdown_count - UI_DROPDOWN_VISIBLE;
	if (maxscroll < 0) maxscroll = 0;
	if (UI_dropdown_scroll > maxscroll) UI_dropdown_scroll = maxscroll;

	clicked = 0;
}
string UI_Dropdown(string cvar_name, vector pos, float width, string items)
{
	float idx = cvar(cvar_name);
	float count = UI_ListCount(items);
	if (count <= 0) count = 1;
	if (idx < 0) idx = 0;
	if (idx > (count - 1)) idx = count - 1;

	string cur = UI_ListGet(items, idx);

	// If windows are capturing input, only allow controls in the input window
	if (UI_IsBehindWindow())
	{
		UI_FrameInput(pos, [width, font_size * 1.4]);
		UI_Text(cur, pos + [font_size * 0.4, font_size * 0.2]);
		UI_Text("▼", pos + [width - font_size * 0.9, font_size * 0.15]);
		return cur;
	}

	float header_h = font_size * 1.4;
	vector header_size = [width, header_h, 0];

	float header_hover = UI_MouseInRectSize(pos, header_size);

	UI_FrameInput(pos, header_size);
	UI_Text(cur, pos + [font_size * 0.4, font_size * 0.2, 0]);
	UI_Text("▼", pos + [width - font_size * 0.9, font_size * 0.15, 0], '0.85 0.85 0.85');

	float is_open = (UI_dropdown_open && UI_dropdown_cvar == cvar_name && UI_dropdown_owner == UI_draw_window);
	// If some other dropdown is open, this one just draws header (and should not be clickable)
	if (UI_dropdown_open && !is_open)
		return cur;
		
	// Toggle open on click
	if (header_hover && clicked)
	{
		if (is_open) UI_DropdownClose();
		else UI_DropdownOpen(cvar_name, items, pos, width, header_h);
		clicked = 0; // IMPORTANT: block click-through
		return cur;
	}



	// Draw open list
	if (is_open)
	{
		float row_h = UI_dropdown_row_h;
		vector list_pos = pos + [0, header_h, 0];

		float visible = UI_DROPDOWN_VISIBLE;
		if (visible < 1) visible = 1;
		if (visible > count) visible = count;

		float maxscroll = count - visible;
		if (maxscroll < 0) maxscroll = 0;

		if (UI_dropdown_scroll < 0) UI_dropdown_scroll = 0;
		if (UI_dropdown_scroll > maxscroll) UI_dropdown_scroll = maxscroll;

		vector list_size = [width, row_h * visible];

		float in_header = header_hover;
		float in_list = UI_MouseInRect(list_pos, list_pos + list_size);

		// Wheel scroll when cursor over header OR list
		if (UI_wheel != 0 && (in_header || in_list))
		{
			UI_dropdown_scroll = UI_dropdown_scroll - UI_wheel; // wheel up => smaller index
			if (UI_dropdown_scroll < 0) UI_dropdown_scroll = 0;
			if (UI_dropdown_scroll > maxscroll) UI_dropdown_scroll = maxscroll;

			// consume wheel so other widgets won't use it
			UI_wheel = 0;
		}

		UI_Frame(list_pos, list_size, 0);

		// Visible rows (scrolled)
		float start = UI_dropdown_scroll;

		for (float r = 0; r < visible; r++)
		{
			float i = start + r;

			vector row_pos = list_pos + [0, row_h * r, 0];
			vector row_size = [width, row_h, 0];

			float row_hover = UI_MouseInRectSize(row_pos, row_size);

			if (row_hover)
				drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.9, 0);

			string item = UI_ListGet(UI_dropdown_items, i);
			UI_Text(item, row_pos + [font_size * 0.4, font_size * 0.2, 0], '0.85 0.85 0.85');

			// Click row selects
			if (row_hover && clicked)
			{
				cmd(strcat(cvar_name, " ", ftos(i), "\n"));
				localsound("sound/misc/menu2.wav");
				UI_DropdownClose();

				// block click-through
				clicked = 0;
				return item;
			}
		}

		// Click inside dropdown should NEVER reach elements behind it
		if (clicked && (in_header || in_list))
		{
			clicked = 0;
		}

		// Click outside closes
		if (clicked)
		{
			if (!in_header && !in_list)
				UI_DropdownClose();
		}

		// Optional: scroll bar indicator (tiny)
		if (count > visible)
		{
			float bar_h = list_size_y;
			float knob_h = bar_h * (visible / count);
			if (knob_h < font_size * 0.6) knob_h = font_size * 0.6;

			float t = (maxscroll > 0) ? (UI_dropdown_scroll / maxscroll) : 0;
			float y = (bar_h - knob_h) * t;

			vector sb_pos = list_pos + [width - font_size * 0.4, 0, 0];
			drawfill(sb_pos, [font_size * 0.2, bar_h, 0], '0 0 0', 0.35, 0);
			drawfill(sb_pos + [0, y, 0], [font_size * 0.2, knob_h, 0], '1 1 1', 0.25, 0);
		}
	}

	return cur;
}
