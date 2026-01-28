
#define AMBIENT_SOUND_STATIC			0	// medium radius attenuation
#define AMBIENT_SOUND_EVERYWHERE		1
#define AMBIENT_SOUND_SMALLRADIUS		2
#define AMBIENT_SOUND_MEDIUMRADIUS		4
#define AMBIENT_SOUND_LARGERADIUS		8
#define AMBIENT_SOUND_START_SILENT		16
#define AMBIENT_SOUND_NOT_LOOPING		32

void AmbientGeneric_Play()
{
	sound(self, CHAN_VOICE, self.noise, self.volume, self.distance);
}

void ambient_generic_think()
{
	AmbientGeneric_Play();
	if(self.wait) self.nextthink = time + self.wait;
};
	
void ambient_generic_use()
{
	// if (!FBitSet(spawnflags, AMBIENT_SOUND_START_SILENT))
	if(self.state)
	{
		self.wait = 0;
		sound(self, CHAN_VOICE, "misc/null.wav", 1, 0);
	}
	else AmbientGeneric_Play();
	self.state = !self.state;
};
	
void ambient_generic()
{
	if (FBitSet(spawnflags, AMBIENT_SOUND_EVERYWHERE))
	{
		self.distance = ATTN_NONE;
	}
	else if (FBitSet(spawnflags, AMBIENT_SOUND_SMALLRADIUS))
	{
		self.distance = ATTN_IDLE;
	}
	else if (FBitSet(spawnflags, AMBIENT_SOUND_MEDIUMRADIUS))
	{
		self.distance = ATTN_STATIC;
	}
	else if (FBitSet(spawnflags, AMBIENT_SOUND_LARGERADIUS))
	{
		self.distance = ATTN_NORM;
	}
	else // if the designer didn't set a sound attenuation, default to one.
	{
		self.distance = ATTN_STATIC;
	}

	if(!self.message || strlen(self.message) < 1)
	{
		// dprint("EMPTY AMBIENT AT: ", vtos(self.origin), "\n");
		remove(self);
		return;
	}
	self.noise = self.message;
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.use = ambient_generic_use;
	self.think = ambient_generic_think;
	
	precache_sound(self.noise);
	if (FBitSet(spawnflags, AMBIENT_SOUND_NOT_LOOPING))
		self.wait = FALSE;
	else
		self.wait = soundlength(self.noise);
	
	
	self.volume = self.health * 10;
	if (self.volume > 100) self.volume = 100;
	if (self.volume < 0) self.volume = 0;
	self.volume = self.volume / 100;
	
	if (!FBitSet(spawnflags, AMBIENT_SOUND_START_SILENT))
	{
		self.nextthink = time + 0.1;
		self.state = 1;
	}
};	