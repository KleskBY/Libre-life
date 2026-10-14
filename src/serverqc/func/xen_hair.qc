
#define SF_HAIR_SYNC	0x0001
#define XEN_HAIR_MODEL	"models/hair.iqm"
#define XEN_HAIR_FRAMES	255

void XenHair_Think()
{
	self.frame = self.frame + self.framerate * 12;
	while (self.frame > XEN_HAIR_FRAMES)
		self.frame = self.frame - XEN_HAIR_FRAMES;

	self.nextthink = time + 0.5;
}

void xen_hair()
{
	precache_model(XEN_HAIR_MODEL);
	setmodel(self, XEN_HAIR_MODEL);
	setsize(self, '-4 -4 0', '4 4 32');

	if (!(self.spawnflags & SF_HAIR_SYNC))
	{
		self.frame = random(0, XEN_HAIR_FRAMES);
		self.framerate = random(0.7, 1.4);
	}
	else
	{
		self.frame = 0;
		self.framerate = 1;
	}

	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.think = XenHair_Think;
	self.nextthink = time + random(0.1, 0.4);
}
