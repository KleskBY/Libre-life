
.float iMagnitude;

#define	SF_ENVEXPLOSION_NODAMAGE	( 1 << 0 )
#define	SF_ENVEXPLOSION_REPEATABLE	( 1 << 1 )
#define SF_ENVEXPLOSION_NOFIREBALL	( 1 << 2 )
#define SF_ENVEXPLOSION_NOSMOKE		( 1 << 3 )
#define SF_ENVEXPLOSION_NODECAL		( 1 << 4 )
#define SF_ENVEXPLOSION_NOSPARKS	( 1 << 5 )

void EnvExplosion_Smoke()
{
	if (!(self.spawnflags & SF_ENVEXPLOSION_NOSMOKE))
	{
		pointparticles(particleeffectnum("dust"), self.origin, randomvec(), TRUE);
	}
	
	if (!(self.spawnflags & SF_ENVEXPLOSION_REPEATABLE))
	{
		remove(self);
	}
}

void EnvExplosion_DoFire()
{
	self.model = "";
	self.solid = SOLID_NOT;
	vector vecSpot = self.origin + '0 0 8';
	traceline(vecSpot, vecSpot + '0 0 -40', TRUE, self);

	if (trace_fraction != 1.0) self.origin = trace_endpos + (trace_plane_normal * (self.iMagnitude - 24) * 0.6);
	else self.origin = self.origin;
	
	if ( !( self.spawnflags & SF_ENVEXPLOSION_NOFIREBALL ) )
	{
		te_explosion(self.origin); // Sprite_Create("sprites/zerogxplode.spr", self.origin, TRUE);
	}
	else //no sprite
	{
		te_explosion(self.origin); // Sprite_Create("sprites/zerogxplode.spr", self.origin, TRUE);
	}

	if (!(self.spawnflags & SF_ENVEXPLOSION_NODAMAGE))
	{
		entity attacker = (self.owner != world) ? self.owner : self;
		T_RadiusDamage(self, attacker, self.iMagnitude, self.iMagnitude * 2.5, DMG_BLAST);
	}

	self.think = EnvExplosion_Smoke;
	self.nextthink = time + 0.3;

	if (!( self.spawnflags & SF_ENVEXPLOSION_NOSPARKS))
	{
		te_spark(self.origin, trace_plane_normal, Math_RandomInt(0,3));
	}
}

void EnvExplosion_Use()
{
	EnvExplosion_DoFire();
}

void EnvExplosion_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	EnvExplosion_DoFire();
}

void env_explosion()
{
	self.solid = SOLID_NOT;
	self.effects = EF_NODRAW;
	self.movetype = MOVETYPE_NONE;
	self.use = EnvExplosion_Use;
	self.usehl = EnvExplosion_UseHL;
}
