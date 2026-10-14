// Spawn N flyers in radius around self.origin and remove self.
// Each flyer wanders in a slow random circle (no leader/squad coordination).
// Killing one alarms the rest (raises pitch + speed) via Flyer_Alarm.
//
// Uses boid.mdl (aflock.mdl was commented out in the original source).
// Anims (data/models/boid.iqm.framegroups): bird_fly1=0, idle=1

#define FLYER_MODEL          "models/boid.iqm"
#define FLYER_DEFAULT_COUNT  8
#define FLYER_DEFAULT_RADIUS 128
#define FLYER_SPEED          120
#define FLYER_SPEED_ALARMED  220
#define FLYER_TURN_INTERVAL  3
#define FLYER_SOUND_INTERVAL 4

#define FLYER_FR_FLY1   0
#define FLYER_FR_IDLE   1

#define FLYER_SND_ALERT1  "boid/boid_alert1.wav"
#define FLYER_SND_ALERT2  "boid/boid_alert2.wav"
#define FLYER_SND_IDLE1   "boid/boid_idle1.wav"
#define FLYER_SND_IDLE2   "boid/boid_idle2.wav"

.float flyer_nextTurn;
.float flyer_nextSound;
.float flyer_alarmedUntil;

.float iFlockSize;
.float flFlockRadius;

float Flyer_FrameByName(string name)
{
	if (name == "bird_fly1") return FLYER_FR_FLY1;
	if (name == "idle")      return FLYER_FR_IDLE;
	return -1;
}

void Flyer_Precache()
{
	precache_model(FLYER_MODEL);
	precache_sound(FLYER_SND_ALERT1);
	precache_sound(FLYER_SND_ALERT2);
	precache_sound(FLYER_SND_IDLE1);
	precache_sound(FLYER_SND_IDLE2);
}

void Flyer_MakeSound()
{
	if (self.flyer_alarmedUntil > time)
	{
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, FLYER_SND_ALERT1, FLYER_SND_ALERT2);
	}
	else
	{
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, FLYER_SND_IDLE1, FLYER_SND_IDLE2);
	}
}

void Flyer_IdleThink()
{
	self.nextthink = time + 0.2;

	if (self.health <= 0) return;

	if (time >= self.flyer_nextTurn)
	{
		self.angles_y = self.angles_y + (random() * 90 - 45);
		self.angles_x = (random() * 30 - 15);
		self.flyer_nextTurn = time + FLYER_TURN_INTERVAL + random() * 2;
	}

	makevectors(self.angles);
	float spd = (self.flyer_alarmedUntil > time) ? FLYER_SPEED_ALARMED : FLYER_SPEED;
	self.velocity = v_forward * spd;
	self.frame    = FLYER_FR_FLY1;

	if (time >= self.flyer_nextSound)
	{
		Flyer_MakeSound();
		self.flyer_nextSound = time + FLYER_SOUND_INTERVAL + random() * 4;
	}
}

void Flyer_Alarm()
{
	// Alarm self + every other flyer within audible range.
	entity head = findradius(self.origin, 768);
	while (head)
	{
		if (head.classname == "monster_flyer")
			head.flyer_alarmedUntil = time + 15;
		head = head.chain;
	}
}

void Flyer_FallHack()
{
	if (self.flags & FL_ONGROUND)
	{
		self.velocity = '0 0 0';
		self.think    = SUB_Null;
		self.nextthink = 0;
		return;
	}
	self.think     = Flyer_FallHack;
	self.nextthink = time + 0.1;
}

void Flyer_Die()
{
	Flyer_Alarm();
	self.deadflag  = DEAD_DEAD;
	self.framerate = 0;
	setsize(self, '0 0 0', '0 0 0');
	self.movetype  = MOVETYPE_TOSS;
	self.think     = Flyer_FallHack;
	self.nextthink = time + 0.1;
}

// Spawn a single flyer at pos with random heading. Returns the entity.
entity Flyer_SpawnOne(vector pos)
{
	entity boid = spawn();
	boid.classname = "monster_flyer";
	setmodel(boid, FLYER_MODEL);
	setsize(boid, '-5 -5 0', '5 5 2');
	setorigin(boid, pos);

	boid.solid       = SOLID_SLIDEBOX;
	boid.movetype    = MOVETYPE_FLY;
	boid.takedamage  = DAMAGE_AIM;
	boid.health      = 1;
	boid.max_health  = 1;
	boid.monster_bloodColor = BLOOD_COLOR_RED;
	boid.monster_fieldOfView = 0.2;
	boid.angles      = '0 0 0';
	boid.angles_y    = random() * 360;
	boid.frameByName = Flyer_FrameByName;
	boid.frame       = FLYER_FR_FLY1;
	boid.th_die      = Flyer_Die;
	boid.flyer_nextTurn  = time + random() * FLYER_TURN_INTERVAL;
	boid.flyer_nextSound = time + random() * FLYER_SOUND_INTERVAL;

	entity stemp = self;
	self = boid;
	Monster_InitTakeDamage();
	self = stemp;

	boid.think     = Flyer_IdleThink;
	boid.nextthink = time + 0.1 + random() * 0.5;
	return boid;
}

// Single flyer entity (rare standalone use; map authors prefer monster_flyer_flock).
void monster_flyer()
{
	if (RemoveInDeathmatch()) { remove(self); return; }
	Flyer_Precache();

	setmodel(self, FLYER_MODEL);
	setsize(self, '-5 -5 0', '5 5 2');

	self.solid       = SOLID_SLIDEBOX;
	self.movetype    = MOVETYPE_FLY;
	self.takedamage  = DAMAGE_AIM;
	self.health      = 1;
	self.max_health  = 1;
	self.monster_bloodColor = BLOOD_COLOR_RED;
	self.monster_fieldOfView = 0.2;
	self.frameByName = Flyer_FrameByName;
	self.frame       = FLYER_FR_FLY1;
	self.th_die      = Flyer_Die;

	Monster_InitTakeDamage();

	self.flyer_nextTurn  = time + random() * FLYER_TURN_INTERVAL;
	self.flyer_nextSound = time + random() * FLYER_SOUND_INTERVAL;
	self.think           = Flyer_IdleThink;
	self.nextthink       = time + 0.1;
	total_monsters       = total_monsters + 1;
}

// Flock controller: spawn N flyers in radius then remove self.
void monster_flyer_flock()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) { remove(self); return; }
	Flyer_Precache();

	float count = (self.iFlockSize > 0)   ? self.iFlockSize   : FLYER_DEFAULT_COUNT;
	float radius = (self.flFlockRadius > 0) ? self.flFlockRadius : FLYER_DEFAULT_RADIUS;

	float i;
	for (i = 0; i < count; i = i + 1)
	{
		vector offset;
		offset_x = (random() * 2 - 1) * radius;
		offset_y = (random() * 2 - 1) * radius;
		offset_z = random() * 16;
		Flyer_SpawnOne(self.origin + offset);
	}

	remove(self);
}
