
#define XEN_PLANTLIGHT_MODEL	"models/light.iqm"
#define XEN_PLANT_GLOW_SPRITE	"sprites/flare6.spr"
#define XEN_PLANT_HIDE_TIME	5

#define XEN_PLANT_IDLE		0
#define XEN_PLANT_CROUCH	1
#define XEN_PLANT_CROUCHIDLE	2
#define XEN_PLANT_STAND		3

.entity xenPlantGlow;
.float xenPlantActivity;
.float xenPlantStateTime;

void XenPlantLight_SetGlowOrigin()
{
	if (!self.xenPlantGlow)
		return;

	setorigin(self.xenPlantGlow, self.origin + '0 0 16');
}

void XenPlantLight_LightOn()
{
	SUB_UseTargetsHL(self, USE_ON, 0);
	if (self.xenPlantGlow)
		self.xenPlantGlow.effects = self.xenPlantGlow.effects - (self.xenPlantGlow.effects & EF_NODRAW);
}

void XenPlantLight_LightOff()
{
	SUB_UseTargetsHL(self, USE_OFF, 0);
	if (self.xenPlantGlow)
		self.xenPlantGlow.effects = self.xenPlantGlow.effects | EF_NODRAW;
}

void XenPlantLight_SetActivity(float activity)
{
	self.xenPlantActivity = activity;

	if (activity == XEN_PLANT_IDLE)
		self.frame = 0;
	else if (activity == XEN_PLANT_CROUCH)
	{
		self.frame = 1;
		self.xenPlantStateTime = time + 0.6;
	}
	else if (activity == XEN_PLANT_CROUCHIDLE)
		self.frame = 2;
	else if (activity == XEN_PLANT_STAND)
	{
		self.frame = 3;
		self.xenPlantStateTime = time + 0.6;
	}
}

void XenPlantLight_Think()
{
	self.nextthink = time + 0.1;
	XenPlantLight_SetGlowOrigin();

	if (self.xenPlantActivity == XEN_PLANT_CROUCH)
	{
		if (time >= self.xenPlantStateTime)
		{
			XenPlantLight_SetActivity(XEN_PLANT_CROUCHIDLE);
			XenPlantLight_LightOff();
		}
	}
	else if (self.xenPlantActivity == XEN_PLANT_CROUCHIDLE)
	{
		if (time > self.dmgtime)
		{
			XenPlantLight_SetActivity(XEN_PLANT_STAND);
			XenPlantLight_LightOn();
		}
	}
	else if (self.xenPlantActivity == XEN_PLANT_STAND)
	{
		if (time >= self.xenPlantStateTime)
			XenPlantLight_SetActivity(XEN_PLANT_IDLE);
	}
}

void XenPlantLight_Touch()
{
	if (other.classname != "player")
		return;

	self.dmgtime = time + XEN_PLANT_HIDE_TIME;
	if (self.xenPlantActivity == XEN_PLANT_IDLE || self.xenPlantActivity == XEN_PLANT_STAND)
		XenPlantLight_SetActivity(XEN_PLANT_CROUCH);
}

void XenPlantLight_CreateGlow()
{
	entity glow = Sprite_Create(XEN_PLANT_GLOW_SPRITE, self.origin + '0 0 16', FALSE);
	glow.classname = "xen_plantlight_glow";
	glow.rendercolor = self.rendercolor;
	glow.renderamt = self.renderamt;
	glow.renderfx = self.renderfx;
	glow.rendermode = self.rendermode;
	glow.scale = self.scale;
	if (!glow.renderamt)
		glow.renderamt = 255;
	if (glow.rendercolor == '0 0 0')
		glow.rendercolor = '255 255 255';
	self.xenPlantGlow = glow;
}

void xen_plantlight()
{
	precache_model(XEN_PLANTLIGHT_MODEL);
	precache_model(XEN_PLANT_GLOW_SPRITE);

	setmodel(self, XEN_PLANTLIGHT_MODEL);
	setsize(self, '-80 -80 0', '80 80 32');

	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.touch = XenPlantLight_Touch;
	self.frame = random(0, 255);

	XenPlantLight_SetActivity(XEN_PLANT_IDLE);
	XenPlantLight_CreateGlow();

	self.think = XenPlantLight_Think;
	self.nextthink = time + 0.1;
}
