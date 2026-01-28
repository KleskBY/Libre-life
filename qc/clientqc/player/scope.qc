

/////////////////////////////////////
////////////// SCOPE ////////////////
/////////////////////////////////////


float scoping;
float endScoping;
void enableScope()
{
	aiming = 1;
	if(!IsSniper(getstati(STAT_ACTIVEWEAPON)) || getstati(STAT_HEALTH) < 1)  return;
	scoping = 1;
	endScoping = time + 1.1;
	cvar_set("r_drawviewmodel", "0");
}

void disableScope()
{
	aiming = 0;
	scoping = 0;
	cvar_set("r_drawviewmodel", "1");
}

void Scope_Draw()
{
	if(!scoping) return;

	if(isRunning || !IsSniper(getstati(STAT_ACTIVEWEAPON)) || getstati(STAT_HEALTH) < 1) 
	{
		disableScope();
		return;
	}

	if(scoping == 1)
	{
		drawfill('0 0 0', [vid_x, vid_y, 0], '0 0 0', fabs(endScoping-time), 0);
		if(endScoping < time) scoping = 2;
	}
	
	drawpic([0, 0], "gfx/scope", [vid_x, vid_y], '1 1 1', 1, 0);

}
