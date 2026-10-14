// spawnflags: shared turret bits only
// SF_MONSTER_TURRET_AUTOACTIVATE = 32
// SF_MONSTER_TURRET_STARTINACTIVE = 64
// AI/anim reuse monster_miniturret.qc via shared think/fire/move helpers.

#define TURRET_MODEL        "models/turret.iqm"
#define TURRET_GLOW_SPRITE  "sprites/flare3.spr"
#define TURRET_HEALTH       Skill_GetValue("sk_turret_health", 50)
#define TURRET_RANGE        (100 * 12)
#define TURRET_DAMAGE       Skill_GetValue("sk_12mm_bullet", 8)

void monster_turret()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	MiniTurret_Precache();
	precache_model(TURRET_MODEL);
	precache_model(TURRET_GLOW_SPRITE);

	self.classname = "monster_turret";
	setmodel(self, TURRET_MODEL);

	self.turret_range     = TURRET_RANGE;
	self.turret_damage    = TURRET_DAMAGE;
	self.turret_minPitch  = -15;
	self.turret_halfWidth = 32;
	self.turret_retractZ  = 16;
	self.turret_deployZ   = 32;
	self.turret_viewZ     = 12.75;

	MiniTurret_SetRetiredBounds();

	self.solid       = SOLID_SLIDEBOX;
	self.movetype    = MOVETYPE_NONE;
	self.health      = TURRET_HEALTH;
	self.max_health  = self.health;
	self.view_ofs    = '0 0 12.75';
	self.deadflag    = DEAD_NO;
	self.flags       = self.flags | FL_MONSTER;
	self.takedamage  = DAMAGE_AIM;
	self.takeDmgFn   = MiniTurret_TakeDamage;
	self.th_die      = MiniTurret_Die;
	self.use         = MiniTurret_Use;
	self.usehl       = MiniTurret_UseHL;
	self.monster_bloodColor = -1;   // DONT_BLEED: machines spark, never bleed

	self.cnt   = 0;
	self.dmg   = 0;
	self.state = MINITURRET_STATE_OFF;
	self.count = ((self.spawnflags & SF_MONSTER_TURRET_AUTOACTIVATE)
		&& !(self.spawnflags & SF_MONSTER_TURRET_STARTINACTIVE));
	self.speed = self.turnrate ? self.turnrate : MINITURRET_TURNRATE;
	self.yaw_speed = self.speed;
	self.wait  = self.maxsleep ? self.maxsleep : MINITURRET_MAXWAIT;

	self.ideal_yaw = Math_AngleMod(self.angles_y);

	if (self.orientation == 1)
		self.view_ofs_z = -12.75;

	self.v_angle    = [0, self.ideal_yaw, 0];
	self.finalangle = self.v_angle;
	self.pausetime  = time + 1;
	self.oldenemy   = world;
	self.enemy      = world;

	MiniTurret_UpdateDisplayAngles();
	setorigin(self, self.origin);

	// EyeOn/EyeOff in MiniTurret thinks ramp brightness based on state.
	self.turretGlow = Sprite_Create(TURRET_GLOW_SPRITE, self.origin + self.view_ofs, FALSE);
	self.turretGlow.classname   = "turret_glow";
	self.turretGlow.owner       = self;
	self.turretGlow.rendermode  = 3;            // kRenderGlow
	self.turretGlow.rendercolor = '255 0 0';
	self.turretGlow.renderamt   = 0;
	self.turretGlow.scale       = 0.5;
	{
		entity stemp = self;
		self = self.turretGlow;
		Render_Apply(self);
		self = stemp;
	}

	if (self.count)
		MiniTurret_BeginAutoSearch();
	else
	{
		self.think = SUB_Null;
		self.nextthink = 0;
	}

	total_monsters = total_monsters + 1;
}
