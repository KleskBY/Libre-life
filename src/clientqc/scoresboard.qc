
void Score_Draw()
{
	if(intermission == 2) return;
	if(!intermission && !showScores) return;
	if(cvar("gamemode") != MODE_SP && !(cvar("gamemode") == MODE_COOP && intermission)) return;

	if(intermission)
	{
		if(!completedTime) completedTime = time;
		drawstring([ui_vid_x / 2 - stringwidth("COMPLETED", true, [ui_font_size * 2, ui_font_size * 2]) / 2 + ui_font_size, ui_vid_y / 2 - ui_font_size * 8], "COMPLETED", [ui_font_size * 2, ui_font_size * 2], '1 1 1', 1, 0);
		UI_Text("TIME:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 - ui_font_size * 6]); 
		UI_Text(substring(ftos(completedTime), 0, strstrofs(ftos(completedTime), ".", 0) + 2), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 - ui_font_size * 6]);
	}
	else 
	{
		drawstring([ui_vid_x / 2 - stringwidth(world.message, true, [ui_font_size, ui_font_size]) / 2 + ui_font_size, ui_vid_y / 2 - ui_font_size * 8], world.message, [ui_font_size, ui_font_size ], '1 1 1', 1, 0);
		UI_Text("TIME:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 - ui_font_size * 6]); 
		UI_Text(substring(ftos(time), 0, strstrofs(ftos(time), ".", 0) + 2), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 - ui_font_size * 6]);
	}
	
	UI_Text("KILLS:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 - ui_font_size * 4]); 
	UI_Text(strcat(ftos(Stat_GetInt(STAT_MONSTERS)), "/", ftos(Stat_GetInt(STAT_TOTALMONSTERS))), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 - ui_font_size * 4]);
	UI_Text("ITEMS:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 - ui_font_size * 2]); 
	UI_Text(strcat(ftos(Stat_GetInt(STAT_PICKED_ITEMS)), "/", ftos(Stat_GetInt(STAT_TOTALITEMS))), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 - ui_font_size * 2]);
	UI_Text("HEALTH:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2]); 
	UI_Text(ftos(Stat_GetInt(STAT_HEALTH)), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2]);
	UI_Text("SECRETS:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 + ui_font_size * 2]); 
	UI_Text(strcat(ftos(Stat_GetInt(STAT_SECRETS)), "/", ftos(Stat_GetInt(STAT_TOTALSECRETS))), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 + ui_font_size * 2]);
	UI_Text("MAPNAME:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 + ui_font_size * 4]); 
	UI_Text(substring(mapname, 5, strlen(mapname) - 9), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 + ui_font_size * 4]);
	UI_Text("PLAYERS:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 + ui_font_size * 6]); 
	UI_Text(ftos(maxclients), [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 + ui_font_size * 6]);
	if(Stat_GetInt(STAT_SHOTS))
	{
		UI_Text("ACCURACY:", [ui_vid_x / 2 - ui_font_size * 7, ui_vid_y / 2 + ui_font_size * 8]); 
		UI_Text(strcat(ftos(Stat_GetInt(STAT_HITS)), "/", ftos(Stat_GetInt(STAT_SHOTS)), "(", ftos(floor(Stat_GetInt(STAT_HITS) / Stat_GetInt(STAT_SHOTS) * 100)), "%)")  , [ui_vid_x / 2 + ui_font_size * 6, ui_vid_y / 2 + ui_font_size * 8]);
	}
}
