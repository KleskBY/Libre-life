
#define MAX_HUDMESSAGES 4

float  hm_active   [MAX_HUDMESSAGES];
float  hm_startTime[MAX_HUDMESSAGES];
float  hm_effect   [MAX_HUDMESSAGES];
float  hm_x        [MAX_HUDMESSAGES];
float  hm_y        [MAX_HUDMESSAGES];
vector hm_rgb1     [MAX_HUDMESSAGES];
float  hm_a1       [MAX_HUDMESSAGES];
vector hm_rgb2     [MAX_HUDMESSAGES];
float  hm_a2       [MAX_HUDMESSAGES];
float  hm_fadein   [MAX_HUDMESSAGES];
float  hm_fadeout  [MAX_HUDMESSAGES];
float  hm_holdtime [MAX_HUDMESSAGES];
float  hm_fxtime   [MAX_HUDMESSAGES];
string hm_message  [MAX_HUDMESSAGES];

// hudmsg <channel> <x> <y> <effect> <r1> <g1> <b1> <a1> <r2> <g2> <b2> <a2> <fadein> <fadeout> <holdtime> <fxtime> "<msg>"
float HudMessage_Parse(string cmd)
{
	dprint("HM_Parse: '"); dprint(cmd); dprint("'\n");
	float ntok = tokenize(cmd);
	dprint("HM_Parse ntok="); dprint(ftos(ntok)); dprint("\n");
	if (ntok < 18) return FALSE;
	if (argv(0) != "hudmsg") return FALSE;

	float ch = stof(argv(1));
	if (ch < 0) ch = 0;
	if (ch >= MAX_HUDMESSAGES) ch = MAX_HUDMESSAGES - 1;

	if (hm_message[ch] != "")
		strunzone(hm_message[ch]);

	hm_active[ch]    = TRUE;
	hm_startTime[ch] = time;
	hm_x[ch]         = stof(argv(2));
	hm_y[ch]         = stof(argv(3));
	hm_effect[ch]    = stof(argv(4));
	hm_rgb1[ch]      = [stof(argv(5)), stof(argv(6)), stof(argv(7))];
	hm_a1[ch]        = stof(argv(8));
	hm_rgb2[ch]      = [stof(argv(9)), stof(argv(10)), stof(argv(11))];
	hm_a2[ch]        = stof(argv(12));
	hm_fadein[ch]    = stof(argv(13));
	hm_fadeout[ch]   = stof(argv(14));
	hm_holdtime[ch]  = stof(argv(15));
	hm_fxtime[ch]    = stof(argv(16));
	hm_message[ch]   = strzone(argv(17));
	return TRUE;
}

float HudMessage_ResolveX(float frac, float textW)
{
	if (frac < 0) return (ui_vid_x - textW) * 0.5;
	if (frac > 1) frac = 1;
	return frac * (ui_vid_x - textW);
}
float HudMessage_ResolveY(float frac, float textH)
{
	if (frac < 0) return (ui_vid_y - textH) * 0.5;
	if (frac > 1) frac = 1;
	return frac * (ui_vid_y - textH);
}

float HudMessage_Alpha(float elapsed, float fadein, float hold, float fadeout)
{
	if (elapsed < fadein)
	{
		if (fadein <= 0) return 1;
		return elapsed / fadein;
	}
	if (elapsed < fadein + hold) return 1;
	float t = elapsed - fadein - hold;
	if (fadeout <= 0) return 0;
	if (t >= fadeout) return 0;
	return 1 - (t / fadeout);
}

void HudMessage_DrawSlot(float i)
{
	if (!hm_active[i]) return;

	float elapsed = time - hm_startTime[i];
	float total   = hm_fadein[i] + hm_holdtime[i] + hm_fadeout[i];
	if (elapsed >= total)
	{
		hm_active[i] = FALSE;
		return;
	}

	float a01 = HudMessage_Alpha(elapsed, hm_fadein[i], hm_holdtime[i], hm_fadeout[i]);

	vector scale = [ui_font_size * 1.2, ui_font_size * 1.2];

	// Multi-line: server joins lines with '|' (see serverqc/titles.qc).
	string msg = hm_message[i];

	// Measure widest line for centering.
	float lineCount = tokenizebyseparator(msg, "|");
	float maxW = 0;
	float k;
	for (k = 0; k < lineCount; k++)
	{
		float w = stringwidth(argv(k), TRUE, scale);
		if (w > maxW) maxW = w;
	}
	float totalH = lineCount * scale_y * 1.1;

	float baseX = HudMessage_ResolveX(hm_x[i], maxW);
	float baseY = HudMessage_ResolveY(hm_y[i], totalH);

	vector rgb = hm_rgb1[i] * (1 / 255.0);
	float  a   = (hm_a1[i] / 255.0) * a01;

	// Re-tokenize because earlier stringwidth pass may have churned the buffer.
	tokenizebyseparator(msg, "|");
	for (k = 0; k < lineCount; k++)
	{
		string line = argv(k);
		float w = stringwidth(line, TRUE, scale);
		// Centers each line within the column when x == -1.
		float x = (hm_x[i] < 0) ? baseX + (maxW - w) * 0.5 : baseX;
		float y = baseY + k * scale_y * 1.1;
		drawstring([x, y], line, scale, rgb, a, 0);
	}
}

void HudMessage_Draw()
{
	if (intermission) return;
	drawfont = FONT_CENTERPRINT;
	float i;
	for (i = 0; i < MAX_HUDMESSAGES; i++)
		HudMessage_DrawSlot(i);
	drawfont = FONT_DEFAULT;
}
