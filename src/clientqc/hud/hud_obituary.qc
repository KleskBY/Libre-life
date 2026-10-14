// Kill feed, top-right. Fed by the server's "obit" console command
// (serverqc/obituary.qc):
//
//   obit "<killer>" "<victim>" <weaponID> <flags> <damageClass>
//
// An empty killer means a suicide or a world kill; the flags say which, and
// whether the killing shot was a headshot. CSQC_ConsoleCommand passes the first
// three arguments on, so the flags are read straight out of the tokenizer this
// is still called inside; an older server simply leaves them 0.

#define OBIT_MAX      6
#define OBIT_LIFETIME 6
#define OBIT_FADE     1

#define OBIT_SELF     1   // killed themselves
#define OBIT_WORLD    2   // the map or a monster did it
#define OBIT_HEAD     8   // the killing shot hit the head

// Half-Life ships no death notice art, so a kill shows the weapon's own HUD
// sprite, a death by the world shows the matching damage icon the HUD already
// uses (DmgIcon_Pic), and a headshot is called out in text.

string obit_killer[OBIT_MAX];
string obit_victim[OBIT_MAX];
float  obit_wid   [OBIT_MAX];
float  obit_time  [OBIT_MAX];
float  obit_flags [OBIT_MAX];
float  obit_dmg   [OBIT_MAX];

void Obituary_Push(string killer, string victim, float wid)
{
	// The entry about to fall off the end owns its strings; release them first.
	if (obit_time[OBIT_MAX - 1])
	{
		strunzone(obit_killer[OBIT_MAX - 1]);
		strunzone(obit_victim[OBIT_MAX - 1]);
	}

	// Shuffle down; oldest entry falls off the end.
	for (float i = OBIT_MAX - 1; i > 0; i--)
	{
		obit_killer[i] = obit_killer[i - 1];
		obit_victim[i] = obit_victim[i - 1];
		obit_wid   [i] = obit_wid   [i - 1];
		obit_time  [i] = obit_time  [i - 1];
		obit_flags [i] = obit_flags [i - 1];
		obit_dmg   [i] = obit_dmg   [i - 1];
	}

	obit_killer[0] = strzone(killer);
	obit_victim[0] = strzone(victim);
	obit_wid   [0] = wid;
	obit_time  [0] = time;
	obit_flags [0] = stof(argv(4));
	obit_dmg   [0] = (argv(5) == "") ? -1 : stof(argv(5));
}

void Obituary_Draw()
{
	float fh    = ui_font_size;
	float rowH  = fh * 1.9;
	float iconH = fh * 1.5;
	float gap   = fh * 0.5;
	float pad   = fh * 0.45;
	vector fv = [fh, fh];
	float rightEdge = ui_vid_x - fh * 1.5;
	float y = fh * 3;
	string me = getplayerkeyvalue(player_localnum, "name");

	for (float i = 0; i < OBIT_MAX; i++)
	{
		if (!obit_time[i]) continue;

		float age = time - obit_time[i];
		if (age > OBIT_LIFETIME) continue;

		float a = 1;
		if (age > OBIT_LIFETIME - OBIT_FADE)
			a = (OBIT_LIFETIME - age) / OBIT_FADE;
		float slide = (age < 0.15) ? (1 - age / 0.15) * fh * 4 : 0;   // new rows slide in

		string killer = obit_killer[i];
		string victim = obit_victim[i];
		float flags = obit_flags[i];
		float suicide = (killer == "") || (flags & (OBIT_SELF | OBIT_WORLD));
		if (suicide) killer = "";

		// Every sprite here is a white Half-Life glyph, so all of them are
		// additive. A fall or a crush has no icon at all.
		string pic = "";
		if (!suicide && obit_wid[i] > WID_NONE && obit_wid[i] < WID_COUNT)
			pic = weapon_sprite[obit_wid[i]];
		else if (suicide && obit_dmg[i] >= 0)
			pic = DmgIcon_Pic(obit_dmg[i]);

		// Icons keep their own shape: a sprite sheet entry is far from square.
		float iconW = 0;
		if (pic != "")
		{
			vector isz = drawgetimagesize(pic);
			iconW = iconH;
			if (isz_y > 0) iconW = iconH * isz_x / isz_y;
			if (iconW > fh * 6) iconW = fh * 6;
		}

		float head = !suicide && (flags & OBIT_HEAD);
		float wHead = head ? stringwidth("HEADSHOT", FALSE, fv * 0.7) + gap * 0.5 : 0;
		float wVictim = stringwidth(victim, TRUE, fv);
		float wKiller = (killer == "") ? 0 : stringwidth(killer, TRUE, fv) + gap;
		float width = pad + wKiller + iconW + wHead + gap + wVictim + pad;
		if (pic == "" && !head) width = width + gap;

		vector at = [rightEdge - width + slide, y];
		float involved = (killer == me) || (victim == me);

		drawfill(at, [width, rowH], '0 0 0', 0.5 * a, 0);
		if (involved)
		{
			vector edge = (victim == me) ? '0.85 0.25 0.2' : '1 0.8 0.35';
			drawfill(at, [width, 1], edge, 0.8 * a, 0);
			drawfill(at + [0, rowH - 1], [width, 1], edge, 0.8 * a, 0);
			drawfill(at, [fh * 0.2, rowH], edge, 0.9 * a, 0);
		}

		vector pen = at + [pad, (rowH - fh) * 0.5];

		if (killer != "")
		{
			drawstring(pen, killer, fv, (killer == me) ? '1 0.85 0.4' : '0.92 0.92 0.88', a, 0);
			pen_x = pen_x + wKiller;
		}

		if (pic != "")
		{
			drawpic([pen_x, at_y + (rowH - iconH) * 0.5], pic, [iconW, iconH], '1 1 1', a, DRAWFLAG_ADDITIVE);
			pen_x = pen_x + iconW;
		}

		if (head)
		{
			pen_x = pen_x + gap * 0.5;
			drawstring([pen_x, pen_y + fh * 0.15], "HEADSHOT", fv * 0.7, '1 0.75 0.3', a, 0);
			pen_x = pen_x + stringwidth("HEADSHOT", FALSE, fv * 0.7);
		}
		pen_x = pen_x + gap;

		drawstring(pen, victim, fv, (victim == me) ? '1 0.85 0.4' : '0.92 0.92 0.88', a, 0);

		y = y + rowH + fh * 0.3;
	}
}
