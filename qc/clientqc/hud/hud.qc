

/////////////////////////////////////
/////////////// HUD /////////////////
/////////////////////////////////////

void HUD_Draw()
{
	if(intermission || !cvar("hud_draw") || cvar("viewsize") > 100) return;
	if(!Player_IsAlive()) return;
	if(scoping) return;
	
	drawfont = FONT_SBAR;
	vector hud_size = [font_size * 2, font_size * 2];
	vector healthColor = [HUD_COLOR_x, (playerHealth / 100) * HUD_COLOR_y, (playerHealth / 100) * HUD_COLOR_z];
	string healthStr = strcat("+", ftos(playerHealth));
	drawstring([hud_size_x, vid_y - hud_size_x * 1.5], healthStr, hud_size, healthColor, HUD_ALPHA, 0);
	
	//medkits
	drawpic([hud_size_x, vid_y - hud_size_y * 2.5], "gfx/medkit", UI_FixedVector('24 24 0'), HUD_COLOR, HUD_ALPHA, 0);
	drawstring([hud_size_x + hud_size_x * 0.75, vid_y - hud_size_y * 2.5 + font_size * 0.1], ftos(getstati(STAT_MEDKITS)), UI_FixedVector('24 24 0'), HUD_COLOR, HUD_ALPHA, 0);
	
	//Ammo counter
	if(playerWeapon && playerWeapon != WP_KNIFE) 
	{
		string ammo = ftos(playerAmmo);
		float offset = stringwidth(ammo, true, hud_size) + hud_size_x;
		drawstring([vid_x - offset, vid_y - hud_size_y * 1.5], ammo, hud_size, HUD_COLOR, HUD_ALPHA, 0);
	
		if(playerWeapon != WP_GRENADE)
		{
			string clip = ftos(playerClip);
			if(strlen(clip) == 1) clip = strcat(" ", clip);
			clip = strcat(clip, "/");
			offset = offset + stringwidth(clip, true, UI_FixedVector('24 24 0'));
			drawstring([vid_x - offset, vid_y - hud_size_y * 1.2], clip, UI_FixedVector('24 24 0'), HUD_COLOR, HUD_ALPHA, 0);
		}
	}
	
	HUD_WeaponSelect();

	
	drawfont = FONT_DEFAULT;
	
	HUD_DrawThrowPower();
	
	if(!aiming) DrawCrosshair();
};
