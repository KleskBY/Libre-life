// Player Setup page (Options window tab).
//
// Name and colours are plain engine cvars, so nothing is needed server-side:
// the engine forwards them as user info; the scoreboard reads the name back
// through getplayerkeyvalue().

// Quake palette rows 0..13, numbered by topcolor/bottomcolor
string UI_ColorName(float c)
{
	if (c == 0)  return "White";
	if (c == 1)  return "Brown";
	if (c == 2)  return "Lavender";
	if (c == 3)  return "Khaki";
	if (c == 4)  return "Red";
	if (c == 5)  return "Light brown";
	if (c == 6)  return "Olive";
	if (c == 7)  return "Tan";
	if (c == 8)  return "Green";
	if (c == 9)  return "Purple";
	if (c == 10) return "Beige";
	if (c == 11) return "Pale green";
	if (c == 12) return "Yellow";
	return "Blue";
}

vector UI_ColorSwatch(float c)
{
	if (c == 0)  return '0.85 0.85 0.85';
	if (c == 1)  return '0.45 0.30 0.18';
	if (c == 2)  return '0.60 0.55 0.75';
	if (c == 3)  return '0.60 0.55 0.35';
	if (c == 4)  return '0.80 0.20 0.15';
	if (c == 5)  return '0.60 0.42 0.25';
	if (c == 6)  return '0.40 0.45 0.20';
	if (c == 7)  return '0.75 0.62 0.45';
	if (c == 8)  return '0.25 0.60 0.25';
	if (c == 9)  return '0.50 0.25 0.60';
	if (c == 10) return '0.80 0.75 0.60';
	if (c == 11) return '0.55 0.75 0.55';
	if (c == 12) return '0.85 0.80 0.25';
	return '0.30 0.45 0.85';
}

void UI_DrawPlayerSetupPage(vector base)
{
	UI_Text("Player name", base + [ui_font_size]);
	UI_InputText("_cl_name", base + [ui_font_size, ui_font_size * 2], UI_MAX_NAME_LENGTH, "");

	float top = rint(cvar("topcolor"));
	float bot = rint(cvar("bottomcolor"));

	UI_Text(strcat("Primary: ", UI_ColorName(top)), base + [ui_font_size, ui_font_size * 5]);
	UI_Slider(base + [ui_font_size, ui_font_size * 6.5], [ui_font_size * 18, 2], "topcolor", 0, 13, 1);
	drawfill(base + [ui_font_size * 20, ui_font_size * 5], [ui_font_size * 2, ui_font_size * 2],
	         UI_ColorSwatch(top), 1, 0);

	UI_Text(strcat("Secondary: ", UI_ColorName(bot)), base + [ui_font_size, ui_font_size * 9]);
	UI_Slider(base + [ui_font_size, ui_font_size * 10.5], [ui_font_size * 18, 2], "bottomcolor", 0, 13, 1);
	drawfill(base + [ui_font_size * 20, ui_font_size * 9], [ui_font_size * 2, ui_font_size * 2],
	         UI_ColorSwatch(bot), 1, 0);
}
