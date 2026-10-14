// Multiplayer scoring, kill feed and the scoreboard broadcast channel.
//
// addstat only ever reaches the client it belongs to, so per-player scores are
// pushed with stuffcmd + CSQC_ConsoleCommand, which uses the same ad-hoc channel
// rest of the mod already uses for hudmsg / scrfade / shockwave / cam. Rows are
// only sent when something changes (connect, disconnect, kill), so the traffic
// is negligible. A freshly loaded CSQC pulls everything with "cmd sbsync" (sv.qc).
// Without SCOREBOARD_KD (gamedefs.qc) deathmatch shows engine frags only and
// sends no rows at all; coop still needs them for its deaths column.
//
//   sbrow <slot> <kills> <deaths>
//   sbdel <slot>
//   obit  "<killer>" "<victim>" <weaponID>

float Player_SlotIndex(entity p);

.float kills;	// kills of other players; unlike .frags a suicide never takes one away

// Set around a kill the player didn't earn (team switch)
// case with m_DisableDeathMessages / m_DisableDeathPenalty.
float g_noDeathPenalty;

// Every connected client, players and observers alike.
entity Scoreboard_ClientChain()
{
	return findchainflags(flags, FL_CLIENT);
}

void Scoreboard_SendRowTo(entity dest, entity p)
{
	if (!dest || !p) return;
#ifndef SCOREBOARD_KD
	if (cvar("gamemode") != MODE_COOP) return;	// deathmatch reads frags from the engine
#endif
	stuffcmd(dest, strcat("sbrow ", ftos(Player_SlotIndex(p)), " ",
	                      ftos(p.kills), " ", ftos(p.deaths), "\n"));
}

// One player's row to everybody.
void Scoreboard_BroadcastRow(entity p)
{
	if (!p) return;
	for (entity c = Scoreboard_ClientChain(); c; c = c.chain)
		Scoreboard_SendRowTo(c, p);
}

// Everybody's rows to one client (used when a client joins mid-game).
void Scoreboard_SendAllTo(entity dest)
{
	if (!dest) return;
	for (entity c = Scoreboard_ClientChain(); c; c = c.chain)
		Scoreboard_SendRowTo(dest, c);
}

void Scoreboard_BroadcastRemove(entity p)
{
	if (!p) return;
	string msg = strcat("sbdel ", ftos(Player_SlotIndex(p)), "\n");
	for (entity c = Scoreboard_ClientChain(); c; c = c.chain)
		if (c != p) stuffcmd(c, msg);
}

// netname is client-chosen and lands inside a quoted stuffcmd that every client
// runs through localcmd: a quote, ';' or newline would end the obit and start a
// console command on someone else's machine. '$' would expand a cvar.
string Obituary_SafeName(string s)
{
	string out = "";
	float n = strlen(s);
	for (float i = 0; i < n; i = i + 1)
	{
		float c = str2chr(s, i);
		if (c < 32 || c == 34 || c == 36 || c == 59 || c == 92 || c == 127) continue;
		out = strcat(out, substring(s, i, 1));
	}
	return out;
}

string Obituary_NameOf(entity e)
{
	if (!e) return "";
	string n = Obituary_SafeName(e.netname);
	if (n == "") return "player";
	return n;
}

// Index into the HUD damage icons the client already ships (DmgIcon_Pic,
// clientqc/hud/hud_damageindicator.qc). -1 when the kill was not one of them.
float Obituary_DmgClass(float bits)
{
	if (bits & DMG_POISON)                      return 0;
	if (bits & (DMG_ACID | DMG_NERVEGAS))       return 1;
	if (bits & (DMG_FREEZE | DMG_SLOWFREEZE))   return 2;
	if (bits & DMG_DROWN)                       return 3;
	if (bits & (DMG_BURN | DMG_SLOWBURN))       return 4;
	if (bits & DMG_RADIATION)                   return 6;
	if (bits & DMG_SHOCK)                       return 7;
	return -1;
}

#define OBIT_SELF    1
#define OBIT_WORLD   2
#define OBIT_HEAD    8

void Obituary_Broadcast(entity killer, entity victim, float wid, float flags, float dmgClass)
{
	// Split across two calls: strcat is a builtin, so it takes at most eight
	// arguments and a nine argument call silently drops the tail.
	string msg = strcat("obit \"", Obituary_NameOf(killer), "\" \"",
	                    Obituary_NameOf(victim), "\" ", ftos(wid));
	msg = strcat(msg, " ", ftos(flags), " ", ftos(dmgClass), "\n");
	for (entity c = Scoreboard_ClientChain(); c; c = c.chain)
		stuffcmd(c, msg);
}

// Called from Combat_Killed for every entity that dies; only players score.
void(entity targ, entity attacker) ClientObituary =
{
	if (!targ || targ.classname != "player") return;
	if (!IsMultiplayer()) return;

	if (g_noDeathPenalty)
	{
		Scoreboard_BroadcastRow(targ);
		return;
	}

	targ.deaths = targ.deaths + 1;

	float suicide = (!attacker || attacker == targ || attacker == world ||
	                 attacker.classname != "player");
	float wid = WID_NONE;

	if (suicide)
	{
		targ.frags = targ.frags - 1;
		Obituary_Broadcast(world, targ, WID_NONE, (attacker == targ) ? OBIT_SELF : OBIT_WORLD,
		                   Obituary_DmgClass(damage_kill_type));
	}
	else
	{
		wid = Weapon_IDFromBit(attacker.weapon);
		attacker.frags = attacker.frags + 1;
		attacker.kills = attacker.kills + 1;

		float oflags = 0;
		if (targ.hitbox == HITBOX_HEAD && targ.hitbox_time == time) oflags = OBIT_HEAD;
		Obituary_Broadcast(attacker, targ, wid, oflags, -1);
		Scoreboard_BroadcastRow(attacker);
	}

	Scoreboard_BroadcastRow(targ);

	// Fires these two events on every multiplayer death
	SUB_FireTargets("game_playerdie", targ, targ, USE_TOGGLE, 0);
	if (!suicide)
		SUB_FireTargets("game_playerkill", attacker, attacker, USE_TOGGLE, 0);
};
