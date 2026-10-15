// Bot lifecycle: spawning a client with no connection, and the think entity
// that drives it.
//
// THE BRAIN IS A SEPARATE ENTITY, AND IT HAS TO BE.
//
// Two things rule out hanging the bot think off the player frame. First,
// PlayerPostThink returns at `if (!IsAlive(self))` before it reaches
// Player_UpdateGeiger, which is where QUALKER smuggles its per frame player
// work in, so a dead player runs none of it and the between lives buy phase
// would never execute. Second, the player edict's own .think already belongs to
// Player_Dead, and PlayerPreThink actively restores it if anything overwrites
// it. A companion edict sidesteps both and costs one entity.
//
// Respawn itself is unaffected: it rides Player_DeathThink, which PlayerPreThink
// reaches before the alive branch.

void Bot_Frame(entity bot);        // bot_think.qc
// Aggression is rolled INDEPENDENTLY of skill on purpose. Skill decides whether
// a bot hits; aggression decides whether it pushes and whether it takes cover.
// Two bots of the same skill behaving differently is what stops a server of
// them feeling like one opponent copied eight times.
void Bot_Personality(entity bot)
{
	float base = cvar("bot_skill");
	if (base <= 0) base = 0.5;
	if (base > 1) base = 1;

	float s = base + random(-0.2, 0.2);
	if (s < 0) s = 0;
	if (s > 1) s = 1;

	bot.bot_skill     = s;
	bot.bot_aim       = 0.055 - 0.045 * s;
	bot.bot_react     = 0.45 - 0.30 * s + random(0, 0.12);
	bot.bot_aggro     = random();
	bot.bot_rangePref = random(0.6, 1.4);
	bot.bot_seed      = random();
	bot.bot_state     = BSTATE_ROAM;
	bot.bot_goal      = VEC_ORIGIN;
	bot.bot_lkp       = VEC_ORIGIN;
	Bot_ClearPath(bot);
}
void Scoreboard_BroadcastRow(entity p);

float g_qkBotCount;

// The name a bot is about to be given. spawnclient() deliberately skips the
// serverinfo send so the netname can be set before ClientConnect runs, but an
// engine that connects the slot on its own would announce the join first. The
// obituary override reads this so that case still prints a name.
string g_qkBotPendingName;

#define BOT_NAME_COUNT 16
string bot_name[BOT_NAME_COUNT];

void Bot_NameInit()
{
	if (bot_name[0] != "") return;
	bot_name[0]  = "Freeman";    bot_name[1]  = "Calhoun";
	bot_name[2]  = "Kleiner";    bot_name[3]  = "Rosenberg";
	bot_name[4]  = "Keller";     bot_name[5]  = "Cross";
	bot_name[6]  = "Shephard";   bot_name[7]  = "Otis";
	bot_name[8]  = "Walter";     bot_name[9]  = "Colette";
	bot_name[10] = "Gina";       bot_name[11] = "Harold";
	bot_name[12] = "Luther";     bot_name[13] = "Simmons";
	bot_name[14] = "Isaac";      bot_name[15] = "Gordon";
}

float Bot_IsBot(entity e)
{
	if (!e) return FALSE;
	return e.bot_isBot;
}

float Bot_Count()
{
	float n = 0;
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
		if (Bot_IsBot(c)) n = n + 1;
	return n;
}

float Bot_HumanCount()
{
	float n = 0;
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
		if (!Bot_IsBot(c)) n = n + 1;
	return n;
}

// A name nobody on the server is already using.
string Bot_PickName()
{
	Bot_NameInit();

	string prefix = cvar_string("bot_prefix");
	float start = rint(random(0, BOT_NAME_COUNT - 1));

	for (float pass = 0; pass < BOT_NAME_COUNT; pass = pass + 1)
	{
		float i = start + pass;
		while (i >= BOT_NAME_COUNT) i = i - BOT_NAME_COUNT;

		string want = strcat(prefix, bot_name[i]);
		float taken = FALSE;
		for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
			if (c.netname == want) taken = TRUE;
		if (!taken) return want;
	}

	// Every callsign is out; fall back to a numbered one.
	return strcat(prefix, "Stalker", ftos(g_qkBotCount + 1));
}

void Bot_BrainThink()
{
	self.nextthink = time + BOT_TICK;

	entity bot = self.bot_owner;
	if (!bot || wasfreed(bot) || clienttype(bot) != CLIENTTYPE_BOT)
	{
		remove(self);
		return;
	}

	entity oself = self;
	self = bot;
	Bot_Frame(bot);
	self = oself;
}

void Bot_AttachBrain(entity b)
{
	if (b.bot_brainEnt && !wasfreed(b.bot_brainEnt)) return;

	entity brain = spawn();
	brain.classname  = "bot_brain";
	brain.solid      = SOLID_NOT;
	brain.movetype   = MOVETYPE_NONE;
	brain.bot_owner = b;
	brain.think      = Bot_BrainThink;
	brain.nextthink  = time + BOT_TICK;
	b.bot_brainEnt    = brain;
}

// `restart` keeps the client slots but wipes every edict, so a bot comes back
// as a client with bot_isBot clear and no brain, and stands still. Claim it back.
void Bot_Readopt()
{
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
	{
		if (clienttype(c) != CLIENTTYPE_BOT) continue;
		if (!c.bot_isBot)
		{
			c.bot_isBot = TRUE;
			c.clientcolors = 4 * 16 + 4;
			Bot_Personality(c);
		}
		Bot_AttachBrain(c);
	}
}

entity Bot_Add(float team)
{
	if (!Bot_Count()) g_qkBotCount = 0;

	string nm = Bot_PickName();

	// Published before spawnclient, so anything the engine announces from inside
	// that call can still find a name.
	if (g_qkBotPendingName) strunzone(g_qkBotPendingName);
	g_qkBotPendingName = strzone(nm);

	entity oself = self;
	entity b = spawnclient();
	if (!b)
	{
		self = oself;
		return world;
	}

	self = b;
	self.bot_isBot = TRUE;
	self.netname  = strzone(nm);
	self.clientcolors = 4 * 16 + 4;

	Bot_Personality(self);

	if (Bot_TeamsEnabled() && team > BOT_TEAM_NONE && team < BOT_TEAM_COUNT)
		self.bot_teamPending = team;

	ClientConnect();

	// ClientConnect can refuse the join and dropclient from inside itself, which
	// is what the cooperative player cap does. Putting a dropped client in the
	// server afterwards would be operating on a slot that no longer exists, so
	// the check goes between the two calls rather than after both.
	if (clienttype(b) != CLIENTTYPE_BOT)
	{
		self = oself;
		return world;
	}

	PutClientInServer();
	self = oself;

	Bot_AttachBrain(b);
	g_qkBotCount = g_qkBotCount + 1;

	// The row that went out during ClientConnect carried no name. Resend it now
	// that there is one.
	Scoreboard_BroadcastRow(b);
	return b;
}

void Bot_Remove(entity bot)
{
	if (!bot || !Bot_IsBot(bot)) return;
	if (bot.bot_brainEnt && !wasfreed(bot.bot_brainEnt)) remove(bot.bot_brainEnt);
	bot.bot_brainEnt = world;
	dropclient(bot);
}

void Bot_RemoveAll()
{
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
		if (Bot_IsBot(c)) Bot_Remove(c);
}

// The bot on `team` that is the cheapest to lose: prefer one already dead, then
// the one with the lowest score.
entity Bot_PickRemoval(float team)
{
	entity best = world;
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
	{
		if (!Bot_IsBot(c)) continue;
		if (team > BOT_TEAM_NONE && c.bot_team != team) continue;
		if (!best) { best = c; continue; }
		if (!IsAlive(c) && IsAlive(best)) { best = c; continue; }
		if (IsAlive(c) != IsAlive(best)) continue;
		if (c.frags < best.frags) best = c;
	}
	return best;
}

float Bot_TeamSmallest();
float Bot_TeamSize(float t);

// Survival waves must not lose a fighter halfway through, so removals wait for
// the gap between them.
float Bot_MayRemoveNow()
{
	if (cvar("gamemode") != MODE_SURV) return TRUE;
	entity s = find(world, classname, "survival");
	if (!s) return TRUE;
	return total_monsters <= 0;
}

// One add or remove per call, never a burst: spawnclient runs the whole connect
// and spawn path, and several in one frame is a visible hitch.
void Bot_Balance()
{
	if (cvar("gamemode") == MODE_SP) return;
	Bot_Readopt();

	float want = rint(cvar("bot_quota"));
	if (want < 0) want = 0;

	float have = Bot_Count();

	if (have < want)
	{
		float team = BOT_TEAM_NONE;
		if (Bot_TeamsEnabled()) team = Bot_TeamSmallest();
		Bot_Add(team);
		return;
	}

	if (have > want && Bot_MayRemoveNow())
	{
		Bot_Remove(Bot_PickRemoval(BOT_TEAM_NONE));
		return;
	}

	// Even count, wrong sides. Never move a live bot across: a team switch costs
	// the life. Drop one from the fat side and let the next tick refill.
	if (have == want && want > 0 && Bot_TeamsEnabled() && Bot_MayRemoveNow())
	{
		float a = Bot_TeamSize(BOT_TEAM_A);
		float b = Bot_TeamSize(BOT_TEAM_B);
		if (a - b >= 2)      Bot_Remove(Bot_PickRemoval(BOT_TEAM_A));
		else if (b - a >= 2) Bot_Remove(Bot_PickRemoval(BOT_TEAM_B));
	}
}
