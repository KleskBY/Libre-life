
float lastHealthSeen, lastArmorSeen, lastAmmoSeen, lastClipSeen;
float healthFade, armorFade, ammoFade;

float HUD_PulseAlpha(float fade)
{
	float a = HUD_MIN_ALPHA + (fade / HUD_FADE_TIME) * (128.0 / 255.0);
	if (a > 1) a = 1;
	return a;
}

void HUD_UpdateFades()
{
	if (playerHealth != lastHealthSeen) { healthFade = HUD_FADE_TIME; lastHealthSeen = playerHealth; }
	if (playerArmor  != lastArmorSeen ) { armorFade  = HUD_FADE_TIME; lastArmorSeen  = playerArmor;  }
	if (playerAmmo != lastAmmoSeen || playerClip != lastClipSeen)
	{
		ammoFade = HUD_FADE_TIME;
		lastAmmoSeen = playerAmmo;
		lastClipSeen = playerClip;
	}
	healthFade -= frametime * HUD_FADE_DECAY;
	armorFade  -= frametime * HUD_FADE_DECAY;
	ammoFade   -= frametime * HUD_FADE_DECAY;
	if (healthFade < 0) healthFade = 0;
	if (armorFade  < 0) armorFade  = 0;
	if (ammoFade   < 0) ammoFade   = 0;
}

vector HUD_PainColor()
{
	if (playerHealth > 25) return HUD_RGB_YELLOWISH;
	return HUD_RGB_REDISH;
}

void HUD_DrawHealth(vector hud_size, float hud_y)
{
	if (!playerHasSuit) return;

	float a = HUD_PulseAlpha(healthFade);
	if (playerHealth <= 15) a = 1.0;

	vector color = HUD_PainColor();
	float cross_x = hud_size_x * 0.5;

	// Cross icon
	drawpic([cross_x, hud_y + hud_size_y * 0.2], "gfx/hud_cross", hud_size, color, a, DRAWFLAG_ADDITIVE);

	// Number
	string healthStr = ftos(playerHealth);
	
	float num_x = hud_size_x * 1.5;
	drawstring([num_x, hud_y + hud_size_y * 0.1], healthStr, hud_size, color, a, 0);

	float numW = stringwidth(healthStr, true, hud_size);
	float bar_x = num_x + numW + hud_size_x * 0.2;
	drawfill([bar_x, hud_y + hud_size_y * 0.2], [hud_size_x * 0.075, hud_size_y * 0.7], HUD_RGB_YELLOWISH, a, 0);


	a = HUD_PulseAlpha(armorFade);
	color = HUD_RGB_YELLOWISH;

	float armor_x = bar_x;

	// suit_empty: full outline
	drawpic([armor_x, hud_y], "gfx/hud_suit_empty", hud_size, color, a, DRAWFLAG_ADDITIVE);

	// suit_full: clipped from top so only bottom (charge%) shows
	if (playerArmor > 0)
	{
		float pct = playerArmor / 100;
		if (pct > 1) pct = 1;
		float clip_top = 1.0 - pct;
		drawsubpic([armor_x, hud_y + hud_size_y * clip_top], [hud_size_x, hud_size_y * pct],
			"gfx/hud_suit_full", [0, clip_top], [1, pct], color, a, DRAWFLAG_ADDITIVE);
	}

	// Number
	string armorStr = ftos(playerArmor);
	float armor_num_x = armor_x + hud_size_x * 1.2;
	drawstring([armor_num_x, hud_y + hud_size_y * 0.1], armorStr, hud_size, color, a, 0);


}

void HUD_DrawFlashlight(vector hud_size)
{
	if (!playerHasSuit) return;

	float on = playerFlashOn;
	float bat = playerFlashBattery / 100;
	if (bat > 1) bat = 1;
	if (bat < 0) bat = 0;
	float a = on ? (225.0/255.0) : HUD_MIN_ALPHA;
	vector color = (bat < 0.20) ? HUD_RGB_REDISH : HUD_RGB_YELLOWISH;

	float fl_x = ui_vid_x - hud_size_x * 1.5;
	float fl_y = hud_size_y * 0.5;

	// Casing
	drawpic([fl_x, fl_y], "gfx/hud_flash_empty", hud_size, color, a, DRAWFLAG_ADDITIVE);

	// Beam (when on)
	if (on)
	{
		drawpic([fl_x + hud_size_x * 0.75, fl_y], "gfx/hud_flash_beam", hud_size, color, a, DRAWFLAG_ADDITIVE);
	}

	// Energy
	if (bat > 0)
	{
		float clip_left = 1.0 - bat;
		drawsubpic([fl_x + hud_size_x * clip_left, fl_y],[hud_size_x * bat, hud_size_y], "gfx/hud_flash_full", [clip_left, 0], [bat, 1], color, a, DRAWFLAG_ADDITIVE);
	}
}

void HUD_DrawAmmo(vector hud_size, float hud_y)
{
	if (!playerWeapon || playerWeapon == WEAPON_CROWBAR) return;
	float wid = Weapon_IDFromBit(playerWeapon);
	if (wid == WID_NONE) return;
	float hasClip = (playerWeapon != WEAPON_HANDGRENADE && playerWeapon != WEAPON_SATCHEL
				  && playerWeapon != WEAPON_SNARK && playerWeapon != WEAPON_TRIPMINE
				  && playerWeapon != WEAPON_GAUSS && playerWeapon != WEAPON_EGON
				  && playerWeapon != WEAPON_HORNETGUN);
	vector color = HUD_RGB_YELLOWISH;
	float a = HUD_PulseAlpha(ammoFade);
	float y = rint(hud_y + hud_size_y * 0.1);
	float right = rint(ui_vid_x - hud_size_x * 0.5);
	string ammoIcon = weapon_ammo[wid];
	if (ammoIcon != "")
	{
		float icon_w = rint(hud_size_x * 1.2);
		float icon_h = rint(hud_size_y);
		drawpic([right - icon_w, y], ammoIcon, [icon_w, icon_h], color, a, DRAWFLAG_ADDITIVE);
		right = right - icon_w - hud_size_x * 0.2;
	}
	string reserveStr = ftos(playerAmmo);
	float reserveW = stringwidth(reserveStr, true, hud_size);
	float reserve_x = right - reserveW;
	drawstring([reserve_x, y], reserveStr, hud_size, color, a, 0);
	if (hasClip)
	{
		// separator
		float bar_x = reserve_x - hud_size_x * 0.5;
		drawfill([bar_x, hud_y + hud_size_y * 0.2], [hud_size_x * 0.075, hud_size_y * 0.7], color, a, 0);
		
		// clip
		string clipStr = ftos(playerClip);
		float clipW = stringwidth(clipStr, true, hud_size);
		float clip_x = bar_x - hud_size_x * 0.3 - clipW;
		drawstring([clip_x, y], clipStr, hud_size, color, a, 0);
	}
}

string HUD_TrainIcon()
{
	if (playerTrainHud == 1) return "gfx/hud_train_stop";
	if (playerTrainHud == 2) return "gfx/hud_train_back";
	if (playerTrainHud == 3) return "gfx/hud_train_forward1";
	if (playerTrainHud == 4) return "gfx/hud_train_forward2";
	if (playerTrainHud == 5) return "gfx/hud_train_forward3";
	return "";
}

void HUD_DrawTrain(vector hud_size)
{
	string icon = HUD_TrainIcon();
	if (icon == "") return;

	vector size = hud_size * 1.5;
	vector pos = [rint(ui_vid_x * 0.5 - size_x * 0.5), rint(ui_vid_y - size_y * 2.4)];
	drawpic(pos, icon, size, HUD_RGB_YELLOWISH, 1, DRAWFLAG_ADDITIVE);
}

void HUD_Draw()
{
	Fade_Draw(); 		//env_fade
	HudMessage_Draw(); 	//HudMessage

	if(intermission || !cvar("hud_draw") || cvar("viewsize") > 100) return;
	if(!Player_IsAlive()) return;

	HUD_UpdateFades();

	drawfont = FONT_DEFAULT;
	vector hud_size = [ui_font_size * 2, ui_font_size * 2];
	float hud_y = ui_vid_y - hud_size_y * 1.5;

	HUD_DrawHealth(hud_size, hud_y);
	HUD_DrawFlashlight(hud_size);
	HUD_DrawPain();
	HUD_DrawDamageIcons(hud_size, hud_y);
	HUD_DrawTrain(hud_size);

	HUD_DrawAmmo(hud_size, hud_y);

	HUD_DrawWeaponSelect();

	drawfont = FONT_DEFAULT;
	HUD_DrawThrowPower();

	if(!aiming) DrawCrosshair();
};
