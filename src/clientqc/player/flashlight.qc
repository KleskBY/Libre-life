

float flashlight;
void Flashlight_Draw()
{
	flashlight = (playerFlashOn != 0) && Player_IsAlive() && !intermission;
	if(!flashlight) return;
	makevectors(input_angles);
	if(IsFTE()) adddynamiclight2(pmove_org, 350, '1.95 1.8 1.7', 0, "", PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW);
	else adddynamiclight2(pmove_org, 350, '1.95 1.8 1.7', 0, "cubemaps/237", PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW);
};


void Flashlight_Toggle()
{
	if(intermission || !Player_IsAlive()) return;
	localcmd("cmd flashlight\n");
};