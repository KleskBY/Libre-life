// bot_add, bot_kick, `cmd bot ...` diagnostics, and the debug dump.
//
// Last of the bot files in the manifest so it needs no prototypes, the same
// arrangement anomaly_spawncmd.qc uses.

string Bot_StateName(float s)
{
	if (s == BSTATE_COMBAT) return "combat";
	if (s == BSTATE_HUNT)   return "hunt";
	if (s == BSTATE_REVIVE) return "revive";
	if (s == BSTATE_COVER)  return "cover";
	if (s == BSTATE_REARM)  return "rearm";
	if (s == BSTATE_PEEK)   return "peek";
	if (s == BSTATE_FLANK)  return "flank";
	if (s == BSTATE_PUSH)   return "push";
	if (s == BSTATE_HEAL)   return "heal";
	return "roam";
}

string Bot_BackendName()
{
	if (g_qkBotBackend == BOT_BACKEND_MOVEMENT) return "movement";
	if (g_qkBotBackend == BOT_BACKEND_STDPHYS)  return "stdphysics";
	if (g_qkBotBackend == BOT_BACKEND_VELOCITY) return "velocity";
	return "unset";
}

void Bot_DebugDump()
{
	sprint(self, strcat("bots: ", ftos(Bot_Count()), " of ",
	                    ftos(rint(cvar("bot_quota"))), ", backend ",
	                    Bot_BackendName(), "\n"));
	// Links matter more than nodes: a graph with nodes and no links routes
	// nothing, and looks identical from the node count alone.
	sprint(self, strcat("nav: ", (WP_Ready() ? "ready " : "absent "),
	                    ftos(wp_count), " nodes ", ftos(wp_linkCount), " links",
	                    WPG_Active() ? " (generating)" : "", "\n"));

	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
	{
		if (!Bot_IsBot(c)) continue;

		string line = strcat("  ", c.netname, " ", Bot_StateName(c.bot_state),
		                     " skill ", ftos(rint(c.bot_skill * 100)));
		line = strcat(line, " hp ", ftos(rint(c.health)),
		                    c.bot_target ? " engaged" : " idle");
		// An observer reads as alive everywhere else, so name it here.
		if (c.classname != "player") line = strcat(line, " OBSERVER");
		else if (c.bot_down)          line = strcat(line, " DOWN");
		// What it is trying to do. This is what separates a movement fault from
		// a pathing one: wish 0 means it never asked to move.
		line = strcat(line, " wish ", ftos(rint(c.bot_wishSpeed * 100)),
		                    " goal ", ftos(rint(vlen(c.bot_goal - c.origin))));
		line = strcat(line, " hop ", ftos(c.bot_pathPos), "/", ftos(c.bot_pathLen),
		              " ", WPL_TypeName(Bot_LinkType(c)));
		sprint(self, strcat(line, " stuck ", ftos(c.bot_stuckStage),
		                    " spd ", ftos(rint(vlen(c.velocity))), "\n"));

		// Vertical aim, which is where every sign error in this game shows up.
		// held is what the bot is pointing at, want is where it should be, and
		// punch is the recoil the shot adds on top of both.
		if (c.bot_target)
		{
			vector w = Bot_WantFor(c, Bot_AimPoint(c, c.bot_target));
			sprint(self, strcat("      pitch held ", ftos(rint(c.v_angle_x)),
			                    " want ", ftos(rint(w_x)),
			                    " punch ", ftos(rint(c.punchangle_x)), "\n"));
		}
	}
}

void Bot_CmdAdd(float n)
{
	if (n < 1) n = 1;
	float added = 0;
	for (float i = 0; i < n; i = i + 1)
		if (Bot_Add(Bot_TeamsEnabled() ? Bot_TeamSmallest() : BOT_TEAM_NONE))
			added = added + 1;

	// Keep the manager in step, or the balancer removes what was just added.
	cvar_set("bot_quota", ftos(Bot_Count()));
	sprint(self, strcat("added ", ftos(added), " bot(s)\n"));
}

// A bot by its name with or without bot_prefix.
entity Bot_FindByName(string who)
{
	string prefixed = strcat(cvar_string("bot_prefix"), who);
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
		if (Bot_IsBot(c) && (c.netname == who || c.netname == prefixed))
			return c;
	return world;
}

// No argument kicks every bot, as zBot does.
void Bot_CmdKick(string who)
{
	if (who == "" || who == "all")
	{
		Bot_RemoveAll();
		cvar_set("bot_quota", "0");
		return;
	}

	entity b = Bot_FindByName(who);
	if (!b)
	{
		sprint(self, strcat("bot_kick: no bot named ", who, "\n"));
		return;
	}
	Bot_Remove(b);
	cvar_set("bot_quota", ftos(Bot_Count()));
}

void Bot_Command()
{
	string verb = argv(0);
	if (verb == "bot_add")  { Bot_CmdAdd(stof(argv(1))); return; }
	if (verb == "bot_kick") { Bot_CmdKick(argv(1)); return; }

	string sub = argv(1);

	if (sub == "debug")
	{
		Bot_DebugDump();
		return;
	}

	if (sub == "stuckstats")
	{
		float reset = (argv(2) == "reset");
		for (entity b = findchainflags(flags, FL_CLIENT); b; b = b.chain)
		{
			if (!Bot_IsBot(b)) continue;
			sprint(self, strcat("  ", b.netname, " stuck events ", ftos(b.bot_stuckEvents),
			                    " worst ", ftos(rint(b.bot_stuckWorst * 10) / 10), "s"));
			sprint(self, strcat(" blacklisted ", ftos(WP_BlacklistSize(b)), "\n"));
			if (reset) { b.bot_stuckEvents = 0; b.bot_stuckWorst = 0; }
		}
		return;
	}

	sprint(self, "bot_add [n] | bot_kick [name] | bot_quota <n> | cmd bot debug | cmd bot stuckstats [reset]\n");
}
