
#define XEN_SPORE_SMALL_MODEL	"models/fungus(small).iqm"
#define XEN_SPORE_MED_MODEL	"models/fungus.iqm"
#define XEN_SPORE_LARGE_MODEL	"models/fungus(large).iqm"
#define XEN_SPORE_FRAMES	255

void XenSpore_Think()
{
	self.frame = self.frame + self.framerate * 2.4;
	while (self.frame > XEN_SPORE_FRAMES)
		self.frame = self.frame - XEN_SPORE_FRAMES;

	self.nextthink = time + 0.1;
}

void XenSpore_Touch()
{
}

void XenSpore_Attack()
{
}

float XenSpore_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	XenSpore_Attack();
	return 0;
}

void XenSpore_Precache()
{
	if (self.skin == 0)
		precache_model(XEN_SPORE_SMALL_MODEL);
	else if (self.skin == 1)
		precache_model(XEN_SPORE_MED_MODEL);
	else
		precache_model(XEN_SPORE_LARGE_MODEL);
}

void XenSpore_SetModel()
{
	if (self.skin == 0)
		setmodel(self, XEN_SPORE_SMALL_MODEL);
	else if (self.skin == 1)
		setmodel(self, XEN_SPORE_MED_MODEL);
	else
		setmodel(self, XEN_SPORE_LARGE_MODEL);
}

void XenSpore_SpawnBase()
{
	XenSpore_Precache();
	XenSpore_SetModel();

	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_BBOX;
	self.takedamage = DAMAGE_YES;
	self.takeDmgFn = XenSpore_TakeDamage;
	self.touch = XenSpore_Touch;
	self.frame = random(0, XEN_SPORE_FRAMES);
	self.framerate = random(0.7, 1.4);
	self.think = XenSpore_Think;
	self.nextthink = time + random(0.1, 0.4);
}

entity XenHull_Create(entity source, vector mins, vector maxs, vector offset)
{
	entity hull = spawn();
	hull.classname = "xen_hull";
	hull.movetype = MOVETYPE_NONE;
	hull.solid = SOLID_BBOX;
	hull.owner = source;
	hull.model = source.model;
	hull.modelindex = source.modelindex;
	hull.renderamt = 0;
	hull.rendermode = 2;
	setorigin(hull, source.origin + offset);
	setsize(hull, mins, maxs);
	return hull;
}

void xen_hull()
{
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_BBOX;
	self.renderamt = 0;
	self.rendermode = 2;
}

void xen_spore_small()
{
	self.skin = 0;
	XenSpore_SpawnBase();
	setsize(self, '-16 -16 0', '16 16 64');
}

void xen_spore_medium()
{
	self.skin = 1;
	XenSpore_SpawnBase();
	setsize(self, '-40 -40 0', '40 40 120');
}

void XenSporeLarge_CreateHulls()
{
	makevectors(self.angles);
	XenHull_Create(self, '-12 -12 0', '12 12 120', v_forward * 90 + v_right * -25);
	XenHull_Create(self, '-12 -12 0', '12 12 120', v_forward * 25 + v_right * 75);
	XenHull_Create(self, '-12 -12 0', '12 12 120', v_forward * -15 + v_right * -100);
	XenHull_Create(self, '-12 -12 0', '12 12 120', v_forward * -90 + v_right * -35);
	XenHull_Create(self, '-12 -12 0', '12 12 120', v_forward * -90 + v_right * 60);
}

void xen_spore_large()
{
	self.skin = 2;
	XenSpore_SpawnBase();
	setsize(self, '-48 -48 110', '48 48 240');
	XenSporeLarge_CreateHulls();
}
