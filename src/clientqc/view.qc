
float View_ZoomScale()
{
	if (!IsFTE()) return 1;
	float z = Stat_GetInt(STAT_ZOOM) / 255;
	if (z <= 0 || z >= 1) return 1;
	return z;
}

float autocvar_vid_conwidth;
float autocvar_vid_conheight;

void View_ApplyZoom(float zoom)
{
	if (zoom >= 1) return;
	float width = autocvar_vid_conwidth;
	float height = autocvar_vid_conheight;
	if (width <= 0 || height <= 0) return;
	vector center = cs_unproject([width * 0.5, height * 0.5, 128]);
	vector right = cs_unproject([width, height * 0.5, 128]);
	vector top = cs_unproject([width * 0.5, 0, 128]);
	float depth = vlen(center - getpropertyvec(VF_ORIGIN));
	if (depth <= 0) return;
	float tanX = vlen(right - center) / depth;
	float tanY = vlen(top - center) / depth;
	setproperty(VF_FOVX, atan(tanX * zoom) * 360 / M_PI);
	setproperty(VF_FOVY, atan(tanY * zoom) * 360 / M_PI);
}

void View_Update(float flWidth, float flHeight)
{
    clearscene();	// CSQC builtin to clear scene and reset view properties
	setproperty(VF_DRAWWORLD, 1);	// draw the world
	setproperty(VF_DRAWCROSSHAIR, 0);	// draw the crosshair
	setproperty(VF_DRAWENGINESBAR, 0);

	float zoom = View_ZoomScale();
	View_ApplyZoom(zoom);

	addentities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS);
	Player_GetFields();
	Player_Update();
	Weather_Update();
	renderscene();
	
	if(intermission) 
	{
		setsensitivityscale(0);
		cvar_set("r_drawviewmodel", "0");
	}
	else setsensitivityscale(zoom);
	
	UI_GetRelative();
	UI_UpdateMouse();
	
	Nametag_Draw();        // under the HUD, so it stays on top
	HUD_Draw();
	// Outside HUD_Draw on purpose: early-outs while dead and the kill feed need to be read then
	if (cvar("gamemode") != MODE_SP && !intermission) Obituary_Draw();
	Score_Draw();
	Rankings_Draw();

	UI_DrawCursor();
}

