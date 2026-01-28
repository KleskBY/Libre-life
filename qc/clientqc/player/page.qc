

float Page_Input(string keybind, float flEventType)
{
	if(!showPage) return FALSE;
	if(flEventType) return FALSE;
	
	if (keybind == "togglemenu" || keybind == "+attack" || keybind == "+button4" || keybind == "+button5" || keybind == "+showscores" || keybind == "+use" || keybind == "+jump")
	{
		showPage = FALSE;
		return TRUE;
	}
	return FALSE;
}

void Page_Toggle()
{
	if(!showPage) localsound("misc/page.wav");
	showPage = TRUE;
};

void Page_Draw()
{
	if(!Player_IsAlive()) 
	{
		showPage = false;
	}
	
	if(showPage)
	{
		cvar_set("r_viewscale", "0");
		vector page_size = fixed_vector('900 1139 0' * 0.4);
		drawpic([vid_x / 2 - page_size_x / 2, vid_y / 2 - page_size_y / 2], "textures/notes/page1", page_size, '1 1 1', 1, 0);
	}
	else if(cvar("r_viewscale") == 0) cvar_set("r_viewscale", "1");
}