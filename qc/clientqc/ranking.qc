
//////////////////////////////////
//////////// RANKINGS ////////////
//////////////////////////////////
float lastPing;
void Rankings_Draw()
{
	if(intermission) return;
	if(cvar("gamemode") == MODE_SP) return;
	if(!showScores && !intermission) return;

	if(lastPing + 5 < time)
	{
		lastPing = time;
		localcmd("ping\n");
	}
	
	drawstring([vid_x / 2 - stringwidth("RANKING", true, [font_size * 2, font_size * 2]) / 2, font_size * 4], "RANKING", [font_size * 2, font_size * 2], '1 1 1', 1, 0);

	drawfill([vid_x / 2 - vid_y / 2, vid_y / 2 - vid_y / 4], [vid_y, vid_y / 2], '0.1 0.1 0.1', 0.5, 0);
	drawfill([vid_x / 2 - vid_y / 2, vid_y / 4 - font_size], [vid_y, font_size], '0.9 0.9 0.9', 0.45, 0);
	
	UI_Text("NAME", [vid_x / 4, vid_y / 4 - font_size]);
	UI_Text("PING", [vid_x / 4 + vid_y - font_size * 14, vid_y / 4 - font_size]);
	UI_Text("FRAGS", [vid_x / 4 + vid_y - font_size * 8, vid_y / 4 - font_size]);

	vector pos = [vid_x / 4, vid_y / 4];
	for(float i = 0; i < 32; i++)
	{
		string player_name = getplayerkeyvalue(i, "name");
		if(player_name != "" || player_name)
		{
			string player_kills = getplayerkeyvalue(i, "frags");
			string player_colors = getplayerkeyvalue(i, "colors");
			string player_ping = getplayerkeyvalue(i, "ping");

			
			vector col = '1 1 1';
			if(player_localnum == i) col = '.8 .8 .5';
			drawstring(pos, player_name, [font_size, font_size], col, 1, 0);
			pos_x = vid_x / 4 + vid_y - font_size * 14;
			drawstring(pos, player_ping, [font_size, font_size], col, 1, 0);
			pos_x = vid_x / 4 + vid_y - font_size * 6;
			drawstring(pos, player_kills, [font_size, font_size], col, 1, 0);
			pos_y = pos_y + font_size;
			pos_x = vid_x / 4;
		}
	}
	
	UI_Text(mapname, [vid_x / 2 - vid_y / 2,vid_y -  vid_y / 5]);
	UI_Text(ftos(floor(time)), [vid_x / 2 + vid_y / 2 - font_size * strlen(ftos(floor(time))), vid_y - vid_y / 5]);
}