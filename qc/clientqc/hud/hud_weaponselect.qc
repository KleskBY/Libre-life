
vector HUD_CELLSIZE = '24 24 0';
vector HUD_LONGWEAPON_SIZE = '128 48 0';
// vector HUD_COLOR_SELECTED = '1 0.62 0';
// vector HUD_COLOR = '1 0.81 0.25' ;
// vector HUD_COLOR_SELECTED = '0.96 0.96 0.96';
// vector HUD_COLOR = '.8 0.8 0.8' ;
float hud_col_selected;
float hud_row_selected;
float HUD_MAX_COL = 6;
float HUD_MAX_ROW = 4;
float hud_col_amount[HUD_MAX_COL];
string hud_col1_img[HUD_MAX_ROW];
string hud_col2_img[HUD_MAX_ROW];
string hud_col3_img[HUD_MAX_ROW];
string hud_col4_img[HUD_MAX_ROW];
string hud_col5_img[HUD_MAX_ROW];

void HUD_PushBack(float col, string str)
{
	hud_col_amount[col] = hud_col_amount[col] + 1;
	for(float i = 0; i < HUD_MAX_ROW; i++)
	{
		if(col == 1)
		{
			if(hud_col1_img[i] == "")
			{
				hud_col1_img[i] = str;
				return;
			}
		}
		if(col == 2)
		{
			if(hud_col2_img[i] == "")
			{
				hud_col2_img[i] = str;
				return;
			}
		}
		if(col == 3)
		{
			if(hud_col3_img[i] == "")
			{
				
				hud_col3_img[i] = str;
				return;
			}
		}
		if(col == 4)
		{
			if(hud_col4_img[i] == "")
			{
				hud_col4_img[i] = str;
				return;
			}
		}
		if(col == 5)
		{
			if(hud_col5_img[i] == "")
			{
				hud_col5_img[i] = str;
				return;
			}
		}
	}
}

void HUD_ParseWeaponData(float weapons)
{
	for(float i = 0; i < HUD_MAX_COL; i++)
	{
		hud_col_amount[i] = 0;
	}
	for(float i = 0; i < HUD_MAX_ROW; i++)
	{
		hud_col1_img[i] = "";
		hud_col2_img[i] = "";
		hud_col3_img[i] = "";
		hud_col4_img[i] = "";
		hud_col5_img[i] = "";
	}

	if(weapons & WP_KNIFE) HUD_PushBack(1, "gfx/hud/knife");
	if(weapons & WP_PISTOL) HUD_PushBack(2, "gfx/hud/pm");
	if(weapons & WP_AK74) HUD_PushBack(3, "gfx/hud/ak74");
	if(weapons & WP_VAL) HUD_PushBack(3, "gfx/hud/val");
	if(weapons & WP_OC14) HUD_PushBack(3, "gfx/hud/oc14");
	if(weapons & WP_SHOTGUN) HUD_PushBack(4, "gfx/hud/ks23");
	if(weapons & WP_SNIPER) HUD_PushBack(4, "gfx/hud/svd");
	if(weapons & WP_GRENADE) HUD_PushBack(5, "gfx/hud/grenade");
}

void HUD_SelectWeapon()
{
	string s = "";
	if(hud_col_selected == 1)
	{
		s = hud_col1_img[hud_row_selected];
	}
	if(hud_col_selected == 2)
	{
		s = hud_col2_img[hud_row_selected];
	}
	if(hud_col_selected == 3)
	{
		s = hud_col3_img[hud_row_selected];
	}
	if(hud_col_selected == 4)
	{
		s = hud_col4_img[hud_row_selected];
	}
	if(hud_col_selected == 5)
	{
		s = hud_col5_img[hud_row_selected];
	}

	hud_col_selected = 0;
	hud_row_selected = 0;
	
	if(StringContains(s, "knife")) localcmd("impulse 1\n");
	if(StringContains(s, "pm")) localcmd("impulse 2\n");
	if(StringContains(s, "ak74")) localcmd("impulse 3\n");
	if(StringContains(s, "ks23")) localcmd("impulse 4\n");
	if(StringContains(s, "val")) localcmd("impulse 5\n");
	if(StringContains(s, "svd")) localcmd("impulse 6\n");
	if(StringContains(s, "grenade")) localcmd("impulse 7\n");
	if(StringContains(s, "oc14")) localcmd("impulse 8\n");
};

float HUD_Input(string keybind, float flEventType)
{
	if(flEventType) return FALSE;
	
	if(keybind == "+attack" && hud_col_selected > 0)
	{
		HUD_SelectWeapon();
		return TRUE;
	}
	
	if(!StringContains(keybind, "impulse")) return FALSE;
	
	float c = tokenizebyseparator(keybind, " ");
	if(c < 1) return FALSE;
	
	float selected = stof(argv(1));
	if(selected < 1 || selected >= HUD_MAX_COL) return FALSE;
	
	float weapons = getstati(STAT_WEAPONS);
	if(!weapons) return FALSE;
	HUD_ParseWeaponData(weapons);
	
	if(hud_col_selected == selected)
	{
		hud_row_selected = hud_row_selected + 1;
		if(hud_row_selected >= hud_col_amount[hud_col_selected]) hud_row_selected = 0;
	}
	else
	{
		hud_col_selected = selected;
		hud_row_selected = 0;
	}
	
	if(hud_col_amount[selected] > 0) localsound("misc/hud01.wav");
	else localsound("misc/hud02.wav");

	if(cvar("hud_fastswitch") && hud_col_amount[selected] == 1)
	{
		HUD_SelectWeapon();
	}

	return TRUE;
};

void HUD_DrawWeaponIcon(vector pos, string img, float selected)
{
	pos = pos + UI_FixedVector('0 24 0');
	vector col = HUD_COLOR;
	if(selected) col = HUD_COLOR_SELECTED;
	drawfill(pos, UI_FixedVector(HUD_LONGWEAPON_SIZE), col, 0.2, 0);
	drawpic(pos, img, UI_FixedVector(HUD_LONGWEAPON_SIZE), col, 0.5, 1);
	if(selected)
	{
		//top left corner
		drawfill(pos, UI_FixedVector('10 1 0'), col, 0.5, 0);
		drawfill(pos + UI_FixedVector('0 1 0'), UI_FixedVector('0 10 0'), col, 0.5, 0);
		
		//bottom left
		drawfill(pos + UI_FixedVector([0, HUD_LONGWEAPON_SIZE_y -1]), UI_FixedVector('10 1 0'), col, 0.5, 0);
		drawfill(pos + UI_FixedVector([0, HUD_LONGWEAPON_SIZE_y -12]), UI_FixedVector('0 10 0'), col, 0.5, 0);
	
		//top right
		drawfill(pos + UI_FixedVector([HUD_LONGWEAPON_SIZE_x -11, 0]), UI_FixedVector('10 1 0'), col, 0.5, 0);
		drawfill(pos + UI_FixedVector([HUD_LONGWEAPON_SIZE_x -2, 1]), UI_FixedVector('0 10 0'), col, 0.5, 0);
		
		drawfill(pos + UI_FixedVector([HUD_LONGWEAPON_SIZE_x -11, HUD_LONGWEAPON_SIZE_y -1]), UI_FixedVector('10 1 0'), col, 0.5, 0);
		drawfill(pos + UI_FixedVector([HUD_LONGWEAPON_SIZE_x -2, HUD_LONGWEAPON_SIZE_y -12]), UI_FixedVector('0 10 0'), col, 0.5, 0);
	}	
};

void HUD_WeaponSelect()
{
	if(!hud_col_selected) return;
	vector pos = UI_FixedVector(HUD_CELLSIZE / 2);
	for(float i = 1; i < HUD_MAX_COL; i++)
	{
		drawfill(pos, UI_FixedVector(HUD_CELLSIZE), HUD_COLOR_SELECTED, HUD_ALPHA, 0);
		drawstring(pos + UI_FixedVector(HUD_CELLSIZE / 2), ftos(i),  UI_FixedVector('10 10 0'), HUD_COLOR, HUD_ALPHA, 0);
		if(i == hud_col_selected && hud_col_amount[i] > 0)
		{
			for(float j = 0; j < hud_col_amount[i]; j++)
			{
				if(hud_col_selected == 1) HUD_DrawWeaponIcon(pos + UI_FixedVector('0 48 0') * j, hud_col1_img[j], hud_row_selected == j);
				if(hud_col_selected == 2) HUD_DrawWeaponIcon(pos + UI_FixedVector('0 48 0') * j, hud_col2_img[j], hud_row_selected == j);
				if(hud_col_selected == 3) HUD_DrawWeaponIcon(pos + UI_FixedVector('0 48 0') * j, hud_col3_img[j], hud_row_selected == j);
				if(hud_col_selected == 4) HUD_DrawWeaponIcon(pos + UI_FixedVector('0 48 0') * j, hud_col4_img[j], hud_row_selected == j);
				if(hud_col_selected == 5) HUD_DrawWeaponIcon(pos + UI_FixedVector('0 48 0') * j, hud_col5_img[j], hud_row_selected == j);

			}

		
			// HUD_DrawWeaponIcon(pos, "gfx/hud/ak74", hud_row_selected == 0);
			// HUD_DrawWeaponIcon(pos + UI_FixedVector('0 48 0'), "gfx/hud/val", hud_row_selected == 1);
			// HUD_DrawWeaponIcon(pos+ UI_FixedVector('0 48 0') * 2, "gfx/hud/ks23", hud_row_selected == 2);
			
			pos = pos + UI_FixedVector('6 0 0') + UI_FixedVector([HUD_LONGWEAPON_SIZE_x]);
		}
		else
		{
			for(float j = 0; j < hud_col_amount[i]; j++)
			{
				drawfill(pos + UI_FixedVector('0 24 0') * (j + 1), UI_FixedVector(HUD_CELLSIZE), HUD_COLOR, 0.5, 0);
			}
			pos = pos + UI_FixedVector('6 0 0') + UI_FixedVector('24 0 0');
		}
	}

};