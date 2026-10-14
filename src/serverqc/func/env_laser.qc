
#define SF_BEAM_STARTON  0x0001


.string LaserTarget;
.string EndSprite;
.float  width;
.entity laser_endSprite;

float EnvLaser_IsOn(entity e)
{
	return !(e.effects & EF_NODRAW);
}

void EnvLaser_TurnOff(entity laser)
{
	laser.effects = laser.effects | EF_NODRAW;
	laser.nextthink = -1;
	if (laser.laser_endSprite)
		laser.laser_endSprite.effects = laser.laser_endSprite.effects | EF_NODRAW;
}

void EnvLaser_TurnOn(entity laser)
{
	laser.effects = laser.effects - (laser.effects & EF_NODRAW);
	if (laser.laser_endSprite)
		laser.laser_endSprite.effects = laser.laser_endSprite.effects - (laser.laser_endSprite.effects & EF_NODRAW);
	laser.dmgtime = time;
	laser.nextthink = time;
}

entity EnvLaser_RandomTargetname(string n)
{
	if (!n || n == "") return world;
	entity picked = world;
	float total = 0;
	entity t = find(world, targetname, n);
	while (t)
	{
		total = total + 1;
		if (Math_RandomInt(0, total - 1) < 1) picked = t;
		t = find(t, targetname, n);
	}
	return picked;
}

void EnvLaser_StrikeThink()
{
	if (!EnvLaser_IsOn(self)) return;

	entity pEnd = EnvLaser_RandomTargetname(self.LaserTarget != "" ? self.LaserTarget : self.message);
	vector firePos = pEnd ? pEnd.origin : self.origin;

	traceline(self.origin, firePos, FALSE /*dont_ignore_monsters*/, self);
	vector hit = trace_endpos;

	te_lightning1(self, self.origin, hit);

	if (self.laser_endSprite)
		setorigin(self.laser_endSprite, hit);

	if (self.damage > 0 && trace_ent && trace_ent.takedamage)
	{
		float dt = time - self.dmgtime;
		if (dt < 0.05) dt = 0.05;
		Combat_TakeDamage(trace_ent, self, self, self.damage * dt, DMG_ENERGYBEAM);
	}
	self.dmgtime = time;

	// Tiny spark at the impact for the "burning into the wall" feel.
	DoSpark(hit);

	self.nextthink = time + 0.1;
}

void EnvLaser_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	useType = useTypeArg;            // ShouldToggle reads this global
	float active = EnvLaser_IsOn(self);
	if (!ShouldToggle(active)) return;

	if (active) EnvLaser_TurnOff(self);
	else        EnvLaser_TurnOn(self);
}

void EnvLaser_Use()
{
	EnvLaser_UseHL(activator, self, useType, 0);
}

void env_laser()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;

	if (!self.model || self.model == "")
	{
		dprint("env_laser: missing texture/model — removing\n");
		remove(self);
		return;
	}
	precache_model(self.model);

	if (self.EndSprite && self.EndSprite != "")
	{
		precache_model(self.EndSprite);
		entity sp = spawn();
		sp.classname  = "env_laser_endsprite";
		sp.owner      = self;
		sp.solid      = SOLID_NOT;
		sp.movetype   = MOVETYPE_NONE;
		setmodel(sp, self.EndSprite);
		setorigin(sp, self.origin);
		// Match kRenderGlow functionality using rendercolor/renderamt/renderfx.
		sp.rendercolor = self.rendercolor;
		sp.renderamt   = self.renderamt;
		sp.renderfx    = self.renderfx;
		sp.effects     = self.effects;
		self.laser_endSprite = sp;
	}

	self.use   = EnvLaser_Use;
	self.usehl = EnvLaser_UseHL;
	self.think = EnvLaser_StrikeThink;
	self.flags = self.flags | FL_CUSTOMENTITY;

	// If targetname is set and STARTON is off, start hidden; otherwise on.
	if (self.targetname != "" && !(self.spawnflags & SF_BEAM_STARTON))
		EnvLaser_TurnOff(self);
	else
		EnvLaser_TurnOn(self);
}
