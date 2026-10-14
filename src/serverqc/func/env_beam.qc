
#define SF_BEAM_STARTON			0x0001
#define SF_BEAM_TOGGLE			0x0002
#define SF_BEAM_RANDOM			0x0004
#define SF_BEAM_RING			0x0008
#define SF_BEAM_SPARKSTART		0x0010
#define SF_BEAM_SPARKEND		0x0020
#define SF_BEAM_DECALS			0x0040
#define SF_BEAM_SHADEIN			0x0080
#define SF_BEAM_SHADEOUT		0x0100
#define SF_BEAM_TEMPORARY		0x8000

.string LightningStart;
.string LightningEnd;
.string texture;
.float  life;
.float  BoltWidth;
.float  NoiseAmplitude;
.float  TextureScroll;
.float  StrikeTime;
.float  framestart;
.float  framerate;
.float  Radius;
.float  damage;
.float  useSpriteBeam;

.float  beamFrameCount;
.float  beamSmoke;

.entity beamHead;
.float  segIndex;
.float  segCount;
.vector beamStart;
.vector beamEnd;


entity Beam_RandomTargetname(string szName)
{
	if (!szName || szName == "") return world;

	entity picked = world;
	float total = 0;
	entity t = find(world, targetname, szName);
	while (t)
	{
		total = total + 1;
		if (Math_RandomInt(0, total-1) < 1) picked = t;
		t = find(t, targetname, szName);
	}
	return picked;
}

float BEAM_VARIANT_LIGHTNING1 = 1;
float BEAM_VARIANT_LIGHTNING2 = 2;
float BEAM_VARIANT_LIGHTNING3 = 3;
float BEAM_VARIANT_BEAM       = 0;


void Beam_SegThink()
{
	entity src = self.owner;
	if (src == world || src.beamHead == world)
	{
		remove(self);
		return;
	}

	vector vs = src.beamStart;
	vector ve = src.beamEnd;
	vector delta = ve - vs;
	float dist = vlen(delta);
	if (dist <= 0)
	{
		self.nextthink = time + 0.1;
		return;
	}
	vector dir = delta / dist;

	float t   = (self.segIndex + 0.5) / src.segCount;
	vector mid = vs + delta * t;

	if (0 && src.NoiseAmplitude > 0)
	{
		float noiseGain = (src.NoiseAmplitude / 255) * dist * 0.25;
		makevectors(vectoangles(dir));
		float ph   = time * 6 + self.segIndex * 1.7;
		float ofsA = sin(ph) * noiseGain;
		float ofsB = sin(ph * 1.3 + 1.2) * noiseGain;
		mid = mid + v_right * ofsA + v_up * ofsB;
	}

	setorigin(self, mid);
	self.angles = vectoangles(dir);

	float fps    = src.framerate      > 0 ? (src.framerate * 0.1) : 10;
	float frames = src.beamFrameCount > 0 ?  src.beamFrameCount    : 3;
	float frameOfs = src.framestart
	               + time * fps
	               + self.segIndex * (src.TextureScroll * 0.1);
	self.frame = floor(mod(frameOfs, frames));

	self.nextthink = time + 0.05;
}

// Builds the persistent segment chain once
void Beam_BuildChain()
{
	string sprite = self.texture;
	if (!sprite) return;
	precache_model(sprite);

	vector delta = self.beamEnd - self.beamStart;
	float dist = vlen(delta);
	if (dist <= 0)
	{
		dprint("env_beam ");
		dprint(self.targetname);
		dprint(": zero-length beam, start==end\n");
		return;
	}

	float segLen = 16;
	float count  = max(1, ceil(dist / segLen));
	self.segCount = count;

	float widthScale = self.BoltWidth > 0 ? (self.BoltWidth / 80) : 1;
	vector colorMod  = self.rendercolor != '0 0 0' ? (self.rendercolor / 255) : '1 1 1';
	float  alphaVal  = self.renderamt   > 0        ? (self.renderamt / 255)   : 1;

	entity prev = world;
	float i;
	for (i = 0; i < count; i++)
	{
		entity seg = spawn();
		seg.classname = "env_beam_seg";
		seg.solid     = SOLID_NOT;
		seg.movetype  = MOVETYPE_NONE;
		seg.owner     = self;
		seg.segIndex  = i;
		seg.effects   = EF_NOSHADOW | EF_ADDITIVE;
		setmodel(seg, sprite);
		setorigin(seg, self.beamStart);
		seg.scale     = widthScale;
		seg.colormod  = colorMod;
		seg.alpha     = alphaVal;
		seg.think     = Beam_SegThink;
		seg.nextthink = time + 0.01;

		if (prev == world) self.beamHead = seg;
		else               prev.chain    = seg;
		prev = seg;
	}

	dprint("env_beam ");
	dprint(self.targetname);
	dprint(": built ");
	dprint(ftos(count));
	dprint(" segs from ");
	dprint(vtos(self.beamStart));
	dprint(" to ");
	dprint(vtos(self.beamEnd));
	dprint(" sprite=");
	dprint(sprite);
	dprint("\n");
}

void Beam_DestroyChain()
{
	entity seg = self.beamHead;
	while (seg)
	{
		entity nxt = seg.chain;
		remove(seg);
		seg = nxt;
	}
	self.beamHead = world;
}

// Schedulable: tear down chain after one-shot life expires.
void Beam_FadeOutThink()
{
	Beam_DestroyChain();
	self.think     = SUB_Null;
	self.nextthink = -1;
}

float Beam_TextureIsLightningish(string tex)
{
	if (!tex) return TRUE;
	if (strstrofs(tex, "lgtning",   0) != -1) return TRUE;
	if (strstrofs(tex, "lightning", 0) != -1) return TRUE;
	if (strstrofs(tex, "plasma",    0) != -1) return TRUE;
	return FALSE;
}

// Maps fake rising smoke and steam with a wide, nearly straight, dark grey
// lightning beam; drawn as a bolt here it reads as electricity.
float Beam_IsSmoke()
{
	if (!Beam_TextureIsLightningish(self.texture)) return FALSE;
	if (self.BoltWidth < 70 || self.NoiseAmplitude > 3) return FALSE;

	vector c = self.rendercolor;
	if (c == '0 0 0') return FALSE;
	float hi = max(c_x, max(c_y, c_z));
	float lo = min(c_x, min(c_y, c_z));
	return (hi <= 128 && hi - lo <= 32);
}

float Beam_TextureIsLaser(string tex)
{
	if (!tex) return FALSE;
	if (strstrofs(tex, "laserbeam", 0) != -1) return TRUE;
	return FALSE;
}

void Beam_Emit(vector vsrc, vector vdst)
{
	if (!self.texture || self.texture == "")
	{
		te_lightning1(self, vsrc, vdst);
		return;
	}

	if (self.beamSmoke)
	{
		trailparticles(self, particleeffectnum("hl_beam_smoke"), vsrc, vdst);
		return;
	}

	if (Beam_TextureIsLaser(self.texture))
	{
		DrawLine(vsrc, vdst, "models/laserbeam.md3", 32, 1.05, 0.1);
		return;
	}

	if (self.useSpriteBeam || !Beam_TextureIsLightningish(self.texture))
	{
		self.beamStart = vsrc;
		self.beamEnd   = vdst;
		if (self.beamHead == world)
			Beam_BuildChain();
		return;
	}

	te_lightning1(self, vsrc, vdst);
}

vector Beam_startPos;
vector Beam_endPos;
float Beam_RandomPoint(vector vecSrc)
{
	float r = self.Radius ? self.Radius : 256;
	float i;
	for (i = 0; i < 10; i = i + 1)
	{
		vector dir = randomvec();
		dir = normalize(dir);
		traceline(vecSrc, vecSrc + dir * r, FALSE, self);
		if (trace_fraction == 1.0) continue;
		if (vlen(trace_endpos - vecSrc) < r * 0.1) continue;
		Beam_startPos = vecSrc;
		Beam_endPos   = trace_endpos;
		return TRUE;
	}
	return FALSE;
}

// Returns TRUE if we have usable start/end positions in the globals.
float Beam_ResolveEndpoints()
{
	entity pStart = Beam_RandomTargetname(self.LightningStart);
	entity pEnd   = Beam_RandomTargetname(self.LightningEnd);

	if (pStart == world && pEnd == world && !(self.spawnflags & SF_BEAM_RANDOM))
	{
		dprint("env_beam ");
		dprint(self.targetname);
		dprint(": no endpoints (start='");
		dprint(self.LightningStart);
		dprint("' end='");
		dprint(self.LightningEnd);
		dprint("')\n");
	}

	// Fallback to the entity's own origin if no LightningStart was set.
	if (pStart == world) Beam_startPos = self.origin;
	else                 Beam_startPos = pStart.origin;

	if (pEnd != world)
	{
		Beam_endPos = pEnd.origin;
		return TRUE;
	}

	if (self.spawnflags & SF_BEAM_RANDOM)
		return Beam_RandomPoint(Beam_startPos);

	if (self.target && self.target != "")
	{
		entity pFallback = find(world, targetname, self.target);
		if (pFallback != world)
		{
			Beam_endPos = pFallback.origin;
			return TRUE;
		}
	}

	return FALSE;
}

// 
// Think (strike)
// 

// One strike: emit visuals, apply damage, spawn sparks.
void Beam_Strike()
{
	if (!Beam_ResolveEndpoints()) return;
	Beam_Emit(Beam_startPos, Beam_endPos);
	if (self.spawnflags & SF_BEAM_SPARKSTART) DoSpark(Beam_startPos);
	if (self.spawnflags & SF_BEAM_SPARKEND)   DoSpark(Beam_endPos);
	if (self.damage > 0)
	{
		traceline(Beam_startPos, Beam_endPos, FALSE, self);
		if (trace_ent && trace_ent.takedamage)
		{
			float dt = time - self.dmgtime;
			if (dt < 0.05) dt = 0.05;
			Combat_TakeDamage(trace_ent, self, self, self.damage * dt, DMG_ENERGYBEAM);
		}
		self.dmgtime = time;
	}
}

// Periodic re-strike while ON.
void Beam_StrikeThink()
{
	if (!self.state) { self.nextthink = -1; return; }

	Beam_Strike();

	float lifev   = self.life;
	float restrk  = self.StrikeTime;
	float delay;

	if (self.beamSmoke || Beam_TextureIsLaser(self.texture))
	{
		self.nextthink = time + 0.1;
		return;
	}

	if (self.spawnflags & SF_BEAM_RANDOM) delay = lifev + random(0, restrk);
	else                                  delay = lifev + restrk;
	if (delay < 0.1) delay = 0.1;
	self.nextthink = time + delay;
}

void Beam_Use()
{
	if (!(self.spawnflags & (SF_BEAM_TOGGLE | SF_BEAM_STARTON)))
	{
		Beam_Strike();
		// Spec: life=0 = infinite. Only schedule fade-out for finite life.
		if (self.life > 0)
		{
			self.think     = Beam_FadeOutThink;
			self.nextthink = time + self.life;
		}
		return;
	}

	useType = USE_TOGGLE;
	if (!ShouldToggle(self.state)) return;

	if (self.state)
	{
		// OFF
		self.state     = 0;
		self.think     = SUB_Null;
		self.nextthink = -1;
		Beam_DestroyChain();
	}
	else
	{
		// ON
		self.state     = 1;
		self.think     = Beam_StrikeThink;
		self.nextthink = time + 0.1;
		self.dmgtime   = time;
	}
}

void Beam_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!(self.spawnflags & (SF_BEAM_TOGGLE | SF_BEAM_STARTON)))
	{
		Beam_Strike();
		// Spec: life=0 = infinite. Only schedule fade-out for finite life.
		if (self.life > 0)
		{
			self.think     = Beam_FadeOutThink;
			self.nextthink = time + self.life;
		}
		return;
	}

	useType = useTypeArg;			// ShouldToggle() reads this global
	if (!ShouldToggle(self.state)) return;

	if (self.state)
	{
		self.state     = 0;
		self.think     = SUB_Null;
		self.nextthink = -1;
		Beam_DestroyChain();
	}
	else
	{
		self.state     = 1;
		self.think     = Beam_StrikeThink;
		self.nextthink = time + 0.1;
		self.dmgtime   = time;
	}
}


void env_beam()
{
	self.solid     = SOLID_NOT;
	self.movetype  = MOVETYPE_NONE;
	self.classname = "env_beam";

	if (self.texture && self.texture != "")
	{
		if(self.texture == "sprites/laserbeam.spr") precache_model("models/laserbeam.md3");
		else precache_model(self.texture);
	}
	self.beamSmoke = Beam_IsSmoke();


	self.use     = Beam_Use;
	self.usehl   = Beam_UseHL;
	self.dmgtime = time;

	if (self.spawnflags & SF_BEAM_STARTON)
	{
		self.state     = 1;
		self.think     = Beam_StrikeThink;
		self.nextthink = time + 1.0;
	}
	else
	{
		self.state = 0;
	}
}
