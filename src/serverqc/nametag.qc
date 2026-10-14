// Nametag roster: which player slots may carry a name above the head, and on
// which side. One character per slot, broadcast only when it changes:
//
//   ntag <roster>      '-' not taggable, '0' no side, '1'..'9' a side
//
// The client draws the tags (clientqc/hud/hud_nametags.qc). Side comes from the
// stock .team field, the same one combat.qc reads for friendly fire. See
// docs/guide/08-player.md, "Nametags".

#define NAMETAG_PUBLISH_RATE 0.2   // seconds between roster rebuilds

string g_nametagRoster;     // zoned copy of the last roster sent
float  g_nametagZoned;
float  g_nametagNextAt;

// An observer keeps health 666 and DEAD_NO, so the classname is the real test.
string Nametag_SlotChar(entity p)
{
	if (p.classname != "player") return "-";
	if (!(p.flags & FL_CLIENT)) return "-";
	if (p.deadflag != DEAD_NO || p.health <= 0) return "-";
	if (!p.modelindex) return "-";

	float gm = cvar("gamemode");
	if (gm == MODE_COOP || gm == MODE_SURV) return "1";
	if (p.team >= 1 && p.team <= 9) return ftos(p.team);
	return "0";
}

string Nametag_BuildRoster()
{
	float top = -1;
	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
	{
		float s = num_for_edict(c) - 1;
		if (s > top) top = s;
	}

	string r = "";
	for (float i = 0; i <= top; i = i + 1)
		r = strcat(r, Nametag_SlotChar(edict_num(i + 1)));
	return r;
}

void Nametag_SendTo(entity dest)
{
	if (!dest) return;
	stuffcmd(dest, strcat("ntag ", g_nametagRoster, "\n"));
}

void Nametag_Frame()
{
	if (!IsMultiplayer()) return;
	if (time < g_nametagNextAt) return;
	g_nametagNextAt = time + NAMETAG_PUBLISH_RATE;

	string r = Nametag_BuildRoster();
	if (g_nametagZoned && r == g_nametagRoster) return;
	if (g_nametagZoned) strunzone(g_nametagRoster);
	g_nametagRoster = strzone(r);
	g_nametagZoned = TRUE;

	for (entity c = findchainflags(flags, FL_CLIENT); c; c = c.chain)
		Nametag_SendTo(c);
}
