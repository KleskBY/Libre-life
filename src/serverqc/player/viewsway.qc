// Viewmodel follow and lean, for FTE only.
//
// DarkPlaces moves the gun against the view with cl_followmodel (position lag)
// and cl_leanmodel (angle lag), and applies them to any entity carrying the
// view-relative render flag, which is what this game's viewmodel is. FTE has
// neither: its two implementations are a pair of FIXME comments. So they are
// computed here instead and added to the viewmodel pose, and Zircon is left to
// its own engine version.
//
// The gun bob is NOT here. Both engines implement cl_bobmodel themselves and
// both apply it to this entity; FTE just defaults the switch to 0, which
// default.cfg now sets.
//
// The filter chain is DarkPlaces', kept step for step so the two engines feel
// the same: highpass the view origin and angles to get something like velocity,
// scale it, then highpass and lowpass THAT to turn velocity into acceleration.
// The long form is in docs/guide/08-player.md, "Viewmodel sway".

.vector sway_orgPrev;      // last frame's view origin
.vector sway_orgHigh;      // origin highpass state, held RELATIVE to sway_orgPrev
.vector sway_angPrev;
.vector sway_angHigh;      // angle highpass state, also relative
.vector sway_orgAdjHigh;
.vector sway_orgAdjLow;
.vector sway_angAdjHigh;
.vector sway_angAdjLow;

// Outputs, already converted into the viewmodel's own space and sign, so every
// call site is a bare addition.
.vector sway_origin;
.vector sway_angles;

// Filter poles and travel limits, at DarkPlaces' defaults. Not cvars: they only
// mean anything as a tuned set, and the four *_speed scalars below are the
// knobs worth turning.
#define SWAY_FOLLOW_SIDE_LIMIT    6
#define SWAY_FOLLOW_SIDE_HP1      30
#define SWAY_FOLLOW_SIDE_HP       5
#define SWAY_FOLLOW_SIDE_LP       10
#define SWAY_FOLLOW_UP_LIMIT      5
#define SWAY_FOLLOW_UP_HP1        60
#define SWAY_FOLLOW_UP_HP         2
#define SWAY_FOLLOW_UP_LP         10

#define SWAY_LEAN_SIDE_LIMIT      35
#define SWAY_LEAN_SIDE_HP1        30
#define SWAY_LEAN_SIDE_HP         3
#define SWAY_LEAN_SIDE_LP         20
#define SWAY_LEAN_UP_LIMIT        50
#define SWAY_LEAN_UP_HP1          5
#define SWAY_LEAN_UP_HP           15
#define SWAY_LEAN_UP_LP           20

// Further than a frame of movement can legitimately cover, but far short of a
// teleport. A sprint crosses about four units per input frame.
#define SWAY_SNAP_DIST            200

#define SWAY_CVAR_REFRESH         0.25

// Declared bare and assigned in code. A global with a literal initialiser
// compiles as a CONSTANT here and every later assignment silently does nothing.
float sway_cvarNext;
float sway_follow;
float sway_lean;
float sway_followSideSpeed;
float sway_followUpSpeed;
float sway_leanSideSpeed;
float sway_leanUpSpeed;

void Viewsway_RefreshCvars()
{
	if (time < sway_cvarNext) return;
	sway_cvarNext = time + SWAY_CVAR_REFRESH;

	sway_follow = cvar("cl_followmodel");
	sway_lean   = cvar("cl_leanmodel");

	sway_followSideSpeed = cvar("cl_followmodel_side_speed");
	sway_followUpSpeed   = cvar("cl_followmodel_up_speed");
	sway_leanSideSpeed   = cvar("cl_leanmodel_side_speed");
	sway_leanUpSpeed     = cvar("cl_leanmodel_up_speed");

	// FTE has no engine defaults for any of these, so an unset cvar reads 0 and
	// would silently disable the effect it names.
	if (sway_followSideSpeed <= 0) sway_followSideSpeed = 0.25;
	if (sway_followUpSpeed   <= 0) sway_followUpSpeed   = 0.5;
	if (sway_leanSideSpeed   <= 0) sway_leanSideSpeed   = 0.7;
	if (sway_leanUpSpeed     <= 0) sway_leanUpSpeed     = 0.65;
}

void Viewsway_Reset(entity p)
{
	// Clearing prev is what marks the filters unseeded: Viewsway_Step reseeds
	// from the live view on the next frame it runs rather than treating the
	// whole distance from the world origin as one frame of movement.
	p.sway_orgPrev     = '0 0 0';
	p.sway_angPrev     = '0 0 0';
	p.sway_orgHigh     = '0 0 0';
	p.sway_angHigh     = '0 0 0';
	p.sway_orgAdjHigh  = '0 0 0';
	p.sway_orgAdjLow   = '0 0 0';
	p.sway_angAdjHigh  = '0 0 0';
	p.sway_angAdjLow   = '0 0 0';
	p.sway_origin      = '0 0 0';
	p.sway_angles      = '0 0 0';
}

void Viewsway_Step(entity p)
{
	// Zircon computes both of these in the engine and applies them to this same
	// entity, so running them here as well would double the effect.
	//
	// cl_viewsway must be created by default.cfg, in both gamedirs: an unset
	// cvar reads 0 here, which is indistinguishable from someone turning it off.
	if (!IsFTE() || cvar("cl_viewsway") == 0)
	{
		p.sway_origin = '0 0 0';
		p.sway_angles = '0 0 0';
		return;
	}

	Viewsway_RefreshCvars();

	if (!sway_follow && !sway_lean)
	{
		p.sway_origin = '0 0 0';
		p.sway_angles = '0 0 0';
		return;
	}

	vector org = p.origin + p.view_ofs;
	vector ang = p.v_angle;
	float dt = frametime;

	// A hidden frame (dead, intermission, mind grabbed, observer) returns before
	// the pose runs, so prev can be stale by a whole map when the gun comes back.
	// The lean limits are 35 and 50 degrees, wide enough for that to lurch.
	if (dt <= 0 || p.sway_orgPrev == '0 0 0'
	    || vlen(org - p.sway_orgPrev) > SWAY_SNAP_DIST)
	{
		Viewsway_Reset(p);
		p.sway_orgPrev = org;
		p.sway_angPrev = ang;
		return;
	}

	vector frac, limit, store, outOrg, outAng;

	// The highpass state is held relative to prev so the number stays small.
	// Rebase to absolute, filter, then subtract back.
	frac  = dt * [SWAY_FOLLOW_SIDE_HP1, SWAY_FOLLOW_SIDE_HP1, SWAY_FOLLOW_UP_HP1];
	limit = [SWAY_FOLLOW_SIDE_LIMIT, SWAY_FOLLOW_SIDE_LIMIT, SWAY_FOLLOW_UP_LIMIT];
	store = p.sway_orgHigh + p.sway_orgPrev;
	store = Math_Lowpass3Limited(org, frac, limit, store);
	outOrg = org - store;
	p.sway_orgPrev = org;
	p.sway_orgHigh = store - org;

	// Angles put the UP pair on pitch and the SIDE pair on yaw, which is not the
	// axis order the origin uses; swapping them feels plausible and is wrong.
	frac  = dt * [SWAY_LEAN_UP_HP1, SWAY_LEAN_SIDE_HP1, 0];
	limit = [SWAY_LEAN_UP_LIMIT, SWAY_LEAN_SIDE_LIMIT, 0];
	store = p.sway_angHigh + p.sway_angPrev;
	// Wrap the STORE to the turn nearest the input, not to [-180,180] about zero:
	// a continuous spin would otherwise lurch once per revolution.
	store_x += 360 * floor((ang_x - store_x) / 360 + 0.5);
	store_y += 360 * floor((ang_y - store_y) / 360 + 0.5);
	store_z += 360 * floor((ang_z - store_z) / 360 + 0.5);
	store = Math_Lowpass3Limited(ang, frac, limit, store);
	outAng = ang - store;
	p.sway_angPrev = ang;
	p.sway_angHigh = store - ang;

	if (!sway_follow) outOrg = '0 0 0';
	if (!sway_lean)   outAng = '0 0 0';

	outOrg = [outOrg_x * -sway_followSideSpeed,
	          outOrg_y * -sway_followSideSpeed,
	          outOrg_z * -sway_followUpSpeed];
	outAng = [outAng_x * -sway_leanUpSpeed, outAng_y * -sway_leanSideSpeed, 0];

	// Highpass then lowpass, which turns the velocity above into acceleration.
	// The lowpass runs LAST so its state IS the final vector.
	frac = dt * [SWAY_FOLLOW_SIDE_HP, SWAY_FOLLOW_SIDE_HP, SWAY_FOLLOW_UP_HP];
	p.sway_orgAdjHigh = Math_Lowpass3(outOrg, frac, p.sway_orgAdjHigh);
	outOrg = outOrg - p.sway_orgAdjHigh;
	frac = dt * [SWAY_FOLLOW_SIDE_LP, SWAY_FOLLOW_SIDE_LP, SWAY_FOLLOW_UP_LP];
	p.sway_orgAdjLow = Math_Lowpass3(outOrg, frac, p.sway_orgAdjLow);
	outOrg = p.sway_orgAdjLow;

	frac = dt * [SWAY_LEAN_UP_HP, SWAY_LEAN_SIDE_HP, 0];
	p.sway_angAdjHigh = Math_Lowpass3(outAng, frac, p.sway_angAdjHigh);
	outAng = outAng - p.sway_angAdjHigh;
	frac = dt * [SWAY_LEAN_UP_LP, SWAY_LEAN_SIDE_LP, 0];
	p.sway_angAdjLow = Math_Lowpass3(outAng, frac, p.sway_angAdjLow);
	outAng = p.sway_angAdjLow;

	// The origin delta came out in world axes and the viewmodel's origin is read
	// in view space. The Y negation is the engine's, not a fudge: the weapon
	// matrix has its right vector inverted, so the model's local +Y is view LEFT.
	makevectors(ang);
	p.sway_origin = [outOrg * v_forward, 0 - (outOrg * v_right), outOrg * v_up];

	// Angles came out in the view convention, where positive pitch looks down.
	// Entity render angles use the opposite sign, the same flip Viewmodel_Kick
	// applies to punchangle.
	p.sway_angles = [0 - outAng_x, outAng_y, 0];
}
