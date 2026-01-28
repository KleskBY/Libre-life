
////////////////////////////
/////////// VIEW ///////////
////////////////////////////

void View_Update(float flWidth, float flHeight) 
{
    clearscene(); 						// CSQC builtin to clear the scene of all entities / reset our view properties
	setproperty(VF_DRAWWORLD, 1); 		// we want to draw world!
	setproperty(VF_DRAWCROSSHAIR, 0);	// we want to draw our crosshair!
	setproperty(VF_DRAWENGINESBAR, 0);
	addentities(MASK_NORMAL | MASK_ENGINE | MASK_ENGINEVIEWMODELS);
	Player_GetFields();
	Player_Update();
	renderscene();
	
	if(intermission) 
	{
		setsensitivityscale(0);
		cvar_set("r_drawviewmodel", "0");
	}
	else setsensitivityscale(1);
	
	UI_GetRelative();
	UI_UpdateMouse();
	
	Scope_Draw();
	HUD_Draw();
	Score_Draw();
	Rankings_Draw();

	UI_DrawCursor();
}

