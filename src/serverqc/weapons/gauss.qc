
#define GAUSS_PRIMARY_DAMAGE	Skill_GetValue("sk_plr_gauss", 20)
#define GAUSS_MAX_CHARGE_DAMAGE	200
#define GAUSS_PRIMARY_COST		2		// ammo per primary shot
#define GAUSS_CHARGE_COST		1		// ammo per charge tick
#define GAUSS_PRIMARY_RATE		0.2
#define GAUSS_CHARGE_TICK		0.3		// ammo burn interval (singleplayer)
#define GAUSS_FULL_CHARGE_TIME	4.0		// seconds to reach full charge
#define GAUSS_OVERCHARGE_TIME	10.0
#define GAUSS_OVERCHARGE_DAMAGE	50
#define GAUSS_BEAM_RANGE		8192
#define GAUSS_MAX_BOUNCES		10
#define GAUSS_MAX_CARRY			100

#define GAUSS_VIEW_MODEL		"models/v_gauss.iqm"
#define GAUSS_WORLD_MODEL		"models/w_gauss.iqm"

// Animations (matches gauss_e enum)
#define GAUSS_IDLE				0
#define GAUSS_IDLE2				1
#define GAUSS_FIDGET			2
#define GAUSS_SPINUP			3
#define GAUSS_SPIN				4
#define GAUSS_FIRE				5
#define GAUSS_FIRE2				6
#define GAUSS_HOLSTER_ANIM		7
#define GAUSS_DRAW				8

#define GAUSS_FIRE_SOUND		"weapons/gauss2.wav"
#define GAUSS_ELECTRO4_SOUND	"weapons/electro4.wav"
#define GAUSS_ELECTRO5_SOUND	"weapons/electro5.wav"
#define GAUSS_ELECTRO6_SOUND	"weapons/electro6.wav"
#define GAUSS_CHARGE_SOUND		"ambience/pulsemachine.wav"

#define GAUSS_AMMO ammoUranium
.float gauss_pickup;

// Per-player charge state
.float gauss_charging;			// 0 = idle, 1 = spinup, 2 = spinning
.float gauss_chargeStart;		// time when charge began
.float gauss_nextBurn;		// next time we eat a round while charging
.float gauss_primaryFire;		// TRUE if this shot is primary (not charged)

float IsBSPModel( void ) { return trace_ent.solid == SOLID_BSP || trace_ent.movetype == MOVETYPE_PUSH; }
float ReflectGauss( void ) { return ( IsBSPModel() && !trace_ent.takedamage ); }
void SpawnBeam(vector src, vector dest)
{
	entity e = spawn();
	e.think = SUB_Remove;
	e.nextthink = time + 0.1;
	te_lightning3(e, src,dest);
}

void HotGlow_Think()
{
	if(self.alpha <= 0)
	{
		self.think = SUB_Remove;
	}
	self.alpha = self.alpha - 0.1;
	self.nextthink = time + 0.1;
}

void SpawnHotSpace(vector src)
{
	entity e = spawn();
	setmodel(e, "sprites/hotglow.spr");
	setorigin(e, src);
	e.effects = EF_ADDITIVE;
	e.alpha = 2;
	e.think = HotGlow_Think;
	e.nextthink = time + 0.1;
}

// and punching through steep ones (secondary only). Damages anything hit.
void Gauss_Fire(vector src, vector dir, float flDamage, float isPrimary)
{
	float nMaxHits = GAUSS_MAX_BOUNCES;
	float fHasPunched = FALSE;
	float fFirstBeam = TRUE;
	float nTotal = 0;
	float flMaxFrac = 1;
	vector dest = src + dir * GAUSS_BEAM_RANGE;

	makevectors(self.v_angle);
	vector viewmodel_ofs = v_forward * 15 + v_right * .6 + v_up * -1;

	while (flDamage > 10 && nMaxHits > 0)
	{
		nMaxHits--;

		traceline(src, dest, FALSE, self);

		// Snapshot trace globals IMMEDIATELY. Damage/think chains below may
		// call traceline internally and clobber these before we need them.
		entity  hit_ent    = trace_ent;
		vector  hit_pos    = trace_endpos;
		vector  hit_normal = trace_plane_normal;
		float   hit_frac   = trace_fraction;
		float   hit_solid  = trace_allsolid;
		vector  tr_endpos  = hit_pos;

		// Only offset the first segment to align with the gun barrel.
		// Reflected/punch-through segments start exactly at the bounce point.
		vector beam_src = fFirstBeam ? (src + viewmodel_ofs) : src;
		if (hit_frac >= 1.0)
		{
			SpawnBeam(beam_src, dest);
			break;
		}

		// Draw beam segment to hit point
		SpawnBeam(beam_src, hit_pos);

		if ( fFirstBeam )
		{
			self.effects |= EF_MUZZLEFLASH;
			fFirstBeam = FALSE;
			nTotal += 26;
		}

		if (hit_ent.takedamage)
		{
			ClearMultiDamage();
			if (hit_ent == self)
			{
				self.hitbox = 0;
			}
			Combat_TraceAttack(flDamage, dir, DMG_BULLET | DMG_ALWAYSGIB);
			ApplyMultiDamage();
		}

		// Reflection check uses snapshot, not live trace globals.
		
		if ((hit_ent.solid == SOLID_BSP || hit_ent.movetype == MOVETYPE_PUSH) && !hit_ent.takedamage)
		{
			
			float n;
			entity pentIgnore = world;
			n = -Math_DotProduct(hit_normal, dir);

			if (n < 0.5)
			{
				vector r;
				r = 2.0 * hit_normal * n + dir;
				flMaxFrac = flMaxFrac - hit_frac;
				dir = r;
				src = hit_pos + dir * 8;
				dest = src + dir * GAUSS_BEAM_RANGE;


				nTotal += 34;
				
				// lose energy
				if (n == 0) n = 0.1;
				flDamage = flDamage * (1 - n);
			}
			else
			{
				nTotal += 13;

				if (fHasPunched)
					break;
				fHasPunched = TRUE;

				if (!isPrimary)
				{
					traceline(hit_pos + dir * 8, dest, FALSE, pentIgnore);
					if (!trace_allsolid)
					{
						traceline(trace_endpos, tr_endpos, FALSE, pentIgnore);
						float n2 = vlen(trace_endpos - tr_endpos);
						if (n2 < flDamage)
						{
							SpawnHotSpace(hit_pos);
							if (n2 == 0) n2 = 1;
							flDamage -= n2;

							nTotal += 21;

							// T_RadiusDamage(trace_endpos + vecDir * 8, self,
							float damage_radius;
			
							if (IsMultiplayer())
							{
								damage_radius = flDamage * 1.75;
							}
							else
							{
								damage_radius = flDamage * 2.5;
							}


							nTotal += 53;

							src = trace_endpos + dir;
						}
					}
					else
					{
						flDamage = 0;
					}
				}
				else
				{
					flDamage = 0;
				}
			}
		}
		else
		{
			src = hit_pos + dir;
		}
		
	}
}

//
//
void GAUSS_PrimaryAttack()
{
	if (self.GAUSS_AMMO < GAUSS_PRIMARY_COST) return;
	if (time < self.attack_finished) return;

	// Can't fire underwater
	if (self.waterlevel >= 3)
	{
		self.attack_finished = time + 0.15;
		return;
	}

	self.GAUSS_AMMO -= GAUSS_PRIMARY_COST;
	self.currentammo = self.GAUSS_AMMO;

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, GAUSS_FIRE_SOUND);
	Weapon_SetFrame(GAUSS_FIRE);
	self.effects = self.effects | EF_MUZZLEFLASH;

	self.gauss_primaryFire = TRUE;
	Gauss_Fire(src, v_forward, GAUSS_PRIMARY_DAMAGE, TRUE);

	self.attack_finished = time + GAUSS_PRIMARY_RATE;
}

//
// Charging eats ammo over time. Overcharging zaps the player.
//
void GAUSS_ChargeThink();

void GAUSS_SecondaryRelease()
{
	if (!self.gauss_charging)
		return;

	// Calculate damage based on charge time
	float chargeTime = time - self.gauss_chargeStart;
	if (chargeTime > GAUSS_FULL_CHARGE_TIME)
		chargeTime = GAUSS_FULL_CHARGE_TIME;

	float flDamage = GAUSS_MAX_CHARGE_DAMAGE * (chargeTime / GAUSS_FULL_CHARGE_TIME);
	if (flDamage < 10) flDamage = 10;

	makevectors(self.v_angle + self.punchangle);
	vector src = self.origin + self.view_ofs;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, GAUSS_FIRE_SOUND);
	Weapon_SetFrame(GAUSS_FIRE2);
	self.effects = self.effects | EF_MUZZLEFLASH;

	self.velocity = self.velocity - v_forward * flDamage * 5;

	self.gauss_primaryFire = FALSE;
	Gauss_Fire(src, v_forward, flDamage, FALSE);

	self.gauss_charging = 0;
	self.attack_finished = time + 1.0;
}

void GAUSS_ChargeThink()
{
	if (!self.gauss_charging)
		return;

	// If player released fire2
	if (!self.button6)
	{
		GAUSS_SecondaryRelease();
		self.think = Player_Think;
		self.nextthink = time + 0.01;
		return;
	}

	if (self.waterlevel >= 3)
	{
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, GAUSS_ELECTRO4_SOUND);
		Weapon_SetFrame(GAUSS_IDLE);
		self.gauss_charging = 0;
		self.attack_finished = time + 0.5;
		self.think = Player_Think;
		self.nextthink = time + 0.01;
		return;
	}

	// Eat ammo periodically while charging
	if (time >= self.gauss_nextBurn && self.gauss_nextBurn != -1)
	{
		self.GAUSS_AMMO -= GAUSS_CHARGE_COST;
		self.currentammo = self.GAUSS_AMMO;
		self.gauss_nextBurn = time + GAUSS_CHARGE_TICK;
	}

	// Stop eating ammo once fully charged
	if (time - self.gauss_chargeStart >= GAUSS_FULL_CHARGE_TIME)
		self.gauss_nextBurn = -1;

	if (self.GAUSS_AMMO <= 0)
	{
		self.GAUSS_AMMO = 0;
		self.currentammo = 0;
		GAUSS_SecondaryRelease();
		self.think = Player_Think;
		self.nextthink = time + 0.01;
		return;
	}

	if (time - self.gauss_chargeStart > GAUSS_OVERCHARGE_TIME)
	{
		Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, GAUSS_ELECTRO4_SOUND);
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, GAUSS_ELECTRO6_SOUND);

		self.gauss_charging = 0;
		Weapon_SetFrame(GAUSS_IDLE);
		self.attack_finished = time + 1.0;

		// Hurt the player
		T_Damage(self, world, world, GAUSS_OVERCHARGE_DAMAGE, DMG_SHOCK);

		self.think = Player_Think;
		self.nextthink = time + 0.01;
		return;
	}

	// Transition from spinup to spin animation
	if (self.gauss_charging == 1)
	{
		if (time - self.gauss_chargeStart > 0.5)
		{
			Weapon_SetFrame(GAUSS_SPIN);	// gauss_charging 1 -> 2 makes this one-shot
			self.gauss_charging = 2;
		}
	}

	self.think = GAUSS_ChargeThink;
	self.nextthink = time + 0.1;
}

void GAUSS_SecondaryAttack()
{
	if (self.gauss_charging)
		return;		// already charging

	if (self.GAUSS_AMMO <= 0)
	{
		self.attack_finished = time + 0.5;
		return;
	}
	if (time < self.attack_finished) return;

	// Can't charge underwater
	if (self.waterlevel >= 3)
	{
		self.attack_finished = time + 0.5;
		return;
	}

	self.GAUSS_AMMO -= GAUSS_CHARGE_COST;
	self.currentammo = self.GAUSS_AMMO;

	self.gauss_charging = 1;
	self.gauss_chargeStart = time;
	self.gauss_nextBurn = time + GAUSS_CHARGE_TICK;

	Weapon_SetFrame(GAUSS_SPINUP);
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, GAUSS_CHARGE_SOUND);

	self.think = GAUSS_ChargeThink;
	self.nextthink = time + 0.1;
}

void GAUSS_Reload()
{
}

void GAUSS_Switch()
{
	// Cancel any active charge on holster
	if (self.gauss_charging)
	{
		self.gauss_charging = 0;
	}

	Weapon_SetFrame(GAUSS_DRAW);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void GAUSS_Select()
{
	if (!self.gauss_pickup)
		self.gauss_pickup = TRUE;

	self.currentClip = 0;
	self.currentammo = self.GAUSS_AMMO;
	self.weaponmodel = GAUSS_VIEW_MODEL;
	self.weaponSwitch = GAUSS_Switch;
	self.weaponAttack = GAUSS_PrimaryAttack;
	self.weaponAttack2 = GAUSS_SecondaryAttack;
	self.weaponReload = GAUSS_Reload;
	self.weaponSelect = GAUSS_Select;
}

void GAUSS_Precache()
{
	precache_model(GAUSS_VIEW_MODEL);
	precache_model(GAUSS_WORLD_MODEL);
	precache_model("sprites/hotglow.spr");

	precache_sound(GAUSS_FIRE_SOUND);
	precache_sound(GAUSS_ELECTRO4_SOUND);
	precache_sound(GAUSS_ELECTRO5_SOUND);
	precache_sound(GAUSS_ELECTRO6_SOUND);
	precache_sound(GAUSS_CHARGE_SOUND);
}
