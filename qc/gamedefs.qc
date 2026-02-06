
////////////////////////////////////////
///////////////// DEFS /////////////////
////////////////////////////////////////

#define printline(...)  print(VA_ARGS, "\n")
#define printn(...)  print(VA_ARGS, "\n")
// #define ASSERT(cond) if (!(cond)) { objerror("ASSERT failed"); }
#define ASSERTSZ(f, t) if (!(f)) objerror(t)
#define ASSERT(cond) if (!(cond)) objerror("ASSERT failed")
#define printf(x, ...) print(sprintf(x, __VA_ARGS__))

// #define VEC_HULL_MIN		'-16 -16 -36'
// #define VEC_HULL_MAX		'16 16 36'
#define VEC_HUMAN_HULL_MIN	'-16 -16 0'
#define VEC_HUMAN_HULL_MAX	'16 16 72'
#define VEC_HUMAN_HULL_DUCK	'16 16 36'

float TRUE 	= 1;
float FALSE = 0;
float true = 1;
float false = 0;

float TS_AT_TOP 	= 0;
float TS_AT_BOTTOM 	= 1;
float TS_GOING_UP 	= 2;
float TS_GOING_DOWN = 3;

// channels
#define CHAN_AUTO			0
#define CHAN_WEAPON			1
#define	CHAN_VOICE			2
#define CHAN_ITEM			3
#define	CHAN_BODY			4
#define CHAN_STREAM			5			// allocate stream channel from the static or dynamic area
#define CHAN_STATIC			6			// allocate channel from the static area 
#define CHAN_NETWORKVOICE_BASE	7		// voice data coming across the network
#define CHAN_NETWORKVOICE_END	500		// network voice data reserves slots (CHAN_NETWORKVOICE_BASE through CHAN_NETWORKVOICE_END).
#define CHAN_BOT			501			// channel used for bot chatter.

#define	PITCH_NORM		100			// non-pitch shifted
#define PITCH_LOW		95			// other values are possible - 0-255, where 255 is very high
#define PITCH_HIGH		120

#define int float

#define ARMOR_RATIO	 0.2	// Armor Takes 80% of the damage
#define ARMOR_BONUS  0.5	// Each Point of Armor is work 1/x points of health

#define DMG_GENERIC			0			// generic damage was done
#define DMG_CRUSH			(1 << 0)	// crushed by falling or moving object
#define DMG_BULLET			(1 << 1)	// shot
#define DMG_SLASH			(1 << 2)	// cut, clawed, stabbed
#define DMG_BURN			(1 << 3)	// heat burned
#define DMG_FREEZE			(1 << 4)	// frozen
#define DMG_FALL			(1 << 5)	// fell too far
#define DMG_BLAST			(1 << 6)	// explosive blast damage
#define DMG_CLUB			(1 << 7)	// crowbar, punch, headbutt
#define DMG_SHOCK			(1 << 8)	// electric shock
#define DMG_SONIC			(1 << 9)	// sound pulse shockwave
#define DMG_ENERGYBEAM		(1 << 10)	// laser or other high energy beam 
#define DMG_NEVERGIB		(1 << 12)	// with this bit OR'd in, no damage type will be able to gib victims upon death
#define DMG_ALWAYSGIB		(1 << 13)	// with this bit OR'd in, any damage type can be made to gib victims upon death.
#define DMG_DROWN			(1 << 14)	// Drowning
// time-based damage
#define DMG_TIMEBASED		(~(0x3fff))	// mask for time-based damage

#define DMG_PARALYZE		(1 << 15)	// slows affected creature down
#define DMG_NERVEGAS		(1 << 16)	// nerve toxins, very bad
#define DMG_POISON			(1 << 17)	// blood poisioning
#define DMG_RADIATION		(1 << 18)	// radiation exposure
#define DMG_DROWNRECOVER	(1 << 19)	// drowning recovery
#define DMG_ACID			(1 << 20)	// toxic chemicals or acid burns
#define DMG_SLOWBURN		(1 << 21)	// in an oven
#define DMG_SLOWFREEZE		(1 << 22)	// in a subzero freezer
#define DMG_MORTAR			(1 << 23)	// Hit by air raid (done to distinguish grenade from mortar)

// These are caps bits to indicate what an object's capabilities (currently used for save/restore and level transitions)
#define		FCAP_CUSTOMSAVE				0x00000001
#define		FCAP_ACROSS_TRANSITION		0x00000002		// should transfer between transitions
#define		FCAP_MUST_SPAWN				0x00000004		// Spawn after restore
#define		FCAP_DONT_SAVE				0x80000000		// Don't save this
#define		FCAP_IMPULSE_USE			0x00000008		// can be used by the player
#define		FCAP_CONTINUOUS_USE			0x00000010		// can be used by the player
#define		FCAP_ONOFF_USE				0x00000020		// can be used by the player
#define		FCAP_DIRECTIONAL_USE		0x00000040		// Player sends +/- 1 when using (currently only tracktrains)
#define		FCAP_MASTER					0x00000080		// Can be used to "master" other entities (like multisource)

#define SF_MOMENTARY_DOOR				0x0001
#define	SF_ITEM_USE_ONLY				256 //  ITEM_USE_ONLY = BUTTON_USE_ONLY = DOOR_USE_ONLY!!! 


// message protocol defines
float SVC_SETVIEWPORT	= 5;
float SVC_SETVIEWANGLES	= 10;

float	FL_LADDERJUMP			= 8192;	// for ladders

//Playermodel size
vector	VEC_HULL_MIN = '-16 -16 -24';
vector	VEC_HULL_MAX = '16 16 32';
vector PLAYER_STAND_SIZE_MIN = VEC_HULL_MIN;
vector PLAYER_STAND_SIZE_MAX = VEC_HULL_MAX + '0 0 12';
// vector HL_PLAYER_STAND_SIZE_MIN = '-16 -16 -36';
// vector HL_PLAYER_STAND_SIZE_MAX = '16 16 36';
vector PLAYER_DUCK_SIZE_MIN = PLAYER_STAND_SIZE_MIN;
vector PLAYER_DUCK_SIZE_MAX = PLAYER_STAND_SIZE_MAX - '0 0 28';

float HUD_ALPHA = 0.8;
// vector HUD_COLOR = '1 0.81 0.25';
// vector HUD_COLOR_SELECTED = '1 0.62 0';
vector HUD_COLOR = '.96 0.96 0.96' ;
vector HUD_COLOR_SELECTED = '0.66 0.66 0.66';


vector STAND_VIEW_OFS = '0 0 24' + '0 0 12';
vector DUCK_VIEW_OFS = '0 0 6' + '0 0 6';


float AUTOJUMP = 0;
float JUMPCOOLDOWN = 0.95;
float AUTOBOTS = 0;
float AUTORELOAD = 1;
float PUSHING_FACTOR = 4;
float OLD_SERVER = 0;
float SHOTS_HIT_MODEL = 0;

float HITBOX_HEAD = 1;
float HITBOX_LEGS = 0;
float HITBOX_BODY = -1;

float MODE_SP = 0;
float MODE_COOP = 1;
float MODE_DM = 2;
float MODE_TDM = 3;
float MODE_DE = 4;
float MODE_HNS = 5;
float MODE_KZ = 6;
float MODE_ZM = 7;
float MODE_SURV = 8;


////////////// WEAPONS /////////////////

float WP_KNIFE = 1;
float WP_PISTOL = 2;
float WP_RIFLE = 4;
float WP_AK74 = 4;
float WP_SHOT = 8;
float WP_SHOTGUN = 8;
float WP_VAL = 16;
float WP_SNIPER = 32;
float WP_GRENADE = 64;
float WP_OC14 = 128;

float IsSniper(float weapon)
{
	if(weapon == WP_SNIPER) return 1;
	return 0;
}

////////////// PLAYER STATES /////////////////

float STATE_IDLE = 1;
float STATE_AIM = 2;
float STATE_RUN = 4;
float STATE_CROUCH = 8;

////////////// PLAYER STATS /////////////////

float STAT_ZOOM = 32;
float STAT_TOTALITEMS = 33;
float STAT_PICKED_ITEMS = 34;
float STAT_SHOTS = 35;
float STAT_HITS = 36;
float STAT_MEDKITS = 37;
float STAT_MONEY = 38;
float STAT_VEC1 = 39;
float STAT_VEC2 = 40;
float STAT_VEC3 = 41;
float STAT_INCROSS = 42;
float STAT_CLIP = 43;
float STAT_WEAPONS = 44;

.float vec1;
.float vec2;
.float vec3;
.float incross;

.float picked_items;
.float total_shots;
.float total_hits;
.float item;

////////////////////////////////////////
//////////////// FIELDS ////////////////
////////////////////////////////////////


.void() sightSound;
.float() checkAttack;
.void(float damage, vector org, vector dir) traceAttack;

.float lastTouch;
.vector lastAngles;

.float timer;
.entity hook;

.float reload;
.entity viewmodel;
.float blockSwitch;
.float hitbox;

//Stance
.float crouching;
.float running;
.float stamina;

.float footstep_finished;


//WEAPONS
.void() weaponAttack;
.void() weaponAttack2;
.void() weaponSwitch;
.void() weaponReload;
.void() weaponSelect;
.entity gun;

.float weapons;
.float ShootsFired;
.float weaponfired;
.float currentClip;
.vector aimofs;

.float medkits;
.float ammo9x18, ammo9x19, ammo545x39, ammo9x39, ammo762x39, ammo762x54, ammoBat, ammoShells, ammoGrenades, ammoVog;

.string task;
.vector task_pos;

//Doors
.float movesnd;
.string noiseMoving;
.float stopsnd;
.string noiseArrived;
.float locked_sound;
.float unlocked_sound;
.string noiseLocked;
.string noiseUnlocked;

.vector ang1;
.vector ang2;

.float object_caps; // FCAP object capabilities
.float radius;
.float rendermode;

float StringContains(string str, string needle)
{
	if(str == "") return FALSE;
	if(strstrofs(str, needle, 0) >= 0) return TRUE;
	return FALSE;
}

float FStrEq(string str1, string str2)
{
	return (str1 == str2);
}

float FClassnameIs(entity ent, string str)
{
	return (ent.classname == str);
}


////////////////////////////////////////
//////////////// CVARS /////////////////
////////////////////////////////////////

void RegisterCvar(string cv, string def)
{
#ifdef MENUQC
	registercvar(cv, def, 0);
#else
	registercvar(cv, def);
#endif
}

void RegisterCustomCvars()
{
	RegisterCvar("hud_draw", "1");
	RegisterCvar("hud_fastswitch", "0");
	RegisterCvar("bot_stop", "0");
	RegisterCvar("gamemode", "0");
	RegisterCvar("antiafk", "0");
	RegisterCvar("crosshair_static", "1");
	RegisterCvar("landmark", "");
	RegisterCvar("landmark_pos", "");
	RegisterCvar("landmark_player_pos", "");
	RegisterCvar("landmark_player_angles", "");
	RegisterCvar("landmark_player_velocity", "");
	
	
	#ifndef MENUQC
	registercommand("flashlight");
	registercommand("page");
	registercommand("lookat");
	registercommand("steamcmd");
	registercommand("quicksave");
	registercommand("quickload");
	registercommand("steam_resetachievements");
	#endif
}