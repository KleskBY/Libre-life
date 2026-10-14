
#define SHOTGUN_DAMAGE 				Skill_GetValue("sk_plr_buckshot", 5)
#define SHOTGUN_MAX_CLIP 			8
#define SHOTGUN_RATE 				0.95
#define SHOTGUN_SEMI 				FALSE
#define SHOTGUN_DISTANCE 			2048
#define SHOTGUN_SOUND_RADIUS 		2500
#define SHOTGUN_MUZZLE_POS 			'130 -20 -30'
#define SHOTGUN_SHELL_POS			'35 11 -10'
#define  SHOTGUN_MUZZLE_SCALE		1

#define SHOTGUN_AMMO ammoShells
.float shotgun_clip;
.float shotgun_pickup;

//Sounds
#define SHOTGUN_FIRE1_SOUND			"weapons/sbarrel1.wav"
#define SHOTGUN_FIRE2_SOUND			"weapons/dbarrel1.wav"
#define SHOTGUN_RELOAD1_SOUND		"weapons/reload1.wav"
#define SHOTGUN_RELOAD2_SOUND		"weapons/reload3.wav"
#define SHOTGUN_COCK_SOUND			"weapons/scock1.wav"
#define SHOTGUN_NOAMMO_SOUND		"weapons/357_cock1.wav"

//Models
#define SHOTGUN_VIEW_MODEL			"models/v_shotgun.iqm"
#define SHOTGUN_WORLD_MODEL			"models/w_shotgun.iqm"
#define SHOTGUN_SHELL_MODEL			"models/shotgunshell.iqm"

//Anims
#define SHOTGUN_IDLE 				0
#define SHOTGUN_FIRE				1
#define SHOTGUN_FIRE2				2
#define SHOTGUN_RELOAD				3
#define SHOTGUN_PUMP				4
#define SHOTGUN_START_RELOAD		5
#define SHOTGUN_DRAW				6
#define SHOTGUN_HOLSTER				7
#define SHOTGUN_IDLE4				8
#define SHOTGUN_IDLE_DEEP			9

void SHOTGUN_Reload_Finish()
{
	Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, SHOTGUN_RELOAD2_SOUND);
	Weapon_SetFrame(SHOTGUN_PUMP);
	self.think = Player_Think;
	self.nextthink = time + 0.75;
}

void SHOTGUN_Reload2();
void SHOTGUN_Reload_Insert()
{
	if(self.button0) //Stop when shooting
	{	
		Player_Think();
		self.think = Player_Think;
		self.nextthink = time;
		return;
	}
	
	Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, SHOTGUN_RELOAD1_SOUND);
	self.shotgun_clip = self.shotgun_clip + 1;
	self.SHOTGUN_AMMO = self.SHOTGUN_AMMO - 1;
	self.currentClip = self.shotgun_clip;
	self.currentammo = self.SHOTGUN_AMMO;
	self.think = SHOTGUN_Reload2;
	self.nextthink = time + 0.1;
}

void SHOTGUN_Reload2()
{
	Weapon_SetFrame(SHOTGUN_RELOAD);   // one restart per shell inserted

	if(self.button0) //Stop when shooting
	{	
		Player_Think();
		self.think = Player_Think;
		self.nextthink = time;
		return;
	}
	
	if(self.shotgun_clip >= SHOTGUN_MAX_CLIP || self.SHOTGUN_AMMO <= 0)
	{
		self.think = SHOTGUN_Reload_Finish;
		self.nextthink = time + 0.2;
	}
	else
	{
		self.think = SHOTGUN_Reload_Insert;
		self.nextthink = time + 0.5;
	}
}

void SHOTGUN_Reload()
{
	self.currentClip = self.shotgun_clip;
	if(self.shotgun_clip >= SHOTGUN_MAX_CLIP) return;
	if(self.SHOTGUN_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}
	
	Weapon_SetFrame(SHOTGUN_START_RELOAD);
	self.nextthink = time + 0.5;
	self.think = SHOTGUN_Reload2;
	self.reload = TRUE;
	
}

void SHOTGUN_PrimaryAttack();
void SHOTGUN_SecondaryAttack()
{
	if (self.waterlevel == 3 || self.shotgun_clip <= 0)
	{
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, SHOTGUN_NOAMMO_SOUND);
		self.attack_finished = time + 0.5;
		return;
	}
	if(self.shotgun_clip == 1)
	{
		SHOTGUN_PrimaryAttack();
		return;
	}
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	Weapon_SetFrame(SHOTGUN_FIRE2);
	self.shotgun_clip = self.shotgun_clip - 2;
	self.currentClip = self.shotgun_clip;

	Weapon_FireStart();
	if(IsMultiplayer())
	{
		for(float i = 0; i < 8; i++)
			Weapon_FireShot(VECTOR_CONE_DM_SHOTGUN * 1000, SHOTGUN_DISTANCE, SHOTGUN_DAMAGE, DMG_BULLET);
	}
	else
	{
		for(float i = 0; i < 12; i++)
			Weapon_FireShot(VECTOR_CONE_10DEGREES * 1000, SHOTGUN_DISTANCE, SHOTGUN_DAMAGE, DMG_BULLET);
	}
	Weapon_FireEnd();

	pointparticles(particleeffectnum("double_shotgun_muzzleflash"), self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 4, self.velocity * 50, 1);
	Shell_Eject(SHOTGUN_SHELL_MODEL, SHOTGUN_SHELL_POS);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(SHOTGUN_SOUND_RADIUS), PITCH_NORM, SHOTGUN_FIRE2_SOUND);
	self.attack_finished = time + 1.25;
	self.think = Player_Think;
	self.nextthink = time + 1.25;
	
}

void SHOTGUN_PrimaryAttack()
{
	if (self.waterlevel == 3 || self.shotgun_clip <= 0)
	{
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, SHOTGUN_NOAMMO_SOUND);
		self.attack_finished = time + 0.5;
		if(self.SHOTGUN_AMMO > 0) self.impulse = 100;
		return;
	}
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	Weapon_SetFrame(SHOTGUN_FIRE);
	self.shotgun_clip = self.shotgun_clip - 1;
	self.currentClip = self.shotgun_clip;

	Weapon_FireStart();
	if(IsMultiplayer())
	{
		for(float i = 0; i < 4; i++)
			Weapon_FireShot(VECTOR_CONE_DM_SHOTGUN * 1000, SHOTGUN_DISTANCE, SHOTGUN_DAMAGE, DMG_BULLET);
	}
	else
	{
		for(float i = 0; i < 6; i++)
			Weapon_FireShot(VECTOR_CONE_10DEGREES * 1000, SHOTGUN_DISTANCE, SHOTGUN_DAMAGE, DMG_BULLET);
	}
	Weapon_FireEnd();
	pointparticles(particleeffectnum("double_shotgun_muzzleflash"), self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 4, self.velocity * 50, 1);
	Shell_Eject(SHOTGUN_SHELL_MODEL, SHOTGUN_SHELL_POS);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(SHOTGUN_SOUND_RADIUS), PITCH_NORM, SHOTGUN_FIRE1_SOUND);
	Weapon_Muzzleflash(SHOTGUN_MUZZLE_POS, SHOTGUN_MUZZLE_SCALE);
	self.attack_finished = time + SHOTGUN_RATE;
	self.nextthink = time + SHOTGUN_RATE;
	self.think = Player_Think;
}

void SHOTGUN_Switch()
{
	Weapon_SetFrame(SHOTGUN_DRAW);
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void SHOTGUN_Select()
{
	if(!self.shotgun_pickup)
	{
		self.shotgun_pickup = TRUE;
		self.shotgun_clip = SHOTGUN_MAX_CLIP;
	}
	self.currentClip = self.shotgun_clip;
	self.currentammo = self.SHOTGUN_AMMO;
	self.weaponmodel = SHOTGUN_VIEW_MODEL;
	self.weaponSwitch = SHOTGUN_Switch;
	self.weaponAttack = SHOTGUN_PrimaryAttack;
	self.weaponAttack2 = SHOTGUN_SecondaryAttack;
	self.weaponReload = SHOTGUN_Reload;
	self.weaponSelect = SHOTGUN_Select;
}

void SHOTGUN_Precache()
{
	precache_model(SHOTGUN_VIEW_MODEL);
	precache_model(SHOTGUN_WORLD_MODEL);
	// precache_model(SHOTGUN_PLAYER_MODEL);

	precache_model (SHOTGUN_SHELL_MODEL);

	precache_sound("items/9mmclip1.wav");              

	precache_sound(SHOTGUN_RELOAD1_SOUND);
	precache_sound(SHOTGUN_RELOAD2_SOUND);

	precache_sound(SHOTGUN_FIRE1_SOUND);
	precache_sound(SHOTGUN_FIRE2_SOUND);

	precache_sound(SHOTGUN_NOAMMO_SOUND);
}

