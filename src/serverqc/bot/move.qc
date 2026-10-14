// Bot locomotion.
//
// THE BACKEND IS MEASURED AT RUNTIME, NOT ASSUMED.
//
// Player movement in this game is engine physics on MOVETYPE_WALK driven by the
// engine's own usercmd. There is no SV_PlayerPhysics, and QC never reads
// .movement outside BetterNoclip. A bot client has no usercmd, so which of the
// three possible ways to push it actually works is an engine question that
// differs between FTE and DarkPlaces derivatives.
//
// Writing .velocity is the default, because it is what this project has already
// been shown to move a bot with. bot_physics forces one of the three, and 0
// puts it back on the self measuring path, which watches whether a bot that is
// asking to move covers ground and escalates if it does not.
//
// That probe is deliberately NOT the default. It cannot tell a backend that does
// nothing apart from a bot that is merely blocked, out of path, or wedged
// against another bot at a spawn point, and getting that wrong strands every bot
// on a backend that is worse than the one it left.
//
// runstandardplayerphysics is bound but never called unless checkextension
// reports it: calling a missing builtin is fatal, while declaring an unused one
// costs nothing.

#define BOT_BACKEND_AUTO      0
#define BOT_BACKEND_VELOCITY  1
#define BOT_BACKEND_MOVEMENT  2
#define BOT_BACKEND_STDPHYS   3

void(entity ent) runstandardplayerphysics = #347;

float Bot_Jump(entity bot, float crouch);

// The input globals the standard physics reads. FTE resolves these by name at
// load, so declaring them here is how they bind; on DarkPlaces they are inert
// globals nothing looks at. Pitch runs the other way round from vectoangles in
// this set: positive is DOWN, which is also how a bot stores .v_angle.
float  input_timelength;
vector input_angles;
vector input_movevalues;
float  input_buttons;

float g_qkBotBackend;
float g_qkBotStdPhysOk;
float g_qkBotProbeTime;
float g_qkBotProbeMoved;

.vector bot_wish;        // unit direction the brain wants to travel
.float  bot_wishSpeed;   // 0..1 of run speed
.vector bot_lastOrg;     // for the backend probe and the stuck check

// Speed shaping is entirely client side for humans (Player_MoveSpeed and friends
// in clientqc/player/player.qc). A bot has no CSQC, so without this it would run
// at whatever the engine defaults to and visibly outpace or trail players.
float Bot_WishSpeed(entity bot)
{
	float base = BOT_WALK_SPEED;
	if (bot.running) base = BOT_SPRINT_SPEED;

	if (bot.crouching)                    base = base * BOT_CROUCH_MULT;
	else if (bot.bot_aimState == STATE_AIM) base = base * BOT_AIM_MULT;

	float capped = cvar("sv_maxspeed");
	if (capped > 0 && base > capped) base = capped;
	return base;
}

void Bot_BackendInit()
{
	if (g_qkBotBackend) return;

	g_qkBotStdPhysOk = FALSE;
	if (cvar("pr_checkextension"))
		g_qkBotStdPhysOk = checkextension("DP_QC_RUNSTANDARDPLAYERPHYSICS");
	if (IsFTE()) g_qkBotStdPhysOk = TRUE;

	float forced = rint(cvar("bot_physics"));
	if (forced > BOT_BACKEND_AUTO && forced <= BOT_BACKEND_STDPHYS)
	{
		g_qkBotBackend = forced;
		return;
	}

	g_qkBotBackend = BOT_BACKEND_VELOCITY;
	g_qkBotProbeTime = 0;
	g_qkBotProbeMoved = time;
}

void Bot_BackendEscalate()
{
	if (rint(cvar("bot_physics")) != BOT_BACKEND_AUTO) return;

	if (g_qkBotBackend == BOT_BACKEND_VELOCITY)
	{
		g_qkBotBackend = BOT_BACKEND_MOVEMENT;
		print("bots: velocity is being clobbered, trying .movement\n");
	}
	else if (g_qkBotBackend == BOT_BACKEND_MOVEMENT && g_qkBotStdPhysOk)
	{
		g_qkBotBackend = BOT_BACKEND_STDPHYS;
		print("bots: .movement is inert, using runstandardplayerphysics\n");
	}
	else if (g_qkBotBackend == BOT_BACKEND_MOVEMENT)
	{
		print("bots: no usable movement backend on this engine, bots will not walk\n");
		g_qkBotBackend = BOT_BACKEND_STDPHYS;   // stop re-probing
	}
	g_qkBotProbeTime = 0;
}

// Watches bots that are asking to move on open ground. Any one of them covering
// distance proves the backend, so the timer only advances while EVERY moving bot
// is getting nowhere. A bot wedged on a spawn point or waiting on a path is not
// evidence that writing velocity does nothing.
void Bot_BackendProbe(entity bot, float wanted)
{
	if (rint(cvar("bot_physics")) != BOT_BACKEND_AUTO) return;
	if (g_qkBotBackend == BOT_BACKEND_STDPHYS) return;

	if (!wanted) return;
	if (!(bot.flags & FL_ONGROUND)) return;

	// Nothing solid immediately ahead, or being blocked would read as the
	// backend failing.
	vector ahead = bot.origin + bot.bot_wish * 40;
	tracebox(bot.origin, bot.mins, bot.maxs, ahead, FALSE, bot);
	if (trace_fraction < 1) return;

	if (vlen(bot.origin - bot.bot_lastOrg) > 4)
	{
		g_qkBotProbeMoved = time;
		return;
	}

	if (time - g_qkBotProbeMoved > 4)
		Bot_BackendEscalate();
}

void Bot_ApplyVelocity(entity bot, vector dir, float speed)
{
	vector want = dir * speed;

	// Vertical motion stays the engine's: gravity, jumps and water all live
	// there, and overwriting z would make a bot hover or sink.
	if (bot.flags & FL_ONGROUND)
	{
		bot.velocity_x = want_x;
		bot.velocity_y = want_y;
	}
	else
	{
		// Airborne: nudge rather than steer, so a jump keeps its arc.
		bot.velocity_x = bot.velocity_x + (want_x - bot.velocity_x) * 0.08;
		bot.velocity_y = bot.velocity_y + (want_y - bot.velocity_y) * 0.08;
	}
}

// .movement IS THE ANIMATION SYSTEM'S INPUT, NOT JUST THE ENGINE'S.
//
// Player_AnimUpdate decides whether a player is walking from
// `p.movement_x != 0 || p.movement_y != 0`, never from velocity. So a bot moved
// by any other backend reads as standing still and plays the idle pose while
// gliding across the floor. This is set on EVERY backend for that reason, not
// only the one that moves the bot with it.
//
// It also feeds WaterBrush_Touch, which is what lets a bot actually swim rather
// than bob. func_ladder skips bots outright, so nothing there is at risk.
void Bot_SetMovement(entity bot, vector dir, float speed)
{
	makevectors([0, bot.v_angle_y, 0]);
	bot.movement = [(dir * v_forward) * speed, (dir * v_right) * speed, 0];
}

void Bot_ApplyStdPhys(entity bot, vector dir, float speed)
{
	if (!g_qkBotStdPhysOk) return;

	makevectors([0, bot.v_angle_y, 0]);
	input_angles     = bot.v_angle;
	input_movevalues = [(dir * v_forward) * speed, (dir * v_right) * speed, 0];
	input_buttons    = bot.button0 + bot.button2 * 2;
	input_timelength = frametime;

	entity oself = self;
	self = bot;
	runstandardplayerphysics(bot);
	self = oself;
}

// The brain sets a goal; this is what actually pushes the body, every frame.
void Bot_Locomote(entity bot)
{
	Bot_BackendInit();

	// Re-asserted every frame: Bot_ClearButtons wipes it at the top of one.
	if (time < bot.bot_crouchUntil) bot.button3 = TRUE;

	vector dir = bot.bot_wish;
	float wanted = (vlen(dir) > 0.1) && (bot.bot_wishSpeed > 0);

	if (wanted)
	{
		dir_z = 0;
		dir = normalize(dir);
		float speed = Bot_WishSpeed(bot) * bot.bot_wishSpeed;

		// Always, whichever backend does the moving: the gait, the footstep code
		// and Player_Stance all read it.
		Bot_SetMovement(bot, dir, speed);

		if (g_qkBotBackend == BOT_BACKEND_STDPHYS)      Bot_ApplyStdPhys(bot, dir, speed);
		else if (g_qkBotBackend != BOT_BACKEND_MOVEMENT) Bot_ApplyVelocity(bot, dir, speed);
	}
	else if (bot.flags & FL_ONGROUND)
	{
		bot.velocity_x = 0;
		bot.velocity_y = 0;
		bot.movement   = '0 0 0';
	}

	Bot_BackendProbe(bot, wanted);
	bot.bot_lastOrg = bot.origin;
}

// Point the body at a world position and ask for a speed. Everything above this
// line is the only thing that changes if the engine answer changes.
void Bot_MoveTo(entity bot, vector goal, float wish)
{
	// Progress is measured against whatever the bot was last sent toward; a new
	// target restarts the measurement (bot/steer.qc).
	if (vlen(goal - bot.bot_progTarget) > 32)
	{
		bot.bot_progTarget = goal;
		bot.bot_progBest   = 99999;
		bot.bot_progAt     = time;
		bot.bot_stuckStage = 0;
	}

	vector d = goal - bot.origin;
	d_z = 0;
	if (vlen(d) < 1) { bot.bot_wishSpeed = 0; return; }

	bot.bot_wish      = normalize(d);
	bot.bot_wishSpeed = wish;
}

void Bot_StopMoving(entity bot)
{
	bot.bot_wish      = '0 0 0';
	bot.bot_wishSpeed = 0;
}

// Sidestep while shooting. The clearance trace is what stops a bot strafing into
// a wall and grinding along it for the whole fight.
void Bot_Strafe(entity bot, vector toward, float dist)
{
	if (time > bot.bot_strafeUntil)
	{
		bot.bot_strafeDir   = (random() < 0.5) ? -1 : 1;
		bot.bot_strafeUntil = time + random(0.3, 0.9);

		// Harder to hit: a skilled bot breaks its rhythm with a hop or a duck.
		if (bot.bot_skill > 0.6 && random() < 0.15)      Bot_Jump(bot, FALSE);
		else if (bot.bot_skill > 0.5 && random() < 0.2)  bot.bot_crouchUntil = time + random(0.3, 0.7);
	}

	makevectors([0, bot.v_angle_y, 0]);
	vector side = v_right * bot.bot_strafeDir;
	vector probe = bot.origin + side * dist;

	tracebox(bot.origin, bot.mins, bot.maxs, probe, FALSE, bot);
	if (trace_fraction < 0.9)
	{
		bot.bot_strafeDir   = 0 - bot.bot_strafeDir;
		bot.bot_strafeUntil = time + random(0.3, 0.9);
		side = v_right * bot.bot_strafeDir;
	}

	bot.bot_wish      = normalize(side + toward * 0.35);
	bot.bot_wishSpeed = 0.85;
}

#define BOT_PROBE_CLEAR   0
#define BOT_PROBE_STEP    1     // blocked low, open at jump height
#define BOT_PROBE_HEAD    2     // blocked standing, open ducked
#define BOT_PROBE_WALL    3
#define BOT_PROBE_LEDGE   4     // open ahead, no floor under it

// The jump core's Player_Jump applies, applied here directly. Core rate limits a
// bot to one jump a second and refuses one within a second of touching
// anything, which is exactly when a bot pinned against a ledge needs to jump.
float Bot_Jump(entity bot, float crouch)
{
	if (!(bot.flags & FL_ONGROUND)) return FALSE;
	if (time < bot.bot_jumpAt) return FALSE;

	bot.bot_jumpAt = time + 0.35;
	bot.velocity_z = bot.velocity_z + 270;
	bot.flags = bot.flags - (bot.flags & FL_ONGROUND);
	bot.lastTouch = time;
	if (crouch) bot.bot_crouchUntil = time + 0.6;   // the air duck hull clears higher ledges

	Sound_Play(bot, CHAN_BODY, 1, Sound_Radius(500), PITCH_NORM, "player/pl_jump2.wav");
	return TRUE;
}

// What is directly ahead, against world and brush entities only, so another
// player in the way never reads as a wall.
float Bot_Probe(entity bot, vector dir)
{
	dir_z = 0;
	if (vlen(dir) < 0.1) return BOT_PROBE_CLEAR;
	dir = normalize(dir);

	vector o  = bot.origin;
	vector mn = PLAYER_STAND_SIZE_MIN;
	vector mx = PLAYER_STAND_SIZE_MAX;

	tracebox(o, mn, mx, o + dir * 24, WP_NOMON, bot);
	if (trace_fraction == 1)
	{
		vector a = trace_endpos;
		tracebox(a, mn, mx, a - '0 0 48', WP_NOMON, bot);
		return (trace_fraction == 1) ? BOT_PROBE_LEDGE : BOT_PROBE_CLEAR;
	}

	tracebox(o, mn, mx, o + '0 0 44', WP_NOMON, bot);
	if (trace_fraction == 1)
	{
		tracebox(o + '0 0 44', mn, mx, o + '0 0 44' + dir * 24, WP_NOMON, bot);
		if (trace_fraction == 1) return BOT_PROBE_STEP;
	}

	tracebox(o, PLAYER_DUCK_SIZE_MIN, PLAYER_DUCK_SIZE_MAX, o + dir * 24, WP_NOMON, bot);
	if (trace_fraction == 1) return BOT_PROBE_HEAD;
	return BOT_PROBE_WALL;
}
