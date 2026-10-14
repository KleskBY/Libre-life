// How a bot points its weapon, which is most of what decides whether it reads as
// a person or a turret.
//
// Six things do the work, roughly in order of how much each contributes:
//
//   reaction     nothing happens at all for a beat after a target appears
//   body point   low skill shoots at the chest, high skill at the head
//   bad lead     the intercept is deliberately under estimated, never perfect
//   slow error   the aim offset wanders rather than jittering per frame
//   settle       a slightly underdamped approach, so a fast snap overshoots
//   turn cap     a hard limit on degrees per second
//
// The fourth is the one worth protecting. Per frame randomness reads as a
// machine shaking; an offset that drifts over a third of a second reads as a
// hand that is not quite steady.

#define BOT_AIM_DAMP        0.82
#define BOT_AIM_ACCEL       60
#define BOT_AIM_TURN_BASE   340    // degrees per second at skill 0
#define BOT_AIM_TURN_SKILL  520    // added at skill 1
#define BOT_AIM_ERR_HOLD_LO 0.22   // seconds an error offset is held
#define BOT_AIM_ERR_HOLD_HI 0.45

// Per axis shortest difference; Math_AngleDistance (math.qc) does one axis.
vector Bot_AngleDelta3(vector want, vector cur)
{
	return [Math_AngleDistance(want_x, cur_x), Math_AngleDistance(want_y, cur_y), 0];
}

// A look direction in the convention .v_angle is actually stored in: vectoangles
// returns pitch positive UP, every consumer runs it through makevectors which
// reads positive as DOWN, so the pitch is normalised and negated here, once.
// Without the normalise an engine that wraps pitch into 0..360 hands back 350,
// which negates to -350 and hits the clamp in Bot_Aim as 80 degrees the wrong way.
vector Bot_LookAngles(vector dir)
{
	vector a = vectoangles(dir);
	return [0 - Math_AngleDistance(a_x, 0), Math_AngleDistance(a_y, 0), 0];
}

// RECOIL HAS TO BE DECAYED AND AIMED THROUGH, BOTH.
//
// Weapon_FireShot fires along v_angle PLUS punchangle, and the engine only
// decays punchangle while processing a real client's move packet. A bot has no
// packet, so its recoil accumulates without bound: the AK adds up to 2.2 degrees
// of upward punch per shot, so a bot walks its fire into the ceiling over a
// magazine and only ever connects on a target above it.
#define BOT_PUNCH_DECAY 9

void Bot_DecayPunch(entity bot)
{
	if (bot.punchangle == '0 0 0') return;

	float k = 1 - frametime * BOT_PUNCH_DECAY;
	if (k < 0) k = 0;
	bot.punchangle = bot.punchangle * k;
	if (vlen(bot.punchangle) < 0.1) bot.punchangle = '0 0 0';
}

// Where to point so the round lands on `p`, pulling down against the current
// punch the way a player does. Scaled by skill, so a poor bot's burst still
// climbs and a good one holds it flat.
vector Bot_WantFor(entity bot, vector p)
{
	vector want = Bot_LookAngles(p - (bot.origin + bot.view_ofs));
	return want - bot.punchangle * (0.3 + bot.bot_skill * 0.7);
}

// Where on the target the bot is trying to put the shot.
vector Bot_AimPoint(entity bot, entity tgt)
{
	// Head bias climbs with skill. A poor bot centre masses and a good one goes
	// for the head, which is exactly how the two look different to play against.
	float bias = 0.15 + bot.bot_skill * 0.75;
	vector p = tgt.origin + tgt.view_ofs * bias;

	// Lead, deliberately imperfect. A bot that solves the intercept exactly is
	// instantly recognisable; one that leads a third of the way trails a
	// strafing player the way a mediocre human does.
	vector rel = p - (bot.origin + bot.view_ofs);
	float dist = vlen(rel);
	if (dist > 1 && tgt.velocity != '0 0 0')
	{
		float travel = dist / 2400;                       // a plausible bullet time
		float frac = bot.bot_skill * 0.85;
		p = p + tgt.velocity * travel * frac;
	}
	return p;
}

// Re-roll the standing error offset. Held for a fraction of a second, then
// walked toward a new one.
void Bot_RollAimError(entity bot)
{
	if (time < bot.bot_aimNextErr) return;
	bot.bot_aimNextErr = time + random(BOT_AIM_ERR_HOLD_LO, BOT_AIM_ERR_HOLD_HI);

	// Wider while moving: nobody shoots straight at a run.
	float move = vlen([bot.velocity_x, bot.velocity_y, 0]) / BOT_SPRINT_SPEED;
	float cone = bot.bot_aim * (1 + move * 0.7);
	if (bot.bot_aimState == STATE_AIM) cone = cone * 0.55;
	if (bot.crouching) cone = cone * 0.8;

	float deg = cone * 57.29578;
	bot.bot_aimErr = [random(0 - deg, deg), random(0 - deg, deg), 0];
}

float Bot_ReactReady(entity bot)
{
	if (!bot.bot_target) return FALSE;
	return time >= bot.bot_sawTime + bot.bot_react;
}

// TRUE when the muzzle is inside `cone` degrees of the target, which is what
// gates firing.
float Bot_OnTarget(entity bot, float cone)
{
	if (!bot.bot_target) return FALSE;

	vector want = Bot_WantFor(bot, Bot_AimPoint(bot, bot.bot_target));
	vector d = Bot_AngleDelta3(want, bot.v_angle);
	return (fabs(d_x) < cone && fabs(d_y) < cone);
}

// Called every frame while alive, not on the planner cadence: the settle curve
// is the point and it needs frame resolution.
void Bot_Aim(entity bot)
{
	vector want;

	Bot_DecayPunch(bot);

	if (bot.bot_target && Bot_ReactReady(bot) && Bot_TargetVisible(bot, bot.bot_target))
	{
		Bot_RollAimError(bot);
		vector p = Bot_AimPoint(bot, bot.bot_target);
		want = Bot_WantFor(bot, p) + bot.bot_aimErr;
	}
	else if (bot.bot_lkp != '0 0 0')
	{
		// Nothing in sight but somewhere worth watching.
		want = Bot_LookAngles(bot.bot_lkp - (bot.origin + bot.view_ofs));
	}
	else if (bot.bot_wishSpeed > 0 && bot.bot_wish != '0 0 0')
	{
		// Look where you are going.
		want = Bot_LookAngles(bot.bot_wish);
	}
	else
	{
		// Idle. Drift slowly so the anti AFK sampler never sees a frozen view,
		// and so a standing bot does not look switched off.
		want = bot.v_angle;
		want_y = want_y + sin(time * 0.3 + bot.bot_seed * 6) * 0.6;
	}

	want_z = 0;
	if (want_x > 80) want_x = 80;
	if (want_x < -80) want_x = -80;

	vector d = Bot_AngleDelta3(want, bot.v_angle);

	// Second order approach. The overshoot on a fast snap is the single most
	// recognisably human artefact in the whole model, so the damping is
	// deliberately just short of critical.
	bot.bot_aimVel = bot.bot_aimVel * BOT_AIM_DAMP
	                 + d * BOT_AIM_ACCEL * frametime;

	float cap = BOT_AIM_TURN_BASE + BOT_AIM_TURN_SKILL * bot.bot_skill;
	float sp = vlen(bot.bot_aimVel);
	if (sp > cap) bot.bot_aimVel = bot.bot_aimVel * (cap / sp);

	vector na = bot.v_angle + bot.bot_aimVel * frametime;
	na_x = Math_Clamp(na_x, -80, 80);
	na_y = Math_AngleMod(na_y);
	na_z = 0;

	bot.v_angle = na;

	// Both, and x zeroed on the body. Server side makevectors consumers read
	// .angles while the firing code and the awareness model read .v_angle.
	bot.angles = [0, na_y, 0];
	bot.fixangle = FALSE;
}
