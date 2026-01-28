
string GLOCK_PLAYER_MODEL = "models/players/ussr_rifle.md3";
string GLOCK_VIEW_MODEL = "models/v_9mmhandgun.iqm";
string GLOCK_WORLD_MODEL = "models/weapons/w_ak.md3";
string GLOCK_SHELL_MODEL = "models/shell.iqm";

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

float GLOCK_DAMAGE = 35;
float GLOCK_MAX_CLIP = 17;
float GLOCK_RATE = 0.11;
float GLOCK_SEMI = FALSE;
float GLOCK_DISTANCE = 8192;
float GLOCK_SOUND_RADIUS = 2500;
vector GLOCK_AIMOFS = '-6 4.2 3.8';
vector GLOCK_SPREAD = '9 9 0'; //0.01
vector GLOCK_MUZZLE_POS = '38 -4 -6';
float  GLOCK_MUZZLE_SCALE = 2;

.float GLOCK_AMMO = ammo9x19;
.float GLOCK_CLIP;
.float GLOCK_PICKUP;

string GLOCK_FIRE_SOUND = "weapons/pl_gun3.wav";
string GLOCK_CLIPIN_SOUND = "weapons/ak74/clipin.wav";
string GLOCK_CLIPOUT_SOUND = "weapons/ak74/clipout.wav";
string GLOCK_SLIDE1_SOUND = "weapons/sniper/boltback.wav";
string GLOCK_SLIDE2_SOUND = "weapons/sniper/boltrelease.wav";
string GLOCK_NOAMMO_SOUND = "weapons/noammo.wav";

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
	// sound(self, CHAN_ITEM, GLOCK_NOAMMO_SOUND, 1, ATTN_NORM);
}

void GLOCK_Fire(float flSpread, float flCycleTime, float fUseAutoAim)
{
	self.GLOCK_CLIP = self.GLOCK_CLIP - 1;
	self.currentClip = self.GLOCK_CLIP;
	if(self.GLOCK_CLIP == 0) self.weaponframe = GLOCK_SHOOT_EMPTY;
	else self.weaponframe = GLOCK_SHOOT;
	pointparticles(particleeffectnum("supernailgun_muzzleflash"), self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 2, self.velocity * 50, 1);
	Weapon_Fire(Weapon_Spread('100 100 0' * flSpread), GLOCK_DISTANCE, GLOCK_DAMAGE);
	Shell_Eject( self.origin + self.view_ofs + v_up * -5 + v_forward * 20 + v_right * 2, GLOCK_SHELL_MODEL);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	sound(self, CHAN_WEAPON, GLOCK_FIRE_SOUND, 1, SoundRadius(GLOCK_SOUND_RADIUS));
	// MuzzleFlash(self.viewmodel.origin + GLOCK_MUZZLE_POS, GLOCK_MUZZLE_SCALE);
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
	self.currentClip = self.GLOCK_CLIP;
	self.weaponmodel = GLOCK_VIEW_MODEL;
	setmodel(self, GLOCK_PLAYER_MODEL);
	self.weaponSwitch = GLOCK_Switch;
	self.weaponAttack = GLOCK_PrimaryAttack;
	self.weaponAttack2 = GLOCK_SecondaryAttack;
	self.weaponReload = GLOCK_Reload;
	self.weaponSelect = GLOCK_Select;
	// SetGun(CROWBAR_WORLD_MODEL);
}


