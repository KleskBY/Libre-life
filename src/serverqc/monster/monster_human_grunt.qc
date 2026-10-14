// HGRUNT_9MMAR = 1 (MP5 burst fire)
//   HGRUNT_HANDGRENADE     = 2
//   HGRUNT_GRENADELAUNCHER = 4
//   HGRUNT_SHOTGUN         = 8
// spawnflags: only shared SF_MONSTER_GAG = 2

#define HGRUNT_MODEL              "models/hgrunt.iqm"
#define HGRUNT_HEALTH             Skill_GetValue("sk_hgrunt_health", 50) + 50
#define HGRUNT_LIMP_HEALTH        20
#define HGRUNT_FOV                0.2
#define HGRUNT_SIGHT_RANGE        2048	// CheckRangeAttack1 works up to 2048
#define HGRUNT_ATTACK_RANGE       2048
#define HGRUNT_ATTACK_DOT         0.5
#define HGRUNT_MELEE_RANGE        70
#define HGRUNT_BURST_DAMAGE       Skill_GetValue("sk_9mmAR_bullet", 4)
#define HGRUNT_BURST_SHOTS        3
#define HGRUNT_BURST_DELAY        0.1
#define HGRUNT_ATTACK_COOLDOWN    1.5
#define HGRUNT_BULLET_SPREAD      0.08716
#define HGRUNT_SHOTGUN_SPREAD     0.13053
#define HGRUNT_SHOTGUN_PELLETS    Skill_GetValue("sk_hgrunt_pellets", 5)
#define HGRUNT_SHOTGUN_DAMAGE     Skill_GetValue("sk_plr_buckshot", 5)
#define HGRUNT_SHOTGUN_COOLDOWN   2.0
#define HGRUNT_GRENADE_RANGE      256
#define HGRUNT_GRENADE_MAX_RANGE  1024
#define HGRUNT_GRENADE_COOLDOWN   6
#define HGRUNT_GRENADE_SPEED      Skill_GetValue("sk_hgrunt_gspeed", 600)
#define HGRUNT_SPEECH_INTERVAL    8
#define HGRUNT_CLIP_MP5           36
#define HGRUNT_CLIP_SHOTGUN       8
#define HGRUNT_RELOAD_LOW         5       // opportunistic reload threshold (no LOS)
#define HGRUNT_STRAFE_INTERVAL    2.5
#define HGRUNT_STRAFE_DIST        48    // lateral clearance the trace checks for
#define HGRUNT_STRAFE_STEP        12    // per-tick lateral move during the strafe (was one 48u pop)
#define HGRUNT_STRAFE_TIME        0.5   // strafe substate duration
#define HGRUNT_RUN_STEP           18
#define HGRUNT_GRENADE_FEAR_RAD   300	// flee live grenades within this radius (blast ~250)
#define HGRUNT_MELEE_DAMAGE       Skill_GetValue("sk_hgrunt_kick", 10)

// .weapons bits
#define HGRUNT_W_MP5              1
#define HGRUNT_W_HANDGRENADE      2
#define HGRUNT_W_GRENADELAUNCHER  4
#define HGRUNT_W_SHOTGUN          8

// Bodygroup submodel indices (hgrunt.iqm.bodyinfo groups "heads"/"weapons",
#define HGRUNT_HEAD_GRUNT         0
#define HGRUNT_HEAD_COMMANDER     1
#define HGRUNT_HEAD_SHOTGUN       2
#define HGRUNT_HEAD_M203          3
#define HGRUNT_GUN_MP5            0
#define HGRUNT_GUN_SHOTGUN        1
#define HGRUNT_GUN_NONE           2

// Anim indices (from hgrunt.iqm.framegroups conversion order)
#define HGRUNT_FR_WALK1                 0
#define HGRUNT_FR_RUN                   1
#define HGRUNT_FR_VICTORYDANCE          2
#define HGRUNT_FR_COWER                 3
#define HGRUNT_FR_FLINCH                4
#define HGRUNT_FR_LAUNCHGRENADE         9
#define HGRUNT_FR_THROWGRENADE          10
#define HGRUNT_FR_IDLE1                 11
#define HGRUNT_FR_IDLE2                 12
#define HGRUNT_FR_COMBATIDLE            13
#define HGRUNT_FR_FRONTKICK             14
#define HGRUNT_FR_CROUCHING_MP5         17
#define HGRUNT_FR_STANDING_MP5          18
#define HGRUNT_FR_RELOAD_MP5  	        19
#define HGRUNT_FR_STANDING_SHOTGUN      21
#define HGRUNT_FR_LIMPWALK              27
#define HGRUNT_FR_LIMPRUN               28
#define HGRUNT_FR_STRAFELEFT            31
#define HGRUNT_FR_STRAFERIGHT           32
#define HGRUNT_FR_DIEFORWARD            34
#define HGRUNT_FR_DIESIMPLE             35
#define HGRUNT_FR_DIEBACKWARDS          36
#define HGRUNT_FR_DIEHEADSHOT           37
#define HGRUNT_FR_DIEGUTSHOT            38

// player's hks1-3.
#define HGRUNT_FIRE1_SOUND        "hgrunt/gr_mgun1.wav"
#define HGRUNT_FIRE2_SOUND        "hgrunt/gr_mgun2.wav"
#define HGRUNT_SHOTGUN_SOUND      "weapons/sbarrel1.wav"
#define HGRUNT_GLAUNCHER_SOUND    "weapons/glauncher.wav"
#define HGRUNT_RELOAD_SOUND       "hgrunt/gr_reload1.wav"
#define HGRUNT_KICK_SOUND         "zombie/claw_miss2.wav"
#define HGRUNT_KICKHIT_SOUND      "zombie/claw_strike1.wav"
#define HGRUNT_PAIN_SOUND1        "hgrunt/gr_pain1.wav"
#define HGRUNT_PAIN_SOUND2        "hgrunt/gr_pain2.wav"
#define HGRUNT_PAIN_SOUND3        "hgrunt/gr_pain3.wav"
#define HGRUNT_PAIN_SOUND4        "hgrunt/gr_pain4.wav"
#define HGRUNT_PAIN_SOUND5        "hgrunt/gr_pain5.wav"
#define HGRUNT_DIE_SOUND1         "hgrunt/gr_die1.wav"
#define HGRUNT_DIE_SOUND2         "hgrunt/gr_die2.wav"
#define HGRUNT_DIE_SOUND3         "hgrunt/gr_die3.wav"

.float hgrunt_combatState;
#define HGCS_RUN       0
#define HGCS_ATTACK    1
#define HGCS_RELOAD    2
#define HGCS_GRENADE   3
#define HGCS_LAUNCHER  4
#define HGCS_MELEE     5
#define HGCS_STRAFE    6
#define HGCS_FLEE      7   // running from a live grenade (highest priority)

.float hgrunt_nextAttack;
.float hgrunt_nextGrenade;
.float hgrunt_nextSpeech;
.float hgrunt_nextStrafe;
.float hgrunt_burstShots;
.float hgrunt_burstTarget;     // how many rounds this burst (varies per attack)
.float hgrunt_crouchAttack;    // TRUE = this attack fires from the crouch pose
.float hgrunt_clip;
.float hgrunt_subStateEnd;
.float hgrunt_actTime;         // one-shot mid-anim action time (kick/throw/fire); 0 = already fired
.float hgrunt_strafeDir;       // -1 left, +1 right
.vector hgrunt_fleeFrom;       // danger point to run away from (grenade origin)
.entity hgrunt_fleeMarker;     // temp movetogoal target used while fleeing
.float hgrunt_lastDmgDir;      // 0 unknown, 1 front, -1 back
.float hgrunt_lastHitGroup;    // for headshot/gut death anim
.vector hgrunt_lkp;            // last-known position of enemy

float HGrunt_FrameByName(string name)
{
	if (name == "walk1")             return HGRUNT_FR_WALK1;
	if (name == "run")               return HGRUNT_FR_RUN;
	if (name == "cower")             return HGRUNT_FR_COWER;
	if (name == "smflinch")          return HGRUNT_FR_FLINCH;
	if (name == "launchgrenade")     return HGRUNT_FR_LAUNCHGRENADE;
	if (name == "throwgrenade")      return HGRUNT_FR_THROWGRENADE;
	if (name == "idle1")             return HGRUNT_FR_IDLE1;
	if (name == "idle2")             return HGRUNT_FR_IDLE2;
	if (name == "combatidle")        return HGRUNT_FR_COMBATIDLE;
	if (name == "frontkick")         return HGRUNT_FR_FRONTKICK;
	if (name == "crouching_mp5_blend1")     return HGRUNT_FR_CROUCHING_MP5;
	if (name == "standing_mp5_blend1")      return HGRUNT_FR_STANDING_MP5;
	if (name == "reload_mp5")		 return HGRUNT_FR_RELOAD_MP5;
	if (name == "standing_shotgun_blend1")  return HGRUNT_FR_STANDING_SHOTGUN;
	if (name == "limpingwalk")       return HGRUNT_FR_LIMPWALK;
	if (name == "limpingrun")        return HGRUNT_FR_LIMPRUN;
	if (name == "strafeleft")        return HGRUNT_FR_STRAFELEFT;
	if (name == "straferight")       return HGRUNT_FR_STRAFERIGHT;
	if (name == "dieforward")        return HGRUNT_FR_DIEFORWARD;
	if (name == "diesimple")         return HGRUNT_FR_DIESIMPLE;
	if (name == "diebackwards")      return HGRUNT_FR_DIEBACKWARDS;
	if (name == "dieheadshot")       return HGRUNT_FR_DIEHEADSHOT;
	if (name == "diegutshot")        return HGRUNT_FR_DIEGUTSHOT;
	return -1;
}

#define HGRUNT_GUN_LENGTH      20                         // right hand to muzzle, the MP5 is part of the mesh
#define HGRUNT_SHELL_MP5       "models/shell.iqm"
#define HGRUNT_SHELL_SHOTGUN   "models/shotgunshell.iqm"

void HGrunt_Precache()
{
	precache_model(HGRUNT_MODEL);
	precache_model(HGRUNT_SHELL_MP5);
	precache_model(HGRUNT_SHELL_SHOTGUN);
	precache_model("models/w_grenade.iqm");
	precache_sound(HGRUNT_FIRE1_SOUND);
	precache_sound(HGRUNT_FIRE2_SOUND);
	precache_sound(HGRUNT_SHOTGUN_SOUND);
	precache_sound(HGRUNT_GLAUNCHER_SOUND);
	precache_sound(HGRUNT_RELOAD_SOUND);
	precache_sound(HGRUNT_KICK_SOUND);
	precache_sound(HGRUNT_KICKHIT_SOUND);
	precache_sound(HGRUNT_PAIN_SOUND1);
	precache_sound(HGRUNT_PAIN_SOUND2);
	precache_sound(HGRUNT_PAIN_SOUND3);
	precache_sound(HGRUNT_PAIN_SOUND4);
	precache_sound(HGRUNT_PAIN_SOUND5);
	precache_sound(HGRUNT_DIE_SOUND1);
	precache_sound(HGRUNT_DIE_SOUND2);
	precache_sound(HGRUNT_DIE_SOUND3);
	precache_sound("weapons/explode3.wav");
}

void HGrunt_PlayFrame(float fr)
{
	if (self.frame == fr) return;
	self.frame      = fr;
	self.frame1time = time;
	self.framerate  = 1;
}

float HGrunt_IsLimping() { return (self.health > 0 && self.health <= HGRUNT_LIMP_HEALTH); }

float HGrunt_HasMP5()      { return (self.weapons & HGRUNT_W_MP5) != 0; }
float HGrunt_HasShotgun()  { return (self.weapons & HGRUNT_W_SHOTGUN) != 0; }
float HGrunt_HasHandGrn()  { return (self.weapons & HGRUNT_W_HANDGRENADE) != 0; }
float HGrunt_HasLauncher() { return (self.weapons & HGRUNT_W_GRENADELAUNCHER) != 0; }

float HGrunt_ClipMax()
{
	if (HGrunt_HasShotgun()) return HGRUNT_CLIP_SHOTGUN;
	return HGRUNT_CLIP_MP5;
}

float HGrunt_CanSee(entity tgt)
{
	if (!tgt) return FALSE;
	traceline(self.origin + self.view_ofs, tgt.origin + tgt.view_ofs, FALSE, self);
	return (trace_fraction == 1.0 || trace_ent == tgt);
}

// relationship table: CLASS_HUMAN_MILITARY + friendly NPCs are R_AL/R_NO).
float HGrunt_IsFriend(entity e)
{
	return (e.classname == "monster_scientist"
		|| e.classname == "monster_barney"
		|| e.classname == "monster_sitting_scientist"
		|| e.classname == "monster_human_grunt"
		|| e.classname == "monster_human_assassin"
		|| e.classname == "monster_sentry"
		|| e.classname == "monster_miniturret"
		|| e.classname == "monster_turret");
}

entity HGrunt_FindEnemy()
{
	if (self.spawnflags & SF_MONSTER_PRISONER) return world;

	entity head = findradius(self.origin, HGRUNT_SIGHT_RANGE);
	entity best = world;
	float bestDist = HGRUNT_SIGHT_RANGE + 1;
	while (head)
	{
		if (head != self && head.health > 0 && !(head.flags & FL_NOTARGET))
		{
			float isPlayer  = (head.flags & FL_CLIENT) != 0;
			float isFriend  = HGrunt_IsFriend(head);
			if (isPlayer || (!isFriend && (head.flags & FL_MONSTER)))
			{
				if (HGrunt_CanSee(head))
				{
					float d = vlen(head.origin - self.origin);
					if (d < bestDist) { best = head; bestDist = d; }
				}
			}
		}
		head = head.chain;
	}
	return best;
}

void HGrunt_Speak(string label)
{
	if (self.hgrunt_nextSpeech > time) return;
	if ((self.spawnflags & SF_MONSTER_GAG) && !self.enemy) return;
	Sentences_Play(self, CHAN_VOICE, label, 1.0, ATTN_NORM, 100);
	self.hgrunt_nextSpeech = time + HGRUNT_SPEECH_INTERVAL + random() * 4;
}

void HGrunt_SpeakForce(string label)
{
	if ((self.spawnflags & SF_MONSTER_GAG) && !self.enemy) return;
	Sentences_Play(self, CHAN_VOICE, label, 1.0, ATTN_NORM, 100);
	self.hgrunt_nextSpeech = time + HGRUNT_SPEECH_INTERVAL + random() * 4;
}

// Aim and fire
vector HGrunt_ShootOrigin()
{
	if (self.hgrunt_crouchAttack) return self.origin + '0 0 48';
	return self.origin + '0 0 60';
}

// Which firing pose to play: shotgun always stands; MP5 stands or crouches.
float HGrunt_AttackFrame()
{
	if (HGrunt_HasShotgun())      return HGRUNT_FR_STANDING_SHOTGUN;
	if (self.hgrunt_crouchAttack) return HGRUNT_FR_CROUCHING_MP5;
	return HGRUNT_FR_STANDING_MP5;
}

vector HGrunt_AimAt(entity tgt, float spread)
{
	vector shootOrigin = HGrunt_ShootOrigin();
	vector aim = tgt.origin + tgt.view_ofs - shootOrigin;
	aim = normalize(aim);
	makevectors(vectoangles(aim));
	aim = aim
		+ v_right * ((random() * 2 - 1) * spread)
		+ v_up    * ((random() * 2 - 1) * spread);
	return normalize(aim);
}

void HGrunt_PlayFireSnd()
{
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, 100, HGRUNT_FIRE1_SOUND, HGRUNT_FIRE2_SOUND);
}

void HGrunt_FireMP5()
{
	if (!self.enemy) return;
	vector aim = HGrunt_AimAt(self.enemy, HGRUNT_BULLET_SPREAD);
	vector shootOrigin = HGrunt_ShootOrigin();
	traceline(shootOrigin, shootOrigin + aim * 2048, FALSE, self);
	if (trace_fraction < 1.0 && trace_ent && trace_ent.takedamage != DAMAGE_NO)
		T_Damage(trace_ent, self, self, HGRUNT_BURST_DAMAGE, DMG_BULLET);
	HGrunt_PlayFireSnd();
	self.effects = self.effects | EF_MUZZLEFLASH;
	Monster_MuzzleEffects(self, aim, HGRUNT_GUN_LENGTH, HGRUNT_SHELL_MP5);
	self.hgrunt_clip = self.hgrunt_clip - 1;
}

void HGrunt_FireShotgun()
{
	if (!self.enemy) return;
	vector shootOrigin = HGrunt_ShootOrigin();
	vector baseAim = normalize(self.enemy.origin + self.enemy.view_ofs - shootOrigin);
	makevectors(vectoangles(baseAim));
	float i;
	for (i = 0; i < HGRUNT_SHOTGUN_PELLETS; i = i + 1)
	{
		vector aim = baseAim
			+ v_right * ((random() * 2 - 1) * HGRUNT_SHOTGUN_SPREAD)
			+ v_up    * ((random() * 2 - 1) * HGRUNT_SHOTGUN_SPREAD);
		aim = normalize(aim);
		traceline(shootOrigin, shootOrigin + aim * 2048, FALSE, self);
		if (trace_fraction < 1.0 && trace_ent && trace_ent.takedamage != DAMAGE_NO)
			T_Damage(trace_ent, self, self, HGRUNT_SHOTGUN_DAMAGE, DMG_BULLET);
	}
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HGRUNT_SHOTGUN_SOUND);
	self.effects = self.effects | EF_MUZZLEFLASH;
	Monster_MuzzleEffects(self, baseAim, HGRUNT_GUN_LENGTH + 4, HGRUNT_SHELL_SHOTGUN);
	self.hgrunt_clip = self.hgrunt_clip - 1;
}


//  - never grenade an airborne enemy above us (they'll be gone when it lands)
//  - never throw inside the 256u self-blast radius (2D)
float HGrunt_GrenadeOK(float dist)
{
	if (!self.enemy) return FALSE;
	if (dist < HGRUNT_GRENADE_RANGE || dist > HGRUNT_GRENADE_MAX_RANGE) return FALSE;
	if (!(self.enemy.flags & FL_ONGROUND) && self.enemy.waterlevel == 0
		&& self.hgrunt_lkp_z > self.absmax_z)
		return FALSE;
	vector to = self.hgrunt_lkp - self.origin;
	to_z = 0;
	if (vlen(to) <= HGRUNT_GRENADE_RANGE) return FALSE;
	return TRUE;
}

void HGrunt_ThrowHandGrenade()
{
	if (!self.enemy) return;

	vector aim = self.enemy.origin - self.origin;
	float dist = vlen(aim);
	if (dist < 1) return;

	makevectors(self.angles);
	vector src = self.origin + v_forward * 18 + '0 0 36';

	// Aim straight forward at ~45-deg pitch; scale speed with distance.
	vector dir;
	dir_x = (self.enemy.origin_x - src_x);
	dir_y = (self.enemy.origin_y - src_y);
	dir_z = 0;
	float horiz = vlen(dir);
	if (horiz < 1) horiz = 1;
	dir = normalize(dir);

	// Ballistic: pick speed so grenade arcs ~2.5s flight to enemy horiz dist.
	float speed = horiz / 1.5;
	if (speed < 400) speed = 400;
	if (speed > 1100) speed = 1100;

	vector vel = dir * speed + '0 0 1' * (speed * 0.6);

	HandGrenade_Create(self, src, vel, 3.0);
	Sound_Play(self, CHAN_WEAPON, 0.4, ATTN_NORM, PITCH_NORM, "weapons/explode3.wav");
	HGrunt_SpeakForce("HG_THROW");
}

void HGrunt_ContactGrenadeTouch()
{
	if (other == self.owner) return;
	HandGrenade_Explode();
}

void HGrunt_FireLauncher()
{
	if (!self.enemy) return;
	vector start = HGrunt_ShootOrigin();

	entity grenade = spawn();
	grenade.owner = self;
	grenade.movetype = MOVETYPE_BOUNCE;
	grenade.solid = SOLID_BBOX;
	grenade.classname = "grenade";
	setmodel(grenade, "models/w_grenade.iqm");
	setsize(grenade, '-1 -1 -1', '1 1 1');
	setorigin(grenade, start);

	// Target calculation: aim at LKP + enemy velocity * flight time
	vector target = self.hgrunt_lkp;
	if (HGrunt_CanSee(self.enemy))
		target = target + self.enemy.velocity
			* (vlen(target - self.origin) / HGRUNT_GRENADE_SPEED);

	vector to = target - start;
	vector flat = to;
	flat_z = 0;
	float horiz = vlen(flat);
	if (horiz < 1) horiz = 1;
	// Ballistic arc at fixed muzzle speed: aim flat at gspeed, add enough
	// vertical to cover drop over the flight time (g=800).
	float flightTime = horiz / HGRUNT_GRENADE_SPEED;
	float vz = (to_z / flightTime) + 0.5 * 800 * flightTime;
	grenade.velocity = normalize(flat) * HGRUNT_GRENADE_SPEED + '0 0 1' * vz;
	grenade.avelocity = '300 200 0';
	grenade.scale = 0.5;
	grenade.angles = vectoangles(grenade.velocity);
	grenade.touch = HGrunt_ContactGrenadeTouch;
	grenade.think = HandGrenade_Explode;    // fuse fallback if it never hits
	grenade.nextthink = time + 4;

	Sound_Play(self, CHAN_WEAPON, 0.8, ATTN_NORM, PITCH_NORM, HGRUNT_GLAUNCHER_SOUND);
	self.effects = self.effects | EF_MUZZLEFLASH;
	Monster_MuzzleEffects(self, normalize(to), HGRUNT_GUN_LENGTH, "");   // launcher: flash, no casing
	HGrunt_SpeakForce("HG_THROW");
}

// Melee kick
void HGrunt_KickHit()
{
	if (!self.enemy || self.enemy.health <= 0) return;

	// Use the shared forward-hull sweep (as zombie/islave/bullchicken do)
	// instead of a hand-rolled horizontal facing dot. The old check compared
	// normalize(enemy - origin) against a horizontal v_forward, so when the
	// target stood higher (staircase) the large z component pulled the dot below
	// decision kept re-entering melee, freezing the grunt swinging in place.
	// The hull sweep starts at view_ofs height and carries ±16 of vertical slack,
	// so a target a step or two up is still hit. (Deals the damage internally.)
	makevectors(self.angles);
	entity pHurt = Combat_CheckTraceHullAttack(HGRUNT_MELEE_RANGE, HGRUNT_MELEE_DAMAGE, DMG_CLUB);
	if (!pHurt) return;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HGRUNT_KICKHIT_SOUND);

	// Bunt whatever got kicked.
	if (pHurt.flags & FL_CLIENT)
	{
		pHurt.velocity = pHurt.velocity + v_forward * 250 + '0 0 200';
		pHurt.flags = pHurt.flags - (pHurt.flags & FL_ONGROUND);
		pHurt.punchangle = '15 0 0';
	}
}

// Sidestep / strafe
// Start a sidestep. Enters the sustained HGCS_STRAFE substate (plays the
// strafe anim + steps sideways a little each tick) rather than the old single
// 48u pop with no animation. Returns TRUE if a strafe was started.
float HGrunt_TryStrafe()
{
	if (time < self.hgrunt_nextStrafe) return FALSE;

	makevectors(self.angles);
	float canRight = FALSE, canLeft = FALSE;
	traceline(self.origin, self.origin + v_right * (HGRUNT_STRAFE_DIST + 16), FALSE, self);
	if (trace_fraction == 1.0) canRight = TRUE;
	traceline(self.origin, self.origin - v_right * (HGRUNT_STRAFE_DIST + 16), FALSE, self);
	if (trace_fraction == 1.0) canLeft = TRUE;

	float dir = 0;
	if (canLeft && canRight) dir = (random() >= 0.5) ? 1 : -1;
	else if (canLeft)  dir = -1;
	else if (canRight) dir =  1;
	if (!dir) return FALSE;

	self.hgrunt_strafeDir   = dir;
	self.hgrunt_combatState = HGCS_STRAFE;
	self.hgrunt_subStateEnd = time + HGRUNT_STRAFE_TIME;
	self.hgrunt_nextStrafe  = time + HGRUNT_STRAFE_INTERVAL + random() * 1.5;
	HGrunt_PlayFrame(dir > 0 ? HGRUNT_FR_STRAFERIGHT : HGRUNT_FR_STRAFELEFT);
	self.frame1time = time;
	return TRUE;
}

// Grenade fear
// Nearest live grenade (not our own) close enough to hurt and with a clear
// blast path to us; world if none. No CSoundEnt in this port, so we sense the
// grenade entity directly (classname "grenade", .owner = thrower, .nextthink =
// absolute detonation time). LOS-gated so we don't flee grenades walled off
// from us (T_RadiusDamage can't hurt through solid world anyway).
entity HGrunt_SenseGrenade()
{
	entity g = findradius(self.origin, HGRUNT_GRENADE_FEAR_RAD);
	while (g)
	{
		if (g.classname == "grenade" && g.owner != self && g.nextthink > time)
		{
			traceline(self.origin + self.view_ofs, g.origin, TRUE, self);
			if (trace_fraction >= 1.0 || trace_ent == g)
				return g;
		}
		g = g.chain;
	}
	return world;
}

// Run away from a danger point (grenade). Drives with movetogoal toward a temp
// (SV_NewChaseDir) dodges walls and steps up obstacles, unlike a blind walkmove
// which just grinds into geometry (and could stall even on open ground).
void HGrunt_FleeAway(vector danger)
{
	vector away = self.origin - danger;
	away_z = 0;
	if (vlen(away) < 1)
	{
		makevectors(self.angles);
		away = v_forward;
	}
	away = normalize(away);

	if (!self.hgrunt_fleeMarker)
	{
		entity mk = spawn();
		mk.classname = "hgrunt_fleemarker";
		mk.solid     = SOLID_NOT;
		mk.movetype  = MOVETYPE_NONE;
		mk.owner     = self;
		self.hgrunt_fleeMarker = mk;
	}
	setorigin(self.hgrunt_fleeMarker, self.origin + away * 256);
	self.goalentity = self.hgrunt_fleeMarker;
	self.ideal_yaw  = vectoyaw(away);
	ChangeYaw();
	movetogoal(HGRUNT_RUN_STEP);
}

void HGrunt_EnterFlee(entity gren)
{
	self.hgrunt_combatState = HGCS_FLEE;
	self.hgrunt_subStateEnd = time + 1.2;      // commit to running for a beat
	self.hgrunt_fleeFrom    = gren.origin;
	self.monster_movementGoal     = MOVEGOAL_NONE;   // straight run-away, not node routing
	HGrunt_SpeakForce("HG_GREN");
}

// State entry helpers
void HGrunt_Combat();
void HGrunt_Stand();

void HGrunt_EnterReload()
{
	self.hgrunt_combatState = HGCS_RELOAD;
	self.hgrunt_subStateEnd = time + 2.5;
	HGrunt_PlayFrame(HGRUNT_FR_RELOAD_MP5);
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, HGRUNT_RELOAD_SOUND);
	HGrunt_SpeakForce("HG_COVER");
	// Grunts retreat to cover while reloading. Find a node hidden from
	// the enemy and route there (driven by the HGCS_RELOAD substate below).
	Monster_TakeCover(self.enemy);
}

void HGrunt_EnterGrenade()
{
	self.hgrunt_combatState = HGCS_GRENADE;
	self.hgrunt_subStateEnd = time + 1.0;
	self.hgrunt_actTime     = time + 0.6;   // release grenade partway through
	HGrunt_PlayFrame(HGRUNT_FR_THROWGRENADE);
}

void HGrunt_EnterLauncher()
{
	self.hgrunt_combatState = HGCS_LAUNCHER;
	self.hgrunt_subStateEnd = time + 0.9;
	self.hgrunt_actTime     = time + 0.45;
	HGrunt_PlayFrame(HGRUNT_FR_LAUNCHGRENADE);
}

void HGrunt_EnterMelee()
{
	self.hgrunt_combatState = HGCS_MELEE;
	self.hgrunt_subStateEnd = time + 0.7;
	self.hgrunt_actTime     = time + 0.35;  // kick connects mid-swing
	HGrunt_PlayFrame(HGRUNT_FR_FRONTKICK);
	self.frame1time = time;                 // restart the swing even on back-to-back
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, HGRUNT_KICK_SOUND);
}

void HGrunt_EnterAttack()
{
	self.hgrunt_combatState = HGCS_ATTACK;
	self.hgrunt_burstShots  = 0;
	// Vary the burst length so it isn't a robotic 3 every time (2..6 rounds).
	self.hgrunt_burstTarget = 2 + floor(random() * 5);
	// Occasionally crouch to fire (MP5 only; shotgun always stands).
	self.hgrunt_crouchAttack = (!HGrunt_HasShotgun() && random() < 0.4);
	HGrunt_PlayFrame(HGrunt_AttackFrame());
}

void HGrunt_EnterRun()
{
	self.hgrunt_combatState = HGCS_RUN;
	HGrunt_PlayFrame(HGrunt_IsLimping() ? HGRUNT_FR_LIMPRUN : HGRUNT_FR_RUN);
}

// Decision: pick a combat substate to enter given the current view of the world
void HGrunt_PickAttack(float canSee, float dist)
{
	if (self.hgrunt_clip <= 0) { HGrunt_EnterReload(); return; }

	// Melee at point blank.
	if (dist <= HGRUNT_MELEE_RANGE && canSee) { HGrunt_EnterMelee(); return; }

	// Grenade decision when out of LOS or mid/long distance. Feasibility
	// gates (airborne enemy, self-blast radius)
	float grenadeChance = 0;
	if (HGrunt_HasLauncher() && time >= self.hgrunt_nextGrenade && HGrunt_GrenadeOK(dist))
	{
		grenadeChance = (!canSee) ? 0.6 : 0.25;
		if (random() < grenadeChance)
		{
			HGrunt_EnterLauncher();
			self.hgrunt_nextGrenade = time + HGRUNT_GRENADE_COOLDOWN;
			return;
		}
	}
	if (HGrunt_HasHandGrn() && time >= self.hgrunt_nextGrenade && HGrunt_GrenadeOK(dist))
	{
		grenadeChance = (!canSee) ? 0.55 : 0.18;
		if (random() < grenadeChance)
		{
			HGrunt_EnterGrenade();
			self.hgrunt_nextGrenade = time + HGRUNT_GRENADE_COOLDOWN;
			return;
		}
	}

	// Only open fire when actually facing the enemy (flDot >= 0.5).
	makevectors(self.angles);
	vector toEnemy = self.enemy.origin - self.origin;
	toEnemy_z = 0;
	if (vlen(toEnemy) > 1 && normalize(toEnemy) * v_forward < HGRUNT_ATTACK_DOT)
	{
		// already ran this tick) instead of idling, so it reads as tracking.
		HGrunt_PlayFrame(HGrunt_HasShotgun() ? HGRUNT_FR_STANDING_SHOTGUN : HGRUNT_FR_STANDING_MP5);
		return;
	}

	// Occasionally sidestep before firing. TryStrafe enters HGCS_STRAFE, so
	if (canSee && time >= self.hgrunt_nextStrafe && random() < 0.25)
	{
		if (HGrunt_TryStrafe())
		{
			HGrunt_SpeakForce("HG_TAUNT");
			return;
		}
	}

	HGrunt_EnterAttack();
}

// Combat tick
void HGrunt_FaceEnemy()
{
	if (!self.enemy) return;
	vector to = self.enemy.origin - self.origin;
	to_z = 0;
	if (vlen(to) > 1)
	{
		self.ideal_yaw = vectoyaw(normalize(to));
		ChangeYaw();
	}
}

void HGrunt_Combat()
{
	if (Monster_YieldIfDead()) return;
	// Schedule FIRST: if the body kills us (own blast, trigger_hurt during
	// movetogoal), th_die installs the death chain afterwards and wins.
	self.think     = HGrunt_Combat;
	self.nextthink = time + 0.1;

	if (self.monster_cine && self.monster_cine != world)
	{
		self.think = HGrunt_Combat;
		self.nextthink = time + 0.2;
		return;
	}
	if (Monster_IsBarnacled())
	{
		self.think = HGrunt_Combat;
		self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
		Monster_BarnacledThink();
		return;
	}

	// re-acquired instead of meleeing in place (recovers a grunt already wedged
	// into self-target by a self/friendly grenade blast).
	if (self.enemy == self || (self.enemy && HGrunt_IsFriend(self.enemy)))
		self.enemy = world;

	if (!self.enemy || self.enemy.health <= 0)
	{
		self.enemy = HGrunt_FindEnemy();
		if (!self.enemy)
		{
			self.hgrunt_combatState = HGCS_RUN;
			self.think     = HGrunt_Stand;
			self.nextthink = time + 0.1;
			return;
		}
	}

	self.monster_state = MONSTERSTATE_COMBAT;
	// While following a node route, let movetogoal handle yaw (prevents unnatural turning/grinding).
	if (self.monster_movementGoal != MOVEGOAL_NODE)
		HGrunt_FaceEnemy();

	float canSee = HGrunt_CanSee(self.enemy);
	float dist   = vlen(self.enemy.origin - self.origin);
	if (canSee) self.hgrunt_lkp = self.enemy.origin;

	float s = self.hgrunt_combatState;

	// Grenade fear: top priority, interrupts EVERY other state (
	//     SCHED_TAKE_COVER_FROM_BEST_SOUND). The moment a live grenade we didn't
	if (s != HGCS_FLEE)
	{
		entity gren = HGrunt_SenseGrenade();
		if (gren != world)
		{
			HGrunt_EnterFlee(gren);
			return;
		}
	}

	if (s == HGCS_FLEE)
	{
		HGrunt_PlayFrame(HGrunt_IsLimping() ? HGRUNT_FR_LIMPRUN : HGRUNT_FR_RUN);
		// after we start fleeing, the grunt runs toward where the grenade actually landed (behind him).
		// grunt run toward where the grenade actually landed (behind him).
		gren = HGrunt_SenseGrenade();
		if (gren != world) self.hgrunt_fleeFrom = gren.origin;
		HGrunt_FleeAway(self.hgrunt_fleeFrom);
		// Leave once committed for a beat AND no live grenade remains.
		if (time >= self.hgrunt_subStateEnd && gren == world)
			self.hgrunt_combatState = HGCS_RUN;
		return;
	}

	if (s == HGCS_STRAFE)
	{
		// Sidestep while facing the enemy (HGrunt_FaceEnemy ran above), stepping
		// a little each tick so it reads as a strafe, not a teleport.
		HGrunt_PlayFrame(self.hgrunt_strafeDir > 0 ? HGRUNT_FR_STRAFERIGHT : HGRUNT_FR_STRAFELEFT);
		makevectors(self.angles);
		// Blocked mid-strafe (wall, crate, ledge)? Flip direction instead of moonwalking in place.
		// moonwalking in place against the obstacle for the whole substate.
		if (!walkmove(self.angles_y + (self.hgrunt_strafeDir > 0 ? 270 : 90), HGRUNT_STRAFE_STEP))
			self.hgrunt_strafeDir = -self.hgrunt_strafeDir;

		// Keep firing at the enemy while dodging, if it's visible and we have ammo.
		if (canSee && self.hgrunt_clip > 0 && time >= self.hgrunt_nextAttack)
		{
			if (HGrunt_HasShotgun())
			{
				HGrunt_FireShotgun();
				self.hgrunt_nextAttack = time + HGRUNT_SHOTGUN_COOLDOWN;
			}
			else
			{
				HGrunt_FireMP5();
				self.hgrunt_nextAttack = time + HGRUNT_BURST_DELAY;
			}
		}

		if (time >= self.hgrunt_subStateEnd)
			self.hgrunt_combatState = HGCS_RUN;
		return;
	}
	if (s == HGCS_RELOAD)
	{
		// Move to cover if a route was found, otherwise cower in place.
		if (self.monster_movementGoal == MOVEGOAL_NODE)
		{
			HGrunt_PlayFrame(HGrunt_IsLimping() ? HGRUNT_FR_LIMPRUN : HGRUNT_FR_RUN);
			// is briefly visible (the destination node breaks LOS).
			self.goalentity = world;
			Monster_AdvanceRoute(8);
		}
		else
		{
			HGrunt_PlayFrame(HGRUNT_FR_RELOAD_MP5);
		}
		if (time >= self.hgrunt_subStateEnd)
		{
			self.hgrunt_clip = HGrunt_ClipMax();
			self.hgrunt_combatState = HGCS_RUN;
			self.monster_movementGoal = MOVEGOAL_NONE;   // done reloading: stop routing
		}
		return;
	}
	if (s == HGCS_GRENADE)
	{
		HGrunt_PlayFrame(HGRUNT_FR_THROWGRENADE);
		// unreliable at 10Hz and silently drops the throw).
		if (self.hgrunt_actTime && time >= self.hgrunt_actTime)
		{
			HGrunt_ThrowHandGrenade();
			self.hgrunt_actTime = 0;
		}
		if (time >= self.hgrunt_subStateEnd)
		{
			self.hgrunt_combatState = HGCS_RUN;
		}
		return;
	}
	if (s == HGCS_LAUNCHER)
	{
		HGrunt_PlayFrame(HGRUNT_FR_LAUNCHGRENADE);
		if (self.hgrunt_actTime && time >= self.hgrunt_actTime)
		{
			HGrunt_FireLauncher();
			self.hgrunt_actTime = 0;
		}
		if (time >= self.hgrunt_subStateEnd)
		{
			self.hgrunt_combatState = HGCS_RUN;
		}
		return;
	}
	if (s == HGCS_MELEE)
	{
		HGrunt_PlayFrame(HGRUNT_FR_FRONTKICK);
		if (self.hgrunt_actTime && time >= self.hgrunt_actTime)
		{
			HGrunt_KickHit();
			self.hgrunt_actTime = 0;
		}
		if (time >= self.hgrunt_subStateEnd)
			self.hgrunt_combatState = HGCS_RUN;
		return;
	}

	if (s == HGCS_ATTACK)
	{
		HGrunt_PlayFrame(HGrunt_AttackFrame());

		if (!canSee || self.hgrunt_clip <= 0)
		{
			self.hgrunt_crouchAttack = FALSE;
			self.hgrunt_combatState = HGCS_RUN;
			return;
		}

		if (time >= self.hgrunt_nextAttack)
		{
			if (HGrunt_HasShotgun())
			{
				HGrunt_FireShotgun();
				self.hgrunt_nextAttack = time + HGRUNT_SHOTGUN_COOLDOWN;
				self.hgrunt_burstShots = 0;
				self.hgrunt_combatState = HGCS_RUN;   // pause and re-decide
			}
			else
			{
				HGrunt_FireMP5();
				self.hgrunt_burstShots = self.hgrunt_burstShots + 1;
				if (self.hgrunt_burstShots >= self.hgrunt_burstTarget)
				{
					self.hgrunt_burstShots = 0;
					self.hgrunt_crouchAttack = FALSE;
					self.hgrunt_nextAttack = time + HGRUNT_ATTACK_COOLDOWN;
					self.hgrunt_combatState = HGCS_RUN;  // re-decide next tick
					if (random() < 0.3) HGrunt_SpeakForce("HG_TAUNT");
				}
				else
				{
					self.hgrunt_nextAttack = time + HGRUNT_BURST_DELAY;
				}
			}
		}

		return;
	}


	// cooldown (hgrunt_nextAttack). Melee used to live only inside
	// HGrunt_PickAttack, which is gated behind that cooldown, so during a 1.5s
	// post-burst cooldown the grunt charged into the player instead of kicking.
	// Kick the instant the enemy is in melee range.
	if (canSee && dist <= HGRUNT_MELEE_RANGE)
	{
		HGrunt_EnterMelee();
		return;
	}

	if (self.hgrunt_clip <= 0)
	{
		HGrunt_EnterReload();
		return;
	}

	// instead of running dry mid-firefight (approximates SCHED_GRUNT_COVER_AND_RELOAD).
	if (!canSee && self.hgrunt_clip <= HGRUNT_RELOAD_LOW
		&& self.hgrunt_clip < HGrunt_ClipMax())
	{
		HGrunt_EnterReload();
		return;
	}

	// (steering toward the route node), so HGrunt_FaceEnemy is skipped this tick. Shooting logic must be skipped while routing.
	// tick. Do NOT try to shoot while routing: the grunt is facing the route
	// node, not the enemy, so PickAttack's facing check would fail every tick
	// and deadlock it in the aim pose forever (never advancing the route, never
	// turning). AdvanceRoute self-abandons once it can walk straight to the
	// enemy, and normal combat resumes.
	if (self.monster_movementGoal == MOVEGOAL_NODE)
	{
		HGrunt_PlayFrame(HGrunt_IsLimping() ? HGRUNT_FR_LIMPRUN : HGRUNT_FR_RUN);
		self.goalentity = self.enemy;
		Monster_AdvanceRoute(HGRUNT_RUN_STEP);
		return;
	}

	// Stop and fire when the fire cooldown is up and we have LOS.
	if (canSee && dist <= HGRUNT_ATTACK_RANGE && time >= self.hgrunt_nextAttack)
	{
		HGrunt_PickAttack(canSee, dist);
		return;
	}

	// Otherwise ADVANCE on the enemy (or its last-known position). Melee takes over at point-blank.
	//     between bursts is what makes the grunt read as aggressive instead of
	//     planted; melee (checked above) takes over at point-blank so it never
	HGrunt_PlayFrame(HGrunt_IsLimping() ? HGRUNT_FR_LIMPRUN : HGRUNT_FR_RUN);
	vector goal = canSee ? self.enemy.origin : self.hgrunt_lkp;
	vector to = goal - self.origin;
	to_z = 0;
	if (vlen(to) > 1)
	{
		self.ideal_yaw = vectoyaw(normalize(to));
		ChangeYaw();
		self.goalentity = self.enemy;
		if (!Monster_SlideStep(HGRUNT_RUN_STEP))   // wall slide owns the think when active
		{
			movetogoal(HGRUNT_RUN_STEP);
			Monster_StuckCheck(HGRUNT_RUN_STEP);
		}
	}

	// While closing without LOS, sometimes lob a grenade over cover.
	if (!canSee && HGrunt_HasHandGrn() && time >= self.hgrunt_nextGrenade
		&& HGrunt_GrenadeOK(dist) && random() < 0.05)
	{
		HGrunt_EnterGrenade();
		self.hgrunt_nextGrenade = time + HGRUNT_GRENADE_COOLDOWN;
	}

	if (random() < 0.02) HGrunt_Speak("HG_CHARGE");

}

// Stand / Walk
void HGrunt_Stand()
{
	if (Monster_YieldIfDead()) return;
	if (self.monster_cine && self.monster_cine != world)
	{
		self.think = HGrunt_Stand;
		self.nextthink = time + 0.2;
		return;
	}
	if (Monster_IsBarnacled())
	{
		self.think = HGrunt_Stand;
		self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
		Monster_BarnacledThink();
		return;
	}

	HGrunt_PlayFrame(HGRUNT_FR_IDLE1);
	self.monster_state = MONSTERSTATE_IDLE;

	entity threat = HGrunt_FindEnemy();
	if (threat)
	{
		self.enemy = threat;
		self.hgrunt_lkp = threat.origin;
		HGrunt_SpeakForce("HG_ALERT");
		self.hgrunt_combatState = HGCS_RUN;
		self.think     = HGrunt_Combat;
		self.nextthink = time + 0.1;
		return;
	}

	if (random() < 0.04) HGrunt_Speak("HG_IDLE");
	if (random() < 0.01) HGrunt_Speak("HG_QUEST");

	self.think     = HGrunt_Stand;
	self.nextthink = time + 0.3;
}

void HGrunt_Walk()
{
	if (Monster_YieldIfDead()) return;
	// Schedule FIRST so a mid-think death lets th_die win the think.
	self.think     = HGrunt_Walk;
	self.nextthink = time + 0.1;

	if (self.monster_cine && self.monster_cine != world)
	{
		self.think = HGrunt_Walk;
		self.nextthink = time + 0.2;
		return;
	}
	if (Monster_IsBarnacled())
	{
		self.think = HGrunt_Walk;
		self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
		Monster_BarnacledThink();
		return;
	}
	HGrunt_PlayFrame(HGrunt_IsLimping() ? HGRUNT_FR_LIMPWALK : HGRUNT_FR_WALK1);
	AI_Walk(8);
}

// Set TRUE while a grunt is rappelling down a rope (monster_grunt_repel).
// Suppresses the pain flinch + aggro-think hijack so a hit doesn't knock the
// grunt out of its scripted descent.
.float hgrunt_repelling;

void HGrunt_Pain(entity attacker, float damage)
{
	if (self.health <= 0 || self.deadflag != DEAD_NO) return;
	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us
	if (self.hgrunt_repelling) return;   // no flinch/think-swap while on the rope

	// Record damage direction (front/back) relative to grunt's facing.
	if (attacker && attacker != world)
	{
		makevectors(self.angles);
		vector to = normalize(attacker.origin - self.origin);
		self.hgrunt_lastDmgDir = (to * v_forward > 0) ? 1 : -1;
	}

	if (self.pain_finished > time) return;
	self.pain_finished = time + 0.6;
	HGrunt_PlayFrame(HGRUNT_FR_FLINCH);
	if (floor(random() * 7) < 5)	// 5 samples over 7 rolls: 2/7 of pain hits stay silent
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM,
			HGRUNT_PAIN_SOUND3, HGRUNT_PAIN_SOUND4, HGRUNT_PAIN_SOUND5,
			HGRUNT_PAIN_SOUND1, HGRUNT_PAIN_SOUND2);

	// pain handler sets self.enemy directly, bypassing FindEnemy/Look logic, so it needs its own gates.
	if (!(self.spawnflags & SF_MONSTER_PRISONER)
		&& attacker != self
		&& attacker.health > 0
		&& (attacker.flags & (FL_CLIENT | FL_MONSTER))
		&& !HGrunt_IsFriend(attacker))
	{
		self.enemy = attacker;
		self.hgrunt_lkp = attacker.origin;
		if (self.think != HGrunt_Combat)
		{
			self.hgrunt_combatState = HGCS_RUN;
			self.think = HGrunt_Combat;
			self.nextthink = time + 0.1;
		}
		// Heavy damage triggers an immediate strafe.
		if (damage >= 15 && time >= self.hgrunt_nextStrafe) HGrunt_TryStrafe();
	}
}

void HGrunt_TraceAttack(entity attacker, float flDamage, vector vecDir, float bitsDamageType)
{
	// Hit group inference from trace_endpos vs origin height.
	float zUp = trace_endpos_z - self.origin_z;
	if (zUp >= 56)      self.hgrunt_lastHitGroup = HITGROUP_HEAD;
	else if (zUp >= 32) self.hgrunt_lastHitGroup = HITGROUP_CHEST;
	else                self.hgrunt_lastHitGroup = HITGROUP_STOMACH;

	// Delegate to the standard blood/multi-damage pipeline.
	Monster_TraceAttack(attacker, flDamage, vecDir, bitsDamageType);
}

// Die

// plus ammo_ARgrenades if he carried the launcher. Velocities from GibMonster.
.float hgrunt_droppedGun;

void weapon_9mmAR();
void weapon_shotgun();
void ammo_ARgrenades();

void HGrunt_DropOne(void() spawnFn)
{
	entity item = spawn();
	entity oldself = self;
	self = item;
	spawnFn();
	self = oldself;

	setorigin(item, HGrunt_ShootOrigin());
	item.velocity_x = random(-100, 100);
	item.velocity_y = random(-100, 100);
	item.velocity_z = random(200, 300);
	item.avelocity_y = random(200, 400);
}

void HGrunt_DropGun()
{
	if (self.hgrunt_droppedGun) return;
	self.hgrunt_droppedGun = TRUE;

	// Gun submodel vanishes from the corpse
	Body_SetGroup(self, "weapons", HGRUNT_GUN_NONE);

	if (HGrunt_HasShotgun())
		HGrunt_DropOne(weapon_shotgun);
	else
		HGrunt_DropOne(weapon_9mmAR);

	if (HGrunt_HasLauncher())
		HGrunt_DropOne(ammo_ARgrenades);
}

void HGrunt_Die()
{
	Monster_ExitScriptedSequence();

	// Stops any in-flight combat sentences (HG_ALERT/TAUNT/...) that chain words via sentence_player think, preventing the corpse from talking after death.
	Sentences_Stop(self, CHAN_VOICE);

	if (self.hgrunt_fleeMarker) { remove(self.hgrunt_fleeMarker); self.hgrunt_fleeMarker = world; }

	HGrunt_DropGun();

	if (Gib_ShouldGib()) { Gib(); return; }

	self.takedamage  = DAMAGE_NO;
	self.solid       = SOLID_CORPSE;
	self.movetype    = MOVETYPE_TOSS;
	self.deadflag    = DEAD_DEAD;
	self.use         = SUB_Null;
	self.usehl       = __NULL__;
	self.object_caps = 0;
	self.flags       = self.flags - (self.flags & FL_MONSTER);
	setsize(self, '-16 -16 -16', '16 16 0');
	
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM,
		HGRUNT_DIE_SOUND1, HGRUNT_DIE_SOUND2, HGRUNT_DIE_SOUND3);

	// Pick death anim by hitgroup + damage direction.
	float dieFrame;
	if (self.hgrunt_lastHitGroup == HITGROUP_HEAD)
		dieFrame = HGRUNT_FR_DIEHEADSHOT;
	else if (self.hgrunt_lastHitGroup == HITGROUP_STOMACH)
		dieFrame = HGRUNT_FR_DIEGUTSHOT;
	else if (self.hgrunt_lastDmgDir == -1)
		dieFrame = HGRUNT_FR_DIEBACKWARDS;
	else if (self.hgrunt_lastDmgDir == 1)
		dieFrame = HGRUNT_FR_DIEFORWARD;
	else
		dieFrame = HGRUNT_FR_DIESIMPLE;

	HGrunt_PlayFrame(dieFrame);

	self.enemy      = world;
	self.oldenemy   = world;
	self.goalentity = world;
	self.movetarget = world;
	self.think     = SUB_Null;
	self.nextthink = -1;
}

// Sight sound (used by ai's FoundTarget)
void HGrunt_SightSound()
{
	HGrunt_SpeakForce("HG_ALERT");
}

void monster_human_grunt()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	HGrunt_Precache();

	setmodel(self, HGRUNT_MODEL);
	setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

	self.solid     = SOLID_SLIDEBOX;
	self.movetype  = MOVETYPE_STEP;
	self.health    = HGRUNT_HEALTH;
	self.max_health = self.health;
	self.yaw_speed = YAW_HL(150);	// Sets yaw speed for idle/run actions
	self.view_ofs  = '0 0 50';

	self.monster_state      = MONSTERSTATE_IDLE;
	self.monster_idealState = MONSTERSTATE_IDLE;
	self.monster_bloodColor        = BLOOD_COLOR_RED;
	self.monster_fieldOfView     = HGRUNT_FOV;
	self.flags               = self.flags | FL_MONSTER;

	// Default weapon mix if `.weapons` not set by map: MP5 + handgrenades.
	if (!self.weapons) self.weapons = HGRUNT_W_MP5 | HGRUNT_W_HANDGRENADE;

	// Determines weapon/skin setup: shotgun grunts get shotgun/head; M203 grunts get M203 head and are dark-skinned; others are 80/20 light/dark.
	self.skinFamily = (random() < 0.8) ? 0 : 1;
	if (HGrunt_HasShotgun())
	{
		Body_SetGroup(self, "weapons", HGRUNT_GUN_SHOTGUN);
		Body_SetGroup(self, "heads",   HGRUNT_HEAD_SHOTGUN);
	}
	else if (HGrunt_HasLauncher())
	{
		Body_SetGroup(self, "heads", HGRUNT_HEAD_M203);
		self.skinFamily = 1;
	}
	Body_Apply(self);

	self.frameByName = HGrunt_FrameByName;

	self.th_stand = HGrunt_Stand;
	self.th_walk  = HGrunt_Walk;
	self.th_run   = HGrunt_Combat;
	self.th_pain  = HGrunt_Pain;
	self.th_die   = HGrunt_Die;
	self.sightSound = HGrunt_SightSound;

	Monster_InitTakeDamage();
	self.traceAttack = HGrunt_TraceAttack;

	self.hgrunt_clip          = HGrunt_ClipMax();
	self.hgrunt_combatState   = HGCS_RUN;
	self.hgrunt_nextStrafe    = time + 1;

	self.think     = HGrunt_Stand;
	self.nextthink = time + 0.1 + random() * 0.5;
	total_monsters = total_monsters + 1;

	HGrunt_PlayFrame(HGRUNT_FR_IDLE1);
}
