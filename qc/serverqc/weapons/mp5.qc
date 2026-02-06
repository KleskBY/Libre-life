
#define MP5_DAMAGE 				35
#define MP5_MAX_CLIP 			50
#define MP5_RATE 				0.1
#define MP5_SEMI 				FALSE
#define MP5_DISTANCE 			8192
#define MP5_SOUND_RADIUS 		2500
#define MP5_MUZZLE_POS 			'165 -10 -30'
#define MP5_SHELL_POS			'35 11 -10'
#define  MP5_MUZZLE_SCALE		1

#define MP5_AMMO ammo9x19
#define MP5_SECONDARY_AMMO 		ammoGrenades
.float MP5_CLIP;
.float MP5_PICKUP;

//Sounds
#define MP5_FIRE1_SOUND			"weapons/hks1.wav"
#define MP5_FIRE2_SOUND			"weapons/hks2.wav"
#define MP5_FIRE3_SOUND			"weapons/hks3.wav"
#define MP5_FIRE_GRENADE_SOUND	"weapons/glauncher.wav"
#define MP5_CLIPIN_SOUND		"weapons/ak74/clipin.wav"
#define MP5_CLIPOUT_SOUND		"weapons/ak74/clipout.wav"
#define MP5_SLIDE1_SOUND		"weapons/sniper/boltback.wav"
#define MP5_SLIDE2_SOUND		"weapons/sniper/boltrelease.wav"
#define MP5_RELOAD1_SOUND		"items/clipinsert1.wav"
#define MP5_RELOAD2_SOUND		"items/clipinsert2.wav"
#define MP5_NOAMMO_SOUND		"weapons/357_cock1.wav"

//Models
#define MP5_PLAYER_MODEL		"models/players/ussr_rifle.md3"
#define MP5_VIEW_MODEL			"models/v_9mmar.iqm"
#define MP5_WORLD_MODEL			"models/w_9mmar.iqm"
#define MP5_SHELL_MODEL			"models/shell.iqm"
#define MP5_GRENADE_MODEL		"models/grenade.iqm"

//Anims
#define MP5_LONGIDLE 			0
#define MP5_IDLE1				1
#define MP5_LAUNCH				2
#define MP5_RELOAD				3
#define MP5_DEPLOY				4
#define MP5_FIRE1				5
#define MP5_FIRE2				6
#define MP5_FIRE3				7

void MP5_ReloadFinish()
{
	Weapon_Reload(MP5_AMMO, MP5_CLIP, MP5_MAX_CLIP);
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void MP5_Reload2()
{
	sound(self, CHAN_ITEM, MP5_RELOAD1_SOUND, 1, ATTN_NORM);
	self.think = MP5_ReloadFinish;
	self.nextthink = time + 0.75;
}

void MP5_Reload()
{
	self.currentClip = self.MP5_CLIP;
	if(self.MP5_CLIP >= MP5_MAX_CLIP + 1) return;
	if(self.MP5_AMMO <= 0)
	{
		CycleWeaponReverseCommand();
		return;
	}
	self.weaponframe = MP5_RELOAD;
	self.nextthink = time + 0.75;
	self.think = MP5_Reload2;
	self.reload = TRUE;
	sound(self, CHAN_ITEM, MP5_RELOAD2_SOUND, 1, ATTN_NORM);
}

void MP5_GrenadeExplosion()
{
	Combat_Explode(100, 100 * 2.5);
}

void MP5_LaunchGrenade()
{
    makevectors(self.v_angle);
    vector start = self.origin + v_forward * 16 + v_up * 16 + v_right * 5;

    entity grenade = spawn();
    grenade.owner = self;
    grenade.movetype = MOVETYPE_BOUNCE;
    grenade.solid = SOLID_BBOX;
    grenade.classname = "grenade";
    grenade.touch = MP5_GrenadeExplosion;
    grenade.think = SUB_Remove;
    grenade.nextthink = time + 5;
    grenade.velocity = v_forward * 1200 + v_up * 100 + self.velocity;
	grenade.avelocity_x = random(-100, -500);
    grenade.angles = self.v_angle;
    grenade.model = MP5_GRENADE_MODEL;
    setmodel(grenade, grenade.model);
    setsize(grenade, '-4 -4 -4', '4 4 4');
    setorigin(grenade, start);
	grenade.scale = 0.5;
}

void MP5_SecondaryAttack()
{
	if (self.waterlevel == 3 || self.MP5_SECONDARY_AMMO <= 0)
	{
		sound(self, CHAN_ITEM, MP5_NOAMMO_SOUND, 1, ATTN_NORM);
		self.attack_finished = time + 0.5;
		return;
	}
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	self.weaponframe = MP5_FIRE1;
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	sound(self, CHAN_WEAPON, MP5_FIRE_GRENADE_SOUND, 1, SoundRadius(MP5_SOUND_RADIUS));
	MP5_LaunchGrenade();
	self.attack_finished = time + 1;
	self.think = Player_Think;
	self.nextthink = time + 1;
	
}

void MP5_PrimaryAttack()
{
	if (self.waterlevel == 3 || self.MP5_CLIP <= 0)
	{
		sound(self, CHAN_ITEM, MP5_NOAMMO_SOUND, 1, ATTN_NORM);
		self.attack_finished = time + 0.5;
		if(self.MP5_AMMO > 0) self.impulse = 100;
		return;
	}
	
	self.effects = self.effects | EF_MUZZLEFLASH;
	self.weaponframe = MP5_FIRE1;
	self.MP5_CLIP = self.MP5_CLIP - 1;
	self.currentClip = self.MP5_CLIP;
	if(IsMultiplayer())
	{
		Weapon_Fire(Weapon_Spread(VECTOR_CONE_6DEGREES * 1000), MP5_DISTANCE, MP5_DAMAGE);
	}
	else
	{
		Weapon_Fire(Weapon_Spread(VECTOR_CONE_3DEGREES * 1000), MP5_DISTANCE, MP5_DAMAGE);
	}
	
	Shell_Eject(MP5_SHELL_MODEL, MP5_SHELL_POS);
	self.punchangle_x += random(-2, -1);
	self.punchangle_y += random(-1, 1);
	// sound(self, CHAN_WEAPON, MP5_FIRE_SOUND, 1, SoundRadius(MP5_SOUND_RADIUS));
	float r = RandomInt(1, 3);
	if(r == 1) sound(self, CHAN_WEAPON, MP5_FIRE1_SOUND, 1, SoundRadius(MP5_SOUND_RADIUS));
	else if(r == 2) sound(self, CHAN_WEAPON, MP5_FIRE2_SOUND, 1, SoundRadius(MP5_SOUND_RADIUS));
	else if(r == 3) sound(self, CHAN_WEAPON, MP5_FIRE3_SOUND, 1, SoundRadius(MP5_SOUND_RADIUS));
	Weapon_Muzzleflash(MP5_MUZZLE_POS, MP5_MUZZLE_SCALE);
	self.attack_finished = time + MP5_RATE;
}

void MP5_Switch()
{
	self.weaponframe = MP5_DEPLOY;
	self.reload = TRUE;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void MP5_Select()
{
	if(!self.MP5_PICKUP)
	{
		self.MP5_PICKUP = TRUE;
		self.MP5_CLIP = MP5_MAX_CLIP;
	}
	self.currentClip = self.MP5_CLIP;
	self.currentammo = self.MP5_AMMO;
	self.weaponmodel = MP5_VIEW_MODEL;
	self.weaponSwitch = MP5_Switch;
	self.weaponAttack = MP5_PrimaryAttack;
	self.weaponAttack2 = MP5_SecondaryAttack;
	self.weaponReload = MP5_Reload;
	self.weaponSelect = MP5_Select;
}

void MP5_Precache()
{
	precache_model(MP5_VIEW_MODEL);
	precache_model(MP5_WORLD_MODEL);
	precache_model(MP5_PLAYER_MODEL);

	precache_model (MP5_SHELL_MODEL);// brass shellTE_MODEL

	precache_model(MP5_GRENADE_MODEL);	// grenade

	precache_model("models/w_9mmARclip.mdl");
	precache_sound("items/9mmclip1.wav");              

	precache_sound(MP5_RELOAD1_SOUND);
	precache_sound(MP5_RELOAD2_SOUND);

	precache_sound(MP5_FIRE1_SOUND);// H to the K
	precache_sound(MP5_FIRE2_SOUND);// H to the K
	precache_sound(MP5_FIRE3_SOUND);// H to the K

	precache_sound(MP5_FIRE_GRENADE_SOUND);
	precache_sound("weapons/glauncher2.wav");

	precache_sound(MP5_NOAMMO_SOUND);
}


