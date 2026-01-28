entity win_settings;
//Options window
float settings_page;
float SETTINGS_AUDIO = 0;
float SETTINGS_VIDEO = 1;
float SETTINGS_GRAPHICS = 2;
float SETTINGS_AIM = 3;
float SETTINGS_KEYBOARD = 4;

void UI_SelectSettings()
{
	settings_page = stof(exec);
}

void ProcessResolutionChange(string res)
{
	tokenizebyseparator(res, "x");
	float res_w = stof(argv(0));
	float res_h = stof(argv(1));
	if(cvar("vid_width") != res_w || cvar("vid_height") != res_h)
	{
		string res_cmd = "vid_desktopfullscreen 0; vid_width ";
		res_cmd = strcat(res_cmd, argv(0), "; vid_height ", argv(1), "\n");
		cmd(res_cmd);
	}
}


float lastEffects;
float lastLighting;
void ProcessSettingsChange()
{
	if(cvar("ui_lighting") != lastLighting)
	{
		if(cvar("ui_lighting") == 0) cmd("r_coronas 1;gl_flashblend 1;r_shadow_gloss 0;r_shadow_realtime_dlight 0;r_shadow_realtime_dlight_shadows 0;r_shadow_realtime_world 0;r_shadow_realtime_world_lightmaps 0;r_shadow_realtime_world_shadows 1;r_bloom 0;\n");
		else if(cvar("ui_lighting") == 1) cmd("r_coronas 1;gl_flashblend 0;r_shadow_gloss 1;r_shadow_realtime_dlight 1;r_shadow_realtime_dlight_shadows 0;r_shadow_realtime_world 0;r_shadow_realtime_world_lightmaps 0;r_shadow_realtime_world_shadows 1;\n");
		else if(cvar("ui_lighting") == 2) cmd("r_coronas 1;gl_flashblend 0;r_shadow_gloss 1;r_shadow_realtime_dlight 1;r_shadow_realtime_dlight_shadows 1;r_shadow_realtime_world 0;r_shadow_realtime_world_lightmaps 0;r_shadow_realtime_world_shadows 1;\n");
		else if(cvar("ui_lighting") == 3) cmd("r_coronas 1;gl_flashblend 0;r_shadow_gloss 1;r_shadow_realtime_dlight 1;r_shadow_realtime_dlight_shadows 1;r_shadow_realtime_world 1;r_shadow_realtime_world_lightmaps 0;r_shadow_realtime_world_shadows 1;\n");
		lastLighting = cvar("ui_lighting");
	}
	
	//Effects
	if(cvar("ui_effects") != lastEffects)
	{
		if(cvar("ui_effects") == 0) cmd("cl_particles 1;cl_particles_quake 1;cl_particles_quality 1;cl_particles_explosions_shell 0;r_explosionclip 1;cl_stainmaps 0;cl_stainmaps_clearonload 1;cl_decals 0;cl_particles_bulletimpacts 1;cl_particles_smoke 1;cl_particles_sparks 1;cl_particles_bubbles 1;cl_particles_blood 1;cl_particles_blood_alpha 1;cl_particles_blood_bloodhack 0;cl_beams_polygons 0;cl_beams_instantaimhack 0;cl_beams_quakepositionhack 1;cl_beams_lightatend 0;r_lerpmodels 1;r_lerpsprites 1;r_lerplightstyles 0;gl_polyblend 1;r_skyscroll1 1;r_skyscroll2 2;r_waterwarp 1;r_wateralpha 1;r_waterscroll 1\n");
		else if(cvar("ui_effects") == 1) cmd("cl_particles 1;cl_particles_quake 0;cl_particles_quality 1;cl_particles_explosions_shell 0;r_explosionclip 1;cl_stainmaps 0;cl_stainmaps_clearonload 1;cl_decals 1;cl_particles_bulletimpacts 1;cl_particles_smoke 1;cl_particles_sparks 1;cl_particles_bubbles 1;cl_particles_blood 1;cl_particles_blood_alpha 1;cl_particles_blood_bloodhack 1;cl_beams_polygons 1;cl_beams_instantaimhack 0;cl_beams_quakepositionhack 1;cl_beams_lightatend 0;r_lerpmodels 1;r_lerpsprites 1;r_lerplightstyles 0;gl_polyblend 1;r_skyscroll1 1;r_skyscroll2 2;r_waterwarp 1;r_wateralpha 1;r_waterscroll 1\n");
		else if(cvar("ui_effects") == 2) cmd("cl_particles 1;cl_particles_quake 0;cl_particles_quality 2;cl_particles_explosions_shell 0;r_explosionclip 1;cl_stainmaps 1;cl_stainmaps_clearonload 1;cl_decals 1;cl_particles_bulletimpacts 1;cl_particles_smoke 1;cl_particles_sparks 1;cl_particles_bubbles 1;cl_particles_blood 1;cl_particles_blood_alpha 1;cl_particles_blood_bloodhack 1;cl_beams_polygons 1;cl_beams_instantaimhack 0;cl_beams_quakepositionhack 1;cl_beams_lightatend 0;r_lerpmodels 1;r_lerpsprites 1;r_lerplightstyles 0;gl_polyblend 1;r_skyscroll1 1;r_skyscroll2 2;r_waterwarp 1;r_wateralpha 1;r_waterscroll 1\n");
		lastEffects = cvar("ui_effects");
	}
	
	//Invert mouse
	if(cvar("ui_invert_mouse") && cvar("m_pitch") > 0) cvar_set("m_pitch", ftos(-cvar("m_pitch")));
	else if(cvar("m_pitch") < 0) cvar_set("m_pitch", ftos(-cvar("m_pitch")));
}


void UI_DrawSettingsContents()
{
	ProcessSettingsChange();

	vector base = win_settings.UI_win_pos + [font_size * 0.5, font_size * 2, 0];
	vector tab_size = [font_size * 4, font_size];
	float tab_step = font_size * 4.1;
	vector tab_ofs = base ;

	UI_Button2("Audio", tab_ofs + [tab_step * 0], tab_size, UI_SelectSettings, ftos(SETTINGS_AUDIO));
	UI_Button2("Video", tab_ofs + [tab_step * 1], tab_size, UI_SelectSettings, ftos(SETTINGS_VIDEO));
	UI_Button2("Graphics", tab_ofs + [tab_step * 2], tab_size, UI_SelectSettings, ftos(SETTINGS_GRAPHICS));
	UI_Button2("Aim", tab_ofs + [tab_step * 3], tab_size, UI_SelectSettings, ftos(SETTINGS_AIM));
	UI_Button2("Keyboard", tab_ofs + [tab_step * 4], tab_size, UI_SelectSettings, ftos(SETTINGS_KEYBOARD));
	
	UI_Frame(base + [0, font_size * 1], win_settings.UI_win_size -[font_size * 1, font_size * 5], false);
	drawfill(tab_ofs + [1, tab_size_y, 0] + [tab_step * settings_page], [tab_size_x, 2], UI_WINDOW_BACKGROUND, UI_WINDOW_BACKGROUND_ALPHA, 0);

	if(settings_page == SETTINGS_AUDIO)
	{
		base = base + [0, font_size * 2];

		UI_Text("Sound effects volume", base + [font_size]);
		UI_Slider(base + [font_size, font_size * 2], [font_size * 23, 2], "volume", 0, 1, 0.05);
		
		UI_Text("Music volume", base + [font_size, font_size * 4]);
		UI_Slider(base + [font_size, font_size * 6], [font_size * 23, 2], "bgmvolume", 0, 1, 0.05);
		
		UI_Text("Master volume", base + [font_size, font_size * 8]);
		UI_Slider(base + [font_size, font_size * 10], [font_size * 23, 2], "mastervolume", 0, 1, 0.05);
	}
	else if(settings_page == SETTINGS_VIDEO)
	{
		base = base + [0, font_size * 2];
		
		UI_Text("Gamma", base + [font_size, font_size * 6]);
		UI_Slider(base + [font_size, font_size * 8], [font_size * 23, 2], "v_gamma", 0.1, 2, 0.05);
		
		UI_Text("Contrast", base + [font_size, font_size * 10]);
		UI_Slider(base + [font_size, font_size * 12], [font_size * 23, 2], "v_contrast", 0.1, 2, 0.05);
		
		UI_Checkbox("Fullscreen", base + [font_size * 1, font_size * 4], "vid_fullscreen");
		UI_Checkbox("V-Sync", base + [font_size * 12, font_size * 4], "vid_vsync");

		UI_Text("Video resolution", base + [font_size * 1, font_size * 2]);
		string res;
		if(cvar("ui_display_mode") == 0) res = UI_Dropdown("ui_resolution", base + [font_size * 8, font_size * 2], font_size * 11, "640x480|800x600|1024x768|1400x1050|1440x1080|1600x1200|1856x1392|1920x1440");
		else if(cvar("ui_display_mode") == 1) res = UI_Dropdown("ui_resolution", base + [font_size * 8, font_size * 2], font_size * 11, "1280x720|1366x768|1600x900|1920x1080|2560x1440|3840x2160");
		else if(cvar("ui_display_mode") == 2) res = UI_Dropdown("ui_resolution", base + [font_size * 8, font_size * 2], font_size * 11, "1280x800|1440x900|1680x1050|1920x1200|2560x1600");
		ProcessResolutionChange(res);

		UI_Text("Display Mode", base + [font_size * 1, font_size * 0.1]);
		UI_Dropdown("ui_display_mode", base + [font_size * 8, font_size * 0], font_size * 11, "Squarer (4:3)|Widescreen (16:9)|Wider (16:10)");
	}
	else if(settings_page == SETTINGS_GRAPHICS)
	{
		base = base + [font_size * 0, font_size * 2];
		
		UI_Checkbox("Bloom", base + [font_size * 1, font_size * 4], "r_bloom"); 
		UI_Checkbox("FXAA", base + [font_size * 12, font_size * 4], "r_fxaa"); 
		
		UI_Checkbox("Postprocessing", base + [font_size * 1, font_size * 6], "r_glsl_postprocess");
		UI_Checkbox("Pretty Water", base + [font_size * 12, font_size * 6], "r_water");
		
		UI_Checkbox("Show FPS", base + [font_size * 1, font_size * 8], "showfps");
		UI_Checkbox("Animated shaders", base + [font_size * 12, font_size * 8], "r_deformvertexes");
		
		UI_Text("Effects quality", base + [font_size * 1, font_size * 2]);
		UI_Dropdown("ui_effects", base + [font_size * 8, font_size * 2], font_size * 11, "Low|Medium|High");
		
		UI_Text("Lighting quality", base + [font_size * 1, font_size * 0.1]);
		UI_Dropdown("ui_lighting", base + [font_size * 8], font_size * 11, "Low|Medium|High|Best");
		
	}
	else if(settings_page == SETTINGS_AIM)
	{		
		base = base + [font_size, font_size * 2];
		UI_Checkbox("Invert mouse", base, "ui_invert_mouse"); 
		UI_Text("Revese mouse up-down axis", base + [font_size * 10], '.6 .6 .6');

		base = base + [0, font_size * 1.5];
		UI_Checkbox("Mouse filter", base, "m_filter"); 
		UI_Text("Smooth out mouse movement", base + [font_size * 10], UI_TEXT_INACTIVE);
		
		base = base + [0, font_size * 1.5];
		UI_Checkbox("Auto-Aim", base, "ui_autoaim"); 
		UI_Text("Aim at enemies automatically", base + [font_size * 10], UI_TEXT_INACTIVE);
		
		base = base + [0, font_size * 1.5];
		UI_Checkbox("Raw mouse input", base, "ui_raw"); 
		UI_Text("Directly access mouse data", base + [font_size * 10], UI_TEXT_INACTIVE);
		
		base = base + [0, font_size * 1.5];
		UI_Checkbox("Lower input latency", base, "ui_raw"); 
		UI_Text("Reduce input time", base + [font_size * 10], UI_TEXT_INACTIVE);
		
		UI_Text("Aim sensitivity", base + [0, font_size * 3]);
		UI_Slider(base + [0, font_size * 5], [font_size * 23, 2], "sensitivity", 0.2, 10, 0.05);
	}
	else if(settings_page == SETTINGS_KEYBOARD)
	{
		base = base + [0, font_size * 2];
		// base + [0, font_size * 1], win_settings.UI_win_size -[font_size * 1, font_size * 5]
		vector panel_size = win_settings.UI_win_size -[font_size * 1, font_size * 5];
		UI_KeybindList(base-[0, font_size], win_settings.UI_win_size -[font_size * 1, font_size * 5], 15);
	}
	
	vector button_size = [font_size * 3, font_size * 1.25];
	base = win_settings.UI_win_pos + win_settings.UI_win_size - button_size - [font_size * 0.4, font_size * 0.4];
	UI_Button2("Cancel", base - [font_size * 3.5 ], button_size,  UI_ToggleWindow, "Options");
	UI_Button2("Apply", base, button_size, UI_Cmd, "menu_restart; vid_restart; togglemenu; \n");
}
