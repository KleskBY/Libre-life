
//Settings
#define GLOCK_DAMAGE			Skill_GetValue("sk_plr_9mm_bullet", 8)
#define GLOCK_MAX_CLIP			17
#define GLOCK_RATE				0.11
#define GLOCK_SEMI				FALSE
#define GLOCK_DISTANCE			8192
#define GLOCK_SOUND_RADIUS		2500
#define GLOCK_MUZZLE_POS		'145 -30 -30'
#define GLOCK_SHELL_POS			'30 11 -10'
#define GLOCK_MUZZLE_SCALE		1

//Models
#define GLOCK_PLAYER_MODEL		""
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
#define GLOCK_SHOOT_R			10

//SOUNDS
#define GLOCK_FIRE_SOUND		"weapons/pl_gun3.wav"
#define GLOCK_CLIPIN_SOUND		""
#define GLOCK_CLIPOUT_SOUND		""
#define GLOCK_SLIDE1_SOUND		""
#define GLOCK_SLIDE2_SOUND		""
#define GLOCK_RELOAD_SOUND		"weapons/357_reload1.wav"
#define GLOCK_NOAMMO_SOUND		"weapons/357_cock1.wav"

#define GLOCK_AMMO ammo9x19
.float glock_clip;
.float glock_pickup;

void GLOCK_ReloadFinish()
{
	Weapon_Reload(GLOCK_AMMO, glock_clip, GLOCK_MAX_CLIP);
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void GLOCK_Reload()
{
	self.currentClip = self.glock_clip;
	if(self.glock_clip >= GLOCK_MAX_CLIP + 1) return;
	if(self.GLOCK_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}
	if(self.glock_clip != 0) Weapon_SetFrame(GLOCK_RELOAD_NOT_EMPTY);
	else Weapon_SetFrame(GLOCK_RELOAD);
	self.nextthink = time + 2.2;
	self.think = GLOCK_ReloadFinish;
	self.reload = TRUE;
	Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, GLOCK_RELOAD_SOUND);
}

void GLOCK_Fire(float flSpread, float flCycleTime, float fUseAutoAim)
{
	if(GLOCK_SEMI && self.ShootsFired != 0) return;
	
	if(self.GLOCK_AMMO <= 0 && self.glock_clip <= 0)
	{
		self.attack_finished = time + 0.5;
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, GLOCK_NOAMMO_SOUND);
		// CycleWeaponReverseCommand();
		return;
	}
	
	if (self.glock_clip <= 0) 
	{
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, GLOCK_NOAMMO_SOUND);
		self.attack_finished = time + 0.5;
		if (AUTORELOAD) self.impulse = 100;
		self.think = Player_Think;
		return;
	}                           


	self.glock_clip = self.glock_clip - 1;
	self.currentClip = self.glock_clip;
	if(self.glock_clip == 0) Weapon_SetFrame(GLOCK_SHOOT_EMPTY);
	else
	{
		if(self.weaponframe == GLOCK_SHOOT) Weapon_SetFrame(GLOCK_SHOOT_R);
		else Weapon_SetFrame(GLOCK_SHOOT);
	}
	pointparticles(particleeffectnum("supernailgun_muzzleflash"), self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 2, self.velocity * 50, 1);
	Weapon_Fire(Weapon_Spread('1000 1000 0' * flSpread), GLOCK_DISTANCE, GLOCK_DAMAGE);
	Shell_Eject(GLOCK_SHELL_MODEL, GLOCK_SHELL_POS);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(GLOCK_SOUND_RADIUS), PITCH_NORM, GLOCK_FIRE_SOUND);
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
	Weapon_SetFrame(GLOCK_DRAW);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void GLOCK_Select()
{
	if(!self.glock_pickup)
	{
		self.glock_pickup = TRUE;
		self.glock_clip = GLOCK_MAX_CLIP;
	}
	self.currentClip = self.glock_clip;
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
	// precache_model(GLOCK_PLAYER_MODEL);
	precache_model(GLOCK_WORLD_MODEL);
	
	precache_sound(GLOCK_FIRE_SOUND);
	precache_sound(GLOCK_RELOAD_SOUND);
	
}

