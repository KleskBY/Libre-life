
#define SF_GLOBAL_SET              0x0001

.string globalstate;
.float  triggermode;
.float  initialstate;

string GlobalState_CvarName(string n) { return strcat("gs_", n); }

void GlobalState_CvarSet(string cv, string val)
{
	RegisterCvar(cv, "");
	cvar_set(cv, val);
}

float GlobalState_InTable(string name)
{
	if (!name || name == "") return FALSE;
	string idx = cvar_string("gs_index");
	if (idx == "") return FALSE;

	float n = tokenizebyseparator(idx, " ");
	for (float i = 0; i < n; i = i + 1)
		if (argv(i) == name) return TRUE;
		
	return FALSE;
}

void GlobalState_AppendIndex(string name)
{
	string idx = cvar_string("gs_index");
	if (idx == "") GlobalState_CvarSet("gs_index", name);
	else           GlobalState_CvarSet("gs_index", strcat(idx, " ", name));
}

float GlobalState_Get(string name)
{
	if (!name || name == "") return GLOBAL_OFF;
	string raw = cvar_string(GlobalState_CvarName(name));
	if (raw == "") return GLOBAL_OFF;
	tokenize(raw);
	return stof(argv(0));
}

string GlobalState_GetMap(string name)
{
	string raw = cvar_string(GlobalState_CvarName(name));
	if (raw == "") return "";
	tokenize(raw);
	return argv(1);
}

void GlobalState_Add(string name, string mapName, float state)
{
	if (!name || name == "") return;
	if (!GlobalState_InTable(name))
		GlobalState_AppendIndex(name);
	GlobalState_CvarSet(GlobalState_CvarName(name), sprintf("%d %s", state, mapName));
}

void GlobalState_Set(string name, float state)
{
	if (!name || name == "") return;
	string m = GlobalState_GetMap(name);
	if (m == "") m = mapname;
	GlobalState_Add(name, m, state);
}

void GlobalState_ClearAll()
{
	string idx = cvar_string("gs_index");
	if (idx != "")
	{
		float n = tokenizebyseparator(idx, " ");
		for (float i = 0; i < n; i = i + 1)
			GlobalState_CvarSet(GlobalState_CvarName(argv(i)), "");
	}
	GlobalState_CvarSet("gs_index", "");

	// Also wipe the spent-one-shot table (see below).
	idx = cvar_string("spent_index");
	if (idx != "")
	{
		float n2 = tokenizebyseparator(idx, " ");
		for (float j = 0; j < n2; j = j + 1)
			GlobalState_CvarSet(strcat("spent_", argv(j)), "");
	}
	GlobalState_CvarSet("spent_index", "");

	GlobalState_CvarSet("hub_maps", "");
	GlobalState_CvarSet("hub_transition", "0");
	GlobalState_CvarSet("hub_restore_pending", "");
	GlobalState_CvarSet("hub_loaded", "0");
}


string GlobalState_CompanionFile(string slot)
{
	float L = strlen(slot);
	if (L > 4 && substring(slot, L - 4, 4) == ".sav")
		slot = substring(slot, 0, L - 4);
	return strcat(slot, ".gs");
}

void GlobalState_WriteCfg(string slot)
{
	if (!slot || slot == "") return;

	float fh = fopen(GlobalState_CompanionFile(slot), FILE_WRITE);
	if (fh < 0) return;

	// env_global flags: index + one line per name.
	string idx = cvar_string("gs_index");
	fputs(fh, strcat("gs_index ", idx, "\n"));
	if (idx != "")
	{
		float n = tokenizebyseparator(idx, " ");
		for (float i = 0; i < n; i = i + 1)
		{
			string cv = GlobalState_CvarName(argv(i));
			fputs(fh, strcat(cv, " ", cvar_string(cv), "\n"));
		}
	}

	// Spent one-shot / kill tables: index + one line per map.
	string sidx = cvar_string("spent_index");
	fputs(fh, strcat("spent_index ", sidx, "\n"));
	if (sidx != "")
	{
		float m = tokenizebyseparator(sidx, " ");
		for (float j = 0; j < m; j = j + 1)
		{
			string cv2 = strcat("spent_", argv(j));
			fputs(fh, strcat(cv2, " ", cvar_string(cv2), "\n"));
		}
	}

	fputs(fh, strcat("hub_maps ", cvar_string("hub_maps"), "\n"));
	fputs(fh, strcat("hub_serial ", cvar_string("hub_serial"), "\n"));

	fclose(fh);
}

void GlobalState_RestoreCfg(string slot)
{
	if (!slot || slot == "") return;

	float sessionHubSerial = cvar("hub_serial");

	GlobalState_ClearAll();

	float fh = fopen(GlobalState_CompanionFile(slot), FILE_READ);
	if (fh < 0) return;

	string line;
	while ((line = fgets(fh)))
	{
		if (line == "") continue;
		float nm = tokenize(line);
		if (nm < 1) continue;
		string name = argv(0);
		string val = "";
		if (strlen(line) > strlen(name) + 1)
			val = substring(line, strlen(name) + 1, strlen(line) - strlen(name) - 1);
		if (substring(name, 0, 3) != "gs_" && substring(name, 0, 6) != "spent_" &&
		    name != "hub_maps" && name != "hub_serial")
			continue;	// a .gs file never sets any other cvar
		GlobalState_CvarSet(name, val);
	}
	fclose(fh);

	if (sessionHubSerial > cvar("hub_serial"))
		cvar_set("hub_serial", ftos(sessionHubSerial));
}


string Spent_ComputeToken(entity e)
{
	if (e.model != "" && str2chr(e.model, 0) == 42)	// '*' = brush model
		return strcat(e.classname, e.model);
	return sprintf("%s@%g_%g_%g", e.classname, e.origin_x, e.origin_y, e.origin_z);
}

string Spent_Token(entity e)
{
	if (e.spent_token) return e.spent_token;
	return Spent_ComputeToken(e);
}

void Spent_Capture(entity e)
{
	if (!e.spent_token)
		e.spent_token = strzone(Spent_ComputeToken(e));
}

float Spent_IsSpent(entity e)
{
	string cur = cvar_string(strcat("spent_", mapname));
	if (cur == "") return FALSE;
	string tok = Spent_Token(e);
	float n = tokenizebyseparator(cur, " ");
	for (float i = 0; i < n; i = i + 1)
		if (argv(i) == tok) return TRUE;
	return FALSE;
}

void Spent_Mark(entity e)
{
	if (Spent_IsSpent(e)) return;

	string cv  = strcat("spent_", mapname);
	string tok = Spent_Token(e);
	string cur = cvar_string(cv);
	GlobalState_CvarSet(cv, (cur == "") ? tok : strcat(cur, " ", tok));

	// Track which maps have spent tables so ClearAll can wipe them.
	string idx = cvar_string("spent_index");
	float found = FALSE;
	if (idx != "")
	{
		float n = tokenizebyseparator(idx, " ");
		for (float i = 0; i < n; i = i + 1)
			if (argv(i) == mapname) { found = TRUE; break; }
	}
	if (!found)
		GlobalState_CvarSet("spent_index", (idx == "") ? mapname : strcat(idx, " ", mapname));
}


float g_spentMapLoadTime;
void Spent_StampMapLoad() { g_spentMapLoadTime = time; }

float Monster_RemoveIfSpent()
{
	if (!g_spentMapLoadTime || time > g_spentMapLoadTime + 0.5)
		return FALSE;
	Spent_Capture(self);
	if (!Spent_IsSpent(self)) return FALSE;
	remove(self);
	return TRUE;
}


float GlobalState_EntityGetState(entity e)
{
	if (!e.globalname || e.globalname == "") return GLOBAL_OFF;
	return GlobalState_Get(e.globalname);
}

float GlobalState_EntityInTable(entity e)
{
	if (!e.globalname || e.globalname == "") return FALSE;
	return GlobalState_InTable(e.globalname);
}

void GlobalState_EntitySetState(entity e, float st)
{
	if (!e.globalname || e.globalname == "") return;
	if (GlobalState_InTable(e.globalname))
		GlobalState_Set(e.globalname, st);
	else
		GlobalState_Add(e.globalname, mapname, st);
}

void GlobalState_MarkEntityDead(entity e)
{
	if (!e.globalname || e.globalname == "") return;
	GlobalState_EntitySetState(e, GLOBAL_DEAD);
}

float GlobalState_RemoveIfDead(entity e)
{
	if (!e.globalname || e.globalname == "") return FALSE;
	if (GlobalState_EntityGetState(e) != GLOBAL_DEAD) return FALSE;
	remove(e);
	return TRUE;
}


void EnvGlobal_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!self.globalstate || self.globalstate == "") return;

	float oldState = GlobalState_Get(self.globalstate);
	float newState;

	switch ((float)self.triggermode)
	{
	case 0: newState = GLOBAL_OFF;  break;
	case 1: newState = GLOBAL_ON;   break;
	case 2: newState = GLOBAL_DEAD; break;
	default:
	case 3:
		if      (oldState == GLOBAL_ON)  newState = GLOBAL_OFF;
		else if (oldState == GLOBAL_OFF) newState = GLOBAL_ON;
		else                             newState = oldState;
		break;
	}

	if (GlobalState_InTable(self.globalstate))
		GlobalState_Set(self.globalstate, newState);
	else
		GlobalState_Add(self.globalstate, mapname, newState);
}

void EnvGlobal_Use()
{
	EnvGlobal_UseHL(activator, self, useType, 0);
}

void env_global()
{
	if (!self.globalstate || self.globalstate == "")
	{
		remove(self);
		return;
	}

	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;

	if ((self.spawnflags & SF_GLOBAL_SET) && !GlobalState_InTable(self.globalstate))
		GlobalState_Add(self.globalstate, mapname, self.initialstate);

	self.use   = EnvGlobal_Use;
	self.usehl = EnvGlobal_UseHL;
}
