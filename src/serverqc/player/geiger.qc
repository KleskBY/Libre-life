
.float geiger_decayTime;
.float geiger_rollTime;

void Player_GeigerPrecache()
{
	precache_sound("player/geiger1.wav");
	precache_sound("player/geiger2.wav");
	precache_sound("player/geiger3.wav");
	precache_sound("player/geiger4.wav");
	precache_sound("player/geiger5.wav");
	precache_sound("player/geiger6.wav");
}

void Player_UpdateGeiger()
{
	if (time > self.geiger_decayTime)
	{
		self.geiger_decayTime = time + 0.25;
		if (!Math_RandomInt(0, 3))
			self.geiger_range = 1000;
	}

	float r = self.geiger_range;
	if (r <= 0 || r >= 1000) return;

	if (time < self.geiger_rollTime) return;
	self.geiger_rollTime = time + 0.02;

	float pct, flvol, i;
	if      (r > 800) { pct = 0;  flvol = 0;    i = 0; }
	else if (r > 600) { pct = 2;  flvol = 0.4;  i = 2; }
	else if (r > 500) { pct = 4;  flvol = 0.5;  i = 2; }
	else if (r > 400) { pct = 8;  flvol = 0.6;  i = 3; }
	else if (r > 300) { pct = 8;  flvol = 0.7;  i = 3; }
	else if (r > 200) { pct = 28; flvol = 0.78; i = 3; }
	else if (r > 150) { pct = 40; flvol = 0.80; i = 3; }
	else if (r > 100) { pct = 60; flvol = 0.85; i = 3; }
	else if (r > 75)  { pct = 80; flvol = 0.9;  i = 3; }
	else if (r > 50)  { pct = 90; flvol = 0.95; i = 2; }
	else              { pct = 95; flvol = 1.0;  i = 2; }

	flvol = (flvol * Math_RandomInt(0, 127)) / 255 + 0.25;

	if (Math_RandomInt(0, 127) < pct || Math_RandomInt(0, 127) < pct)
	{
		float j = Math_RandomInt(0, 1);
		if (i > 2) j += Math_RandomInt(0, 1);
		Sound_Play(self, CHAN_AUTO, flvol, ATTN_STATIC, PITCH_NORM, sprintf("player/geiger%d.wav", j + 1));
	}
}
