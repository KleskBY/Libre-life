
#define GIB_HEALTH_VALUE		-16
#define GIB_HUMAN_RANDOM_COUNT	10
#define GIB_ALIEN_RANDOM_COUNT	4
#define GIB_BLOOD_RED			73
#define GIB_BLOOD_ALIEN			195

.float monster_bloodColor;
.string monster_gibHead;	// head model, thrown when a monster/corpse separates
.string monster_gibPiece;	// chunk model; empty = random progs/gib1-3.mdl
.float gib_blood_color;
.float gib_blood_decals;
.float gib_lifetime;
.float blood_anim_count;
.float blood_anim_rate;
.float blood_die;

float Gib_ShouldGib(float gibMode = 0)
{
	if (gibMode == 2) return TRUE; 	// GIB_ALWAYS
	if (gibMode == 1) return FALSE; // GIB_NEVER
	return (self.health < GIB_HEALTH_VALUE);
}

float Blood_ColorFor(entity victim);

float Gib_IsAlien()
{
	if (self.classname == "monster_bigmomma") return TRUE;   // own gib set
	return Blood_ColorFor(self) == GIB_BLOOD_ALIEN;
}

float Blood_ColorFor(entity victim)
{
	if (victim == world) return 0;
	if (victim.monster_bloodColor < 0) return 0;   // DONT_BLEED
	if (victim.flags & FL_CLIENT) return GIB_BLOOD_RED;
	if (victim.monster_bloodColor) return victim.monster_bloodColor;
	if (victim.classname == "func_guntarget") return 0;
	if (victim.classname == "monster_miniturret") return 0;
	if (victim.flags & FL_MONSTER) return GIB_BLOOD_RED;
	return 0;
}

float Blood_ImpactCount(float damage)
{
	float count = ceil(damage * 0.5);
	if (count < 4) count = 4;
	if (count > 12) count = 12;
	return count;
}

void Blood_SpriteTint(entity e, float color)
{
	if (color == GIB_BLOOD_ALIEN)
		e.colormod = '0.905 0.89 0.34';	// yellow-green
	else
		e.colormod = '1 0 0';	// red
}

void Blood_BurstThink()
{
	self.frame = self.frame + 1;
	if (self.frame >= self.blood_anim_count)
	{
		remove(self);
		return;
	}
	self.nextthink = time + self.blood_anim_rate;
}

void Blood_DropletThink()
{
	if (time >= self.blood_die || (self.flags & FL_ONGROUND))
	{
		remove(self);
		return;
	}
	self.frame = self.frame + 1;
	if (self.frame >= self.blood_anim_count)
		self.frame = 0;
	self.nextthink = time + self.blood_anim_rate;
}

void Blood_SpawnBurst(vector org, float color, float damage)
{
	entity e = spawn();
	e.classname = "blood_burst";
	e.movetype = MOVETYPE_NONE;
	e.solid = SOLID_NOT;
	e.effects = EF_NOSHADOW | EF_FULLBRIGHT | EF_ADDITIVE;	// ADDITIVE: FTE .spr transparency
	setmodel(e, "sprites/bloodspray.spr");
	setorigin(e, org);
	setsize(e, '0 0 0', '0 0 0');
	e.scale = bound(0.5, damage * 0.05, 1.6) * random(0.85, 1.25);
	e.frame = 0;
	e.alpha = random(0.65, 0.85);
	e.blood_anim_count = 8;
	e.blood_anim_rate = random(0.035, 0.05);
	Blood_SpriteTint(e, color);
	e.colormod = e.colormod * random(0.75, 1.0);   // brightness jitter
	e.think = Blood_BurstThink;
	e.nextthink = time + e.blood_anim_rate;
}

void Blood_SpawnDroplet(vector org, vector vel, float color)
{
	entity e = spawn();
	e.classname = "blood_drop";
	e.movetype = MOVETYPE_TOSS;
	e.solid = SOLID_NOT;
	e.effects = EF_NOSHADOW | EF_FULLBRIGHT | EF_ADDITIVE;	// ADDITIVE: FTE .spr transparency
	setmodel(e, "sprites/blood.spr");
	setorigin(e, org);
	setsize(e, '0 0 0', '0 0 0');
	e.velocity = vel;
	e.scale = 0.6 * random(0.7, 1.3);
	e.frame = 0;
	e.blood_anim_count = 8;
	e.blood_anim_rate = random(0.04, 0.06);
	e.blood_die = time + random(1.0, 1.5);
	Blood_SpriteTint(e, color);
	e.colormod = e.colormod * random(0.75, 1.0);
	e.think = Blood_DropletThink;
	e.nextthink = time + e.blood_anim_rate;
}

void Blood_SpawnSprites(vector org, vector spray, float color, float damage)
{
	if (!color) return;

	Blood_SpawnBurst(org, color, damage);

	float count = bound(3, ceil(damage * 0.15), 8);
	for (float i = 0; i < count; i = i + 1)
	{
		vector v = spray * random(40, 90);
		v_x = v_x + random(-50, 50);
		v_y = v_y + random(-50, 50);
		v_z = v_z + random(60, 140);
		Blood_SpawnDroplet(org, v, color);
	}
}

void Blood_SpawnImpact(vector org, vector dir, float color, float damage)
{
	if (!color) return;

	vector spray = dir;
	if (vlen(spray) <= 0)
		spray = randomvec() + '0 0 0.5';
	spray = normalize(spray);

	float count = Blood_ImpactCount(damage);
	particle(org, spray * 8, color, count);
	particle(org, spray * 4 + randomvec() * 8, color, ceil(count * 0.5));

	if (color == GIB_BLOOD_RED)
		te_blood(org, spray * 16, count);

	Blood_SpawnSprites(org, spray, color, damage);
}

float Blood_UsesTraceBleed(float dmgType)
{
	return (dmgType & (DMG_CRUSH | DMG_BULLET | DMG_SLASH | DMG_BLAST | DMG_CLUB | DMG_MORTAR));
}

void Blood_TraceBleed(entity victim, vector hitpos, vector dir, float damage, float dmgType)
{
	float color = Blood_ColorFor(victim);
	if (!color) return;
	if (damage <= 0) return;
	if (!Blood_UsesTraceBleed(dmgType)) return;

	float flNoise;
	float cCount;
	if (damage < 10)
	{
		flNoise = 0.1;
		cCount = 1;
	}
	else if (damage < 25)
	{
		flNoise = 0.2;
		cCount = 2;
	}
	else
	{
		flNoise = 0.3;
		cCount = 4;
	}

	vector traceDir = dir;
	if (vlen(traceDir) <= 0)
		traceDir = randomvec() + '0 0 0.5';
	traceDir = normalize(traceDir);

	for (float i = 0; i < cCount; i = i + 1)
	{
		vector bleedDir = traceDir;
		bleedDir_x = bleedDir_x + random(-flNoise, flNoise);
		bleedDir_y = bleedDir_y + random(-flNoise, flNoise);
		bleedDir_z = bleedDir_z + random(-flNoise, flNoise);
		bleedDir = normalize(bleedDir);

		traceline(hitpos, hitpos + bleedDir * 172, TRUE, victim);
		if (trace_fraction == 1)
			continue;
		if (trace_dphitq3surfaceflags & (Q3SURFACEFLAG_SKY | Q3SURFACEFLAG_NOMARKS))
			continue;

		vector burstOrg = trace_endpos + trace_plane_normal * 2;
		vector burstDir = trace_plane_normal * 6 - bleedDir * 6;
		particle(burstOrg, burstDir, color, 6 + cCount * 2);
		if (color == GIB_BLOOD_RED && damage >= 12)
			te_blood(burstOrg, burstDir * 2, 4 + cCount);
	}
}

void SpawnBlood(vector org, vector vel, float damage)
{
	Blood_SpawnImpact(org, vel, GIB_BLOOD_RED, damage);
}

void ShootBlood(vector position, vector direction)
{
	Blood_SpawnImpact(position, direction, GIB_BLOOD_RED, 10);
}

float Gib_IsHuman()
{
	if (self.flags & FL_CLIENT) return TRUE;
	if (self.classname == "monster_zombie") return TRUE;
	if (self.classname == "monster_scientist") return TRUE;
	if (self.classname == "monster_scientist_dead") return TRUE;
	if (self.classname == "monster_barney") return TRUE;
	if (self.classname == "monster_human_grunt") return TRUE;
	if (self.classname == "monster_generic") return TRUE;
	return FALSE;
}

string Gib_HumanHeadModel()
{
	return "models/hgibs01.iqm";
}

string Gib_HumanPieceModel(float idx)
{
	switch (idx)
	{
	case 2: return "models/hgibs02.iqm";
	case 3: return "models/hgibs03.iqm";
	case 4: return "models/hgibs04.iqm";
	case 5: return "models/hgibs05.iqm";
	case 6: return "models/hgibs06.iqm";
	case 7: return "models/hgibs07.iqm";
	case 8: return "models/hgibs08.iqm";
	case 9: return "models/hgibs09.iqm";
	case 10: return "models/hgibs10.iqm";
	default: return "models/hgibs11.iqm";
	}
}

string Gib_AlienPieceModel(float idx)
{
	switch (idx)
	{
	case 1: return "models/agibs01.iqm";
	case 2: return "models/agibs02.iqm";
	case 3: return "models/agibs03.iqm";
	default: return "models/agibs04.iqm";
	}
}

string Gib_BigMommaPieceModel(float idx)
{
	switch (idx)
	{
	case 1: return "models/big_momgibs01.iqm";
	case 2: return "models/big_momgibs02.iqm";
	default: return "models/big_momgibs03.iqm";
	}
}

vector Gib_LimitVelocity(vector vel)
{
	float len = vlen(vel);
	if (len > 300)
		vel = normalize(vel) * 300;
	return vel;
}

float Gib_DamageVelocityScale(float health)
{
	if (health > -50) return 0.7;
	if (health > -200) return 2;
	return 4;
}

vector Gib_AttackDir()
{
	if (damage_attacker && damage_attacker != world && damage_attacker != self)
		return normalize(self.origin - damage_attacker.origin);
	return normalize(randomvec() + '0 0 0.75');
}

vector Gib_RandomPointInBounds()
{
	vector org;
	if (self.size_x || self.size_y || self.size_z)
	{
		org_x = self.absmin_x + self.size_x * random();
		org_y = self.absmin_y + self.size_y * random();
		org_z = self.absmin_z + self.size_z * random() + 1;
		return org;
	}
	return self.origin + randomvec() * 8;
}

vector Gib_RandomVelocity(float health)
{
	vector vel = Gib_AttackDir() * random(50, 100);
	vel_x = vel_x + random(-100, 100);
	vel_y = vel_y + random(-100, 100);
	vel_z = vel_z + random(150, 300);
	vel = vel * Gib_DamageVelocityScale(health);
	return Gib_LimitVelocity(vel);
}

vector Gib_HeadVelocity(float health)
{
	vector vel = [random(-100, 100), random(-100, 100), random(200, 300)];
	vel = vel * Gib_DamageVelocityScale(health);
	return Gib_LimitVelocity(vel);
}


void Gib_WaitTillLand()
{
	if ((self.flags & FL_ONGROUND) || vlen(self.velocity) < 20)
	{
		self.velocity = '0 0 0';
		self.avelocity = '0 0 0';
		self.think = SUB_Remove;
		self.nextthink = time + self.gib_lifetime;
		return;
	}

	self.think = Gib_WaitTillLand;
	self.nextthink = time + 0.5;
}

void Gib_BounceTouch()
{
	if (other == self.owner) return;

	if (self.flags & FL_ONGROUND)
	{
		self.velocity = self.velocity * 0.9;
		self.angles_x = 0;
		self.angles_z = 0;
		self.avelocity_x = 0;
		self.avelocity_z = 0;
		return;
	}

	if (self.gib_blood_decals > 0 && self.gib_blood_color)
	{
		Blood_SpawnImpact(self.origin + '0 0 8', self.velocity * -1, self.gib_blood_color, 6);
		self.gib_blood_decals = self.gib_blood_decals - 1;
	}
}

entity Gib_SpawnPiece(string modelname, vector org, vector vel, float bloodColor)
{
	entity gib = spawn();
	gib.classname = "gib";
	gib.owner = self;
	gib.movetype = MOVETYPE_BOUNCE;
	gib.solid = SOLID_TRIGGER;
	gib.takedamage = DAMAGE_NO;
	gib.effects = EF_NOSHADOW;
	gib.modelflags = MF_ZOMGIB;
	gib.scale = 1;
	gib.frame = 0;
	gib.gib_blood_color = bloodColor;
	gib.gib_blood_decals = 5;
	gib.gib_lifetime = 25;
	gib.velocity = vel;
	gib.avelocity = [random(100, 200), random(100, 300), random(100, 300)];
	gib.touch = Gib_BounceTouch;
	gib.think = Gib_WaitTillLand;
	gib.nextthink = time + 4;

	setmodel(gib, modelname);
	// EF_ADDITIVE for sprite transparency (DP applies it automatically).
	if (StringContains(modelname, ".spr"))
		gib.effects = gib.effects | EF_ADDITIVE;
	setsize(gib, '0 0 0', '0 0 0');
	setorigin(gib, org);
	return gib;
}

void Gib_SpawnHead()
{
	vector org = self.origin + self.view_ofs;
	if (org == self.origin)
		org = self.origin + '0 0 24';
	Gib_SpawnPiece(Gib_HumanHeadModel(), org, Gib_HeadVelocity(self.health), GIB_BLOOD_RED);
}

void Gib_SpawnRandomHumanGibs(float count)
{
	for (float i = 0; i < count; i = i + 1)
	{
		float idx = Math_RandomInt(2, GIB_HUMAN_RANDOM_COUNT + 1);
		Gib_SpawnPiece(Gib_HumanPieceModel(idx), Gib_RandomPointInBounds(), Gib_RandomVelocity(self.health), GIB_BLOOD_RED);
	}
}

void Gib_SpawnRandomAlienGibs(float count)
{
	float bloodColor = GIB_BLOOD_ALIEN;
	for (float i = 0; i < count; i = i + 1)
	{
		float idx = Math_RandomInt(1, GIB_ALIEN_RANDOM_COUNT);
		if (self.classname == "monster_bigmomma")
			Gib_SpawnPiece(Gib_BigMommaPieceModel(Math_RandomInt(1, 3)), Gib_RandomPointInBounds(), Gib_RandomVelocity(self.health), bloodColor);
		else
			Gib_SpawnPiece(Gib_AlienPieceModel(idx), Gib_RandomPointInBounds(), Gib_RandomVelocity(self.health), bloodColor);
	}
}

string Gib_Q1PieceModel(float idx)
{
	switch (idx)
	{
	case 1:  return "progs/gib1.mdl";
	case 2:  return "progs/gib2.mdl";
	default: return "progs/gib3.mdl";
	}
}

void Gib_SpawnQ1Gibs(float count)
{
	if (self.monster_gibHead != "")
		Gib_SpawnPiece(self.monster_gibHead, self.origin + self.view_ofs, Gib_HeadVelocity(self.health), GIB_BLOOD_RED);

	for (float i = 0; i < count; i = i + 1)
	{
		string piece = self.monster_gibPiece;
		if (piece == "") piece = Gib_Q1PieceModel(i + 1);	// gib1/gib2/gib3, one each
		Gib_SpawnPiece(piece, Gib_RandomPointInBounds(), Gib_RandomVelocity(self.health), GIB_BLOOD_RED);
	}
}

void Gib_Q1Precache()
{
	precache_model("progs/gib1.mdl");
	precache_model("progs/gib2.mdl");
	precache_model("progs/gib3.mdl");
	precache_sound("player/udeath.wav");
}

void Gib_HideVictim()
{
	self.solid = SOLID_NOT;
	self.takedamage = DAMAGE_NO;
	self.effects = self.effects | EF_NODRAW;
	self.deadflag = DEAD_DEAD;

	if (self.flags & FL_CLIENT)
	{
		self.weaponmodel = "";
		self.view_ofs = '0 0 0';
		self.movetype = MOVETYPE_NONE;
		return;
	}

	self.think = SUB_Remove;
	self.nextthink = time + 0.1;
}

void Gib_ThrowGib(string gibname, float dm)
{
	if (gibname == "models/hgibs.mdl")
	{
		Gib_SpawnPiece(Gib_HumanPieceModel(Math_RandomInt(2, GIB_HUMAN_RANDOM_COUNT + 1)), Gib_RandomPointInBounds(), Gib_RandomVelocity(dm), GIB_BLOOD_RED);
		return;
	}
	if (gibname == "models/agibs.mdl")
	{
		Gib_SpawnPiece(Gib_AlienPieceModel(Math_RandomInt(1, GIB_ALIEN_RANDOM_COUNT)), Gib_RandomPointInBounds(), Gib_RandomVelocity(dm), GIB_BLOOD_ALIEN);
		return;
	}
	Gib_SpawnPiece(gibname, Gib_RandomPointInBounds(), Gib_RandomVelocity(dm), GIB_BLOOD_RED);
}

void Gib_ThrowHead(string gibname, float dm)
{
	if (gibname == "models/hgibs.mdl" || gibname == "")
		gibname = Gib_HumanHeadModel();
	Gib_SpawnPiece(gibname, self.origin + self.view_ofs, Gib_HeadVelocity(dm), GIB_BLOOD_RED);
}

void Gib_ThrowChunk(string gibname, float dm)
{
	Gib_SpawnPiece(gibname, self.origin, Gib_RandomVelocity(dm) * 0.5, GIB_BLOOD_RED);
}

void Gib_Precache()
{
	precache_model("models/hgibs01.iqm");
	precache_model("models/hgibs02.iqm");
	precache_model("models/hgibs03.iqm");
	precache_model("models/hgibs04.iqm");
	precache_model("models/hgibs05.iqm");
	precache_model("models/hgibs06.iqm");
	precache_model("models/hgibs07.iqm");
	precache_model("models/hgibs08.iqm");
	precache_model("models/hgibs09.iqm");
	precache_model("models/hgibs10.iqm");
	precache_model("models/hgibs11.iqm");

	precache_model("models/agibs01.iqm");
	precache_model("models/agibs02.iqm");
	precache_model("models/agibs03.iqm");
	precache_model("models/agibs04.iqm");

	precache_model("models/big_momgibs01.iqm");
	precache_model("models/big_momgibs02.iqm");
	precache_model("models/big_momgibs03.iqm");

	precache_model("sprites/bloodspray.spr");
	precache_model("sprites/blood.spr");
}

//
// Spawnflag SF_GIBSHOOTER_REPEATABLE: re-arm after burst instead of removing.
//   m_iGibs      total gibs to fire this burst (also initial capacity)
//   delay        time between gib spawns
//
// MOVETYPE_BOUNCE / Gib_WaitTillLand pipeline used by monster gibbing.

#define SF_GIBSHOOTER_REPEATABLE	1

.float m_iGibs;
.float gib_gibCapacity;
.float m_flVelocity;
.float gib_gibVelocity;
.float m_flVariance;
.float m_flGibLife;

.entity() createGibFn;

void GibShooter_ShootThink();

entity GibShooter_CreateGib()
{
	if (cvar("violence_hgibs") == 0)
		return world;

	float idx = Math_RandomInt(2, GIB_HUMAN_RANDOM_COUNT + 1);
	return Gib_SpawnPiece(Gib_HumanPieceModel(idx), self.origin, '0 0 0', GIB_BLOOD_RED);
}

void GibShooter_ShootThink()
{
	self.nextthink = time + self.delay;

	makevectors(self.angles);

	vector shootDir = self.movedir;
	shootDir = shootDir + v_right   * random(-1, 1) * self.m_flVariance;
	shootDir = shootDir + v_forward * random(-1, 1) * self.m_flVariance;
	shootDir = shootDir + v_up      * random(-1, 1) * self.m_flVariance;
	shootDir = normalize(shootDir);

	entity pGib = self.createGibFn();
	if (pGib != world)
	{
		pGib.velocity = shootDir * self.gib_gibVelocity;

		pGib.avelocity_x = random(100, 200);
		pGib.avelocity_y = random(100, 300);
		pGib.avelocity_z = 0;

		float thinkTime = pGib.nextthink - time;
		float lifeTime  = self.m_flGibLife * random(0.95, 1.05);
		if (lifeTime < thinkTime)
		{
			pGib.think = SUB_Remove;
			pGib.nextthink = time + lifeTime;
		}
		else
		{
			pGib.gib_lifetime = lifeTime;
		}
	}

	self.m_iGibs = self.m_iGibs - 1;
	if (self.m_iGibs <= 0)
	{
		if (self.spawnflags & SF_GIBSHOOTER_REPEATABLE)
		{
			self.m_iGibs = self.gib_gibCapacity;
			self.think = SUB_Null;
			self.nextthink = time;
		}
		else
		{
			self.think = SUB_Remove;
			self.nextthink = time;
		}
	}
}

void GibShooter_Use()
{
	self.think = GibShooter_ShootThink;
	self.nextthink = time;
}

void GibShooter_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	self.think = GibShooter_ShootThink;
	self.nextthink = time;
}

void gibshooter()
{
	Gib_Precache();

	self.solid   = SOLID_NOT;
	self.effects = EF_NODRAW;

	if (self.delay == 0)         self.delay = 0.1;
	if (self.m_flGibLife == 0)   self.m_flGibLife = 25;

	if (self.m_flVelocity != 0)  self.gib_gibVelocity = self.m_flVelocity;

	// gib_gibCapacity snapshots the initial count for SF_REPEATABLE re-arm.
	self.gib_gibCapacity = self.m_iGibs;

	SetMovedir();

	self.createGibFn = GibShooter_CreateGib;
	self.use   = GibShooter_Use;
	self.usehl = GibShooter_UseHL;
}

void Gib()
{
	if (self.deadflag == DEAD_DEAD && (self.effects & EF_NODRAW))
		return;

	// id1 monsters come apart into the stock Quake gib set instead of the standard one.
	if (self.q1_monster)
	{
		if (cvar("violence_hgibs") != 0)
			Gib_SpawnQ1Gibs(3);
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "player/udeath.wav");
		Gib_HideVictim();
		return;
	}

	if (Gib_IsAlien())
	{
		if (cvar("violence_agibs") != 0)
			Gib_SpawnRandomAlienGibs(4);
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, "common/bodysplat.wav");
	}
	else
	{
		if (cvar("violence_hgibs") != 0)
		{
			Gib_SpawnHead();
			Gib_SpawnRandomHumanGibs(4);
		}

		if (self.flags & FL_CLIENT)
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "player/gib.wav");
		else
			Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, "common/bodysplat.wav");
	}

	Gib_HideVictim();
}
