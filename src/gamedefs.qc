
///////////////// DEFS /////////////////

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
#define VEC_VIEW			'0 0 28'

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
#define CHAN_STREAM			5
#define CHAN_STATIC			6
#define CHAN_NETWORKVOICE_BASE	7
#define CHAN_NETWORKVOICE_END	500
#define CHAN_BOT			501

// PITCH_NORM is needed by the Sound_* layer, which is
// compiled before this file.
#define PITCH_LOW		95
#define PITCH_HIGH		120

#define int float
#define BOOL float
#define bool float

#define ARMOR_RATIO	 0.2
#define ARMOR_BONUS  0.5

#define DMG_GENERIC			0
#define DMG_CRUSH			(1 << 0)
#define DMG_BULLET			(1 << 1)	// shot
#define DMG_SLASH			(1 << 2)
#define DMG_BURN			(1 << 3)	// heat burned
#define DMG_FREEZE			(1 << 4)	// frozen
#define DMG_FALL			(1 << 5)
#define DMG_BLAST			(1 << 6)
#define DMG_CLUB			(1 << 7)
#define DMG_SHOCK			(1 << 8)	// electric shock
#define DMG_SONIC			(1 << 9)
#define DMG_ENERGYBEAM		(1 << 10)
#define DMG_NEVERGIB		(1 << 12)
#define DMG_ALWAYSGIB		(1 << 13)
#define DMG_DROWN			(1 << 14)	// Drowning
#define DMG_TIMEBASED		(~(0x3fff))

#define DMG_PARALYZE		(1 << 15)
#define DMG_NERVEGAS		(1 << 16)
#define DMG_POISON			(1 << 17)	// blood poisioning
#define DMG_RADIATION		(1 << 18)	// radiation exposure
#define DMG_DROWNRECOVER	(1 << 19)	// drowning recovery
#define DMG_ACID			(1 << 20)
#define DMG_SLOWBURN		(1 << 21)
#define DMG_SLOWFREEZE		(1 << 22)
#define DMG_MORTAR			(1 << 23)

#define DMG_SHOWNHUD		(DMG_POISON | DMG_ACID | DMG_FREEZE | DMG_SLOWFREEZE | DMG_DROWN | DMG_BURN | DMG_SLOWBURN | DMG_NERVEGAS | DMG_RADIATION | DMG_SHOCK)

.float dmg_shownhud_bits;
.float dmg_shownhud_time;	// server-side latch expiry (bits clear when it passes)

#define		FCAP_CUSTOMSAVE				0x00000001
#define		FCAP_ACROSS_TRANSITION		0x00000002
#define		FCAP_MUST_SPAWN				0x00000004
#define		FCAP_DONT_SAVE				0x80000000
#define		FCAP_IMPULSE_USE			0x00000008
#define		FCAP_CONTINUOUS_USE			0x00000010
#define		FCAP_ONOFF_USE				0x00000020
#define		FCAP_DIRECTIONAL_USE		0x00000040
#define		FCAP_MASTER					0x00000080

#define GLOBAL_OFF   0
#define GLOBAL_ON    1
#define GLOBAL_DEAD  2

void(entity e) GlobalState_MarkEntityDead;
float(entity e) GlobalState_RemoveIfDead;
float(entity e) GlobalState_EntityInTable;

.string spent_token;
void(entity e) Spent_Mark;

#define SF_MOMENTARY_DOOR				0x0001
#define	SF_ITEM_USE_ONLY				256

#define	SF_ENVEXPLOSION_NODAMAGE	( 1 << 0 )
#define	SF_ENVEXPLOSION_REPEATABLE	( 1 << 1 )
#define SF_ENVEXPLOSION_NOFIREBALL	( 1 << 2 )
#define SF_ENVEXPLOSION_NOSMOKE		( 1 << 3 )
#define SF_ENVEXPLOSION_NODECAL		( 1 << 4 )
#define SF_ENVEXPLOSION_NOSPARKS	( 1 << 5 )

// message protocol defines
float SVC_SETVIEWPORT	= 5;
float SVC_SETVIEWANGLES	= 10;

#define ENT_CAMERA 1

#ifndef MSG_ENTITY
#define MSG_ENTITY 5
#endif
.float(entity playerent, float changedflags) SendEntity;
.float SendFlags;

// edict.flags
float	FL_FLY					= 1;
float	FL_SWIM					= 2;
float	FL_CLIENT				= 8;	// set for all client edicts
float	FL_INWATER				= 16;
float	FL_MONSTER				= 32;
float	FL_GODMODE				= 64;	// player cheat
float	FL_NOTARGET				= 128;	// player cheat
float	FL_ITEM					= 256;	// extra wide size for bonus items
float	FL_ONGROUND				= 512;	// standing on something
float	FL_PARTIALGROUND		= 1024;
float	FL_WATERJUMP			= 2048;
float	FL_JUMPRELEASED			= 4096;	// for jump debouncing
float	FL_LADDERJUMP			= 8192;	// for ladders
float	FL_FINDABLE_NONSOLID	= 16384; // FTE: allow SOLID_NOT entity to be returned by findradius

#define FL_PROXY				(1<<20)
#define FL_ALWAYSTHINK			(1<<21)
#define FL_BASEVELOCITY			(1<<22)
#define FL_MONSTERCLIP			(1<<23)
#define FL_ONTRAIN				(1<<24)
#define FL_WORLDBRUSH			(1<<25)
#define FL_SPECTATOR            (1<<26)
#define FL_CUSTOMENTITY			(1<<29)
#define FL_KILLME				(1<<30)
#define FL_DORMANT				(1<<31)

float	AS_STRAIGHT		= 1;
float	AS_SLIDING		= 2;
float	AS_MELEE		= 3;
float	AS_MISSILE		= 4;

//Playermodel size
vector	VEC_HULL_MIN = '-16 -16 -24';
vector	VEC_HULL_MAX = '16 16 32';

vector HL_PLAYER_STAND_SIZE_MIN = '-16 -16 -36';
vector HL_PLAYER_STAND_SIZE_MAX = '16 16 36';
var vector PLAYER_STAND_SIZE_MIN = '-16 -16 -24';
var vector PLAYER_STAND_SIZE_MAX = '16 16 44';	// 68 tall (default set)
var vector PLAYER_DUCK_SIZE_MIN  = '-16 -16 -24';
var vector PLAYER_DUCK_SIZE_MAX  = '16 16 16';		// 40 tall

// HL1-style air-duck hull: ground duck hull shifted up, so the feet rise by
// DUCK_AIR_HULL_OFS while total height is unchanged.
var vector PLAYER_DUCK_AIR_SIZE_MIN = '-16 -16 -6';
var vector PLAYER_DUCK_AIR_SIZE_MAX = '16 16 34';
var float  DUCK_AIR_HULL_OFS        = 18;

// player.iqm is authored to 72-unit hull. Shrink it on id1 maps so the
// visible body keeps the same model-to-hull ratio it has on maps.
var float  PLAYER_MODEL_SCALE       = 1;

float HUD_ALPHA = 0.8;

vector HUD_COLOR = '1.0 0.627 0.0';
vector HUD_COLOR_SELECTED = '1 0.62 0';
// HUD colors (RGB_YELLOWISH 255,160,0 ; RGB_REDISH 255,16,16) and fade timing
vector HUD_RGB_YELLOWISH = '1.0 0.627 0.0';
vector HUD_RGB_REDISH    = '1.0 0.0625 0.0625';
float  HUD_MIN_ALPHA     = 0.392;   // 100/255
float  HUD_FADE_TIME     = 100;	// matches FADE_TIME
float  HUD_FADE_DECAY    = 20;      // m_fFade -= dt * 20

var vector STAND_VIEW_OFS = '0 0 42';
var vector DUCK_VIEW_OFS  = '0 0 12';

// Ducking view height is 12 or 6 (id1); standing is 42 or 22. A networked
// STAT_VIEWHEIGHT at or below this is a duck in either map family.
//
// Do NOT test the stat against DUCK_VIEW_OFS_z instead. That global is written
// by PlayerProps_Init from Map_IsId1BSP(), and on FTE the client's
// cvar("bsp") does not agree with the server's, so the client can be
// holding the id1 value (6) while the server is sending 12.
#define PLAYER_DUCK_VIEW_MAX 16

// Swap the whole proportion set to match the map family. Cheap and idempotent:
// re-checking every frame on the client is fine, and needed there because the
// world model (and with it the bsp cvar) may load after CSQC_Init.
var float g_playerPropsMode = -1;

void PlayerProps_Init()
{
	float id1 = Map_IsId1BSP();
	if (g_playerPropsMode == id1)
		return;
	g_playerPropsMode = id1;

	if (id1)
	{
		PLAYER_STAND_SIZE_MIN = VEC_HULL_MIN;
		PLAYER_STAND_SIZE_MAX = VEC_HULL_MAX;
		PLAYER_DUCK_SIZE_MIN  = VEC_HULL_MIN;
		PLAYER_DUCK_SIZE_MAX  = '16 16 8';		// 32 tall
		DUCK_AIR_HULL_OFS     = 15;
		STAND_VIEW_OFS        = '0 0 22';
		DUCK_VIEW_OFS         = '0 0 6';
		PLAYER_MODEL_SCALE    = 56 / 68;
	}
	else
	{
		PLAYER_STAND_SIZE_MIN = '-16 -16 -24';
		PLAYER_STAND_SIZE_MAX = '16 16 44';		// 68 tall
		PLAYER_DUCK_SIZE_MIN  = '-16 -16 -24';
		PLAYER_DUCK_SIZE_MAX  = '16 16 16';		// 40 tall
		DUCK_AIR_HULL_OFS     = 18;
		STAND_VIEW_OFS        = '0 0 42';
		DUCK_VIEW_OFS         = '0 0 12';
		PLAYER_MODEL_SCALE    = 1;
	}

	PLAYER_DUCK_AIR_SIZE_MIN = PLAYER_DUCK_SIZE_MIN + [0, 0, DUCK_AIR_HULL_OFS];
	PLAYER_DUCK_AIR_SIZE_MAX = PLAYER_DUCK_SIZE_MAX + [0, 0, DUCK_AIR_HULL_OFS];
}

float AUTOJUMP = 0;
float JUMPCOOLDOWN = 0.95;
#define HL1_CROUCHJUMP 1	// Toggle HL1-style crouch-jump
float AUTOBOTS = 0;
float AUTORELOAD = 1;
float PUSHING_FACTOR = 4;
float OLD_SERVER = 0;

float HITBOX_HEAD = 1;
float HITBOX_LEGS = 0;
float HITBOX_BODY = -1;

// Deathmatch scoreboard layout, read by serverqc/obituary.qc and clientqc/ranking.qc.
// Defined: KILLS + DEATHS columns fed by sbrow. Removed: one Quake-style FRAGS column
// read from the engine, and deathmatch sends no sbrow at all. Coop shows DEATHS either way.
#define SCOREBOARD_KD

float MODE_SP = 0;
float MODE_COOP = 1;
float MODE_DM = 2;
float MODE_DE = 4;
float MODE_HNS = 5;
float MODE_KZ = 6;
float MODE_ZM = 7;
float MODE_SURV = 8;

////////////// WEAPONS /////////////////

#define ITEM_HEALTHKIT		1
#define ITEM_ANTIDOTE		2
#define ITEM_SECURITY		3
#define ITEM_BATTERY		4

#define WEAPON_NONE				0
#define WEAPON_CROWBAR			1
#define	WEAPON_GLOCK			2
#define WEAPON_PYTHON			4
#define WEAPON_MP5				8
#define WEAPON_CHAINGUN			16
#define WEAPON_CYCLER			WEAPON_CHAINGUN	// debug-only cycler_weapon reuses unused bit
#define WEAPON_CROSSBOW			32
#define WEAPON_SHOTGUN			64
#define WEAPON_RPG				128
#define WEAPON_GAUSS			256
#define WEAPON_EGON				512
#define WEAPON_HORNETGUN		1024
#define WEAPON_HANDGRENADE		2048
#define WEAPON_TRIPMINE			4096
#define	WEAPON_SATCHEL			8192
#define	WEAPON_SNARK			16384
#define WEAPON_SUIT				32768	// HEV suit; a bit like its siblings above
#define MAX_WEAPONS				32

#define VECTOR_CONE_1DEGREES	'0.00873 0.00873 0.00873'
#define VECTOR_CONE_2DEGREES	'0.01745 0.01745 0.01745'
#define VECTOR_CONE_3DEGREES	'0.02618 0.02618 0.02618'
#define VECTOR_CONE_4DEGREES	'0.03490 0.03490 0.03490'
#define VECTOR_CONE_5DEGREES	'0.04362 0.04362 0.04362'
#define VECTOR_CONE_6DEGREES	'0.05234 0.05234 0.05234'
#define VECTOR_CONE_7DEGREES	'0.06105 0.06105 0.06105'
#define VECTOR_CONE_8DEGREES	'0.06976 0.06976 0.06976'
#define VECTOR_CONE_9DEGREES	'0.07846 0.07846 0.07846'
#define VECTOR_CONE_10DEGREES	'0.08716 0.08716 0.08716'
#define VECTOR_CONE_15DEGREES	'0.13053 0.13053 0.13053'
#define VECTOR_CONE_20DEGREES	'0.17365 0.17365 0.17365'
#define VECTOR_CONE_DM_SHOTGUN	'0.08716 0.04362 0.00'
#define VECTOR_CONE_DM_DOUBLESHOTGUN '0.17365 0.04362 0.00'

#define USE_OFF 	0
#define USE_ON		1
#define USE_SET		2
#define USE_TOGGLE 	3
float useType;
float useValue;

////////////// PLAYER STATES /////////////////

float STATE_IDLE = 1;
float STATE_AIM = 2;
float STATE_RUN = 4;
float STATE_CROUCH = 8;

////////////// PLAYER STATS /////////////////

float STAT_ZOOM = 32;	// .viewzoom as 0..255; stats arrive as integers on FTE. Only FTE's CSQC reads it, DP applies viewzoom natively
float STAT_TOTALITEMS = 33;
float STAT_PICKED_ITEMS = 34;
float STAT_SHOTS = 35;
float STAT_HITS = 36;
float STAT_MONEY = 38;
float STAT_VEC1 = 39;
float STAT_VEC2 = 40;
float STAT_VEC3 = 41;
float STAT_INCROSS = 42;
float STAT_CLIP = 43;
float STAT_WEAPONS = 44;
float STAT_FLASHBAT = 45;	// HEV flashlight battery 0..100
float STAT_FLASHLIGHT = 46; // flashlight on/off bool
float STAT_TRAIN = 47;	// train-control HUD state
float STAT_DMGBITS = 48;    // latched DMG_SHOWNHUD bits for HUD damage icons
float STAT_PLAYERFLAGS = 49;	// player .flags (client needs FL_ONGROUND for +use slowdown)
// .punchangle in tenths of a degree, for client aim recoil. FTE leaves the
// engine's own view_punchangle global empty in CSQC, so the value has to be
// networked by hand. 69+ because a downstream game owns 50..68.
float STAT_PUNCH_X = 69;
float STAT_PUNCH_Y = 70;

float FLASH_DRAIN_TIME  = 1.2;
float FLASH_CHARGE_TIME = 0.2;
float FLASH_BATTERY_MAX = 100;

.float vec1;
.float vec2;
.float vec3;
.float incross;

.float picked_items;
.float total_shots;
.float flashlight_battery;	// 0..100
.float flashlight_on;	// bit equivalent
.float flashlight_time;
.float chlevel_lastTouchTime; // anti-ping-pong for trigger_changelevel touch

.float player_longJump;
.float duckStartTime;	// when crouch was pressed; window gate

.float m_speed;
.float total_hits;
.float item;

.float deaths;              // multiplayer scoreboard; .frags is the engine field

//////////////// FIELDS ////////////////

//quake
float skill;
float gameover;		// set when a rule exits
// Q1 intermission state (defined in serverqc/func/q1_intermission.qc).
float intermission_running;
float intermission_exittime;
float	movedist;
entity	activator;
entity	damage_attacker;	// set by T_Damage

.void()		think1;
.vector		finaldest, finalangle;
.float 		delay;
.string		killtarget;
.string		globalname;

.float	attack_state;
.entity		oldenemy;		// mad at this player before taking damage
.float		pain_finished;
.float		show_hostile;	// set to time+0.2 whenever a client fires a weapon or takes damage. Used to alert monsters that otherwise would let the player go
.float 		attack_finished;
.float		pain_finished;
.float		air_finished;	// when time > air_finished, start drowning

.string		mdl;
.float		state;

.float		dmg;			// damage done by door when hit
.float		speed;
.float		jump_flag;		// player jump flag
.float		swim_flag;		// player swimming sound flag
.float		air_finished;	// when time > air_finished, start drowning
.float 		pausetime;
.float		lefty;
.float		search_time;

//
// sounds
//
.float		waitmin, waitmax;
.float		distance;
.float		volume;
.float		pitch;
//
// doors, etc
//
.vector		dest, dest1, dest2;
.float		wait;			// time from firing to restarting
.float		delay;			// time from activation to firing
.entity		trigger_field;	// door's trigger entity
.string		noise4;
.float		lip;
.float		state;
.vector		pos1, pos2;		// top and bottom positions
.float		height;
.float		t_length, t_width;
.vector		mangle;			// angle at start
.vector		oldorigin;		// only used by secret door
.float		count;
.float		cnt;			// id1 misc flag / train bookkeeping
.float		worldtype;		// id1 worldspawn theme: 0 medieval, 1 metal, 2 base
.string 	map;
.entity 	movetarget;

string __fullspawndata;

//AI
.void()									th_stand;
.void()									th_walk;
.void()									th_run;
.void()									th_missile;
.void()									th_melee;
.void(entity attacker, float damage) 	th_pain;
.void()									th_die;
.void()									th_gib;
.void() 								sightSound;
.float() 								checkAttack;
.void(entity attacker, float damage, vector dir, float damageBits) traceAttack;
// .void(entity pActivator, entity pCaller, float useType, float value) Use;

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
.float duckedInAir;
.float q1_monster;

.float footstep_finished;

// Player animation system
.float    basebone;
.float    baseframe;
.float    baseframe1time;
.float    baseframe2;
.float    baseframe2time;
.float    baselerpfrac;

.float    anim_basebone;          // cached spine bone index for basebone cutoff
.string   anim_legs;              // current legs anim name (for change detection)
.string   anim_torso;             // current torso anim name (for change detection)
.float    anim_torso_end_time;    // time at which torso one-shot frees up
.float    anim_torso_locked;      // 1 = torso playing a one-shot, no re-pick
.float    bot_isBot;             // this client is a bot (serverqc/bot)
.float    anim_death_seq;         // chosen death anim frame index (set once in Player_Die)
.float    anim_idle_since;
.float    anim_groundTime;        // last frame the player held FL_ONGROUND
.float    anim_waterTime;         // last frame the player was in swimmable water

.float    last_hitgroup;          // HITGROUP_* of most recent damage
.vector   last_attacker_dir;      // normalize(attacker.origin - self.origin), unit vec

#define HITGROUP_GENERIC        0
#define HITGROUP_HEAD           1
#define HITGROUP_CHEST          2
#define HITGROUP_STOMACH        3
#define HITGROUP_LEFTARM        4
#define HITGROUP_RIGHTARM       5
#define HITGROUP_LEFTLEG        6
#define HITGROUP_RIGHTLEG       7

.float geiger_range;

// func_pushable preset hull selector (set by "size" map key, 0..3)
.float m_iSize;

.float type;

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
.float trainHudState;
.vector aimofs;

.float ammo9x18, ammo9x19, ammo357, ammo545x39, ammo9x39, ammo762x39, ammo762x54, ammoBat, ammoShells, ammoGrenades, ammoVog, ammoBolts, ammoRockets, ammoSatchels, ammoTripmines, ammoUranium, ammoHornets, ammoSnarks, ammo45acp, ammo556x45;

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
.float renderamt;
.float renderfx;
.vector rendercolor;

.float brushWaterMode;       // player currently inside a skin-water brush volume
.float waterBrushTouchTime;  // last time a skin-water brush touched this player

.float inFrictionVol;        // player currently inside a func_friction volume
.float frictionTouchTime;    // last time a func_friction volume touched this player
void Player_FrictionTick();
void Player_FrictionRelease();   // restore friction on disconnect/respawn

.float iMagnitude; //breakable + env_explosion + func_tankmortar

// func_tank state. Mortar reuses iMagnitude above.
.entity tank_controller;
.float  m_flNextAttack;
.vector tank_controllerUsePos;
.float  tank_yawCenter, yawrate, yawrange, yawtolerance;
.float  tank_pitchCenter, pitchrate, pitchrange, pitchtolerance;
.float  tank_fireLast, firerate;
.float  tank_lastSightTime, persistence;
.float  minRange, maxRange;
.vector m_barrelPos;                  // assembled from the barrel/barrely/barrelz keys
.float  preset;	// key: speaker
.float  activity;	// key: info_node hint activity
.float  amount;	// key: env_blood
.float  barrel, barrely, barrelz;	// keys: barrel offset components
.string rotatesound, laserentity;	// keys
.float  spritescale;
.string spritesmoke, spriteflash;
.float  bullet;
.float  bullet_damage;
.vector tank_sightOrigin;
.float  firespread;
.entity tank_ent;        // on player: tank being driven; on func_tankcontrols: linked tank
.entity tank_laser;       // tanklaser: linked env_laser
.float  tank_laserTime;    // tanklaser: turn-off scheduler
.void(vector barrelEnd, vector forward, entity attacker) tankFire;
// .float classify;
.float		storedUseType;
.float		storedUseValue;
.void(entity pActivator, entity pCaller, float useType, float useValue) usehl;	// Use callback. Dispatch prefers this over .use when set.

// Powerups
.float invincible_finished;
.float invisible_finished;
.float super_damage_finished;
.float radsuit_finished;
.float invincible_time, invincible_sound;
.float invisible_time, invisible_sound;
.float super_time, super_sound;
.float rad_time;

#ifdef SVQC
.float(entity inflictor, entity attacker, float damage, float dmgType) takeDmgFn;
.float damagetype;
.float player_viewZoom255;	// .viewzoom rescaled for STAT_ZOOM, which cannot carry a fraction
.float player_punch10x, player_punch10y;	// .punchangle rescaled the same way, stats truncate to integers
#endif

//////////////// CVARS /////////////////

void RegisterCvar(string cv, string def)
{
#ifdef MENUQC
	registercvar(cv, def, 0);
#else
	registercvar(cv, def);
#endif
	if(IsFTE() && cvar_string(cv) == "") cvar_set(cv, def); //stupid fte fix, idk what to do
}

void RegisterCustomCvars()
{
	RegisterCvar("hud_draw", "1");
	RegisterCvar("hud_fastswitch", "0");
	RegisterCvar("bot_stop", "0");
	RegisterCvar("gamemode", "0");
	RegisterCvar("antiafk", "0");
	RegisterCvar("crosshair_static", "1");
	RegisterCvar("crosshair_color_red", "1");
	RegisterCvar("crosshair_color_green", "1");
	RegisterCvar("crosshair_color_blue", "1");
	RegisterCvar("crosshair_size", "0.5");
	RegisterCvar("violence_hgibs", "1");
	RegisterCvar("violence_agibs", "1");
	RegisterCvar("sv_hitmodel", "1");
	RegisterCvar("cl_weather", "1");
	RegisterCvar("cl_weather_rain", "0");
	RegisterCvar("cl_weather_snow", "0");
	RegisterCvar("cl_weather_rain_velocity", "0 0 -700");
	RegisterCvar("cl_weather_snow_velocity", "0 0 -300");
	RegisterCvar("cl_weather_rain_count", "4");
	RegisterCvar("cl_weather_snow_count", "10");
	RegisterCvar("cl_weather_rain_cnt", "2");
	RegisterCvar("cl_weather_snow_cnt", "11");
	RegisterCvar("landmark", "");
	RegisterCvar("landmark_pos", "");
	RegisterCvar("landmark_player_pos", "");
	RegisterCvar("landmark_player_angles", "");
	RegisterCvar("landmark_player_velocity", "");
	RegisterCvar("landmark_train", "");
	RegisterCvar("landmark_train_globalname", "");
	RegisterCvar("landmark_train_pos", "");
	RegisterCvar("landmark_train_angles", "");
	RegisterCvar("landmark_train_velocity", "");
	RegisterCvar("landmark_train_avelocity", "");
	RegisterCvar("landmark_train_path", "");
	RegisterCvar("landmark_train_target", "");
	RegisterCvar("landmark_train_targ", "");
	RegisterCvar("landmark_train_speed", "");
	RegisterCvar("landmark_train_mspeed", "");
	RegisterCvar("landmark_train_startspeed", "");
	RegisterCvar("landmark_train_dir", "");
	RegisterCvar("landmark_train_spawnflags", "");
	RegisterCvar("id1_serverflags", "");
	RegisterCvar("xfer_firetarget", "");
	RegisterCvar("xfer_firedelay", "0");
	RegisterCvar("g_lastSaveSlot", "");
	RegisterCvar("g_lastSaveTime", "0");
	RegisterCvar("g_lastSaveMap",  "");
	RegisterCvar("g_deathRestart", "0");
	RegisterCvar("g_pendingLoad", "");

	// index of maps with a valid _hub_<map>.sav, plus the transition/restore
	// handshake flags. All non-archived; engine restart clears them.
	RegisterCvar("hub_maps", "");
	RegisterCvar("hub_transition", "0");
	RegisterCvar("hub_restore_pending", "");
	RegisterCvar("hub_loaded", "0");
	RegisterCvar("hub_serial", "0");

	// "A changelevel staged a transfer" flag. The inventory itself lives in
	// per-client "xfer<slot>_*" cvars registered on demand by transfer.qc.
	RegisterCvar("xfer_valid", "0");

	// Multiplayer.
	RegisterCvar("g_startwithsuit", "0");
	RegisterCvar("mp_coop_maxplayers", "4");

	// registercommand (#352) is EXT_CSQC, added to DarkPlaces after the base
	// engine shipped; an older build doesn't have builtin #352 at all, and
	// calling an unbound builtin number is a fatal Host_Error, not a no-op,
	// so this has to be detected before the first call rather than caught
	// after. checkextension is builtin #99, itself the one thing every
	// extension-aware engine is guaranteed to implement, per its own doc
	// comment in dpextensions.qc; pr_checkextension gates even that, for an
	// engine with no extension system at all.
	if (cvar("pr_checkextension") && checkextension("EXT_CSQC"))
	{
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
}
