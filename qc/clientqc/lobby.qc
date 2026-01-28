

void Lobby_Start()
{
	setsensitivityscale(1);
	showCursor = false;
	
	string startcmd = "say /start ";
	startcmd = strcat(startcmd, ftos(cvar("saved1") + 1)); //gamemode
	startcmd = strcat(startcmd, " ");
	startcmd = strcat(startcmd, cvar_string("skill")); //skill
	startcmd = strcat(startcmd, " ");
	startcmd = strcat(startcmd, exec); //map
	startcmd = strcat(startcmd, "\n");
	localcmd(startcmd);
};

void Lobby_KickPlayer()
{
	localcmd(strcat("say /kick ", exec));
};

void Lobby_Draw()
{
	if(mapname != "maps/lobby.bsp") return;
	
	setsensitivityscale(0);
	showCursor = true;

	drawfill([font_size * 2, font_size * 3], [vid_x / 2, vid_y - font_size * 6], '0.1 0.1 0.1', 0.5, 0);
	drawfill([font_size * 2, font_size * 3], [vid_x / 2, font_size], '0.9 0.9 0.9', 0.45, 0);
	// text_center("LOBBY", [font_size * 2, font_size * 4]);
	UI_Text("LOBBY", [font_size * 12, font_size * 3]);

	UI_Text("Game mode:", [font_size * 2, font_size * 4]);
	string gamemode = UI_Combobox([vid_x / 2 - font_size * 8, font_size * 4], 8, "COOP|DM", "saved1", 2);

	UI_Text("Map:      ", [font_size * 2, font_size * 8]);
	string map;
	if(cvar("saved1") == MODE_COOP - 1) map = UI_Combobox([vid_x / 2 - font_size * 8, font_size * 8], 8, "e1m1|e1m2|e1m3|e1m4|e1m5|e1m6|e1m7|e1m8", "saved2", 8);
	if(cvar("saved1") == MODE_DM - 1) map = UI_Combobox([vid_x / 2 - font_size * 8, font_size * 8], 8, "cordon|factory", "saved2", 2);
	
	if(cvar("saved1") != MODE_DM - 1)
	{
		UI_Text("Difficulty:", [font_size * 2, font_size * 6]);
		string diff = UI_Combobox([vid_x / 2 - font_size * 8, font_size * 6], 8, "Easy|Normal|Hard", "skill", 3);
	}

	if(strlen(map) > 0) drawpic([font_size * 4, font_size * 10], strcat("maps/", map), [vid_x / 2 - font_size * 4, vid_y / 2], '1 1 1', 1, 0);

	UI_Button("START", [font_size * 13, vid_y - font_size * 4], Lobby_Start, map);
	
	
	drawfill([vid_x / 2 + font_size * 3, font_size * 3], [vid_x / 2 - font_size * 5, vid_y - font_size * 6], '0.1 0.1 0.1', 0.5, 0);
	drawfill([vid_x / 2 + font_size * 3, font_size * 3], [vid_x / 2 - font_size * 5, font_size], '0.9 0.9 0.9', 0.45, 0);
	UI_Text("PLAYERS", [vid_x / 2 + font_size * 11, font_size * 3]);


	float offset = 0;
	for(float i = 0; i < 32; i++)
	{
		string player_name = getplayerkeyvalue(i, "name");
		if(player_name != "" || player_name)
		{
			if(player_localnum == i) 
			{
				player_name = strcat("> ", player_name);
				UI_Text(player_name, [vid_x / 2 + font_size * 3, font_size * 4 + offset], '.75 .75 .5');
			}
			else 
			{
				UI_Button("KICK", [vid_x - font_size * 6, font_size * 4 + offset], Lobby_KickPlayer, player_name);
				UI_Text(player_name, [vid_x / 2 + font_size * 3, font_size * 4 + offset]);
			}
			offset = offset + font_size;
		}
	}
};