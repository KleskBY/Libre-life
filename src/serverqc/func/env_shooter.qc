
.string shootmodel;
.float  shootsounds;
.float  shooter_gibMaterial;
.float  shooter_material;
// .body lives in util_body.qc (shared bodygroup field)

// Map a shootmodel path to a project gib-set base (no ext, lowercase).
string EnvShooter_GibBase(string rawmodel)
{
	string s = strtolower(Breakable_StripExt(rawmodel));

	if (strstrofs(s, "concrete", 0) >= 0)
		return "models/concrete_gibs";

	if (strstrofs(s, "bone",    0) >= 0     // abone, bonegibs
	 || strstrofs(s, "skull",   0) >= 0     // bskull
	 || strstrofs(s, "pelvis",  0) >= 0
	 || strstrofs(s, "ribcage", 0) >= 0
	 || strstrofs(s, "skel",    0) >= 0)
		return "models/bonegibs";

	return s;
}

entity EnvShooter_CreateGib()
{
	entity gib = spawn();
	gib.classname        = "gib";
	gib.owner            = self;
	gib.movetype         = MOVETYPE_BOUNCE;
	gib.solid            = SOLID_TRIGGER;
	gib.takedamage       = DAMAGE_NO;
	gib.effects          = EF_NOSHADOW;
	gib.frame            = 0;
	gib.gib_blood_color  = 0;	// DONT_BLEED
	gib.gib_blood_decals = 0;
	gib.gib_lifetime     = 25;
	gib.avelocity        = [random(100, 200), random(100, 300), random(100, 300)];
	gib.touch            = Gib_BounceTouch;
	gib.think            = Gib_WaitTillLand;
	gib.nextthink        = time + 4;

	float bodyPart = 0;
	if (self.body > 1)
		bodyPart = Math_RandomInt(0, self.body - 1);
	gib.body = bodyPart;

	gib.shooter_material = self.shooter_gibMaterial;

	// Render-field carryover from shooter to gib.
	gib.rendermode  = self.rendermode;
	gib.renderamt   = self.renderamt;
	gib.rendercolor = self.rendercolor;
	gib.renderfx    = self.renderfx;
	gib.scale       = self.scale;
	gib.skin        = self.skin;

	if (self.gibmodelcount > 0)
		setmodel(gib, Breakable_GibFilename(self.gibmodel, Math_RandomInt(1, self.gibmodelcount)));
	else
		setmodel(gib, self.model);
	Body_Apply(gib);	// honor random bodygroup if the model ships a .bodyinfo
	setsize(gib, '0 0 0', '0 0 0');
	setorigin(gib, self.origin);
	return gib;
}

void env_shooter()
{
	if (self.shootmodel != "")
		self.model = self.shootmodel;

	if (self.model == "" || !self.model)
	{
		dprint("env_shooter at "); dprint(vtos(self.origin));
		dprint(" missing shootmodel\n");
		remove(self);
		return;
	}

	float ss = self.shootsounds;
	if      (ss == 0) self.shooter_gibMaterial = MAT_GLASS;
	else if (ss == 1) self.shooter_gibMaterial = MAT_WOOD;
	else if (ss == 2) self.shooter_gibMaterial = MAT_METAL;
	else if (ss == 3) self.shooter_gibMaterial = MAT_FLESH;
	else if (ss == 4) self.shooter_gibMaterial = MAT_ROCKS;
	else              self.shooter_gibMaterial = MAT_NONE;

	string gib_base = EnvShooter_GibBase(self.model);
	string gib_zoned = "";
	float  gib_count = Breakable_LookupCustomGib(gib_base, gib_zoned);

	if (gib_count > 0)
	{
		self.gibmodel      = gib_zoned;
		self.gibmodelcount = gib_count;
	}
	else
	{
		self.gibmodelcount = 0;
		string single = "";
		string cand = strcat(gib_base, ".iqm");
		float fh = fopen(cand, FILE_READ);
		if (fh >= 0)
		{
			fclose(fh);
			single = cand;
		}
		else
		{
			cand = strtolower(self.model);
			fh = fopen(cand, FILE_READ);
			if (fh >= 0)
			{
				fclose(fh);
				single = cand;
			}
		}

		if (single != "")
		{
			self.model = strzone(single);   // strcat/strtolower tempstrings
			precache_model(self.model);
		}
		else
		{
			gib_count = Breakable_LookupCustomGib("models/concrete_gibs", gib_zoned);
			if (gib_count > 0)
			{
				self.gibmodel      = gib_zoned;
				self.gibmodelcount = gib_count;
			}
			else
			{
				precache_model(self.model);   // nothing on disk; let it warn
			}
			dprint("env_shooter: shootmodel not found: ");
			dprint(self.model); dprint("\n");
		}
	}

	if (self.shooter_gibMaterial != MAT_NONE)
		Breakable_EnsureMaterialReady(self.shooter_gibMaterial);

	self.solid   = SOLID_NOT;
	self.effects = EF_NODRAW;

	if (self.delay == 0)         self.delay = 0.1;
	if (self.m_flGibLife == 0)   self.m_flGibLife = 25;
	if (self.m_flVelocity != 0)  self.gib_gibVelocity = self.m_flVelocity;
	self.gib_gibCapacity = self.m_iGibs;

	SetMovedir();

	self.createGibFn = EnvShooter_CreateGib;
	self.use   = GibShooter_Use;
	self.usehl = GibShooter_UseHL;
}
