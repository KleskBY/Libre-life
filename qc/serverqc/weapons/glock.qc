
//Settings
#define GLOCK_DAMAGE			35
#define GLOCK_MAX_CLIP			17
#define GLOCK_RATE				0.11
#define GLOCK_SEMI				FALSE
#define GLOCK_DISTANCE			8192
#define GLOCK_SOUND_RADIUS		2500
#define GLOCK_MUZZLE_POS		'145 -30 -30'
#define GLOCK_SHELL_POS			'30 11 -10'
#define GLOCK_MUZZLE_SCALE		1

//Models
#define GLOCK_PLAYER_MODEL		"models/players/ussr_rifle.md3"
#define GLOCK_VIEW_MODEL		"models/v_9mmhandgun.iqm"
#define GLOCK_WORLD_MODEL		"models/w_9mmhandgun.iqm"
#define GLOCK_SHELL_MODEL		"models/shell.iqm"

//Anims
#define GLOCK_IDLE1				0
#define GLOCK_IDLE2				1
#define GLOCK_IDLE3				2
#define GLOCK_SHOOT				3
#define GLOCK_SHOOT_EMPTY		4
#define GLOCK_RELOAD			5
#define GLOCK_RELOAD_NOT_EMPTY	6
#define GLOCK_DRAW				7
#define GLOCK_HOLSTER			8
#define GLOCK_ADD_SILENCER		9

//SOUNDS
#define GLOCK_FIRE_SOUND		"weapons/pl_gun3.wav"
#define GLOCK_CLIPIN_SOUND		"weapons/ak74/clipin.wav"
#define GLOCK_CLIPOUT_SOUND		"weapons/ak74/clipout.wav"
#define GLOCK_SLIDE1_SOUND		"weapons/sniper/boltback.wav"
#define GLOCK_SLIDE2_SOUND		"weapons/sniper/boltrelease.wav"
#define GLOCK_RELOAD_SOUND		"weapons/357_reload1.wav"
#define GLOCK_NOAMMO_SOUND		"weapons/357_cock1.wav"

#define GLOCK_AMMO ammo9x19
.float GLOCK_CLIP;
.float GLOCK_PICKUP;

void GLOCK_ReloadFinish()
{
	Weapon_Reload(GLOCK_AMMO, GLOCK_CLIP, GLOCK_MAX_CLIP);
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void GLOCK_Reload()
{
	self.currentClip = self.GLOCK_CLIP;
	if(self.GLOCK_CLIP >= GLOCK_MAX_CLIP + 1) return;
	if(self.GLOCK_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}
	if(self.GLOCK_CLIP != 0) self.weaponframe = GLOCK_RELOAD_NOT_EMPTY;
	else self.weaponframe = GLOCK_RELOAD;
	self.nextthink = time + 1.5;
	self.think = GLOCK_ReloadFinish;
	self.reload = TRUE;
	sound(self, CHAN_ITEM, GLOCK_RELOAD_SOUND, 1, ATTN_NORM);
}

void GLOCK_Fire(float flSpread, float flCycleTime, float fUseAutoAim)
{
	if(GLOCK_SEMI && self.ShootsFired != 0) return;
	
	if(self.GLOCK_AMMO <= 0 && self.GLOCK_CLIP <= 0)
	{
		self.attack_finished = time + 0.5;
		sound(self, CHAN_ITEM, GLOCK_NOAMMO_SOUND, 1, ATTN_NORM);
		// CycleWeaponReverseCommand();
		return;
	}
	
	if (self.GLOCK_CLIP <= 0) 
	{
		sound(self, CHAN_ITEM, GLOCK_NOAMMO_SOUND, 1, ATTN_NORM);
		self.attack_finished = time + 0.5;
		if (AUTORELOAD) self.impulse = 100;
		self.think = Player_Think;
		return;
	}                           


	self.GLOCK_CLIP = self.GLOCK_CLIP - 1;
	self.currentClip = self.GLOCK_CLIP;
	if(self.GLOCK_CLIP == 0) self.weaponframe = GLOCK_SHOOT_EMPTY;
	else self.weaponframe = GLOCK_SHOOT;
	pointparticles(particleeffectnum("supernailgun_muzzleflash"), self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 2, self.velocity * 50, 1);
	Weapon_Fire(Weapon_Spread('1000 1000 0' * flSpread), GLOCK_DISTANCE, GLOCK_DAMAGE);
	Shell_Eject(GLOCK_SHELL_MODEL, GLOCK_SHELL_POS);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	sound(self, CHAN_WEAPON, GLOCK_FIRE_SOUND, 1, SoundRadius(GLOCK_SOUND_RADIUS));
	Weapon_Muzzleflash(GLOCK_MUZZLE_POS, GLOCK_MUZZLE_SCALE);
	self.attack_finished = time + flCycleTime;
	self.think = Player_Think;
	self.nextthink = time + flCycleTime;
};


void GLOCK_SecondaryAttack()
{
	GLOCK_Fire(0.1, 0.2, FALSE);
}

void GLOCK_PrimaryAttack()
{
	GLOCK_Fire(0.01, 0.3, TRUE);
}

void GLOCK_Switch()
{
	self.weaponframe = GLOCK_DRAW;
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void GLOCK_Select()
{
	if(!self.GLOCK_PICKUP)
	{
		self.GLOCK_PICKUP = TRUE;
		self.GLOCK_CLIP = GLOCK_MAX_CLIP;
	}
	self.currentClip = self.GLOCK_CLIP;
	self.currentammo = self.GLOCK_AMMO;
	self.weaponmodel = GLOCK_VIEW_MODEL;
	self.weaponSwitch = GLOCK_Switch;
	self.weaponAttack = GLOCK_PrimaryAttack;
	self.weaponAttack2 = GLOCK_SecondaryAttack;
	self.weaponReload = GLOCK_Reload;
	self.weaponSelect = GLOCK_Select;
}

void GLOCK_Precache()
{
	precache_model(GLOCK_VIEW_MODEL);
	precache_model(GLOCK_PLAYER_MODEL);
	precache_model(GLOCK_WORLD_MODEL);
	
	precache_sound(GLOCK_FIRE_SOUND);
	precache_sound(GLOCK_RELOAD_SOUND);
	
}

