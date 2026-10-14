// MULTIPLAYER MATCH RULES

float rules_nextcheck;
float rules_matchover;

void Rules_EndMatch(string reason)
{
	rules_matchover = 1;
	bprint(reason);
	Q1Intermission_Begin(world, mapname);
}

// Called from StartFrame.
void CheckRules()
{
	float gm = cvar("gamemode");
	if (gm != MODE_DM) return;
	if (rules_matchover || intermission_running || gameover) return;

	if (time < rules_nextcheck) return;
	rules_nextcheck = time + 0.5;

	float tl = cvar("timelimit");
	if (tl > 0 && time >= tl * 60)
	{
		Rules_EndMatch("Time limit reached\n");
		return;
	}

	float fl = cvar("fraglimit");
	if (fl <= 0) return;

	entity best = world;
	for (entity p = find(world, classname, "player"); p; p = find(p, classname, "player"))
	{
		if (p.frags < fl) continue;
		if (!best || p.frags > best.frags) best = p;
	}

	if (best) Rules_EndMatch(strcat(best.netname, " hit the frag limit\n"));
}
