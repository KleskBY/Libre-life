

void Precache()
{
	precache_pic("gfx/scope");
	precache_cubemap("cubemaps/237");
	precache_pic("gfx/medkit");
	
	precache_pic("gfx/hud/ak74");
	precache_pic("gfx/hud/grenade");
	precache_pic("gfx/hud/knife");
	precache_pic("gfx/hud/ks23");
	precache_pic("gfx/hud/oc14");
	precache_pic("gfx/hud/pm");
	precache_pic("gfx/hud/svd");
	precache_pic("gfx/hud/val");
	precache_sound("misc/hud01.wav");
	precache_sound("misc/hud02.wav");
	
	precache_pic("gfx/background");
	precache_pic("gfx/cursor");
	if(mapname == "maps/e1m1.bsp") 
	{
		precache_sound("misc/page.wav");
		precache_pic("textures/notes/page");
	}

};