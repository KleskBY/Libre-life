// SERVER BROWSER UI STATE
float UI_srv_dirty;
float UI_srv_scroll;           // first visible row
string UI_srv_selected_ip;     // selection uses ip/cname

.string ip;
.string name;
.string map;
.string mod_name;
.float ping;
.float players;
.float slots;

// internal cache keys (avoid calling gethostcacheindexforkey every row every frame)
float UI_srv_key_ping;
float UI_srv_key_map;
float UI_srv_key_slots;
float UI_srv_key_players;
float UI_srv_key_ip;
float UI_srv_key_name;
float UI_srv_key_mod;

// one-shot refresh flag
float UI_srv_once;


void UI_ServerBrowser_RequestRefresh()
{
	cmd("net_slist\n");
	UI_srv_dirty = 1;
}

void UI_ServerBrowser_InitKeys()
{
	UI_srv_key_ping    = gethostcacheindexforkey("ping");
	UI_srv_key_map     = gethostcacheindexforkey("map");
	UI_srv_key_slots   = gethostcacheindexforkey("maxplayers");
	UI_srv_key_players = gethostcacheindexforkey("numplayers");
	// UI_srv_key_players = gethostcacheindexforkey("numbots");
	// UI_srv_key_players = gethostcacheindexforkey("numhumans");
	// UI_srv_key_players = gethostcacheindexforkey("freeslots");
	// UI_srv_key_players = gethostcacheindexforkey("protocol");
	// UI_srv_key_players = gethostcacheindexforkey("category");
	// UI_srv_key_players = gethostcacheindexforkey("isfavorite");
	UI_srv_key_ip      = gethostcacheindexforkey("cname");   // or "addr" depending on engine
	UI_srv_key_name    = gethostcacheindexforkey("name");
	UI_srv_key_mod     = gethostcacheindexforkey("mod");
}

void UI_ServerBrowser_JoinSelected()
{
	if (strlen(UI_srv_selected_ip) <= 0) return;

	cmd(strcat("connect ", UI_srv_selected_ip, "\n"));

	#ifdef MENUQC
		m_toggle(0);
	#endif
}

void UI_ServerBrowser_Select(string ip)
{
	UI_srv_selected_ip = ip;
}

void UI_ServerBrowser_Table(vector pos, vector size)
{
	if (!UI_srv_once)
	{
		UI_srv_once = 1;
		UI_ServerBrowser_RequestRefresh();
		UI_ServerBrowser_InitKeys();
	}
	
	float total = gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT);
	if (total < 0) total = 0;
	float row_h = font_size * 1.15;
	float header_h = font_size * 1.2;
	UI_FrameInput(pos, size);
	drawfill(pos, [size_x, header_h, 0], '0 0 0', 0.22, 0);

	// columns (tweak)
	float col_name = size_x * 0.55;
	float col_map  = size_x * 0.20;
	float col_slots= size_x * 0.12;
	float col_ping = size_x * 0.13;

	UI_Text("Name",  pos + [font_size * 0.4,  font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Map",   pos + [col_name + font_size * 0.4, font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Slots", pos + [col_name + col_map + font_size * 0.4, font_size * 0.12, 0], '0.85 0.85 0.85');
	UI_Text("Ping",  pos + [col_name + col_map + col_slots + font_size * 0.4, font_size * 0.12, 0], '0.85 0.85 0.85');

	vector list_pos = pos + [0, header_h, 0];
	vector list_size = [size_x, size_y - header_h, 0];

	float visible = floor(list_size_y / row_h);
	if (visible < 1) visible = 1;

	float maxscroll = total - visible;
	if (maxscroll < 0) maxscroll = 0;

	float can_input = !UI_IsBehindWindow();
	float over_list = can_input && UI_MouseInRect(list_pos, list_pos + list_size);
	if (over_list) UI_srv_scroll = UI_ScrollList(UI_srv_scroll, list_pos, list_size, maxscroll);
	if (UI_srv_scroll < 0) UI_srv_scroll = 0;
	if (UI_srv_scroll > maxscroll) UI_srv_scroll = maxscroll;

	float start = UI_srv_scroll;
	float end = start + visible;
	float r;
	for (float i = 0; i < total; i++)
	{
		if(i < start || i > end) continue;
		float ping_data = gethostcachenumber(UI_srv_key_ping, i);
		float slots_data = gethostcachenumber(UI_srv_key_slots, i);
		float players_data = gethostcachenumber(UI_srv_key_players, i);

		// filter out invalid rows
		if (players_data < 0) continue;
		if (slots_data < 2) continue;

		string addr  = gethostcachestring(UI_srv_key_ip, i);
		string nm  = gethostcachestring(UI_srv_key_name, i);
		string mp  = gethostcachestring(UI_srv_key_map, i);
		string modn = gethostcachestring(UI_srv_key_mod, i);
		if (strlen(nm) > 32) nm = substring(nm, 0, 32);
		if (strlen(mp) > 16) mp = substring(mp, 0, 16);

		vector row_pos = list_pos + [0, row_h * r, 0];
		vector row_size = [list_size_x, row_h, 0];

		float hover = can_input && UI_MouseInRectSize(row_pos, row_size);
		if (UI_srv_selected_ip == addr)
			drawfill(row_pos, row_size, '0.55 0.50 0.15', 0.70, 0);
		else if (hover)
			drawfill(row_pos, row_size, '1 1 1', 0.05, 0);

		UI_Text(nm, row_pos + [font_size * 0.4, font_size * 0.10, 0]);
		UI_Text(mp,  row_pos + [col_name + font_size * 0.4, font_size * 0.10, 0], '0.9 0.9 0.9');
		UI_Text(strcat(ftos(players_data), "/", ftos(slots_data)),
				row_pos + [col_name + col_map + font_size * 0.4, font_size * 0.10, 0], '0.9 0.9 0.9');
		UI_Text(ftos(ping_data),
				row_pos + [col_name + col_map + col_slots + font_size * 0.4, font_size * 0.10, 0], '0.9 0.9 0.9');

		if (hover && clicked)
		{
			if (UI_srv_selected_ip == addr)
				UI_ServerBrowser_JoinSelected();
			else
				UI_ServerBrowser_Select(addr);

			clicked = 0;
		}
		r = r + 1;
	}

	// "Refreshing..." if list empty
	if (total <= 0)
	{
		string refresh = "Refreshing...";
		float f = rint(UI_GetTime() * 10) % 4;
		if (f == 0) refresh = "Refreshing";
		if (f == 1) refresh = "Refreshing.";
		if (f == 2) refresh = "Refreshing..";
		if (f == 3) refresh = "Refreshing...";

		UI_Text(refresh, list_pos + [size_x * 0.35, list_size_y * 0.4, 0], '0.85 0.85 0.85');
	}

	if (can_input && clicked && UI_MouseInRectSize(pos, size))
		clicked = 0;

	UI_Scrollbar(total, visible, list_size, list_pos, maxscroll);
}

entity win_servers;

void UI_DrawServersContents()
{
	vector pos = win_servers.UI_win_pos;
	vector size = win_servers.UI_win_size;
	vector base = pos + [font_size * 0.8, font_size * 2.0, 0];

	UI_Text("Select a server to join.", base, '0.85 0.85 0.85');

	vector panel_pos  = base + [0, font_size * 1.3, 0];
	vector panel_size = [size_x - font_size * 1.6, size_y - font_size * 5.5, 0];
	UI_ServerBrowser_Table(panel_pos, panel_size);

	vector button_size = [font_size * 3.5, font_size * 1.25, 0];
	vector btn_base = pos + size - button_size - [font_size * 0.8, font_size * 0.5, 0];

	UI_Button2("Refresh", btn_base - [font_size * 8.0, 0, 0], button_size, UI_Cmd, "net_slist\n"); // or UI_ServerBrowser_RequestRefresh
	UI_Button2("Join",    btn_base - [font_size * 4.0, 0, 0], button_size, UI_ServerBrowser_JoinSelected, "");
	UI_Button2("Cancel",  btn_base,                       button_size, UI_ToggleWindow, "Servers");
}
