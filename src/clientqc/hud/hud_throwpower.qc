
float MAX_THROW_POWER = 1.1;
float throwPower;
void HUD_DrawThrowPower()
{
	if(playerWeapon != WEAPON_HANDGRENADE) return;
	if(playerFrame != 60)
	{
		throwPower = 0;
		return;
	}
	
	throwPower = throwPower + frametime;
	if(throwPower > MAX_THROW_POWER) throwPower = MAX_THROW_POWER;
	
	string txt = "THROW POWER:";
	vector pos = [ ui_vid_x / 2, ui_vid_y * 0.25 ];
	pos_x = pos_x - stringwidth(txt, true, UI_FixedVector('12 12 0'));
	drawstring(pos, txt, UI_FixedVector('12 12 0'), '1 1 1', 0.9, 0);
	drawfill([ ui_vid_x / 2, ui_vid_y * 0.25 + 1 ], UI_FixedVector([100, 8, 0]), '30 30 30', 0.25, 0);
	drawfill([ ui_vid_x / 2, ui_vid_y * 0.25 + 1 ], UI_FixedVector([100 * ((throwPower / MAX_THROW_POWER)) , 8, 0]), '30 30 30', 0.85, 0);
}