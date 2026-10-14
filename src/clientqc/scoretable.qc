// Client-side mirror of the server scoreboard.
//
// Names and pings come from the engine's own client info via getplayerkeyvalue(); kills and deaths are pushed by the server as console commands (see serverqc/obituary.qc):
//   sbrow <slot> <kills> <deaths>
//   sbdel <slot>
//
// parsed in CSQC_ConsoleCommand and stored by client slot.

#define SCORE_MAX_SLOTS 32

float score_active[SCORE_MAX_SLOTS];
float score_kills [SCORE_MAX_SLOTS];
float score_deaths[SCORE_MAX_SLOTS];

void ScoreTable_Clear()
{
	for (float i = 0; i < SCORE_MAX_SLOTS; i++)
	{
		score_active[i] = 0;
		score_kills [i] = 0;
		score_deaths[i] = 0;
	}
}

void ScoreTable_SetRow(float slot, float kills, float deaths)
{
	if (slot < 0 || slot >= SCORE_MAX_SLOTS) return;
	score_active[slot] = 1;
	score_kills [slot] = kills;
	score_deaths[slot] = deaths;
}

void ScoreTable_RemoveRow(float slot)
{
	if (slot < 0 || slot >= SCORE_MAX_SLOTS) return;
	score_active[slot] = 0;
	score_kills [slot] = 0;
	score_deaths[slot] = 0;
}

// A slot counts as present if the engine still has a name for it, so a client
// that connected before we did still shows up even without an sbrow yet.
float ScoreTable_SlotPresent(float slot)
{
	if (slot < 0 || slot >= SCORE_MAX_SLOTS) return FALSE;
	return getplayerkeyvalue(slot, "name") != "";
}

// Frags come from the engine's own per-client counter, kept by the server via the standard .frags field (obituary.qc), making the deathmatch score independent of sbrow messages.
float ScoreTable_Frags(float slot)
{
	if (slot < 0 || slot >= SCORE_MAX_SLOTS) return 0;
	return stof(getplayerkeyvalue(slot, "frags"));
}
