// Multiplayer scoreboard (+showscores).
//
// Name and ping come from engine client info; kills and deaths come from server's sbrow messages in scoretable.qc.
// Deathmatch columns switch on SCOREBOARD_KD (gamedefs.qc); coop has no frags and always shows deaths.

float lastPing;

// Column offsets from the left edge of the panel, in font units.
#define SB_COL_NAME     1
#define SB_COL_SCORE   22
#ifdef SCOREBOARD_KD
#define SB_COL_SCORE2  28
#define SB_COL_PING    35
#define SB_WIDTH       39
#else
#define SB_COL_PING    30
#define SB_WIDTH       34
#endif

float rankings_slots[SCORE_MAX_SLOTS];

// TRUE when slot a ranks above slot b.
float Rankings_Beats(float a, float b)
{
#ifdef SCOREBOARD_KD
	if (score_kills[a] != score_kills[b]) return score_kills[a] > score_kills[b];
	return score_deaths[a] < score_deaths[b];
#else
	return ScoreTable_Frags(a) > ScoreTable_Frags(b);
#endif
}

// Fill rankings_slots with the present slots, best first.
// Returns how many were collected.
float Rankings_Collect()
{
	float n = 0;
	for (float i = 0; i < SCORE_MAX_SLOTS; i++)
	{
		if (!ScoreTable_SlotPresent(i)) continue;
		rankings_slots[n] = i;
		n = n + 1;
	}

	// Selection sort, used for at most 32 entries, drawn only while TAB is held.
	for (float a = 0; a < n; a++)
	{
		float best = a;
		for (float b = a + 1; b < n; b++)
			if (Rankings_Beats(rankings_slots[b], rankings_slots[best])) best = b;
		if (best != a)
		{
			float tmp = rankings_slots[a];
			rankings_slots[a] = rankings_slots[best];
			rankings_slots[best] = tmp;
		}
	}
	return n;
}

string Rankings_TimeString(float secs)
{
	if (secs < 0) secs = 0;
	float m = floor(secs / 60);
	float s = floor(secs - m * 60);
	if (s < 10) return strcat(ftos(m), ":0", ftos(s));
	return strcat(ftos(m), ":", ftos(s));
}

// Score columns of one line: the header when slot < 0, a player otherwise.
void Rankings_DrawScores(vector pos, float slot, float coop, vector col)
{
	float isHeader = slot < 0;
	if (isHeader) slot = 0;		// keeps the array reads below in range; values unused for the header

	if (coop)
	{
		UI_Text(isHeader ? "DEATHS" : ftos(score_deaths[slot]), pos + [ui_font_size * SB_COL_SCORE, 0], col);
		return;
	}
#ifdef SCOREBOARD_KD
	UI_Text(isHeader ? "KILLS"  : ftos(score_kills[slot]),  pos + [ui_font_size * SB_COL_SCORE, 0],  col);
	UI_Text(isHeader ? "DEATHS" : ftos(score_deaths[slot]), pos + [ui_font_size * SB_COL_SCORE2, 0], col);
#else
	UI_Text(isHeader ? "FRAGS"  : ftos(ScoreTable_Frags(slot)), pos + [ui_font_size * SB_COL_SCORE, 0], col);
#endif
}

// Draws one player line at `row` (in font-height units) below `origin`.
void Rankings_DrawRow(vector origin, float row, float slot, float coop)
{
	vector col = '1 1 1';
	if (player_localnum == slot) col = '1 0.95 0.55';

	vector pos = origin + [0, ui_font_size * row];

	string nm = getplayerkeyvalue(slot, "name");
	if (strlen(nm) > 20) nm = substring(nm, 0, 20);

	UI_Text(nm, pos + [ui_font_size * SB_COL_NAME, 0], col);
	Rankings_DrawScores(pos, slot, coop, col);
	UI_Text(getplayerkeyvalue(slot, "ping"), pos + [ui_font_size * SB_COL_PING, 0], col);
}

void Rankings_Draw()
{
	if(intermission) return;
	float gm = cvar("gamemode");
	if(gm == MODE_SP) return;
	if(!showScores) return;

	if(lastPing + 5 < time)
	{
		lastPing = time;
		localcmd("ping\n");
	}

	float coop = (gm == MODE_COOP);

	// Count rows up front so the panel is only as tall as it needs to be.
	float bodyRows = 1;
	for (float i = 0; i < SCORE_MAX_SLOTS; i++)
		if (ScoreTable_SlotPresent(i)) bodyRows = bodyRows + 1;

	float totalRows = bodyRows + 4;		// title, server line, column header, footer
	vector panelSize = [ui_font_size * SB_WIDTH, ui_font_size * (totalRows + 2)];
	vector origin    = [ui_vid_x * 0.5 - panelSize_x * 0.5, ui_vid_y * 0.18];

	UI_Frame(origin, panelSize);
	origin = origin + [0, ui_font_size];

	float row = 0;

	// Title + server identity.
	string host = serverkey("hostname");
	if (host == "") host = cvar_string("hostname");
	UI_Text(host, origin + [ui_font_size * SB_COL_NAME, 0], '1 1 1');
	row = row + 1;

	string limits = mapname;
	float fl = cvar("fraglimit");
	float tl = cvar("timelimit");
	if (fl > 0) limits = strcat(limits, "   fraglimit ", ftos(fl));
	if (tl > 0) limits = strcat(limits, "   time left ", Rankings_TimeString(tl * 60 - time));
	else        limits = strcat(limits, "   ", Rankings_TimeString(time));
	UI_Text(limits, origin + [ui_font_size * SB_COL_NAME, ui_font_size * row], UI_TEXT_INACTIVE);
	row = row + 2;

	// Column header.
	vector hdr = origin + [0, ui_font_size * row];
	UI_Text("NAME", hdr + [ui_font_size * SB_COL_NAME, 0], UI_TEXT_INACTIVE);
	Rankings_DrawScores(hdr, -1, coop, UI_TEXT_INACTIVE);
	UI_Text("PING", hdr + [ui_font_size * SB_COL_PING, 0], UI_TEXT_INACTIVE);
	drawfill(origin + [ui_font_size * 0.5, ui_font_size * (row + 1)],
	         [ui_font_size * (SB_WIDTH - 1), 1], '1 1 1', 0.25, 0);
	row = row + 2;

	float n = Rankings_Collect();
	for (float i = 0; i < n; i++)
	{
		Rankings_DrawRow(origin, row, rankings_slots[i], coop);
		row = row + 1;
	}
}
