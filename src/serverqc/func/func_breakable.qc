
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

#define MAT_GLASS 				0
#define MAT_WOOD 				1
#define MAT_METAL 				2
#define MAT_FLESH 				3
#define MAT_CINDERBLOCK 			4
#define MAT_CEILINGTILE 			5
#define MAT_COMPUTER 			6
#define MAT_UNBREAKABLE_GLASS 	7
#define MAT_ROCKS				8
#define MAT_NONE					9

#define SF_BREAK_TRIGGER_ONLY	1
#define	SF_BREAK_TOUCH			2
#define SF_BREAK_PRESSURE		4
#define SF_BREAK_CROWBAR		256

#define BREAK_TYPEMASK	0x4F
#define BREAK_GLASS		0x01
#define BREAK_METAL		0x02
#define BREAK_FLESH		0x04
#define BREAK_WOOD		0x08
#define BREAK_SMOKE		0x10
#define BREAK_TRANS		0x20
#define BREAK_CONCRETE	0x40
#define BREAK_2			0x80

#define EXP_RANDOM	0
#define EXP_DIRECTED	1

.float material;
.string gibmodel;
.float gibmodelcount;
.float explosion;
.float angle;
.float iMagnitude;
.float explodemagnitude;
vector g_vecAttackDir;

#define BREAKABLE_MATERIAL_MAX      10
#define BREAKABLE_SCAN_MAX          64
#define BREAKABLE_CUSTOM_CACHE_MAX  16

// Per-material registry (indexed by MAT_GLASS..MAT_ROCKS).
string  breakable_gib_base[BREAKABLE_MATERIAL_MAX];     // strzoned base name
float   breakable_gib_count[BREAKABLE_MATERIAL_MAX];    // numbered files found
float   breakable_gib_scanned[BREAKABLE_MATERIAL_MAX];  // 1 = scan attempted (count may be 0)
float   breakable_sounds_done[BREAKABLE_MATERIAL_MAX];  // 1 = sounds precached

// Per-path cache for map-specified self.gibmodel overrides.
string  breakable_custom_base[BREAKABLE_CUSTOM_CACHE_MAX];   // strzoned base name
float   breakable_custom_count[BREAKABLE_CUSTOM_CACHE_MAX];
float   breakable_custom_used;

// Strip trailing ".iqm" / ".mdl" if present; return tempstring.
string Breakable_StripExt(string path)
{
	float n = strlen(path);
	if (n < 4) return path;
	string tail = substring(path, n - 4, 4);
	if (tail == ".iqm" || tail == ".mdl") return substring(path, 0, n - 4);
	return path;
}

// Build a "<base>NN.iqm" path with 2-digit zero padding for index < 10.
string Breakable_GibFilename(string base, float i)
{
	if (i < 10) return strcat(base, "0", ftos(i), ".iqm");
	return strcat(base, ftos(i), ".iqm");
}

float Breakable_ScanGibSet(string base)
{
	float i;
	for (i = 1; i <= BREAKABLE_SCAN_MAX; i++)
	{
		string filename = Breakable_GibFilename(base, i);
		float fh = fopen(filename, FILE_READ);
		if (fh < 0) break;
		fclose(fh);
		precache_model(filename); //CRASH
	}
	return i - 1;
}

string Breakable_MaterialGibBase(float mat)
{
	switch (mat)
	{
		case MAT_WOOD:             return "models/woodgibs";
		case MAT_FLESH:            return "models/fleshgibs";
		case MAT_COMPUTER:         return "models/computergibs";
		case MAT_UNBREAKABLE_GLASS:
		case MAT_GLASS:            return "models/glassgibs";
		case MAT_METAL:            return "models/metalplategibs";
		case MAT_CINDERBLOCK:      return "models/cindergibs";
		case MAT_ROCKS:            return "models/rockgibs";
		case MAT_CEILINGTILE:      return "models/ceilinggibs";
	}
	return "";
}

void Breakable_PrecacheMaterialSounds(float mat)
{
	switch (mat)
	{
		case MAT_WOOD:
			precache_sound("debris/bustcrate1.wav");
			precache_sound("debris/bustcrate2.wav");
			precache_sound("debris/wood1.wav");
			precache_sound("debris/wood2.wav");
			precache_sound("debris/wood3.wav");
			break;
		case MAT_FLESH:
			precache_sound("debris/bustflesh1.wav");
			precache_sound("debris/bustflesh2.wav");
			precache_sound("debris/flesh1.wav");
			precache_sound("debris/flesh2.wav");
			precache_sound("debris/flesh3.wav");
			precache_sound("debris/flesh5.wav");
			precache_sound("debris/flesh6.wav");
			precache_sound("debris/flesh7.wav");
			break;
		case MAT_COMPUTER:
			precache_sound("buttons/spark5.wav");
			precache_sound("buttons/spark6.wav");
			precache_sound("debris/bustmetal1.wav");
			precache_sound("debris/bustmetal2.wav");
			precache_sound("debris/glass1.wav");
			precache_sound("debris/glass2.wav");
			precache_sound("debris/glass3.wav");
			break;
		case MAT_UNBREAKABLE_GLASS:
		case MAT_GLASS:
			precache_sound("debris/bustglass1.wav");
			precache_sound("debris/bustglass2.wav");
			precache_sound("debris/glass1.wav");
			precache_sound("debris/glass2.wav");
			precache_sound("debris/glass3.wav");
			break;
		case MAT_METAL:
			precache_sound("debris/bustmetal1.wav");
			precache_sound("debris/bustmetal2.wav");
			precache_sound("debris/metal1.wav");
			precache_sound("debris/metal2.wav");
			precache_sound("debris/metal3.wav");
			break;
		case MAT_CINDERBLOCK:
		case MAT_ROCKS:
			precache_sound("debris/bustconcrete1.wav");
			precache_sound("debris/bustconcrete2.wav");
			precache_sound("debris/concrete1.wav");
			precache_sound("debris/concrete2.wav");
			precache_sound("debris/concrete3.wav");
			break;
		case MAT_CEILINGTILE:
			precache_sound("debris/bustceiling.wav");
			break;
	}
}

void Breakable_EnsureMaterialReady(float mat)
{
	if (mat < 0 || mat >= BREAKABLE_MATERIAL_MAX) return;

	if (!breakable_sounds_done[mat])
	{
		Breakable_PrecacheMaterialSounds(mat);
		breakable_sounds_done[mat] = 1;
	}

	if (breakable_gib_scanned[mat]) return;
	breakable_gib_scanned[mat] = 1;

	string base = Breakable_MaterialGibBase(mat);
	if (base == "") return;

	float c = Breakable_ScanGibSet(base);
	if (c > 0)
	{
		breakable_gib_base[mat]  = strzone(base);
		breakable_gib_count[mat] = c;
		print("Breakable: material ", ftos(mat), " -> ", base, " (", ftos(c), " gibs)\n");
	}
	else
	{
		print("Breakable: material ", ftos(mat), " -> ", base, " NOT FOUND\n");
	}
}

float Breakable_LookupCustomGib(string base, __inout string out_base_zoned)
{
	for (float i = 0; i < breakable_custom_used; i++)
	{
		if (breakable_custom_base[i] == base)
		{
			out_base_zoned = breakable_custom_base[i];
			return breakable_custom_count[i];
		}
	}
	if (breakable_custom_used >= BREAKABLE_CUSTOM_CACHE_MAX) return 0;
	float c = Breakable_ScanGibSet(base);
	if (c <= 0) return 0;
	string zoned = strzone(base);
	breakable_custom_base[breakable_custom_used]  = zoned;
	breakable_custom_count[breakable_custom_used] = c;
	breakable_custom_used++;
	out_base_zoned = zoned;
	return c;
}

float Breakable_ResolveGibs(__inout string out_base, __inout float out_count)
{
	if (self.gibmodelcount > 0 && self.gibmodel != "")
	{
		out_base = self.gibmodel;
		out_count = self.gibmodelcount;
		return TRUE;
	}
	if (self.material >= 0 && self.material < BREAKABLE_MATERIAL_MAX &&
	    breakable_gib_count[self.material] > 0)
	{
		out_base = breakable_gib_base[self.material];
		out_count = breakable_gib_count[self.material];
		return TRUE;
	}
	return FALSE;
}

void Breakable_PlaySound(float fvol, float pitch, ... snds)
{
	float rsnd = Math_RandomInt(0, snds - 1);
	Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, va_arg(rsnd, string));
	// sound7(self, CHAN_BODY, va_arg(rsnd, string), FOOTSTEPS_VOLUME, Sound_Radius(450));
}

float Breakable_Explodable()
{
	return (self.impulse > 0);
}

void BreakableGib_Touch()
{
	if (self.velocity == '0 0 0') self.avelocity = '0 0 0';
};

#define BREAKABLE_MAX_LIVE_GIBS   80    // global budget
#define BREAKABLE_MAX_BREAK_GIBS  30    // per single break
float g_breakableLiveGibs;

void Breakable_GibRemove()
{
	g_breakableLiveGibs = g_breakableLiveGibs - 1;
	if (g_breakableLiveGibs < 0) g_breakableLiveGibs = 0;
	remove(self);
}

void Breakable_ShootGib(vector position, vector direction, float type)
{
	entity gib = spawn();
	gib.classname = "breakable_gib";
	gib.owner = self;
	gib.movetype = MOVETYPE_BOUNCE;
	gib.solid = SOLID_NOT;
	makevectors (self.angles);
	gib.velocity = direction;
	gib.avelocity = '300 300 300';
	gib.angles = vectoangles(gib.velocity);
	gib.nextthink = time + random(2, 4);
	gib.think = Breakable_GibRemove;
	gib.touch = Breakable_GibRemove;
	g_breakableLiveGibs = g_breakableLiveGibs + 1;
	
	string gib_base = "";
	float  gib_count = 0;
	if (Breakable_ResolveGibs(gib_base, gib_count))
	{
		setmodel(gib, Breakable_GibFilename(gib_base, Math_RandomInt(1, gib_count)));
	}
	gib.scale = random(0.5, 1.5);
	setsize(gib, '-1 -1 -1', '1 1 1');
	setorigin(gib, position);
};
	

void Breakable_ShootParts()
{
    vector spawnPos;
    vector dir;

    float totalVolume = self.size_x * self.size_y * self.size_z;
    float want = ceil(totalVolume / (24 * 24 * 24));    // ~1 gib per 24u cube
    if (want < 4)  want = 4;
    if (want > BREAKABLE_MAX_BREAK_GIBS) want = BREAKABLE_MAX_BREAK_GIBS;

    float room = BREAKABLE_MAX_LIVE_GIBS - g_breakableLiveGibs;
    if (room <= 0) return;
    if (want > room) want = room;

    vector lo = self.absmin + '2 2 2';
    vector hi = self.absmax - '2 2 2';
    if (hi_x < lo_x) hi_x = lo_x;
    if (hi_y < lo_y) hi_y = lo_y;
    if (hi_z < lo_z) hi_z = lo_z;

    float i;
    for (i = 0; i < want; i = i + 1)
    {
        spawnPos_x = lo_x + random() * (hi_x - lo_x);
        spawnPos_y = lo_y + random() * (hi_y - lo_y);
        spawnPos_z = lo_z + random() * (hi_z - lo_z);

        dir = randomvec() * random(50, 200);
        if (self.sounds == BREAKABLE_MATERIAL_GLASS) dir = dir * 0.5;

        Breakable_ShootGib(spawnPos, dir, self.sounds);
    }
}


void Breakable_DamageSound( void )
{
	float pitch;

	if (Math_RandomInt(0,2)) pitch = PITCH_NORM;
	else pitch = 95 + Math_RandomInt(0,34);

	float fvol = random(0.75, 1.0);

	if (self.material == MAT_COMPUTER && Math_RandomInt(0,1))
		self.material = MAT_METAL;

	switch (self.material)
	{
	case MAT_COMPUTER:
	case MAT_GLASS:
	case MAT_UNBREAKABLE_GLASS:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch,
			"debris/glass1.wav", "debris/glass2.wav", "debris/glass3.wav");
		break;

	case MAT_WOOD:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch,
			"debris/wood1.wav", "debris/wood2.wav", "debris/wood3.wav");
		break;

	case MAT_METAL:
		// Two entries on purpose: HL lists metal2 as well but caps the roll at
		// i=2, so metal2 never plays there either. Kept for parity.
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch,
			"debris/metal1.wav", "debris/metal3.wav");
		break;

	case MAT_FLESH:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch,
			"debris/flesh1.wav", "debris/flesh2.wav", "debris/flesh3.wav",
			"debris/flesh5.wav", "debris/flesh6.wav", "debris/flesh7.wav");
		break;

	case MAT_ROCKS:
	case MAT_CINDERBLOCK:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch,
			"debris/concrete1.wav", "debris/concrete2.wav", "debris/concrete3.wav");
		break;

	case MAT_CEILINGTILE:
		break;
	}
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
	
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100, self.noise1, self.noise2);
	
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

	GlobalState_MarkEntityDead(self);
	Spent_Mark(self);

	float pitch = 95 + Math_RandomInt(0, 29);
	if (pitch > 97 && pitch < 103) pitch = 100;

	float fvol = random(0.85, 1.0) + (fabs(self.health) / 100.0);
	if (fvol > 1.0) fvol = 1.0;

	switch (self.material)
	{
	case MAT_GLASS:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, "debris/bustglass1.wav", "debris/bustglass2.wav");
		cFlag = BREAK_GLASS;
		break;
	case MAT_WOOD:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, "debris/bustcrate1.wav", "debris/bustcrate2.wav");
		cFlag = BREAK_WOOD;
		break;
	case MAT_COMPUTER:
	case MAT_METAL:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, "debris/bustmetal1.wav", "debris/bustmetal2.wav");
		cFlag = BREAK_METAL;
		break;
	case MAT_FLESH:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, "debris/bustflesh1.wav", "debris/bustflesh2.wav");
		cFlag = BREAK_FLESH;
		break;
	case MAT_ROCKS:
	case MAT_CINDERBLOCK:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, "debris/bustconcrete1.wav", "debris/bustconcrete2.wav");
		cFlag = BREAK_CONCRETE;
		break;
	case MAT_CEILINGTILE:
		Sound_Play(self, CHAN_VOICE, fvol, ATTN_NORM, pitch, "debris/bustceiling.wav");
		break;
	}
    
		
	if (self.explosion == EXP_DIRECTED)
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

	self.targetname = "";
	self.solid = SOLID_NOT;
	SUB_UseTargets(); // Fire targets on break // SUB_UseTargets( NULL, USE_TOGGLE, 0 );

	self.think = SUB_Remove;
	self.nextthink = self.ltime + 0.1;

	if (Breakable_Explodable())
	{
		Combat_ExplosionCreate(center, self.angles, self, self.impulse, TRUE);
	}
}

float Breakable_IsBreakable()
{
	return (self.material != MAT_UNBREAKABLE_GLASS);
}

//on death or use
void Breakable_Use()
{
	if (!Breakable_IsBreakable()) return;
	self.angles_y = self.angle;
	makevectors(self.angles);
	g_vecAttackDir = v_forward;
	Breakable_Die();
};

void Breakable_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Breakable_IsBreakable()) return;
	self.angles_y = self.angle;
	makevectors(self.angles);
	g_vecAttackDir = v_forward;
	Breakable_Die();
}

void Breakable_TraceAttack(entity attacker, float flDamage, vector dir, float bitsDamageType)
{
	vector org = trace_endpos - dir * 4;
	if (Math_RandomInt(0,1))
	{
		switch(self.material)
		{
			case MAT_COMPUTER:
			{
				te_spark(trace_endpos, trace_plane_normal, 4);
				float flVolume = random( 0.7 , 1.0 );
				Sound_Play(self, CHAN_VOICE, flVolume, ATTN_NORM, 100, "buttons/spark5.wav", "buttons/spark6.wav");
			}
			break;
			
			case MAT_UNBREAKABLE_GLASS:
			break;
		}
	}
	AddMultiDamage(self, flDamage, bitsDamageType);
}


float Breakable_TakeDamage(entity inflictor, entity attacker, float dmg, float bitsDamageType)
{
	vector	vecTemp;

	if (attacker == inflictor)	
	{
		vecTemp = inflictor.origin - (self.absmin + (self.size * 0.5));
		
		if ((attacker.flags & FL_CLIENT) && (self.spawnflags & SF_BREAK_CROWBAR) && (bitsDamageType & DMG_CLUB))
			dmg = self.health;
	}
	else
	{
		vecTemp = inflictor.origin - (self.absmin + (self.size * 0.5));
	}
	
	if (!Breakable_IsBreakable())
		return 0;

	if (bitsDamageType & DMG_CLUB)
		dmg *= 2;

	if (bitsDamageType & DMG_POISON)
		dmg *= 0.1;

	g_vecAttackDir = normalize(vecTemp);
		
	self.health -= dmg;
	if (self.health <= 0)
	{
		Breakable_Die();
		self.takedamage = DAMAGE_NO;
		self.deadflag = DEAD_DEAD;
		return 0;
	}


	Breakable_DamageSound();

	return 1;
}
void Breakable_Touch()
{
	if(other.classname != "player") return;
	if(self.material == MAT_UNBREAKABLE_GLASS) return;
	
	if (FBitSet(spawnflags, SF_BREAK_TOUCH))
	{
		float dmg = vlen(other.velocity) * 0.01;
		if(dmg >= self.health)
		{
			self.touch = SUB_Null;
			Breakable_TakeDamage(other, other, dmg, DMG_CRUSH);
			//T_Damage(other, self, self, dmg / 4);
		}
	}
	
	if (FBitSet(spawnflags, SF_BREAK_PRESSURE) && other.absmin.z >= self.maxs.z - 2 )
	{
		Breakable_DamageSound();
		if (self.delay == 0)
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
	Breakable_EnsureMaterialReady(self.material);

	if (self.gibmodel == "") return;

	if (StringContains(self.gibmodel, "gib"))
	{
		string base = Breakable_StripExt(self.gibmodel);
		string zoned_base = "";
		float count = Breakable_LookupCustomGib(base, zoned_base);
		if (count > 0)
		{
			self.gibmodel = zoned_base;
			self.gibmodelcount = count;
		}
		else
		{
			self.gibmodel = "";
			self.gibmodelcount = 0;
		}
	}
	else
	{
		self.gibmodel = strzone(strireplace(".mdl", ".iqm", self.gibmodel));
		self.gibmodelcount = 0;
	}
};

void func_breakable()
{
	Spent_Capture(self);
	if (Spent_IsSpent(self)) { remove(self); return; }

	Breakable_Precache();
	if(!self.sounds && self.material) self.sounds = self.material;

	if (self.sounds == BREAKABLE_MATERIAL_GLASS)
	{
		precache_sound("debris/glass1.wav");
		precache_sound("debris/glass2.wav");
		self.noise1 = "debris/glass1.wav";
		self.noise2 = "debris/glass2.wav";
	}
	else if (self.sounds == BREAKABLE_MATERIAL_WOOD)
	{
		precache_sound("debris/wood1.wav");
		precache_sound("debris/wood2.wav");
		self.noise1 = "debris/wood1.wav";
		self.noise2 = "debris/wood2.wav";
	}
	else if (self.sounds == BREAKABLE_MATERIAL_METAL)
	{
		precache_sound("debris/metal1.wav");
		precache_sound("debris/metal2.wav");
		self.noise1 = "debris/metal1.wav";
		self.noise2 = "debris/metal2.wav";
	}
	else 
	{
		precache_sound ("common/null.wav");
		self.noise1 = "common/null.wav";
		self.noise2 = "common/null.wav";
	}
	
	if (FBitSet(spawnflags, SF_BREAK_TRIGGER_ONLY))
		self.takedamage	= DAMAGE_NO;
	else
		self.takedamage	= DAMAGE_YES;
	
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.angle = self.angles_y;
	self.max_health = self.health;
	self.impulse = self.explodemagnitude;
	self.traceAttack = Breakable_TraceAttack;
	self.takeDmgFn = Breakable_TakeDamage;
	
	setorigin(self, self.origin);
	setmodel(self, self.model);
	Render_Apply(self);
	Brush_ApplyContents(self);

	if (GlobalState_RemoveIfDead(self))
		return;
	
	if (self.health)
	{
		// self.takedamage = DAMAGE_AIM;
		self.th_die = Breakable_Use;
	}
	
	self.use = Breakable_Use;
	self.usehl = Breakable_UseHL;
	if (!FBitSet(spawnflags, SF_BREAK_TRIGGER_ONLY))
		self.touch = Breakable_Touch;
}
