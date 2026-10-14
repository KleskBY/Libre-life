#define FFADE_OUT      0x0001
#define FFADE_MODULATE 0x0002

float  fade_active;
float  fade_start;
float  fade_duration;
float  fade_holdtime;
float  fade_flags;
vector fade_rgb;
float  fade_peak_a;

// scrfade <r> <g> <b> <a> <duration> <holdtime> <flags>
float Fade_Parse(string cmd)
{
	float ntok = tokenize(cmd);
	if (ntok < 8) return FALSE;
	if (argv(0) != "scrfade") return FALSE;

	fade_rgb       = [stof(argv(1)) / 255, stof(argv(2)) / 255, stof(argv(3)) / 255];
	fade_peak_a    = stof(argv(4)) / 255;
	fade_duration  = stof(argv(5));
	fade_holdtime  = stof(argv(6));
	fade_flags     = stof(argv(7));
	fade_start     = time;
	fade_active    = TRUE;
	return TRUE;
}

float Fade_CurrentAlpha()
{
	float elapsed = time - fade_start;

	if (fade_flags & FFADE_OUT)
	{
		if (elapsed < fade_duration)
		{
			if (fade_duration <= 0) return fade_peak_a;
			return fade_peak_a * (elapsed / fade_duration);
		}
		if (elapsed < fade_duration + fade_holdtime) return fade_peak_a;
		float tOut = elapsed - fade_duration - fade_holdtime;
		if (fade_duration <= 0 || tOut >= fade_duration) return 0;
		return fade_peak_a * (1 - (tOut / fade_duration));
	}
	else
	{
		if (elapsed < fade_holdtime) return fade_peak_a;
		float tIn = elapsed - fade_holdtime;
		if (fade_duration <= 0 || tIn >= fade_duration) return 0;
		return fade_peak_a * (1 - (tIn / fade_duration));
	}
}

void Fade_Draw()
{
	if (!fade_active) return;

	float totalLife = (fade_flags & FFADE_OUT)
		? (fade_duration * 2 + fade_holdtime)
		: (fade_duration + fade_holdtime);

	float a = Fade_CurrentAlpha();
	if (a <= 0 && (time - fade_start) >= totalLife)
	{
		fade_active = FALSE;
		return;
	}
	if (a <= 0) return;

	float drawflag = (fade_flags & FFADE_MODULATE) ? DRAWFLAG_MODULATE : 0;
	drawfill([0, 0], [ui_vid_x, ui_vid_y], fade_rgb, a, drawflag);
}
