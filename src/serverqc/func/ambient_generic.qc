
#define AMBIENT_SOUND_STATIC			0
#define AMBIENT_SOUND_EVERYWHERE		1
#define AMBIENT_SOUND_SMALLRADIUS		2
#define AMBIENT_SOUND_MEDIUMRADIUS		4
#define AMBIENT_SOUND_LARGERADIUS		8
#define AMBIENT_SOUND_START_SILENT		16
#define AMBIENT_SOUND_NOT_LOOPING		32

float AmbientGeneric_Pitch()
{
	if (self.pitch <= 0) return 100;
	return self.pitch;
}

float AmbientGeneric_IsLooping()
{
	return !FBitSet(spawnflags, AMBIENT_SOUND_NOT_LOOPING);
}

float AmbientGeneric_IsSentence()
{
	return str2chr(self.message, 0) == 33; // '!'
}

void AmbientGeneric_Stop()
{
	self.nextthink = -1;
	if (AmbientGeneric_IsSentence())
		Sentences_Stop(self, CHAN_WEAPON);
	Sound_Stop(self, CHAN_WEAPON);
}

void AmbientGeneric_Play(float soundFlags)
{
	if (AmbientGeneric_IsSentence())
	{
		Sentences_Play(self, CHAN_WEAPON, self.message,
			self.volume, self.distance, AmbientGeneric_Pitch());
		return;
	}
	Sound_Emit(self, CHAN_WEAPON, self.noise, self.volume, self.distance, AmbientGeneric_Pitch(), 0);
}

void AmbientGeneric_Think()
{
	self.nextthink = -1;
};
	
void AmbientGeneric_Use()
{
	if (AmbientGeneric_IsLooping() && self.state)
	{
		AmbientGeneric_Stop();
		self.state = 0;
		return;
	}

	if (!AmbientGeneric_IsLooping())
		AmbientGeneric_Stop();

	AmbientGeneric_Play(0);
	if (AmbientGeneric_IsLooping())
		self.state = 1;
};

void AmbientGeneric_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (useTypeArg != USE_TOGGLE)
	{
		if ((self.state && useTypeArg == USE_ON) || (!self.state && useTypeArg == USE_OFF))
			return;
	}

	AmbientGeneric_Use();
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
	else	// default attenuation if none set
	{
		self.distance = ATTN_STATIC;
	}

	if(!self.message || strlen(self.message) < 1)
	{
		remove(self);
		return;
	}
	self.noise = self.message;
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.use = AmbientGeneric_Use;
	self.usehl = AmbientGeneric_UseHL;
	self.think = AmbientGeneric_Think;
	
	if (!AmbientGeneric_IsSentence())
		precache_sound(self.noise);
	self.volume = self.health * 10;
	if (self.volume > 100) self.volume = 100;
	if (self.volume < 0) self.volume = 0;
	self.volume = self.volume / 100;
	
	if (!FBitSet(spawnflags, AMBIENT_SOUND_START_SILENT))
	{
		if (AmbientGeneric_IsLooping())
		{
			AmbientGeneric_Play(0);
			self.state = 1;
		}
		else
			self.state = 0;
	}
};	
