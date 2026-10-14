
//Settings
#define PYTHON_DAMAGE			Skill_GetValue("sk_plr_357_bullet", 40)
#define PYTHON_MAX_CLIP			6
#define PYTHON_RATE				0.75
#define PYTHON_SEMI				FALSE
#define PYTHON_DISTANCE			8192
#define PYTHON_SOUND_RADIUS		2500
#define PYTHON_MUZZLE_POS		'145 -30 -30'
#define PYTHON_MUZZLE_SCALE		1

//Models
#define PYTHON_PLAYER_MODEL		""
#define PYTHON_VIEW_MODEL		"models/v_357.iqm"
#define PYTHON_WORLD_MODEL		"models/w_357.iqm"

//Anims
#define PYTHON_IDLE1 		0
#define PYTHON_FIDGET		1
#define PYTHON_FIRE1		2
#define PYTHON_RELOAD		3
#define PYTHON_HOLSTER		4
#define PYTHON_DRAW			5
#define PYTHON_IDLE2		6
#define PYTHON_IDLE3		7

//SOUNDS
#define PYTHON_FIRE_SOUND		"weapons/357_shot1.wav"
#define PYTHON_RELOAD_SOUND		"weapons/357_reload1.wav"
#define PYTHON_NOAMMO_SOUND		"weapons/357_cock1.wav"

#define PYTHON_AMMO ammo357
.float python_clip;
.float python_pickup;

void PYTHON_ReloadFinish()
{
	Weapon_Reload(PYTHON_AMMO, python_clip, PYTHON_MAX_CLIP, FALSE);
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void PYTHON_Reload()
{
	self.currentClip = self.python_clip;
	if(self.python_clip >= PYTHON_MAX_CLIP) return;
	if(self.PYTHON_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}
	Weapon_SetFrame(PYTHON_RELOAD);
	self.nextthink = time + 3.5;
	self.think = PYTHON_ReloadFinish;
	self.reload = TRUE;
	Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, PYTHON_RELOAD_SOUND);
}

void PYTHON_Fire(float flSpread, float flCycleTime, float fUseAutoAim)
{
	if(PYTHON_SEMI && self.ShootsFired != 0) return;
	
	if(self.PYTHON_AMMO <= 0 && self.python_clip <= 0)
	{
		self.attack_finished = time + 0.5;
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, PYTHON_NOAMMO_SOUND);
		// CycleWeaponReverseCommand();
		return;
	}
	
	if (self.python_clip <= 0) 
	{
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, PYTHON_NOAMMO_SOUND);
		self.attack_finished = time + 0.5;
		if (AUTORELOAD) self.impulse = 100;
		self.think = Player_Think;
		return;
	}                           


	self.python_clip = self.python_clip - 1;
	self.currentClip = self.python_clip;
	Weapon_SetFrame(PYTHON_FIRE1);
	pointparticles(particleeffectnum("supernailgun_muzzleflash"), self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 4, self.velocity * 50, 1);
	Weapon_Fire(Weapon_Spread('1000 1000 0' * flSpread), PYTHON_DISTANCE, PYTHON_DAMAGE);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(PYTHON_SOUND_RADIUS), PITCH_NORM, PYTHON_FIRE_SOUND);
	Weapon_Muzzleflash(PYTHON_MUZZLE_POS, PYTHON_MUZZLE_SCALE);
	self.attack_finished = time + flCycleTime;
	self.think = Player_Think;
	self.nextthink = time + flCycleTime;
};


void PYTHON_SecondaryAttack()
{
	if(!IsMultiplayer()) return;
	if(!self.viewzoom) self.viewzoom = 0.5;
	else self.viewzoom = 0;
	self.attack_finished = time + 0.5;
}

void PYTHON_PrimaryAttack()
{
	PYTHON_Fire(0.01, PYTHON_RATE, TRUE);
}

void PYTHON_Switch()
{
	Weapon_SetFrame(PYTHON_DRAW);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void PYTHON_Select()
{
	if(!self.python_pickup)
	{
		self.python_pickup = TRUE;
		self.python_clip = PYTHON_MAX_CLIP;
	}
	self.currentClip = self.python_clip;
	self.currentammo = self.PYTHON_AMMO;
	self.weaponmodel = PYTHON_VIEW_MODEL;
	self.weaponSwitch = PYTHON_Switch;
	self.weaponAttack = PYTHON_PrimaryAttack;
	self.weaponAttack2 = PYTHON_SecondaryAttack;
	self.weaponReload = PYTHON_Reload;
	self.weaponSelect = PYTHON_Select;
}

void PYTHON_Precache()
{
	precache_model(PYTHON_VIEW_MODEL);
	precache_model(PYTHON_PLAYER_MODEL);
	precache_model(PYTHON_WORLD_MODEL);
	
	precache_sound(PYTHON_FIRE_SOUND);
	precache_sound(PYTHON_RELOAD_SOUND);
	
}

