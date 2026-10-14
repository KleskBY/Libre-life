
vector HUD_CELLSIZE = '24 24 0';
vector HUD_LONGWEAPON_SIZE = '128 42 0';

#define HUD_MAX_COL  6     // slots 1..5 (index 0 unused)
#define HUD_MAX_ROW  4
#define HUD_CELL_COUNT 24

float  hud_col_selected;
float  hud_row_selected;
float  hud_slot_count[HUD_MAX_COL];
float  hud_slot_wid  [HUD_CELL_COUNT];   // 0 = empty, otherwise WID_*

#define HUD_CELL(c, r) ((c) * HUD_MAX_ROW + (r))

void HUD_ParseWeaponData(float weapons)
{
	for (float i = 0; i < HUD_MAX_COL; i++)
		hud_slot_count[i] = 0;
	for (float i = 0; i < HUD_CELL_COUNT; i++)
		hud_slot_wid[i] = WID_NONE;

	for (float c = 1; c < HUD_MAX_COL; c++)
	{
		float row = 0;
		for (float r = 0; r < HUD_MAX_ROW; r++)
		{
			// Find the weapon registered at (c, r)
			for (float id = 1; id < WID_COUNT; id++)
			{
				if (weapon_slot[id] == c && weapon_pos[id] == r && (weapons & weapon_bit[id]))
				{
					hud_slot_wid[HUD_CELL(c, row)] = id;
					row++;
					break;
				}
			}
		}
		hud_slot_count[c] = row;
	}
}

void HUD_SelectWeapon()
{
	float id = hud_slot_wid[HUD_CELL(hud_col_selected, hud_row_selected)];
	hud_col_selected = 0;
	hud_row_selected = 0;
	if (id <= WID_NONE || id >= WID_COUNT)
	{
		Sound_Local("common/wpn_hudoff.wav");
		return;
	}
	Sound_Local("common/wpn_select.wav");
	localcmd(sprintf("impulse %d\n", id));
}

float hud_find_col;
float hud_find_row;

float HUD_FindCellByID(float id)
{
	hud_find_col = 1;
	hud_find_row = 0;
	if (id <= WID_NONE || id >= WID_COUNT) return FALSE;
	for (float c = 1; c < HUD_MAX_COL; c++)
	{
		for (float r = 0; r < HUD_MAX_ROW; r++)
		{
			if (hud_slot_wid[HUD_CELL(c, r)] == id)
			{
				hud_find_col = c;
				hud_find_row = r;
				return TRUE;
			}
		}
	}
	return FALSE;
}

void HUD_CycleWeapon(float dir)
{
	float weapons = Stat_GetInt(STAT_WEAPONS);
	if (!weapons) return;
	HUD_ParseWeaponData(weapons);

	float curBit = Stat_GetInt(STAT_ACTIVEWEAPON);
	float curID = Weapon_IDFromBit(curBit);

	float c, r;
	if (HUD_FindCellByID(curID))
	{
		c = hud_find_col;
		r = hud_find_row;
	}
	else
	{
		c = 1; r = -1; // No current weapon found
	}

	float steps = HUD_MAX_COL * HUD_MAX_ROW;
	float step = (dir < 0) ? -1 : 1;
	for (float i = 0; i < steps; i++)
	{
		r += step;
		if (r >= HUD_MAX_ROW) { r = 0; c++; if (c >= HUD_MAX_COL) c = 1; }
		else if (r < 0) { c--; if (c < 1) c = HUD_MAX_COL - 1; r = HUD_MAX_ROW - 1; }

		float id = hud_slot_wid[HUD_CELL(c, r)];
		if (id != WID_NONE && id != curID)
		{
			localcmd(sprintf("impulse %d\n", id));
			Sound_Local("common/wpn_moveselect.wav");
			return;
		}
	}
	Sound_Local("common/wpn_denyselect.wav");
}

float HUD_Input(string keybind, float flEventType)
{
	if (flEventType) return FALSE;

	if (keybind == "+attack" && hud_col_selected > 0)
	{
		HUD_SelectWeapon();
		return TRUE;
	}

	if (keybind == "togglemenu" && hud_col_selected > 0) // Escape 
	{
		hud_col_selected = 0;
		hud_row_selected = 0;
		Sound_Local("common/wpn_hudoff.wav");
		return TRUE;
	}

	if (keybind == "+invnext")  { HUD_CycleWeapon(+1); return TRUE; }
	if (keybind == "+invprev")  { HUD_CycleWeapon(-1); return TRUE; }

	if (!StringContains(keybind, "impulse")) return FALSE;

	float c = tokenizebyseparator(keybind, " ");
	if (c < 1) return FALSE;

	float selected = stof(argv(1));
	if (selected < 1 || selected >= HUD_MAX_COL) return FALSE;

	float weapons = Stat_GetInt(STAT_WEAPONS);
	if (!weapons) return FALSE;
	HUD_ParseWeaponData(weapons);

	if (hud_slot_count[selected] <= 0) // deny and leave the menu exactly as it was
	{
		Sound_Local("common/wpn_denyselect.wav");
		return TRUE;
	}

	float wasClosed = (hud_col_selected == 0);

	if (hud_col_selected == selected)
	{
		hud_row_selected = hud_row_selected + 1;
		if (hud_row_selected >= hud_slot_count[hud_col_selected]) hud_row_selected = 0;
	}
	else
	{
		hud_col_selected = selected;
		hud_row_selected = 0;
	}

	if (cvar("hud_fastswitch") && hud_slot_count[selected] == 1)
	{
		HUD_SelectWeapon();
		return TRUE;
	}

	if (wasClosed) Sound_Local("common/wpn_hudon.wav");
	else           Sound_Local("common/wpn_moveselect.wav");

	return TRUE;
};

void HUD_DrawWeaponIcon(vector pos, string img, float selected)
{
	pos = pos + UI_FixedVector('0 24 0');
	// HL: selected = bright yellow, unselected = dim yellow
	vector col = HUD_RGB_YELLOWISH;
	float icon_a = selected ? 0.95 : 0.5;
	float bg_a   = selected ? 0.35 : 0.15;
	drawfill(pos, UI_FixedVector(HUD_LONGWEAPON_SIZE), col, bg_a, 0);
	drawpic(pos, img, UI_FixedVector(HUD_LONGWEAPON_SIZE + [0, HUD_LONGWEAPON_SIZE_y]), col, icon_a, DRAWFLAG_ADDITIVE);
	if (selected)
	{
		// HL m_HUD_selection: bracket-corner overlay framing the selected weapon
		drawpic(pos, "gfx/hud_selection", UI_FixedVector(HUD_LONGWEAPON_SIZE + [0, HUD_LONGWEAPON_SIZE_y]), col, 1.0, DRAWFLAG_ADDITIVE);
		/*
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
		*/
	}
};

void HUD_DrawWeaponSelect()
{
	if (!hud_col_selected) return;
	vector pos = UI_FixedVector(HUD_CELLSIZE / 2);
	vector col_y = HUD_RGB_YELLOWISH;
	for (float i = 1; i < HUD_MAX_COL; i++)
	{
		float headerActive = (i == hud_col_selected);
		float headerA = headerActive ? 0.9 : 0.4;
		drawfill(pos, UI_FixedVector(HUD_CELLSIZE), col_y, headerA * 0.4, 0);
		// Number in top-left corner of header (HL bucket digit position)
		drawstring(pos + UI_FixedVector('3 2 0'), ftos(i), UI_FixedVector('10 10 0'), col_y, headerA, 0);

		if (i == hud_col_selected && hud_slot_count[i] > 0)
		{
			for (float j = 0; j < hud_slot_count[i]; j++)
			{
				float id = hud_slot_wid[HUD_CELL(i, j)];
				if (id == WID_NONE) continue;
				HUD_DrawWeaponIcon(pos + UI_FixedVector([0, HUD_LONGWEAPON_SIZE_y + 1]) * j , weapon_sprite[id], hud_row_selected == j);
			}
			pos = pos + UI_FixedVector('6 0 0') + UI_FixedVector([HUD_LONGWEAPON_SIZE_x]);
		}
		else
		{
			for (float j = 0; j < hud_slot_count[i]; j++)
				drawfill(pos + UI_FixedVector([0, HUD_CELLSIZE_y + 2]) * (j + 1), UI_FixedVector(HUD_CELLSIZE), col_y, 0.5, 0);
			pos = pos + UI_FixedVector('6 0 0') + UI_FixedVector([HUD_CELLSIZE_x, 0]);
		}
	}
};
