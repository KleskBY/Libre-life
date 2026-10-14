// Names above other players' heads.
//
// Players are not CSQC entities, so their positions come from getentity on the
// engine's own interpolated entity list; a slot's entity number is slot + 1.
// Who may carry a tag, and on which side, comes from the server's "ntag" roster
// (serverqc/nametag.qc). A missing getentity is a fatal bad builtin call rather
// than a zero return, so every use goes through Nametag_HasGetEntity. See
// docs/guide/08-player.md, "Nametags".

#define NAMETAG_MAX_DIST      1400
#define NAMETAG_FULL_DIST     500     // solid inside this, fading out beyond it
#define NAMETAG_AIM_FRAC      0.06    // enemy tag radius round the crosshair, of screen height
#define NAMETAG_HEAD_OFS      14      // above the top of the standing hull
#define NAMETAG_SIZE_NEAR     14
#define NAMETAG_SIZE_FAR      9
#define NAMETAG_COLOR_FRIEND  '0.6 0.95 0.6'
#define NAMETAG_COLOR_ENEMY   '1 0.5 0.45'

string nametag_roster;
float  nametag_zoned;
float  nametag_gate;          // 0 unknown, 1 getentity usable, 2 not

// FTE has builtin 504 in CSQC but advertises no extension string for it.
float Nametag_HasGetEntity()
{
	if (!nametag_gate)
		nametag_gate = (IsFTE() || checkextension("ZIRCON_GETENTITY_1")) ? 1 : 2;
	return nametag_gate == 1;
}

void Nametag_Parse(string roster)
{
	if (nametag_zoned) strunzone(nametag_roster);
	nametag_roster = strzone(roster);
	nametag_zoned = TRUE;
}

string Nametag_SideOf(float slot)
{
	if (slot < 0 || slot >= strlen(nametag_roster)) return "-";
	return substring(nametag_roster, slot, 1);
}

void Nametag_Draw()
{
	if (cvar("gamemode") == MODE_SP) return;
	if (intermission) return;
	if (!Nametag_HasGetEntity()) return;

	float count = strlen(nametag_roster);
	if (count < 2) return;

	string mine = Nametag_SideOf(player_localnum);
	vector eye = getpropertyvec(VF_ORIGIN);
	float aimR = ui_vid_y * NAMETAG_AIM_FRAC;
	float headOfs = (PLAYER_STAND_SIZE_MAX * '0 0 1') + NAMETAG_HEAD_OFS;

	for (float slot = 0; slot < count; slot = slot + 1)
	{
		if (slot == player_localnum) continue;

		string side = Nametag_SideOf(slot);
		if (side == "-") continue;
		if (!getentity(slot + 1, E_ACTIVE)) continue;   // outside this client's view of the world

		vector head = getentityvec(slot + 1, E_ORIGIN);
		head_z = head_z + headOfs;

		float dist = vlen(head - eye);
		if (dist > NAMETAG_MAX_DIST) continue;

		vector scr = cs_project(head);
		if (scr_z <= 0) continue;                      // behind the eye

		float friendly = (side != "0" && side == mine);
		if (!friendly)
		{
			float dx = scr_x - ui_vid_x * 0.5;
			float dy = scr_y - ui_vid_y * 0.5;
			if (dx * dx + dy * dy > aimR * aimR) continue;
		}

		traceline(eye, head, MOVE_NOMONSTERS, world);  // still hits doors and other brush models
		if (trace_fraction < 1) continue;

		string nm = getplayerkeyvalue(slot, "name");
		if (nm == "") continue;

		float far = bound(0, (dist - NAMETAG_FULL_DIST) / (NAMETAG_MAX_DIST - NAMETAG_FULL_DIST), 1);
		float px = NAMETAG_SIZE_NEAR + (NAMETAG_SIZE_FAR - NAMETAG_SIZE_NEAR) * far;
		vector sz = UI_FixedVector([px, px, 0]);
		float w = stringwidth(nm, TRUE, sz);

		vector col = friendly ? NAMETAG_COLOR_FRIEND : NAMETAG_COLOR_ENEMY;
		drawstring([scr_x - w * 0.5, scr_y - sz_y], nm, sz, col, 1 - far, 0);
	}
}
