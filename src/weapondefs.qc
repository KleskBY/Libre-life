
////////// WEAPON REGISTRY //////////

#define WID_NONE         0
#define WID_CROWBAR      1
#define WID_GLOCK        2
#define WID_PYTHON       3
#define WID_MP5          4
#define WID_SHOTGUN      5
#define WID_CROSSBOW     6
#define WID_HANDGRENADE  7
#define WID_RPG          8
#define WID_SATCHEL      9
#define WID_TRIPMINE     10
#define WID_GAUSS        11
#define WID_EGON         12
#define WID_HORNETGUN    13
#define WID_SNARK        14
#define WID_CYCLER       15
#define WID_COUNT        16  // one past the last valid ID

float  weapon_slot      [WID_COUNT];   // 1-based slot (matches number key)
float  weapon_pos       [WID_COUNT];   // 0-based row within slot
float  weapon_bit       [WID_COUNT];   // matching WEAPON_* bitflag
string weapon_sprite    [WID_COUNT];   // HUD icon path (no extension)
string weapon_ammo      [WID_COUNT];
string weapon_ammo2     [WID_COUNT];
string weapon_name      [WID_COUNT];   // human-readable name
float  weapon_crosshair [WID_COUNT];   // crosshair image index (gfx/crosshairN.png), -1 = none
string weapon_animExt   [WID_COUNT];   // third-person pose suffix, "" = no weapon stance
float  weapon_twoHanded [WID_COUNT];   // TRUE picks the two-handed walk cycle
#ifdef SVQC
var void() weapon_select_func[WID_COUNT]; // server-side Select() function per weapon
#endif

void Weapon_RegistryInit()
{
	weapon_slot[WID_CROWBAR] = 1; weapon_pos[WID_CROWBAR] = 0;
	weapon_bit [WID_CROWBAR] = WEAPON_CROWBAR;
	weapon_sprite[WID_CROWBAR] = "gfx/weapon_crowbar_weapon";
	weapon_name[WID_CROWBAR] = "Crowbar";

	weapon_slot[WID_GLOCK] = 2; weapon_pos[WID_GLOCK] = 0;
	weapon_bit [WID_GLOCK] = WEAPON_GLOCK;
	weapon_sprite[WID_GLOCK] = "gfx/weapon_9mmhandgun_weapon";
	weapon_name[WID_GLOCK] = "9mm Handgun";

	weapon_slot[WID_PYTHON] = 2; weapon_pos[WID_PYTHON] = 1;
	weapon_bit [WID_PYTHON] = WEAPON_PYTHON;
	weapon_sprite[WID_PYTHON] = "gfx/weapon_357_weapon";
	weapon_name[WID_PYTHON] = ".357 Magnum";

	weapon_slot[WID_MP5] = 3; weapon_pos[WID_MP5] = 0;
	weapon_bit [WID_MP5] = WEAPON_MP5;
	weapon_sprite[WID_MP5] = "gfx/weapon_9mmar_weapon";
	weapon_name[WID_MP5] = "9mm AR";

	weapon_slot[WID_SHOTGUN] = 3; weapon_pos[WID_SHOTGUN] = 1;
	weapon_bit [WID_SHOTGUN] = WEAPON_SHOTGUN;
	weapon_sprite[WID_SHOTGUN] = "gfx/weapon_shotgun_weapon";
	weapon_name[WID_SHOTGUN] = "Shotgun";

	weapon_slot[WID_CROSSBOW] = 3; weapon_pos[WID_CROSSBOW] = 2;
	weapon_bit [WID_CROSSBOW] = WEAPON_CROSSBOW;
	weapon_sprite[WID_CROSSBOW] = "gfx/weapon_crossbow_weapon";
	weapon_name[WID_CROSSBOW] = "Crossbow";

	weapon_slot[WID_HANDGRENADE] = 5; weapon_pos[WID_HANDGRENADE] = 0;
	weapon_bit [WID_HANDGRENADE] = WEAPON_HANDGRENADE;
	weapon_sprite[WID_HANDGRENADE] = "gfx/weapon_handgrenade_weapon";
	weapon_name[WID_HANDGRENADE] = "Hand Grenade";

	weapon_slot[WID_RPG] = 4; weapon_pos[WID_RPG] = 0;
	weapon_bit [WID_RPG] = WEAPON_RPG;
	weapon_sprite[WID_RPG] = "gfx/weapon_rpg_weapon";
	weapon_name[WID_RPG] = "RPG";

	weapon_slot[WID_SATCHEL] = 5; weapon_pos[WID_SATCHEL] = 1;
	weapon_bit [WID_SATCHEL] = WEAPON_SATCHEL;
	weapon_sprite[WID_SATCHEL] = "gfx/weapon_satchel_weapon";
	weapon_name[WID_SATCHEL] = "Satchel Charge";

	weapon_slot[WID_TRIPMINE] = 5; weapon_pos[WID_TRIPMINE] = 2;
	weapon_bit [WID_TRIPMINE] = WEAPON_TRIPMINE;
	weapon_sprite[WID_TRIPMINE] = "gfx/weapon_tripmine_weapon";
	weapon_name[WID_TRIPMINE] = "Trip Mine";

	weapon_slot[WID_GAUSS] = 4; weapon_pos[WID_GAUSS] = 1;
	weapon_bit [WID_GAUSS] = WEAPON_GAUSS;
	weapon_sprite[WID_GAUSS] = "gfx/weapon_gauss_weapon";
	weapon_name[WID_GAUSS] = "Tau Cannon";

	weapon_slot[WID_EGON] = 4; weapon_pos[WID_EGON] = 2;
	weapon_bit [WID_EGON] = WEAPON_EGON;
	weapon_sprite[WID_EGON] = "gfx/weapon_egon_weapon";
	weapon_name[WID_EGON] = "Gluon Gun";

	weapon_slot[WID_HORNETGUN] = 4; weapon_pos[WID_HORNETGUN] = 3;
	weapon_bit [WID_HORNETGUN] = WEAPON_HORNETGUN;
	weapon_sprite[WID_HORNETGUN] = "gfx/weapon_hornetgun_weapon";
	weapon_name[WID_HORNETGUN] = "Hornet Gun";

	weapon_slot[WID_SNARK] = 5; weapon_pos[WID_SNARK] = 3;
	weapon_bit [WID_SNARK] = WEAPON_SNARK;
	weapon_sprite[WID_SNARK] = "gfx/weapon_snark_weapon";
	weapon_name[WID_SNARK] = "Snark";

	weapon_slot[WID_CYCLER] = 1; weapon_pos[WID_CYCLER] = 1;
	weapon_bit [WID_CYCLER] = WEAPON_CYCLER;
	weapon_sprite[WID_CYCLER] = "gfx/weapon_crowbar_weapon";
	weapon_name[WID_CYCLER] = "Weapon Cycler";

	// Ammo icons (gfx/weapon_*_ammo[2]). Crowbar has no ammo.
	weapon_ammo[WID_CROWBAR]     = "";
	weapon_ammo[WID_GLOCK]       = "gfx/weapon_9mmhandgun_ammo";
	weapon_ammo[WID_PYTHON]      = "gfx/weapon_357_ammo";
	weapon_ammo[WID_MP5]         = "gfx/weapon_9mmar_ammo";
	weapon_ammo2[WID_MP5]        = "gfx/weapon_9mmar_ammo2"; // contact grenade
	weapon_ammo[WID_SHOTGUN]     = "gfx/weapon_shotgun_ammo";
	weapon_ammo[WID_CROSSBOW]    = "gfx/weapon_crossbow_ammo";
	weapon_ammo[WID_HANDGRENADE] = "gfx/weapon_handgrenade_ammo";
	weapon_ammo[WID_RPG]         = "gfx/weapon_rpg_ammo";
	weapon_ammo[WID_SATCHEL]     = "gfx/weapon_satchel_ammo";
	weapon_ammo[WID_TRIPMINE]    = "";
	weapon_ammo[WID_GAUSS]       = "gfx/weapon_egon_ammo"; // uranium
	weapon_ammo[WID_EGON]        = "gfx/weapon_egon_ammo";
	weapon_ammo[WID_HORNETGUN]   = "gfx/weapon_hornetgun_ammo";
	weapon_ammo[WID_SNARK]       = "gfx/weapon_snark_ammo";
	weapon_ammo[WID_CYCLER]      = "";

	weapon_crosshair[WID_CROWBAR]     = 0;
	weapon_crosshair[WID_GLOCK]       = 1;   // small cross
	weapon_crosshair[WID_PYTHON]      = 2;
	weapon_crosshair[WID_MP5]         = 10;   // open cross with gap
	weapon_crosshair[WID_SHOTGUN]     = 7;   // spread dots
	weapon_crosshair[WID_CROSSBOW]    = 3;   // circle
	weapon_crosshair[WID_HANDGRENADE] = 0;
	weapon_crosshair[WID_RPG]         = 11;  // large circle
	weapon_crosshair[WID_SATCHEL]     = 0;   // dot
	weapon_crosshair[WID_TRIPMINE]    = 0;   // dot
	weapon_crosshair[WID_GAUSS]       = 12;
	weapon_crosshair[WID_EGON]        = 13;  // large circle
	weapon_crosshair[WID_HORNETGUN]   = 0;
	weapon_crosshair[WID_SNARK]       = 0;
	weapon_crosshair[WID_CYCLER]      = -1;  // debug viewmodel cycler

	// Third-person pose family. The name is a suffix on the player model's
	// framegroups (ref_aim_mp5, ref_shoot_crowbar), so "" leaves the body
	// playing the plain gait with no weapon stance at all.
	weapon_animExt[WID_CROWBAR]   = "crowbar";
	weapon_animExt[WID_GLOCK]     = "onehanded";
	weapon_animExt[WID_PYTHON]    = "python";
	weapon_animExt[WID_MP5]       = "mp5";
	weapon_animExt[WID_SHOTGUN]   = "shotgun";
	weapon_animExt[WID_CROSSBOW]  = "bow";
	weapon_animExt[WID_RPG]       = "rpg";
	weapon_animExt[WID_TRIPMINE]  = "trip";
	weapon_animExt[WID_GAUSS]     = "gauss";
	weapon_animExt[WID_EGON]      = "egon";
	weapon_animExt[WID_HORNETGUN] = "hive";
	weapon_animExt[WID_SNARK]     = "squeak";

	weapon_twoHanded[WID_MP5]      = TRUE;
	weapon_twoHanded[WID_SHOTGUN]  = TRUE;
	weapon_twoHanded[WID_CROSSBOW] = TRUE;
	weapon_twoHanded[WID_RPG]      = TRUE;
	weapon_twoHanded[WID_GAUSS]    = TRUE;
	weapon_twoHanded[WID_EGON]     = TRUE;
}

float Weapon_BitFromID(float id)
{
	if (id <= WID_NONE || id >= WID_COUNT) return 0;
	return weapon_bit[id];
}

float Weapon_IDFromBit(float bit)
{
	if (bit == 0) return WID_NONE;
	for (float id = 1; id < WID_COUNT; id++)
		if (weapon_bit[id] == bit) return id;
	return WID_NONE;
}
