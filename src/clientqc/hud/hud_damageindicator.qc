float dmg_take;
float dmg_save;
vector dmg_origin;


float HUD_ParseDamage()
{
	if (dmg_take <= 0 && dmg_save <= 0) return FALSE;

	// zero origin means environmental damage, clear all
	if (dmg_origin == '0 0 0')
	{
		painFront = painRear = painLeft = painRight = 0;
		return FALSE;
	}

	vector vecFrom = dmg_origin - pmove_org;
	float dist = vlen(vecFrom);
	if (dist == 0) return FALSE;
	vecFrom = vecFrom * (1.0 / dist);

	makevectors(input_angles);
	float fb = vecFrom * v_forward;	// front/back axis
	float lr = vecFrom * v_right;	// left/right axis

	// point-blank/fall (light all 4)

	if (fb > 0.3)        painFront = max(painFront, fb);
	else if (-fb > 0.3)  painRear  = max(painRear, fabs(fb));

	if (lr > 0.3)        painRight = max(painRight, lr);
	else if (-lr > 0.3)  painLeft  = max(painLeft, fabs(lr));

	return FALSE;
}

void HUD_DrawPain()
{
	HUD_ParseDamage();
	// painFront = painRear = painLeft = painRight = 1; //testing
	if (!(painFront || painRear || painLeft || painRight)) return;

	vector color = HUD_RGB_REDISH;
	float fade = frametime * 2;
	float pw = ui_font_size * 8;            // pain tile size
	float ph = ui_font_size * 3;
	vector psz = [pw, ph];
	float cx = ui_vid_x * 0.5;
	float cy = ui_vid_y * 0.5;

	float shade;

	if (painFront > 0.4)
	{
		shade = max(painFront, 0.5);
		drawpic([cx - pw * 0.5, cy - ph * 3], "gfx/pain_forward", [pw, ph], color, shade, DRAWFLAG_ADDITIVE);
		painFront = max(0, painFront - fade);
	} else painFront = 0;

	if (painRight > 0.4)
	{
		shade = max(painRight, 0.5);
		drawpic([cx + pw * 2, cy - ph * 0.5], "gfx/pain_right", [ph, pw], color, shade, DRAWFLAG_ADDITIVE);
		painRight = max(0, painRight - fade);
	} else painRight = 0;

	if (painRear > 0.4)
	{
		shade = max(painRear, 0.5);
		drawpic([cx - pw * 0.5, cy + ph * 3], "gfx/pain_back", [pw, ph], color, shade, DRAWFLAG_ADDITIVE);
		painRear = max(0, painRear - fade);
	} else painRear = 0;

	if (painLeft > 0.4)
	{
		shade = max(painLeft, 0.5);
		drawpic([cx - pw * 2, cy - ph * 0.5], "gfx/pain_left", [ph, pw], color, shade, DRAWFLAG_ADDITIVE);
		painLeft = max(0, painLeft - fade);
	} else painLeft = 0;
}

#define DMG_ICON_COUNT 8
#define DMG_ICON_LIFE  2

float dmgicon_expire[DMG_ICON_COUNT];

float DmgIcon_Bits(float i)
{
	switch (i)
	{
		case 0: return DMG_POISON;
		case 1: return DMG_ACID;
		case 2: return DMG_FREEZE | DMG_SLOWFREEZE;
		case 3: return DMG_DROWN;
		case 4: return DMG_BURN | DMG_SLOWBURN;
		case 5: return DMG_NERVEGAS;
		case 6: return DMG_RADIATION;
		default: return DMG_SHOCK;
	}
}

string DmgIcon_Pic(float i)
{
	switch (i)
	{
		case 0: return "gfx/hud_dmg_poison";
		case 1: return "gfx/hud_dmg_chem";
		case 2: return "gfx/hud_dmg_cold";
		case 3: return "gfx/hud_dmg_drown";
		case 4: return "gfx/hud_dmg_heat";
		case 5: return "gfx/hud_dmg_gas";
		case 6: return "gfx/hud_dmg_rad";
		default: return "gfx/hud_dmg_shock";
	}
}

void HUD_DrawDamageIcons(vector hud_size, float hud_y)
{
	float bits = Stat_GetInt(STAT_DMGBITS);

	// DrawDamage: a = |sin(t*2)| * 256 pulse, yellowish, additive.
	float a = fabs(sin(time * 2));

	vector isz = hud_size;
	float x = hud_size_x * 0.5;              // align with the health cross
	float y = hud_y - isz_y * 1.2;           // first icon just above health row

	for (float i = 0; i < DMG_ICON_COUNT; i++)
	{
		if (bits & DmgIcon_Bits(i))
			dmgicon_expire[i] = time + DMG_ICON_LIFE;

		if (dmgicon_expire[i] > time)
		{
			drawpic([x, y], DmgIcon_Pic(i), isz, HUD_RGB_YELLOWISH, a, DRAWFLAG_ADDITIVE);
			y -= isz_y * 1.1;                // stack upward
		}
	}
}
