
#define SF_FUNNEL_REVERSE          0x0001

#define FUNNEL_SPRITE_PATH         "sprites/flare6.spr"
#define FUNNEL_COUNT               32
#define FUNNEL_RADIUS              256
#define FUNNEL_HEIGHT              256
#define FUNNEL_LIFETIME            1.5

void Funnel_ParticleThink()
{
	remove(self);
}

void Funnel_SpawnParticle(vector emitterOrg, float reverse)
{
	entity p = spawn();
	p.classname = "env_funnel_particle";
	p.solid     = SOLID_NOT;
	p.movetype  = MOVETYPE_NOCLIP;
	p.effects   = EF_ADDITIVE;

	setmodel(p, FUNNEL_SPRITE_PATH);

	float ang   = random() * 360;
	float rad   = random() * FUNNEL_RADIUS;
	vector ringPos = emitterOrg + [cos(ang * M_PI / 180) * rad, sin(ang * M_PI / 180) * rad, FUNNEL_HEIGHT];

	vector startPos, endPos;
	if (reverse) { startPos = emitterOrg; endPos = ringPos; }
	else         { startPos = ringPos;    endPos = emitterOrg; }

	setorigin(p, startPos);
	p.velocity = (endPos - startPos) * (1 / FUNNEL_LIFETIME);

	p.think     = Funnel_ParticleThink;
	p.nextthink = time + FUNNEL_LIFETIME;
}

void EnvFunnel_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	float reverse = (self.spawnflags & SF_FUNNEL_REVERSE) ? 1 : 0;
	for (float i = 0; i < FUNNEL_COUNT; i = i + 1)
		Funnel_SpawnParticle(self.origin, reverse);

	self.think     = SUB_Remove;
	self.nextthink = time;
}

void EnvFunnel_Use()
{
	EnvFunnel_UseHL(activator, self, useType, 0);
}

void env_funnel()
{
	precache_model(FUNNEL_SPRITE_PATH);
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.use   = EnvFunnel_Use;
	self.usehl = EnvFunnel_UseHL;
}
