
// Defined in trigger_changelevel.qc (compiled after this file).
entity ChangeLevel_FindLandmark(string pLandmarkName);
void(vector offset) ChangeLevel_ScheduleTrainRestore;
void(entity pActivator) ChangeLevel_SpawnPendingFireAndDie;

float g_hubSpawnSerial;

string Hub_SaveName(string m, float serial)
{
	return sprintf("_hub_%d_%s", serial, m);
}

float Hub_SerialFor(string m)
{
	string idx = cvar_string("hub_maps");
	if (idx == "") return -1;
	float n = tokenizebyseparator(idx, " ");
	for (float i = 0; i < n; i++)
	{
		string tok = argv(i);
		float eq = strstrofs(tok, "=", 0);
		if (eq < 0) continue;
		if (substring(tok, 0, eq) == m)
			return stof(substring(tok, eq + 1, strlen(tok) - eq - 1));
	}
	return -1;
}

// Replace-or-append the map's index pair.
void Hub_SetIndex(string m, float serial)
{
	string pair = strcat(m, "=", ftos(serial));
	string idx  = cvar_string("hub_maps");
	if (idx == "")
	{
		cvar_set("hub_maps", pair);
		return;
	}

	string rebuilt = "";
	float replaced = FALSE;
	float n = tokenizebyseparator(idx, " ");
	for (float i = 0; i < n; i++)
	{
		string tok = argv(i);
		if (tok == "") continue;
		float eq = strstrofs(tok, "=", 0);
		string tokMap = (eq >= 0) ? substring(tok, 0, eq) : tok;
		if (tokMap == m)
		{
			tok = pair;
			replaced = TRUE;
		}
		rebuilt = (rebuilt == "") ? tok : strcat(rebuilt, " ", tok);
	}
	if (!replaced)
		rebuilt = (rebuilt == "") ? pair : strcat(rebuilt, " ", pair);
	cvar_set("hub_maps", rebuilt);
}

void Hub_SaveCurrent()
{
	float serial = cvar("hub_serial") + 1;
	cvar_set("hub_serial", ftos(serial));
	localcmd(strcat("save ", Hub_SaveName(mapname, serial), "\n"));
	Hub_SetIndex(mapname, serial);
	cvar_set("hub_transition", "1");
}

// Called from worldspawn (after RegisterCustomCvars + the new-game wipe).
void Hub_WorldspawnArrivalCheck()
{
	g_hubSpawnSerial = cvar("hub_serial");

	if (cvar("hub_transition") != 1) return;
	cvar_set("hub_transition", "0");

	if (IsDeathmatch() || Map_IsId1BSP()) return;
	// Hub snapshots ride on the engine save/load commands, which are single-player only; coop carries inventory through per-slot cvars instead (transfer.qc).
	if (cvar("gamemode") == MODE_COOP)
	{
		dprint("hub: skipping snapshot restore in coop\n");
		return;
	}

	float serial = Hub_SerialFor(mapname);
	if (serial < 0) return;

	cvar_set("hub_restore_pending", mapname);
	cvar_set("hub_loaded", "0");
	localcmd(strcat("load ", Hub_SaveName(mapname, serial), "\nset hub_loaded 1\n"));
}

void Hub_ArrivalFixup(entity p)
{
	float slot = Player_SlotIndex(p);

	if (strlen(cvar_string("landmark")) > 0)
	{
		entity lm = ChangeLevel_FindLandmark(cvar_string("landmark"));
		if (lm)
		{
			// Prefer this client's own pose; fall back to the legacy global pair for saves made before per-slot fields existed.
			string myPos = PlayerTransfer_GetS(slot, "lm_pos");
			string myAng = PlayerTransfer_GetS(slot, "lm_angles");
			string myVel = PlayerTransfer_GetS(slot, "lm_velocity");
			if (myPos == "") myPos = cvar_string("landmark_player_pos");
			if (myAng == "") myAng = cvar_string("landmark_player_angles");
			if (myVel == "") myVel = cvar_string("landmark_player_velocity");

			vector offset  = lm.origin - stov(cvar_string("landmark_pos"));
			vector new_pos = stov(myPos) + offset;

			setorigin(p, new_pos);
			p.oldorigin = new_pos;
			p.angles    = stov(myAng);
			p.velocity  = stov(myVel);
			p.fixangle  = TRUE;

			p.chlevel_lastTouchTime = time;

			ChangeLevel_ScheduleTrainRestore(offset);
		}
	}

	if (PlayerTransfer_GetF(slot, "ducked") != 1)
	{
		p.crouching   = 0;
		p.duckedInAir = 0;
		setsize(p, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
		p.view_ofs = STAND_VIEW_OFS;
	}

	// Inventory/health/armor the player carried through the transition.
	if (PlayerTransfer_Load(p))
	{
		entity os = self;
		self = p;
		Weapon_Update();
		self = os;
	}

	// trigger_changelevel.changetarget deferred fire (CFireAndDie port).
	ChangeLevel_SpawnPendingFireAndDie(p);

	dprint(strcat("hub: arrival fixup complete on ", mapname, "\n"));
}

// Called every StartFrame. No-op unless a hub arrival is pending.
void Hub_ConsumeArrival()
{
	string pend = cvar_string("hub_restore_pending");
	if (pend == "") return;

	if (pend != mapname)
	{
		cvar_set("hub_restore_pending", "");
		cvar_set("hub_loaded", "0");
		return;
	}

	// Still the fresh throwaway world? (load hasn't executed yet)
	if (cvar("hub_loaded") != 1 && g_hubSpawnSerial == cvar("hub_serial"))
		return;

	entity p = find(world, classname, "player");
	if (!p) return;

	cvar_set("hub_restore_pending", "");
	cvar_set("hub_loaded", "0");

	for (; p; p = find(p, classname, "player"))
		Hub_ArrivalFixup(p);

	TriggerAuto_RearmAll();

	// Consumed by every arrival above; clear once they've all been placed.
	cvar_set("landmark", "");
}
