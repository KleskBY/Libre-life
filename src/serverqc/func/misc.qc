// Ambient hazards inherited from id1 assets (lava-ball fountains, exploding barrels, bubble columns). Models require a game directory that supplies them.
//   speed   misc_fireball vertical launch speed, default FIREBALL_SPEED

#define FIREBALL_MODEL		"progs/lavaball.mdl"
#define FIREBALL_SPEED		1000
#define FIREBALL_DMG		20
#define FIREBALL_LIFETIME	5

#define EXPLOBOX_MODEL		"maps/b_explob.bsp"
#define EXPLOBOX_MODEL_SMALL	"maps/b_exbox2.bsp"
#define EXPLOBOX_HEALTH		20
#define EXPLOBOX_DMG		160
#define EXPLOBOX_RADIUS		200
#define EXPLOBOX_DROP_LIMIT	250	// fell this far below its map position -> discard

#define AIRBUBBLES_SPREAD	8
#define AIRBUBBLES_INTERVAL	0.5

void Fireball_Touch()
{
	T_Damage(other, self, self, FIREBALL_DMG, DMG_BURN);
	remove(self);
}

void Fireball_LaunchThink()
{
	entity ball = spawn();
	ball.classname = "fireball";
	ball.solid     = SOLID_TRIGGER;
	ball.movetype  = MOVETYPE_TOSS;
	ball.velocity  = [random() * 100 - 50,
	                  random() * 100 - 50,
	                  self.speed + random() * 200];

	setmodel(ball, FIREBALL_MODEL);
	setsize(ball, '0 0 0', '0 0 0');
	setorigin(ball, self.origin);

	ball.touch     = Fireball_Touch;
	ball.think     = SUB_Remove;
	ball.nextthink = time + FIREBALL_LIFETIME;

	self.nextthink = time + 3 + random() * 5;
}

void misc_fireball()
{
	precache_model(FIREBALL_MODEL);

	if (!self.speed)
		self.speed = FIREBALL_SPEED;

	self.think     = Fireball_LaunchThink;
	self.nextthink = time + random() * 5;
}

void ExploBox_Die()
{
	self.takedamage = DAMAGE_NO;
	T_RadiusDamage(self, self, EXPLOBOX_DMG, EXPLOBOX_RADIUS);

	self.origin_z = self.origin_z + 32;
	Combat_Explode(0, 0);	// damage already applied; this is effects + remove
}

void ExploBox_Spawn(string mdl)
{
	precache_model(mdl);
	setmodel(self, mdl);

	self.solid      = SOLID_BBOX;
	// FTE networks a SOLID_BBOX entity to predicting clients as a box centred on its
	// origin (width = -mins_x). The barrel's brush model spans 0..32, so clients saw a
	// zero-width box and players standing on it slid/jittered. SOLID_BSP sends the real hull.
	if (IsFTE()) self.solid = SOLID_BSP;
	self.movetype   = MOVETYPE_NONE;
	self.health     = EXPLOBOX_HEALTH;
	self.takedamage = DAMAGE_AIM;
	self.th_die     = ExploBox_Die;

	self.origin_z = self.origin_z + 2;
	float oldz = self.origin_z;
	droptofloor();

	if (oldz - self.origin_z > EXPLOBOX_DROP_LIMIT)
	{
		dprint("explobox fell out of level at ");
		dprint(vtos(self.origin));
		dprint("\n");
		remove(self);
	}
}

void misc_explobox()
{
	ExploBox_Spawn(EXPLOBOX_MODEL);
}

void misc_explobox2()
{
	ExploBox_Spawn(EXPLOBOX_MODEL_SMALL);
}

void AirBubbles_Think()
{
	vector spread = [AIRBUBBLES_SPREAD, AIRBUBBLES_SPREAD, AIRBUBBLES_SPREAD];
	Bubble_Spawn(self.origin - spread, self.origin + spread, 0);

	self.nextthink = time + AIRBUBBLES_INTERVAL + random();
}

void air_bubbles()
{
	if (deathmatch)
	{
		remove(self);
		return;
	}

	precache_model(BUBBLE_SPRITE_PATH);

	self.think     = AirBubbles_Think;
	self.nextthink = time + 1;
}
