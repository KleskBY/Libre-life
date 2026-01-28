

float flashlight;
void Flashlight_Draw()
{
	if(intermission || !Player_IsAlive())
	{
		flashlight = false;
	}
	if(!flashlight) return;
	adddynamiclight2(pmove_org, 350, '1.95 1.8 1.7', 0, "cubemaps/237", PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW);
};


void Flashlight_Toggle()
{
	if(intermission || !Player_IsAlive()) return;
	localcmd("cmd flashlight\n");
	flashlight = !flashlight;
};