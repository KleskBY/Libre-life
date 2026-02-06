
#define BREAKABLE_MATERIAL_GLASS 				0
#define BREAKABLE_MATERIAL_WOOD 				1
#define BREAKABLE_MATERIAL_METAL 				2
#define BREAKABLE_MATERIAL_FLESH 				3
#define BREAKABLE_MATERIAL_BLOCK 				4
#define BREAKABLE_MATERIAL_CEILING_TILE 		5
#define BREAKABLE_MATERIAL_COMPUTER 			6
#define BREAKABLE_MATERIAL_UNBREAKABLE_GLASS 	7
#define BREAKABLE_MATERIAL_ROCKS				8
#define BREAKABLE_MATERIAL_NONE					9

#define matGlass 				0
#define matWood 				1
#define matMetal 				2
#define matFlesh 				3
#define matCinderBlock 			4
#define matCeilingTile 			5
#define matComputer 			6
#define matUnbreakableGlass 	7
#define matRocks				8
#define matNone					9

#define SF_BREAK_TRIGGER_ONLY	1// may only be broken by trigger
#define	SF_BREAK_TOUCH			2// can be 'crashed through' by running player (plate glass)
#define SF_BREAK_PRESSURE		4// can be broken by a player standing on it
#define SF_BREAK_CROWBAR		256// instant break if hit with crowbar

// Break Model Defines
#define BREAK_TYPEMASK	0x4F
#define BREAK_GLASS		0x01
#define BREAK_METAL		0x02
#define BREAK_FLESH		0x04
#define BREAK_WOOD		0x08
#define BREAK_SMOKE		0x10
#define BREAK_TRANS		0x20
#define BREAK_CONCRETE	0x40
#define BREAK_2			0x80

#define expRandom	0
#define expDirected	1

.float material; //for half-life compability
.string gibmodel;
.float explosion;
.float angle;
vector g_vecAttackDir;

void Breakable_PlaySound(float fvol, float pitch, ... snds)
{
	float rsnd = RandomInt(0, snds - 1);
	sound7(self, CHAN_VOICE, va_arg(rsnd, string), fvol, ATTN_NORM, pitch, 0);
	// sound7(self, CHAN_BODY, va_arg(rsnd, string), FOOTSTEPS_VOLUME, SoundRadius(450));
}

float Breakable_Explodable()
{
	return (self.impulse > 0);
}

void breakable_gib_touch()
{
	if (self.velocity == '0 0 0') self.avelocity = '0 0 0';
};

void Breakable_ShootGib(vector position, vector direction, float type)
{	
	entity gib = spawn();
	gib.owner = self;
	gib.movetype = MOVETYPE_BOUNCE;
	gib.solid = SOLID_NOT;
	makevectors (self.angles);
	gib.velocity = direction;
	gib.avelocity = '300 300 300';
	gib.angles = vectoangles(gib.velocity);
	gib.nextthink = time + random(2, 4);
	gib.think = SUB_Remove;
	gib.touch = SUB_Remove;
	
	if(self.gibmodel) setmodel(gib, self.gibmodel);
	gib.scale = random(0.75, 2);
	setsize(gib, '-1 -1 -1', '1 1 1');
	setorigin(gib, position);
};
	

void Breakable_ShootParts()
{
    vector spawnPos;
    vector dir;
    float maxGibs = 30;
    
    // Calculate an approximate cube size
    float totalVolume = self.size_x * self.size_y * self.size_z;
    float cubesize = pow(totalVolume / maxGibs, 1.0 / 3.0); // Cube root
    // Clamp cubesize to reasonable range
    if(cubesize < 16) cubesize = 16; // Minimum cube 16 units
    if(cubesize > 64) cubesize = 64; // Maximum cube 64 units
    
    for (float x = self.absmin_x; x < self.absmax_x; x = x + cubesize)
    for (float y = self.absmin_y; y < self.absmax_y; y = y + cubesize)
    for (float z = self.absmin_z; z < self.absmax_z; z = z + cubesize)
    {
		if(random() < 0.25) continue;
        spawnPos_x = x + cubesize / 2;
        spawnPos_y = y + cubesize / 2;
        spawnPos_z = z + cubesize / 2;
		
		// Clamp to ensure spawnPos stays within absmin and absmax
        spawnPos_x = bound(self.absmin_x + 2, spawnPos_x, self.absmax_x - 2);
        spawnPos_y = bound(self.absmin_y + 2, spawnPos_y, self.absmax_y - 2);
        spawnPos_z = bound(self.absmin_z + 2, spawnPos_z, self.absmax_z - 2);
        
        dir = randomvec() * random(50, 200);
        if(self.sounds == BREAKABLE_MATERIAL_GLASS) dir = dir * 0.5;

        Breakable_ShootGib(spawnPos, dir, self.sounds);
    }
}



void Breakable_DamageSound( void )
{
	float pitch;
	float fvol;
	string rgpsz[6];
	float i;

//	if (RandomInt(0,1))
//		return;

	if (RandomInt(0,2)) pitch = PITCH_NORM;
	else pitch = 95 + RandomInt(0,34);

	fvol = random(0.75, 1.0);

	if (self.material == matComputer && RandomInt(0,1))
		self.material = matMetal;

	switch (self.material)
	{
	case matComputer:
	case matGlass:
	case matUnbreakableGlass:
		rgpsz[0] = "debris/glass1.wav";
		rgpsz[1] = "debris/glass2.wav";
		rgpsz[2] = "debris/glass3.wav";
		i = 3;
		break;

	case matWood:
		rgpsz[0] = "debris/wood1.wav";
		rgpsz[1] = "debris/wood2.wav";
		rgpsz[2] = "debris/wood3.wav";
		i = 3;
		break;

	case matMetal:
		rgpsz[0] = "debris/metal1.wav";
		rgpsz[1] = "debris/metal3.wav";
		rgpsz[2] = "debris/metal2.wav";
		i = 2;
		break;

	case matFlesh:
		rgpsz[0] = "debris/flesh1.wav";
		rgpsz[1] = "debris/flesh2.wav";
		rgpsz[2] = "debris/flesh3.wav";
		rgpsz[3] = "debris/flesh5.wav";
		rgpsz[4] = "debris/flesh6.wav";
		rgpsz[5] = "debris/flesh7.wav";
		i = 6;
		break;

	case matRocks:
	case matCinderBlock:
		rgpsz[0] = "debris/concrete1.wav";
		rgpsz[1] = "debris/concrete2.wav";
		rgpsz[2] = "debris/concrete3.wav";
		i = 3;
		break;

	case matCeilingTile:
		// UNDONE: no ceiling tile shard sound yet
		i = 0;
		break;
	}

	if (i)
		sound7(self, CHAN_VOICE, rgpsz[RandomInt(0,i-1)], fvol, ATTN_NORM, pitch, 0);
}

void BreakableHit(vector org, vector dir)
{
    if(trace_ent.lastTouch > time) return;   
    trace_ent.lastTouch = time + 0.1;

    te_gunshot(org);
	vector meatdir;
	for(float i = 0; i < 2; i++)
	{
		meatdir = normalize(dir) * random(100, 200) + randomvec() * 100;
		Breakable_ShootGib(org, meatdir, trace_ent.sounds);
	}
}

void Breakable_Die2()
{
	if(self.deadflag == DEAD_DEAD) return;
	self.deadflag = DEAD_DEAD;
	
	vector center = (self.absmin + self.absmax) * 0.5;
	if (self.sounds == BREAKABLE_MATERIAL_WOOD)
	{
		pointparticles(particleeffectnum("dust"), center, randomvec(), TRUE);
	}
	
	Breakable_ShootParts();
	
	if(random() > 0.5) sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	else sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM);
	
	//shake items on top

	entity head = findradius(center, 250);
	while (head)
	{
		if (head != world)
		{
			if(head.flags & FL_ITEM)
			{
				head.movetype = MOVETYPE_TOSS;
				if(head.flags & FL_ONGROUND) head.flags = head.flags - FL_ONGROUND;
			}
		}
		head = head.chain;
	}


	self.think = SUB_Remove;
	self.nextthink = self.ltime + 1.01;
}


void Breakable_Die()
{
	vector vecSpot;// shard origin
	vector vecVelocity;// shard velocity
	float cFlag = 0;
	
	float pitch = 95 + RandomInt(0, 29);
	if (pitch > 97 && pitch < 103) pitch = 100;

	// The more negative pev->health, the louder
	// the sound should be.
	float fvol = random(0.85, 1.0) + (fabs(self.health) / 100.0);
	if (fvol > 1.0) fvol = 1.0;

	switch (self.material)
	{
	case matGlass:
		switch (RandomInt(0,1))
		{
		case 0:	sound7(self, CHAN_VOICE, "debris/bustglass1.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		case 1:	sound7(self, CHAN_VOICE, "debris/bustglass2.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		}
		cFlag = BREAK_GLASS;
		break;
	case matWood:
		switch (RandomInt(0,1))
		{
		case 0:	sound7(self, CHAN_VOICE, "debris/bustcrate1.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		case 1:	sound7(self, CHAN_VOICE, "debris/bustcrate2.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		}
		cFlag = BREAK_WOOD;
		break;
	case matComputer:
	case matMetal:
		switch (RandomInt(0,1))
		{
		case 0:	sound7(self, CHAN_VOICE, "debris/bustmetal1.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		case 1:	sound7(self, CHAN_VOICE, "debris/bustmetal2.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		}
		cFlag = BREAK_METAL;
		break;
	case matFlesh:
		switch (RandomInt(0,1))
		{
		case 0:	sound7(self, CHAN_VOICE, "debris/bustflesh1.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		case 1:	sound7(self, CHAN_VOICE, "debris/bustflesh2.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		}
		cFlag = BREAK_FLESH;
		break;
	case matRocks:
	case matCinderBlock:
		switch (RandomInt(0,1))
		{
		case 0:	sound7(self, CHAN_VOICE, "debris/bustconcrete1.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		case 1:	sound7(self, CHAN_VOICE, "debris/bustconcrete2.wav", fvol, ATTN_NORM, pitch, 0);	
			break;
		}
		cFlag = BREAK_CONCRETE;
		break;
	case matCeilingTile:
		sound7(self, CHAN_VOICE, "debris/bustceiling.wav", fvol, ATTN_NORM, pitch, 0);
		break;
	}
    
		
	if (self.explosion == expDirected)
		vecVelocity = g_vecAttackDir * 200;
	else
	{
		vecVelocity_x = 0;
		vecVelocity_y = 0;
		vecVelocity_z = 0;
	}

	vecSpot = self.origin + (self.mins + self.maxs) * 0.5;
	// Breakable_ShootGib(vecSpot, self.size, vecVelocity, 

	float size = self.size_x;
	if (size < self.size_y) size = self.size_y;
	if (size < self.size_z) size = self.size_z;
	
	Breakable_ShootParts();
	
	//shake items on top
	vector center = (self.absmin + self.absmax) * 0.5;
	entity head = findradius(center, 250);
	while (head)
	{
		if (head != world)
		{
			if(head.flags & FL_ITEM)
			{
				head.movetype = MOVETYPE_TOSS;
				if(head.flags & FL_ONGROUND) head.flags = head.flags - FL_ONGROUND;
			}
		}
		head = head.chain;
	}

	// Don't fire something that could fire myself
	self.targetname = "";
	self.solid = SOLID_NOT;
	SUB_UseTargets(); // Fire targets on break // SUB_UseTargets( NULL, USE_TOGGLE, 0 );

	self.think = SUB_Remove;
	self.nextthink = self.ltime + 0.1;

	// if ( m_iszSpawnObject )
		// CBaseEntity::Create( (char *)STRING(m_iszSpawnObject), VecBModelOrigin(pev), pev->angles, edict() );

	if (Breakable_Explodable())
	{
		// ExplosionCreate( Center(), pev->angles, edict(), ExplosionMagnitude(), TRUE );
	}
}

//on death or use
void Breakable_Use()
{
	if (self.material == matUnbreakableGlass) return;
	self.angles_y = self.angle;
	makevectors(self.angles);
	g_vecAttackDir = v_forward;
	Breakable_Die();
};

void Breakable_Touch()
{
	if(other.classname != "player") return;
	if(self.material == matUnbreakableGlass) return;
	
	if (FBitSet(spawnflags, SF_BREAK_TOUCH))
	{
		float dmg = vlen(other.velocity) * 0.01;
		if(dmg >= self.health)
		{
		
			T_Damage (other, self, self, dmg);
			// do a little damage to player if we broke glass or computer
			// pOther->TakeDamage( pev, pev, flDamage/4, DMG_SLASH );
		}
	}
	
	// can be broken when stood upon
	if (FBitSet(spawnflags, SF_BREAK_PRESSURE) && other.absmin.z >= self.maxs.z - 2 )
	{
		// play creaking sound here.
		Breakable_DamageSound();
		if (self.delay == 0) // !!!BUGBUG - why doesn't zero delay work?
		{
			self.delay = 0.1;
		}
		self.touch = SUB_Null;
		self.think = Breakable_Die;
		self.nextthink = self.ltime + self.delay;
	}
}

void Breakable_Precache()
{
	string pGibName;

	switch (self.material) 
	{
	case matWood:
		pGibName = "models/woodgibs.iqm";
		precache_sound("debris/bustcrate1.wav");
		precache_sound("debris/bustcrate2.wav");
		precache_sound("debris/wood1.wav");
		precache_sound("debris/wood2.wav");
		precache_sound("debris/wood3.wav");
		break;
	case matFlesh:
		pGibName = "models/fleshgibs.iqm";
		precache_sound("debris/bustflesh1.wav");
		precache_sound("debris/bustflesh2.wav");
		precache_sound("debris/flesh1.wav");
		precache_sound("debris/flesh2.wav");
		precache_sound("debris/flesh3.wav");
		precache_sound("debris/flesh5.wav");
		precache_sound("debris/flesh6.wav");
		precache_sound("debris/flesh7.wav");
		break;
	case matComputer:
		precache_sound("buttons/spark5.wav");
		precache_sound("buttons/spark6.wav");
		pGibName = "models/computergibs.iqm";
		precache_sound("debris/bustmetal1.wav");
		precache_sound("debris/bustmetal2.wav");
		precache_sound("debris/glass1.wav");
		precache_sound("debris/glass2.wav");
		precache_sound("debris/glass3.wav");
		break;
	case matUnbreakableGlass:
	case matGlass:
		pGibName = "models/glassgibs.iqm";
		precache_sound("debris/bustglass1.wav");
		precache_sound("debris/bustglass2.wav");
		precache_sound("debris/glass1.wav");
		precache_sound("debris/glass2.wav");
		precache_sound("debris/glass3.wav");
		break;
	case matMetal:
		pGibName = "models/metalplategibs.iqm";
		precache_sound("debris/bustmetal1.wav");
		precache_sound("debris/bustmetal2.wav");
		precache_sound("debris/metal1.wav");
		precache_sound("debris/metal2.wav");
		precache_sound("debris/metal3.wav");
		break;
	case matCinderBlock:
		pGibName = "models/cindergibs.iqm";
		precache_sound("debris/bustconcrete1.wav");
		precache_sound("debris/bustconcrete2.wav");
		precache_sound("debris/concrete1.wav");
		precache_sound("debris/concrete2.wav");
		precache_sound("debris/concrete3.wav");
		break;
	case matRocks:
		pGibName = "models/rockgibs.iqm";
		precache_sound("debris/bustconcrete1.wav");
		precache_sound("debris/bustconcrete2.wav");
		precache_sound("debris/concrete1.wav");
		precache_sound("debris/concrete2.wav");
		precache_sound("debris/concrete3.wav");
		break;
	case matCeilingTile:
		pGibName = "models/ceilinggibs.iqm";
		precache_sound("debris/bustceiling.wav");  
		break;
	}
	// Breakable_MaterialSoundPrecache(self.material);
	if (self.gibmodel)
		pGibName = self.gibmodel;

	// m_idShard = 
		precache_model(pGibName);
	self.gibmodel = pGibName;

	// Precache the spawn item's data
	// if (m_iszSpawnObject)
		// UTIL_PrecacheOther( (char *)STRING( m_iszSpawnObject ) );
};

void() func_breakable =
{
	Breakable_Precache();
	if(!self.sounds && self.material) self.sounds = self.material;

	if (self.sounds == BREAKABLE_MATERIAL_GLASS)
	{
		precache_sound("func/glass1.wav");
		precache_sound("func/glass2.wav");
		self.noise1 = "func/glass1.wav";
		self.noise2 = "func/glass2.wav";
	}
	else if (self.sounds == BREAKABLE_MATERIAL_WOOD)
	{
		precache_sound("func/wood1.wav");
		precache_sound("func/wood2.wav");
		self.noise1 = "func/wood1.wav";
		self.noise2 = "func/wood2.wav";
	}
	else if (self.sounds == BREAKABLE_MATERIAL_METAL)
	{
		precache_sound("func/metal1.wav");
		precache_sound("func/metal2.wav");
		self.noise1 = "func/metal1.wav";
		self.noise2 = "func/metal2.wav";
	}
	else 
	{
		precache_sound ("misc/null.wav");
		self.noise1 = "misc/null.wav";
		self.noise2 = "misc/null.wav";
	}
	
	if (FBitSet(spawnflags, SF_BREAK_TRIGGER_ONLY))
		self.takedamage	= DAMAGE_NO;
	else
		self.takedamage	= DAMAGE_YES;
	
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.angle = self.angles_y;
	self.max_health = self.health;
	
	
	setorigin(self, self.origin);
	setmodel(self, self.model);
	
	if (self.health)
	{
		self.takedamage = DAMAGE_AIM;
		self.th_die = Breakable_Use;
	}
	
	

	self.use = Breakable_Use;
	if (!FBitSet(spawnflags, SF_BREAK_TRIGGER_ONLY))
		self.touch = Breakable_Touch;
}