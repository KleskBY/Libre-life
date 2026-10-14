void(string s, ...) cmd = #46;
string(string s) str_cvar = #448;

.string message;

/////////// GLOBALS ////////////

float MOVE_NETWORK_ENTITIES_BAKER_4096 = 4096;	
entity player;
vector playerOrigin;
float playerHealth, playerArmor, playerAmmo, playerClip, playerWeapon, playerHeight, playerFrame;
float playerWeaponBits, playerHasSuit;
float playerFlashBattery, playerFlashOn;
float playerTrainHud;
float playerFlags;

float painFront, painRear, painLeft, painRight;
float isAttacking, isWalking, isCrouching, isJumping, isUsing;
float Player_IsAlive();

float showScores;
float completedTime;

float showInventory;

float aiming;

vector LookAtPos;
float LookAtTime;
float LookAtSpeed = 36;

.float  cam_active;
.vector cam_prev_origin;
.vector cam_prev_angles;
.float  cam_prev_time;     // server time at which prev snapshot arrived
.float  cam_recv_time;     // server time at which latest snapshot arrived

.float renderflags;
.float light_lev;
.float pflags;
.float pmove_flags;

//Compatibility
.vector view_ofs;
.float health;
.float deadflag;

float Stat_GetInt(float stat)
{
	float v = getstati(stat, 0, 24);	// bit form reads the int stat on FTE; the plain form there is getstatf and warns
	if (getstati(stat, 31, 1)) v = v - 16777216;
	return v;
}
