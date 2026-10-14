
#define HGRUNT_FR_REPEL_JUMP   47   // push off the ledge
#define HGRUNT_FR_REPEL_REPEL  48   // looping descent
#define HGRUNT_FR_REPEL_SHOOT  49
#define HGRUNT_FR_REPEL_LAND   50   // touchdown
#define HGRUNT_FR_REPEL_DIE    51   // killed on the rope

#define REPEL_SPEED         300     // descent rate, u/s
#define REPEL_THINK_RATE    0.05    // rope redraw / descent tick
#define REPEL_JUMP_TIME     0.25    // ledge push-off before the descent starts
#define REPEL_LAND_TIME     0.55    // touchdown anim before the AI takes over
#define REPEL_FIRE_DELAY    0.12    // MP5 cadence while rappelling
#define REPEL_ROPE_MODEL    "models/rope.md3"

// Per-grunt repel state. Fields defined here to avoid modifying monster_base.qc.
.vector repel_anchor;               // fixed ceiling attach point for the rope
.float  repel_groundz;              // ground z from the spawn-time down trace
.float  repel_nextFire;             // next allowed MP5 shot while on the rope

// Draw the rope from the ceiling anchor down to the grunt's hands.
void GruntRepel_DrawRope()
{
	DrawLine(self.repel_anchor, self.origin + '0 0 60',
	         REPEL_ROPE_MODEL, 64, 2, REPEL_THINK_RATE);
}

void GruntRepel_Die()
{
	self.hgrunt_repelling = FALSE;
	self.movetype = MOVETYPE_TOSS;     // let the body fall off the rope
	HGrunt_Die();
	if (!wasfreed(self) && self.deadflag == DEAD_DEAD)
		HGrunt_PlayFrame(HGRUNT_FR_REPEL_DIE);
}

void GruntRepel_Descend();

void GruntRepel_Landed()
{
	self.think     = HGrunt_Stand;     // resume normal AI (acquires targets)
	self.nextthink = time + 0.1;
}

void GruntRepel_Land()
{
	self.velocity  = '0 0 0';
	self.movetype  = MOVETYPE_STEP;
	self.origin_z  = self.repel_groundz;
	setorigin(self, self.origin);
	self.hgrunt_repelling = FALSE;
	self.th_die    = HGrunt_Die;
	HGrunt_PlayFrame(HGRUNT_FR_REPEL_LAND);
	self.think     = GruntRepel_Landed;
	self.nextthink = time + REPEL_LAND_TIME;
}

float GruntRepel_TryFire()
{
	if (!HGrunt_HasMP5() || self.hgrunt_clip <= 0)
		return FALSE;

	if (!self.enemy || !IsAlive(self.enemy) || !HGrunt_CanSee(self.enemy))
		self.enemy = HGrunt_FindEnemy();
	if (!self.enemy || !HGrunt_CanSee(self.enemy))
		return FALSE;

	self.angles_y = vectoyaw(self.enemy.origin - self.origin);

	if (time >= self.repel_nextFire)
	{
		HGrunt_FireMP5();
		self.repel_nextFire = time + REPEL_FIRE_DELAY;
	}
	return TRUE;
}

void GruntRepel_Descend()
{
	if (self.health <= 0) return;      // death routed through th_die

	self.movetype = MOVETYPE_FLY;      // gravity-free controlled rappel
	self.velocity = [0, 0, -REPEL_SPEED];

	if (GruntRepel_TryFire())
		HGrunt_PlayFrame(HGRUNT_FR_REPEL_SHOOT);
	else
		HGrunt_PlayFrame(HGRUNT_FR_REPEL_REPEL);

	GruntRepel_DrawRope();

	if (self.origin_z <= self.repel_groundz)
	{
		GruntRepel_Land();
		return;
	}
	self.nextthink = time + REPEL_THINK_RATE;
}

void GruntRepel_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	// Trace straight down to find the ground the grunt will land on.
	traceline(self.origin, self.origin + '0 0 -4096', FALSE, self);
	vector groundPos = trace_endpos;

	entity grunt = spawn();
	grunt.classname = "monster_human_grunt";
	setorigin(grunt, self.origin);
	grunt.angles = self.angles;

	entity stemp = self;
	self = grunt;
	monster_human_grunt();
	self = stemp;

	grunt.repel_anchor    = self.origin;   // ceiling attach = spawner origin
	grunt.repel_groundz   = groundPos_z;
	grunt.movetype        = MOVETYPE_FLY;
	grunt.velocity        = '0 0 0';
	grunt.hgrunt_repelling = TRUE;         // suppress pain flinch while on rope
	grunt.th_die          = GruntRepel_Die;

	grunt.frame      = HGRUNT_FR_REPEL_JUMP;   // push off, hold briefly
	grunt.frame1time = time;
	grunt.framerate  = 1;
	grunt.think      = GruntRepel_Descend;
	grunt.nextthink  = time + REPEL_JUMP_TIME;

	remove(self);
}

void GruntRepel_Use()
{
	GruntRepel_UseHL(activator, self, USE_TOGGLE, 0);
}

void monster_grunt_repel()
{
	if (RemoveInDeathmatch()) return;

	precache_model("models/hgrunt.iqm");
	precache_model(REPEL_ROPE_MODEL);
	HGrunt_Precache();

	self.solid       = SOLID_NOT;
	self.movetype    = MOVETYPE_NONE;
	self.use         = GruntRepel_Use;
	self.usehl       = GruntRepel_UseHL;
	self.object_caps = FCAP_IMPULSE_USE;
}
