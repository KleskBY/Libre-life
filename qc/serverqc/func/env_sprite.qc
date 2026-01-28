
#define SF_SPRITE_STARTON		0x0001
#define SF_SPRITE_ONCE			0x0002
#define SF_SPRITE_TEMPORARY		0x8000

.float lastTime;
.float maxFrame;
.float framerate;
.float renderamt;
float MODEL_FRAMES(float index)
{
	return 128;
}
void Sprite_AnimateThink();



void Sprite_TurnOff(entity e)
{
	e.effects = EF_NODRAW;
	e.nextthink = 0;
}


void Sprite_TurnOn(entity e)
{
	e.effects = 0;
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

void Sprite_Precache()
{
	precache_model(self.model);

	// Reset attachment after save/restore
	if (self.aiment) setattachment(self.aiment, self, "");
	
	// if (self.aiment)
		// setattachment(self.aiment, self.body);
	// else // Clear attachment
	// {
		// self.skin = 0;
		// self.body = 0;
	// }
}


void env_sprite()
{
	self.solid			= SOLID_NOT;
	self.movetype		= MOVETYPE_NONE;
	self.effects		= 0;
	self.frame			= 0;

	Sprite_Precache();
	setmodel(self, self.model);
	self.maxFrame = MODEL_FRAMES(self.modelindex ) - 1;
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
	pSprite.classname = "env_sprite";
	pSprite.solid = SOLID_NOT;
	pSprite.movetype = MOVETYPE_NOCLIP;
	pSprite.framerate = 30;
	Sprite_Init(pSprite, pSpriteName, origin);
	if (animate) Sprite_TurnOn(pSprite);
	return pSprite;
}
