void() trigger_secret =
{
	total_secrets = total_secrets + 1;
	self.wait = -1;
	if (!self.message) self.message = "You found a secret area!";
	if (!self.sounds) self.sounds = 1;
	
	if (self.sounds == 1)
	{
		precache_sound ("misc/secret.wav");
		self.noise = "misc/secret.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound ("misc/talk.wav");
		self.noise = "misc/talk.wav";
	}

	trigger_multiple();
};