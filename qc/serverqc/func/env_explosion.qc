

.float iMagnitude;

#define	SF_ENVEXPLOSION_NODAMAGE	( 1 << 0 ) // when set, ENV_EXPLOSION will not actually inflict damage
#define	SF_ENVEXPLOSION_REPEATABLE	( 1 << 1 ) // can this entity be refired?
#define SF_ENVEXPLOSION_NOFIREBALL	( 1 << 2 ) // don't draw the fireball
#define SF_ENVEXPLOSION_NOSMOKE		( 1 << 3 ) // don't draw the smoke
#define SF_ENVEXPLOSION_NODECAL		( 1 << 4 ) // don't make a scorch mark
#define SF_ENVEXPLOSION_NOSPARKS	( 1 << 5 ) // don't make a scorch mark

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


void EnvExplosion_Use()
{ 
	self.model = "";//invisible
	self.solid = SOLID_NOT;// intangible
	vector vecSpot = self.origin + '0 0 8';
	traceline(vecSpot, vecSpot + '0 0 -40', TRUE, self);
	
	// Pull out of the wall a bit
	if (trace_fraction != 1.0)
	{
		self.origin = trace_endpos + (trace_plane_normal * (self.iMagnitude - 24) * 0.6);
	}
	else
	{
		self.origin = self.origin;
	}

	// draw decal
	/*
	if (!(self.spawnflags & SF_ENVEXPLOSION_NODECAL))
	{
		if (random(0, 1) < 0.5)
		{
			// UTIL_DecalTrace( &tr, DECAL_SCORCH1 );
		}
		else
		{
			// UTIL_DecalTrace( &tr, DECAL_SCORCH2 );
		}
	}
	*/

	// draw fireball
	if ( !( self.spawnflags & SF_ENVEXPLOSION_NOFIREBALL ) )
	{
		te_explosion(self.origin);
		// Sprite_Create("sprites/zerogxplode.spr", self.origin, TRUE);
	}
	else //no sprite
	{
		te_explosion(self.origin);
		// Sprite_Create("sprites/zerogxplode.spr", self.origin, TRUE);
	}

	// do damage
	if (!(self.spawnflags & SF_ENVEXPLOSION_NODAMAGE))
	{
		// RadiusDamage( pev, pev, self.iMagnitude, CLASS_NONE, DMG_BLAST );
	}

	self.think = EnvExplosion_Smoke;
	self.nextthink = time + 0.3;

	// draw sparks
	if (!( self.spawnflags & SF_ENVEXPLOSION_NOSPARKS))
	{
		te_spark(self.origin, trace_plane_normal, RandomInt(0,3));
	}
}


void env_explosion()
{ 
	self.solid = SOLID_NOT;
	self.effects = EF_NODRAW;
	self.movetype = MOVETYPE_NONE;
	self.use = EnvExplosion_Use;

	// float flSpriteScale = (self.iMagnitude - 50) * 0.6;
	// if (flSpriteScale < 10)
	// {
		// flSpriteScale = 10;
	// }

	// m_spriteScale = (int)flSpriteScale;
}