void() ambient_suck_wind =
{
	precache_sound("ambience/suck1.wav");
	ambientsound(self.origin, "ambience/suck1.wav", 1, ATTN_STATIC);
};

void() ambient_drone =
{
	precache_sound("ambience/drone6.wav");
	ambientsound(self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC);
};

void() ambient_flouro_buzz =
{
	precache_sound("ambience/buzz1.wav");
	ambientsound(self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC);
};

void() ambient_drip =
{
	precache_sound("ambience/drip1.wav");
	ambientsound(self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC);
};

void() ambient_comp_hum =
{
	precache_sound("ambience/comp1.wav");
	ambientsound(self.origin, "ambience/comp1.wav", 1, ATTN_STATIC);
};

void() ambient_thunder =
{
	precache_sound("ambience/thunder1.wav");
	ambientsound(self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC);
};

void() ambient_light_buzz =
{
	precache_sound("ambience/fl_hum1.wav");
	ambientsound(self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC);
};

void() ambient_swamp1 =
{
	precache_sound("ambience/swamp1.wav");
	ambientsound(self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC);
};

void() ambient_swamp2 =
{
	precache_sound("ambience/swamp2.wav");
	ambientsound(self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC);
};
