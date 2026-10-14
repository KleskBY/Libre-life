
#define SF_SPRITE_STARTON		0x0001
#define SF_SPRITE_ONCE			0x0002
#define SF_SPRITE_TEMPORARY		0x8000
#define SPRITE_FRAME_MANIFEST		"sprites/sprite_frames.txt"
#define SPRITE_FRAME_MAX_ENTRIES	256

.float lastTime;
.float maxFrame;
.float framerate;
.float spriteframes;	// optional map override: total frame count
.float frames;			// optional map override: total frame count
.float maxframe;		// optional map override: last frame index

float(float mdlidx) modelframecount = #0:modelframecount;

string sprite_frame_model[SPRITE_FRAME_MAX_ENTRIES];
float sprite_frame_count[SPRITE_FRAME_MAX_ENTRIES];
float sprite_frame_manifest_loaded;
float sprite_frame_manifest_count;

float Sprite_KeyvalueFrameCount()
{
	if (self.spriteframes > 0) return self.spriteframes;
	if (self.frames > 0) return self.frames;
	if (self.maxframe > 0) return self.maxframe + 1;
	return 0;
}

void Sprite_FrameManifestInit()
{
	float fh;
	string line;
	float n;
	string path;
	float frames;

	if (sprite_frame_manifest_loaded) return;
	sprite_frame_manifest_loaded = TRUE;
	sprite_frame_manifest_count = 0;

	fh = fopen(SPRITE_FRAME_MANIFEST, FILE_READ);
	if (fh < 0)
	{
		dprint(strcat("Sprite_FrameManifestInit: missing ", SPRITE_FRAME_MANIFEST, "\n"));
		return;
	}

	while ((line = fgets(fh)))
	{
		n = tokenize(line);
		if (n < 2) continue;
		path = argv(0);
		if (substring(path, 0, 2) == "//") continue;
		if (substring(path, 0, 1) == "#") continue;

		frames = stof(argv(1));
		if (frames <= 0) continue;
		if (sprite_frame_manifest_count >= SPRITE_FRAME_MAX_ENTRIES)
		{
			dprint("Sprite_FrameManifestInit: manifest entry limit reached\n");
			break;
		}

		sprite_frame_model[sprite_frame_manifest_count] = strzone(strtolower(path));
		sprite_frame_count[sprite_frame_manifest_count] = frames;
		sprite_frame_manifest_count = sprite_frame_manifest_count + 1;
	}
	fclose(fh);
}

float Sprite_ManifestFrameCount(string modelName)
{
	float i;
	string lowerName;

	Sprite_FrameManifestInit();
	lowerName = strtolower(modelName);
	for (i = 0; i < sprite_frame_manifest_count; i += 1)
	{
		if (sprite_frame_model[i] == lowerName)
			return sprite_frame_count[i];
	}
	return 0;
}

float Sprite_ModelFrameCount(string modelName, float index)
{
	float frames;

	frames = Sprite_KeyvalueFrameCount();
	if (frames > 0) return frames;

	if (IsFTE())
	{
		frames = modelframecount(index);
		if (frames > 0) return frames;
	}

	frames = Sprite_ManifestFrameCount(modelName);
	if (frames > 0) return frames;

	dprint(strcat("Sprite_ModelFrameCount: no frame count for ", modelName, ", assuming 1\n"));
	return 1;
}

float MODEL_FRAMES(float index)
{
	return Sprite_ModelFrameCount(self.model, index);
}
void Sprite_AnimateThink();


void Sprite_TurnOff(entity e)
{
	e.effects = EF_NODRAW;
	e.nextthink = 0;
}


void Sprite_TurnOn(entity e)
{
	e.effects = EF_ADDITIVE;
	if ( (e.framerate && e.maxFrame > 1.0) || (e.spawnflags & SF_SPRITE_ONCE))
	{
		e.think = Sprite_AnimateThink;
		e.nextthink = time;
		e.lastTime = time;
	}
	e.frame = 0;
}

void Sprite_Animate(float frames)
{
	self.frame += frames;
	if (self.frame > self.maxFrame)
	{
		if (self.spawnflags & SF_SPRITE_ONCE)
		{
			Sprite_TurnOff(self);
		}
		else
		{
			if (self.maxFrame > 0)
				self.frame = mod(self.frame, self.maxFrame);
		}
	}
}


void Sprite_AnimateThink()
{
	Sprite_Animate(self.framerate * (time - self.lastTime));
	self.nextthink = time + 0.1;
	self.lastTime = time;
}

void Sprite_AnimateUntilDead()
{
	if (time > self.dmgtime)
		remove(self);
	else
	{
		Sprite_AnimateThink();
		self.nextthink = time;
	}
}

void Sprite_AnimateAndDie(float rate)
{
	if (rate <= 0)
	{
		remove(self);
		return;
	}
	self.framerate = rate;
	self.dmgtime = time + (self.maxFrame / rate);
	self.think = Sprite_AnimateUntilDead;
	self.nextthink = time;
	self.lastTime = time;
}


void Sprite_ExpandThink()
{
	float deltaTime = time - self.lastTime;
	self.scale += self.speed * deltaTime;
	self.renderamt -= self.health * deltaTime;
	if (self.renderamt <= 0)
	{
		self.renderamt = 0;
		remove(self);
	}
	else
	{
		self.nextthink = time + 0.1;
		self.lastTime  = time;
	}
}

void Sprite_Expand(float scaleSpeed, float fadeSpeed)
{
	self.speed = scaleSpeed;
	self.health = fadeSpeed;
	self.think = Sprite_ExpandThink;
	self.nextthink	= time;
	self.lastTime		= time;
}


void Sprite_Use()
{
	float on = self.effects != EF_NODRAW;
	// if ( ShouldToggle( useType, on ) )
	{
		if (on)
		{
			Sprite_TurnOff(self);
		}
		else
		{
			Sprite_TurnOn(self);
		}
	}
}

void Sprite_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	float on = self.effects != EF_NODRAW;
	if (on)
		Sprite_TurnOff(self);
	else
		Sprite_TurnOn(self);
}

void Sprite_Precache()
{
	precache_model(self.model);
	if (self.aiment) setattachment(self.aiment, self, "");
}


void env_sprite()
{
	self.solid			= SOLID_NOT;
	self.movetype		= MOVETYPE_NONE;
	self.effects		= 0;
	self.frame			= 0;
	self.effects 		= EF_ADDITIVE;

	Sprite_Precache();
	setmodel(self, self.model);
	self.maxFrame = Sprite_ModelFrameCount(self.model, self.modelindex) - 1;
	if (self.maxFrame < 0) self.maxFrame = 0;
	if (self.targetname && !(self.spawnflags & SF_SPRITE_STARTON))
		Sprite_TurnOff(self);
	else
		Sprite_TurnOn(self);
	
	if (self.angles_y != 0 && self.angles_z == 0 )
	{
		self.angles_z = self.angles_y;
		self.angles_y = 0;
	}
	
	self.use = Sprite_Use;
	self.usehl = Sprite_UseHL;
}

void Sprite_Init(entity e, string pSpriteName, vector org)
{
	e.model = pSpriteName;
	e.origin = org;
	entity oself = self;
	self = e;
	env_sprite();
	self = oself;
}

entity Sprite_Create(string pSpriteName, vector origin, float animate)
{
	entity pSprite = spawn();
	pSprite.classname 	= "env_sprite";
	pSprite.solid 		= SOLID_NOT;
	pSprite.movetype 	= MOVETYPE_NOCLIP;
	pSprite.effects  	= EF_ADDITIVE;
	pSprite.framerate = 30;
	Sprite_Init(pSprite, pSpriteName, origin);
	if (animate) Sprite_TurnOn(pSprite);
	return pSprite;
}
