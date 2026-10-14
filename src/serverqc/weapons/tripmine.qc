
//Settings
#define TRIPMINE_DAMAGE			Skill_GetValue("sk_plr_tripmine", 150)
#define TRIPMINE_RADIUS			250
#define TRIPMINE_MAX_CARRY		5
#define TRIPMINE_PLACE_RANGE	128			// how far forward the player traces to place
#define TRIPMINE_BEAM_RANGE		2048		// how far the laser beam extends
#define TRIPMINE_POWERUP_TIME	2.5			// delay before the beam arms
#define TRIPMINE_THINK_RATE		0.1
#define TRIPMINE_BREAK_TOLERANCE 2
#define TRIPMINE_PLACE_DELAY	0.3			// cooldown between placements

//Models
#define TRIPMINE_VIEW_MODEL		"models/v_tripmine.iqm"
#define TRIPMINE_WORLD_MODEL	"models/w_tripmine.iqm"

//Anims (matches Half-Life tripmine_e)
#define TRIPMINE_IDLE1			0
#define TRIPMINE_IDLE2			1
#define TRIPMINE_ARM1			2
#define TRIPMINE_ARM2			3
#define TRIPMINE_FIDGET			4
#define TRIPMINE_HOLSTER_ANIM	5
#define TRIPMINE_DRAW			6
#define TRIPMINE_WORLD			7
#define TRIPMINE_GROUND			8

//Sounds
#define TRIPMINE_DEPLOY_SOUND	"weapons/mine_deploy.wav"
#define TRIPMINE_CHARGE_SOUND	"weapons/mine_charge.wav"
#define TRIPMINE_ACTIVATE_SOUND	"weapons/mine_activate.wav"

#define TRIPMINE_AMMO ammoTripmines
.float tripmine_pickup;

// Mine-entity-only fields
.float   tripmine_powerupAt;       // time when powerup finishes
.vector  tripmine_beamDir;         // cached beam forward
.vector  tripmine_beamEnd;         // cached initial beam endpoint (world space)

// Tripmine projectile (wall-mounted charge)
void Tripmine_Explode()
{
	if (self.spent_token) Spent_Mark(self);

	T_RadiusDamage(self, self.owner, TRIPMINE_DAMAGE, TRIPMINE_RADIUS, DMG_BLAST | DMG_ALWAYSGIB);
	te_explosion(self.origin);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(3500), PITCH_NORM, "weapons/explode3.wav");
	self.think = SUB_Remove;
	self.nextthink = time + 0.1;
	// remove(self);
}

// Beam break detection: retraces along the saved beam and detonates if the
// endpoint moved (something entered the beam or the wall behind it shifted).
void Tripmine_BeamBreakThink()
{
	traceline(self.origin, self.origin + self.tripmine_beamDir * TRIPMINE_BEAM_RANGE, FALSE, world);
	te_beam(self, self.origin, trace_endpos);
	vector delta = trace_endpos - self.tripmine_beamEnd;
	if (vlen(delta) > TRIPMINE_BREAK_TOLERANCE)
	{
		Tripmine_Explode();
		return;
	}

	self.think = Tripmine_BeamBreakThink;
	self.nextthink = time + TRIPMINE_THINK_RATE;
}

// Powerup phase: after TRIPMINE_POWERUP_TIME, arm the beam and start checking
// for breaks. Until then the mine is non-solid and silently tolerates touches.
void Tripmine_PowerupThink()
{
	if (time < self.tripmine_powerupAt)
	{
		self.nextthink = time + TRIPMINE_THINK_RATE;
		return;
	}

	// Trace the beam now to lock in its initial endpoint.
	traceline(self.origin, self.origin + self.tripmine_beamDir * TRIPMINE_BEAM_RANGE, FALSE, world);
	self.tripmine_beamEnd = trace_endpos;

	self.solid = SOLID_BBOX;
	setorigin(self, self.origin);              // re-link after solidifying
	Sound_Play(self, CHAN_VOICE, 0.5, ATTN_NORM, PITCH_NORM, TRIPMINE_ACTIVATE_SOUND);
	self.think = Tripmine_BeamBreakThink;
	self.nextthink = time + TRIPMINE_THINK_RATE;
}

// Any damage from outside detonates an armed mine immediately. A powering-up
void Tripmine_Pain(entity attacker, float damage)
{
	if (self.solid != SOLID_BBOX)
	{
		remove(self);
		return;
	}
	Tripmine_Explode();
}

void Tripmine_Create(entity creator, vector pos, vector normal)
{
	entity mine = spawn();
	mine.classname = "monster_tripmine";
	// mine.owner = creator;                  // must be world so engine doesn't skip placer in traces/touch
	mine.movetype = MOVETYPE_FLY;
	mine.solid = SOLID_NOT;              // non-solid during powerup
	setmodel(mine, TRIPMINE_WORLD_MODEL);
	setsize(mine, '-5 -5 -4', '5 5 4');
	setorigin(mine, pos);
	
	mine.angles = vectoangles(normal);
	mine.tripmine_beamDir = normal;
	mine.tripmine_powerupAt = time + TRIPMINE_POWERUP_TIME;
	mine.takedamage = DAMAGE_YES;
	mine.health = 1;
	mine.th_pain = Tripmine_Pain;
	mine.th_die = Tripmine_Explode;
	mine.think = Tripmine_PowerupThink;
	mine.nextthink = time + 0.2;

	Sound_Play(mine, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, TRIPMINE_DEPLOY_SOUND);
	Sound_Play(mine, CHAN_BODY, 0.2, ATTN_NORM, PITCH_NORM, TRIPMINE_CHARGE_SOUND);
}

void TRIPMINE_RetireOrSwitch()
{
	self.weapons = self.weapons & ~WEAPON_TRIPMINE;
	self.impulse = WID_CROWBAR;
}

void TRIPMINE_PrimaryAttack()
{
	if (self.TRIPMINE_AMMO <= 0) return;
	if (time < self.attack_finished) return;

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs;
	vector end = src + v_forward * TRIPMINE_PLACE_RANGE;
	traceline(src, end, FALSE, self);
	if (trace_fraction >= 1.0)
	{
		self.attack_finished = time + TRIPMINE_PLACE_DELAY;
		return;
	}

	// Use the surface normal to orient the mine. trace_plane_normal points outward from the hit surface.
	vector normal = trace_plane_normal;
	if (normal == '0 0 0') normal = v_forward * -1;

	vector pos = trace_endpos + normal * 8;
	Tripmine_Create(self, pos, normal);

	self.TRIPMINE_AMMO = self.TRIPMINE_AMMO - 1;
	self.currentammo = self.TRIPMINE_AMMO;
	Weapon_SetFrame(TRIPMINE_ARM1);
	self.attack_finished = time + TRIPMINE_PLACE_DELAY;

	if (self.TRIPMINE_AMMO <= 0)
	{
		self.think = TRIPMINE_RetireOrSwitch;
		self.nextthink = time + TRIPMINE_PLACE_DELAY;
	}
	else
	{
		self.think = Player_Think;
		self.nextthink = time + TRIPMINE_PLACE_DELAY;
	}
}

void TRIPMINE_SecondaryAttack()
{
}

void TRIPMINE_Reload()
{
}

void TRIPMINE_Switch()
{
	Weapon_SetFrame(TRIPMINE_DRAW);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void TRIPMINE_Select()
{
	if (!self.tripmine_pickup)
		self.tripmine_pickup = TRUE;

	self.currentClip = 0;
	self.currentammo = self.TRIPMINE_AMMO;
	self.weaponmodel = TRIPMINE_VIEW_MODEL;
	self.weaponSwitch = TRIPMINE_Switch;
	self.weaponAttack = TRIPMINE_PrimaryAttack;
	self.weaponAttack2 = TRIPMINE_SecondaryAttack;
	self.weaponReload = TRIPMINE_Reload;
	self.weaponSelect = TRIPMINE_Select;
}

void TRIPMINE_Precache()
{
	precache_model(TRIPMINE_VIEW_MODEL);
	precache_model(TRIPMINE_WORLD_MODEL);
	// precache_model(TRIPMINE_PLAYER_MODEL);

	precache_sound(TRIPMINE_DEPLOY_SOUND);
	precache_sound(TRIPMINE_CHARGE_SOUND);
	precache_sound(TRIPMINE_ACTIVATE_SOUND);
}
