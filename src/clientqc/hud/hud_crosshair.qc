
void DrawCrosshair()
{
	if(intermission) return;
	if(!Player_IsAlive()) return;
	if(cvar("crosshair") <= 0 || playerWeapon <= 0) return;

	float wid = Weapon_IDFromBit(playerWeapon);
	if(wid <= WID_NONE || wid >= WID_COUNT) return;

	float ch_index = weapon_crosshair[wid];
	if(ch_index < 0) return;

	float incross = Stat_GetInt(STAT_INCROSS);
	vector ch_color = [1, 1, 1];
	if(incross == 1) ch_color = [1, 0.01, 0.01];
	if(incross == 2) ch_color = [1, 1, 0.5];

	string ch_img = strcat("gfx/crosshair", ftos(ch_index));
	float ch_scale = cvar("crosshair_size") * ui_vy_rel;
	ch_scale = ch_scale * 2;
	vector img_native = drawgetimagesize(ch_img);
	vector img_size = [rint(img_native_x * rint(ch_scale)), rint(img_native_y * rint(ch_scale))];
	float cx = rint(ui_vid_x * 0.5 - img_size_x * 0.5);
	float cy = rint(ui_vid_y * 0.5 - img_size_y * 0.5);

	drawpic([cx, cy, 0], ch_img, img_size, ch_color, 1, 0);
}
