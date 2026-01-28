
////////////////////////////
////////// SCORE ///////////
////////////////////////////

void Score_Draw()
{
	if(intermission == 2) return;
	if(!intermission && !showScores) return;
	if(cvar("gamemode") != MODE_SP && !(cvar("gamemode") == MODE_COOP && intermission)) return;

	if(intermission)
	{
		if(!completedTime) completedTime = time;
		drawstring([vid_x / 2 - stringwidth("COMPLETED", true, [font_size * 2, font_size * 2]) / 2 + font_size, vid_y / 2 - font_size * 8], "COMPLETED", [font_size * 2, font_size * 2], '1 1 1', 1, 0);
		UI_Text("TIME:", [vid_x / 2 - font_size * 7, vid_y / 2 - font_size * 6]); 
		UI_Text(substring(ftos(completedTime), 0, strstrofs(ftos(completedTime), ".", 0) + 2), [vid_x / 2 + font_size * 6, vid_y / 2 - font_size * 6]);
	}
	else 
	{
		// text_center(world.message, [vid_x / 2, vid_y / 2 - font_size * 8]);
		drawstring([vid_x / 2 - stringwidth(world.message, true, [font_size, font_size]) / 2 + font_size, vid_y / 2 - font_size * 8], world.message, [font_size, font_size ], '1 1 1', 1, 0);
		UI_Text("TIME:", [vid_x / 2 - font_size * 7, vid_y / 2 - font_size * 6]); 
		UI_Text(substring(ftos(time), 0, strstrofs(ftos(time), ".", 0) + 2), [vid_x / 2 + font_size * 6, vid_y / 2 - font_size * 6]);
	}
	
	UI_Text("KILLS:", [vid_x / 2 - font_size * 7, vid_y / 2 - font_size * 4]); 
	UI_Text(strcat(ftos(getstati(STAT_MONSTERS)), "/", ftos(getstati(STAT_TOTALMONSTERS))), [vid_x / 2 + font_size * 6, vid_y / 2 - font_size * 4]);
	UI_Text("ITEMS:", [vid_x / 2 - font_size * 7, vid_y / 2 - font_size * 2]); 
	UI_Text(strcat(ftos(getstati(STAT_PICKED_ITEMS)), "/", ftos(getstati(STAT_TOTALITEMS))), [vid_x / 2 + font_size * 6, vid_y / 2 - font_size * 2]);
	UI_Text("HEALTH:", [vid_x / 2 - font_size * 7, vid_y / 2]); 
	UI_Text(ftos(getstati(STAT_HEALTH)), [vid_x / 2 + font_size * 6, vid_y / 2]);
	UI_Text("SECRETS:", [vid_x / 2 - font_size * 7, vid_y / 2 + font_size * 2]); 
	UI_Text(strcat(ftos(getstati(STAT_SECRETS)), "/", ftos(getstati(STAT_TOTALSECRETS))), [vid_x / 2 + font_size * 6, vid_y / 2 + font_size * 2]);
	UI_Text("MAPNAME:", [vid_x / 2 - font_size * 7, vid_y / 2 + font_size * 4]); 
	UI_Text(substring(mapname, 5, strlen(mapname) - 9), [vid_x / 2 + font_size * 6, vid_y / 2 + font_size * 4]);
	UI_Text("PLAYERS:", [vid_x / 2 - font_size * 7, vid_y / 2 + font_size * 6]); 
	UI_Text(ftos(maxclients), [vid_x / 2 + font_size * 6, vid_y / 2 + font_size * 6]);
	if(getstati(STAT_SHOTS))
	{
		UI_Text("ACCURACY:", [vid_x / 2 - font_size * 7, vid_y / 2 + font_size * 8]); 
		UI_Text(strcat(ftos(getstati(STAT_HITS)), "/", ftos(getstati(STAT_SHOTS)), "(", ftos(floor(getstati(STAT_HITS) / getstati(STAT_SHOTS) * 100)), "%)")  , [vid_x / 2 + font_size * 6, vid_y / 2 + font_size * 8]);
	}
}
