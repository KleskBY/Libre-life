void Weapon_RegisterSelectFuncs();

void NodeGraph_Init();
void NodeGraph_FrameCheck();
void Brush_SanitizeAllSkins();
float g_brushSkinsSanitized;


#define BODYQUE_SIZE 4
entity bodyque_head;
void InitBodyQue()
{
	entity e = spawn();
	e.classname = "bodyque";
	bodyque_head = e;
	for(float i = 0; i < BODYQUE_SIZE; i++)
	{
		e.owner = spawn();
		e.classname = "bodyque";
		e = e.owner;
	}
	e.owner = bodyque_head;
} 


// make a body que entry for the given ent for respawning
void CopyToBodyQue(entity ent)
{
	bodyque_head.angles = ent.angles;
	bodyque_head.model = ent.model;
	bodyque_head.modelindex = ent.modelindex;
	bodyque_head.frame = ent.frame;
	bodyque_head.colormap = ent.colormap;
	bodyque_head.scale = ent.scale;		// player model shrinks on id1 maps
	bodyque_head.movetype = ent.movetype;
	bodyque_head.velocity = ent.velocity;
	bodyque_head.flags = 0;
	setorigin(bodyque_head, ent.origin);
	setsize(bodyque_head, ent.mins, ent.maxs);
	bodyque_head = bodyque_head.owner;
}

void main()
{

}


void Hub_ConsumeArrival();
void CheckRules();
void PublishGameRules();
void Nametag_Frame();
void Bot_Balance();                // bot/client.qc

//Called at the start of each frame.
void StartFrame()
{
	teamplay = cvar("teamplay");
	skill = cvar("skill");
	// Keep client game rules current.
	PublishGameRules();
	// Frag/time limit for the multiplayer modes (rules.qc).
	CheckRules();
	Nametag_Frame();
	// Hub revisit: finish a pending snapshot-restore arrival (no-op otherwise).
	Hub_ConsumeArrival();
	// Build the node graph the first frame after all info_node ents spawned.
	NodeGraph_FrameCheck();
	// Add or drop bots toward the bot_count cvar, one per call.
	Bot_Balance();
	// Clear leftover "skin" "-1" on brush entities whose spawn skipped
	if (!g_brushSkinsSanitized)
	{
		g_brushSkinsSanitized = TRUE;
		Brush_SanitizeAllSkins();
	}
};

void RegisterStats()
{
	addstat(STAT_TOTALITEMS, 2, item);
	addstat(STAT_PICKED_ITEMS, 2, picked_items);
	addstat(STAT_SHOTS, 2, total_shots);
	addstat(STAT_HITS, 2, total_hits);
	addstat(STAT_INCROSS, 2, incross);
	addstat(STAT_CLIP, 2, currentClip);
	addstat(STAT_WEAPONS, 2, weapons);
	addstat(STAT_FLASHBAT, 2, flashlight_battery);
	addstat(STAT_FLASHLIGHT, 2, flashlight_on);
	addstat(STAT_TRAIN, 2, trainHudState);
	addstat(STAT_DMGBITS, 2, dmg_shownhud_bits);
	addstat(STAT_PLAYERFLAGS, 2, flags);
	addstat(STAT_ZOOM, 2, player_viewZoom255);
	addstat(STAT_PUNCH_X, 2, player_punch10x);
	addstat(STAT_PUNCH_Y, 2, player_punch10y);
}

// Push the server's game rules into the client's own cvar copies.
//
// A remote client's game rules (gamemode/coop/deathmatch/fraglimit/timelimit) are stale leftovers from previous sessions.
// Since these values are set once before the map loads, a stuffcmd is sufficient, eliminating the need for per-frame stat updates.
// This ensures the scoreboard, kill feed, and team dialog read the correct mode.
// The values are static after loading.
// Writing the client's copy directly means both CSQC and the menu VM can use plain cvar("gamemode") reads.
// coop/deathmatch are derived from gamemode, ensuring a server started with stale values still provides a consistent set.
float g_pubGamemode, g_pubFraglimit, g_pubTimelimit;

void PublishGameRulesTo(entity p)
{
	float gm = cvar("gamemode");

	// "set" rather than a bare assignment ensures gamemode is ours, not an engine cvar, so the stuffcmd overrides client menu/CSQC registration.
	stuffcmd(p, strcat("set gamemode ", ftos(gm), "\n"));
	stuffcmd(p, strcat("coop ", ftos(gm == MODE_COOP),
	                   "; deathmatch ", ftos(gm == MODE_DM), "\n"));
	stuffcmd(p, strcat("fraglimit ", ftos(cvar("fraglimit")),
	                   "; timelimit ", ftos(cvar("timelimit")), "\n"));
}

// Called every frame; only actually sends when a value moved.
void PublishGameRules()
{
	float gm = cvar("gamemode");
	float fl = cvar("fraglimit");
	float tl = cvar("timelimit");

	if (gm == g_pubGamemode && fl == g_pubFraglimit && tl == g_pubTimelimit)
		return;

	g_pubGamemode  = gm;
	g_pubFraglimit = fl;
	g_pubTimelimit = tl;

	for (entity p = findchainflags(flags, FL_CLIENT); p; p = p.chain)
		PublishGameRulesTo(p);
}


entity lastspawn;

.float startdark;
float g_startdark;

void GlobalState_ClearAll();	// env_global.qc (compiled after main.qc)
void PlayerTransfer_Clear();	// player/transfer.qc
void Spent_StampMapLoad();
void Hub_WorldspawnArrivalCheck();
void Sprite_FrameManifestInit();	// env_sprite.qc

void() worldspawn =
{
	// Bots. Registered here so the console knows the names before anyone types
	// one; bot_count 0 means no bots until a server asks for them.
	RegisterCvar("bot_count", "0");
	RegisterCvar("bot_skill", "0.5");
	RegisterCvar("bot_prefix", "[BOT] ");
	RegisterCvar("bot_physics", "1");
	RegisterCvar("bot_wp_autogen", "1");
	RegisterCvar("bot_wp_genrate", "300");
	RegisterCvar("bot_wp_save", "1");
	RegisterCvar("bot_wp_learn", "1");

	g_startdark = self.startdark;
	PlayerProps_Init();		// player hull/eye height for this map family
	Precache();
	InitBodyQue();
	RegisterCustomCvars();
	localcmd("exec skill.cfg\n");

	if (cvar("xfer_valid") != 1
	    && cvar_string("g_pendingLoad") == ""
	    && cvar_string("hub_restore_pending") == ""
	    && cvar("g_deathRestart") != 1)
	{
		dprint("worldspawn: fresh start — wiping cross-map state\n");
		GlobalState_ClearAll();
		// Also drop any per-client inventory a previous session left staged
		PlayerTransfer_Clear();

		cvar_set("g_lastSaveSlot", "");
		cvar_set("g_lastSaveMap",  "");
		cvar_set("g_lastSaveTime", "0");
		cvar_set("g_pendingLoad",  "");
	}
	cvar_set("g_deathRestart", "0");	// one-shot; consumed by the check above

	Hub_WorldspawnArrivalCheck();

	Spent_StampMapLoad();
	Sentences_Init();
	Titles_Init();
	Sprite_FrameManifestInit();
	NodeGraph_Init();
	if (Map_IsId1BSP() && cvar_string("id1_serverflags") != "")
		serverflags = cvar("id1_serverflags");
	else if (!Map_IsId1BSP())
		serverflags = 0;
	cvar_set("id1_serverflags", "");
	RegisterStats();
	Weapon_RegistryInit();
	Weapon_RegisterSelectFuncs();
	lastspawn = world;
	g_pubGamemode = -1;	// force the first PublishGameRules to actually send
	lightstyle(0, "m"); 													// 0 normal
	lightstyle(1, "mmnmmommommnonmmonqnmmo");
	lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");
	lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");
	lightstyle(4, "mamamamamama");
	lightstyle(5, "jklmnopqrstuvwxyzyxwvutsrqponmlkj");
	lightstyle(6, "nmonqnmomnmomomno");
	lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");
	lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");
	lightstyle(9, "aaaaaaaazzzzzzzz");
	lightstyle(10, "mmamammmmammamamaaamammma");
	lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");
	lightstyle(63, "a");// 63 testing
	
	RegisterStats();
	cvar_set("sv_gravity", "800");
};

