void(string s, ...) cmd = #46;
string(string s) str_cvar = #448;

void localsound(string sample) = 
{
	pointsound('0 0 0', sample, 1, 0);
};

float showCursor;

.string message;



////////////////////////////////
/////////// GLOBALS ////////////
////////////////////////////////


float MOVE_NETWORK_ENTITIES_BAKER_4096 = 4096;	
entity player;
vector playerOrigin;
float playerHealth, playerAmmo, playerClip, playerWeapon, playerHeight, playerFrame;
float isAttacking, isRunning, isCrouching, isJumping;
float Player_IsAlive();

float showScores;
float completedTime;



float showInventory;

float aiming;

vector LookAtPos;
float LookAtTime;
float LookAtSpeed = 36;


.float renderflags;
.float light_lev;
.float pflags;
.float pmove_flags;
