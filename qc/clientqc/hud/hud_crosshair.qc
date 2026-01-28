
//////////////////////////////////
/////////// CROSSHAIR ////////////
//////////////////////////////////

float round_to_0_5(float x) { return rint(x * 2) / 2; }
float round_to_0_25(float x) { return rint(x * 4) / 4; }

vector last_input_angles;
float angles_gap;
void DrawCrosshair()
{
	if(intermission) return;
	if(!Player_IsAlive()) return;
	if(cvar("crosshair") <= 0 || playerWeapon <= 0) return;
	
	float tmp = vlen(input_angles - last_input_angles);
	if(cvar("crosshair_static")) tmp = 0;
	angles_gap = LerpAngle(angles_gap, tmp, 15 * frametime);
	last_input_angles = input_angles;
	
	float incross = getstati(STAT_INCROSS);
	float recoil = fabs(view_punchangle_x);
	vector crosshair_color = [cvar("crosshair_color_red"), cvar("crosshair_color_blue"), cvar("crosshair_color_green")];
	if(incross == 1) crosshair_color = [ 1, .01, .01 ]; //.54 .01 .01
	if(incross == 2) crosshair_color = [ 1, 1, .5 ];
	
	vector crosshair_size = [10, 1, 0] * cvar("crosshair_size");
	crosshair_size_x = rint(crosshair_size_x);
	crosshair_size_y = rint(crosshair_size_y);
	float gap_size = 9 + (recoil * 9 * vx_rel) + (angles_gap * 4 * vx_rel);
	gap_size = round_to_0_5(gap_size);
	float cx = rint(vid_x / 2);
	float cy = rint(vid_y / 2);
	
	float drawfill_size = .3;
	
	drawfill([cx - crosshair_size_x - gap_size, cy], [crosshair_size_x, drawfill_size], crosshair_color, 1, 0); //left
	drawfill([cx + gap_size, cy], [crosshair_size_x, drawfill_size], crosshair_color, 1, 0); //right
	
	drawfill([cx, cy + gap_size], [drawfill_size, crosshair_size_x], crosshair_color, 1, 0); //bottom
	drawfill([cx, cy - crosshair_size_x - gap_size], [drawfill_size, crosshair_size_x], crosshair_color, 1, 0); //top
	
	// crosshair_color = [ 1, .01, .01 ];
	drawline(drawfill_size, [cx - crosshair_size_x - gap_size, cy], [cx - gap_size, cy], crosshair_color, 1, 0); //left
	drawline(drawfill_size, [cx + gap_size, cy], [cx + crosshair_size_x + gap_size, cy], crosshair_color, 1, 0); //right
	
	drawline(drawfill_size, [cx, cy + crosshair_size_x + gap_size], [cx, cy + gap_size], crosshair_color, 1, 0); //bottom
	drawline(drawfill_size, [cx, cy - gap_size], [cx, cy - crosshair_size_x - gap_size], crosshair_color, 1, 0); //top
}

