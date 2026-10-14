
#define EGON_DAMAGE             Skill_GetValue("sk_plr_egon_wide", 15)      // damage per pulse (single player, wide mode)
#define EGON_AMMO_COST          1       // ammo per pulse (10/sec at 0.1s interval)
#define EGON_PULSE_INTERVAL     0.1
#define EGON_BEAM_RANGE         2048

#define EGON_VIEW_MODEL         "models/v_egon.iqm"
#define EGON_WORLD_MODEL        "models/w_egon.iqm"

// Anims (matches egon_e enum)
#define EGON_IDLE1				0
#define EGON_FIDGET1			1
#define EGON_ALTFIREON			2
#define EGON_ALTFIRECYCLE		3
#define EGON_ALTFIREOFF			4
#define EGON_FIRE1				5
#define EGON_FIRE2				6
#define EGON_FIRE3				7
#define EGON_FIRE4				8
#define EGON_DRAW				9
#define EGON_HOLSTER			10


#define EGON_SOUND_OFF          "weapons/egon_off1.wav"
#define EGON_SOUND_RUN          "weapons/egon_run3.wav"
#define EGON_SOUND_STARTUP      "weapons/egon_windup2.wav"

//Fire states
#define EGON_STATE_OFF          0
#define EGON_STATE_CHARGE       1

#define EGON_AMMO ammoUranium
.float egon_pickup;
.float egon_fireState;

void EGON_EndAttack();

void EGON_FireBeam()
{
	makevectors(self.v_angle + self.punchangle);
	vector viewmodel_ofs = v_forward * 5 + v_right * 1.6 + v_up * -3;
	vector src  = self.origin + self.view_ofs + viewmodel_ofs;
	vector dest = src + v_forward * EGON_BEAM_RANGE;

	traceline(src, dest, FALSE, self);
	te_lightning2(self, src, trace_endpos);
	if (trace_fraction != 1.0 && trace_ent.takedamage)
	{
		ClearMultiDamage();
		Combat_TraceAttack(EGON_DAMAGE, v_forward, DMG_ENERGYBEAM | DMG_ALWAYSGIB);
		ApplyMultiDamage();
	}
}

void EGON_FireThink()
{
	if (!self.egon_fireState)
		return;

	if (!self.button0 || self.waterlevel >= 3 || self.EGON_AMMO <= 0)
	{
		EGON_EndAttack();
		self.think     = Player_Think;
		self.nextthink = time + 0.01;
		return;
	}

	EGON_FireBeam();

	self.EGON_AMMO -= EGON_AMMO_COST;
	if (self.EGON_AMMO < 0) self.EGON_AMMO = 0;
	self.currentammo = self.EGON_AMMO;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, EGON_SOUND_RUN);

	self.think     = EGON_FireThink;
	self.nextthink = time + EGON_PULSE_INTERVAL;
}

void EGON_EndAttack()
{
	if (!self.egon_fireState)
		return;

	self.egon_fireState = EGON_STATE_OFF;
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, EGON_SOUND_OFF);
	Weapon_SetFrame(EGON_IDLE1);
	self.attack_finished = time + 0.5;
}

void EGON_PrimaryAttack()
{
	if (self.egon_fireState == EGON_STATE_CHARGE)
		return;  // think chain already running

	if (self.EGON_AMMO <= 0)
	{
		self.attack_finished = time + 0.25;
		return;
	}

	if (self.waterlevel >= 3)
	{
		self.attack_finished = time + 0.25;
		return;
	}

	self.egon_fireState = EGON_STATE_CHARGE;

	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, EGON_SOUND_STARTUP);
	Weapon_SetFrame(EGON_FIRE3);

	self.think     = EGON_FireThink;
	self.nextthink = time + 0.1;
}

void EGON_Reload()
{
}

void EGON_Switch()
{
	self.egon_fireState = EGON_STATE_OFF;
	Weapon_SetFrame(EGON_DRAW);
	self.reload          = TRUE;
	self.think           = Player_Think;
	self.nextthink       = time + 0.5;
}

void EGON_Select()
{
	if (!self.egon_pickup)
		self.egon_pickup = TRUE;

	self.egon_fireState = EGON_STATE_OFF;
	self.currentClip     = 0;
	self.currentammo     = self.EGON_AMMO;
	self.weaponmodel     = EGON_VIEW_MODEL;
	self.weaponSwitch    = EGON_Switch;
	self.weaponAttack    = EGON_PrimaryAttack;
	self.weaponAttack2   = EGON_Reload;
	self.weaponReload    = EGON_Reload;
	self.weaponSelect    = EGON_Select;
}

void EGON_Precache()
{
	precache_model(EGON_VIEW_MODEL);
	precache_model(EGON_WORLD_MODEL);

	precache_sound(EGON_SOUND_OFF);
	precache_sound(EGON_SOUND_RUN);
	precache_sound(EGON_SOUND_STARTUP);
}
