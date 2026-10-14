void ClientKill()
{

}

float Client_PlayerCount()
{
	float n = 0;
	for (entity e = find(world, classname, "player"); e; e = find(e, classname, "player"))
		n = n + 1;
	return n;
}

void ClientConnect()
{
	// Cooperative is capped for now; the create-server menu clamps its max-players slider to the same value
	if (cvar("gamemode") == MODE_COOP)
	{
		float cap = cvar("mp_coop_maxplayers");
		if (cap < 1) cap = 4;
		if (Client_PlayerCount() >= cap)
		{
			sprint(self, strcat("This cooperative server is limited to ",
			                    ftos(cap), " players.\n"));
			dropclient(self);
			return;
		}
	}

	self.frags  = 0;
	self.deaths = 0;
	self.kills = 0;

	if (IsMultiplayer())
	{
		bprint(strcat(Obituary_NameOf(self), " joined the game\n"));
		Scoreboard_SendAllTo(self);		// catch up on everyone already here
		Scoreboard_BroadcastRow(self);
		// The client chain may not include us yet this early, so send our own row directly too.
		Scoreboard_SendRowTo(self, self);
	}
}
void(vector center, float amplitude, float frequency, float duration, float radius) EnvShake_ScreenShake;
void Player_Precache();
entity ChangeLevel_FindLandmark(string pLandmarkName);
void(vector offset) ChangeLevel_ScheduleTrainRestore;
void(entity pActivator) ChangeLevel_SpawnPendingFireAndDie;
void PutClientInServer()
{
	Player_FrictionRelease();   // clear any stale func_friction state from a prior life
	Player_Precache();
	entity spot = SelectSpawnPoint(self);

	self.classname = "player";
	self.health = 100;
	self.takedamage = DAMAGE_AIM;
	self.takeDmgFn = Player_TakeDamage;
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_WALK;
	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;
	
	
	self.effects = 0;
	self.attack_finished = time;
	self.deadflag = DEAD_NO;
	self.th_die = Player_Die;
	self.th_pain = Player_Pain;
	self.pausetime = 0; // paustime is set by teleporters to keep the player from moving a while
	
	//Item stats
	self.item = 0;
	self.picked_items = 0;
	self.total_hits = 0;
	self.total_shots = 0;
	for (entity e = findchainfloat(item, TRUE); e; e = e.chain)
	{
		self.item = self.item + 1;
	}
	
	float hubPending = (cvar_string("hub_restore_pending") == mapname);
	float slot = Player_SlotIndex(self);

	// Landmark arrival is single-player only. Coop carries inventory across the level change but regroups everyone at the map's coop spawn points rather than scattering them at wherever they each happened to be standing; a plain respawn likewise takes the normal spawn-point path below.
	float landmarkArrival = !hubPending && cvar("gamemode") == MODE_SP
	                        && strlen(cvar_string("landmark")) > 0
	                        && PlayerTransfer_GetF(slot, "valid") == 1;

	if(landmarkArrival)
	{
		entity landmark = ChangeLevel_FindLandmark(cvar_string("landmark"));
		if(!landmark)
		{
			self.origin = self.oldorigin = SpawnPoint_SpawnOrigin(spot, self);	// 1998-07-21 Respawning where player died fix by Robert Field
			self.angles = spot.angles;
		}
		else
		{
			// Prefer this client's own pose so coop arrivals keep their spacing; fall back to the legacy global for a single-player transition staged before the per-slot fields existed.
			string myPos = PlayerTransfer_GetS(slot, "lm_pos");
			string myAng = PlayerTransfer_GetS(slot, "lm_angles");
			string myVel = PlayerTransfer_GetS(slot, "lm_velocity");
			if (myPos == "") myPos = cvar_string("landmark_player_pos");
			if (myAng == "") myAng = cvar_string("landmark_player_angles");
			if (myVel == "") myVel = cvar_string("landmark_player_velocity");

			vector old_spot = stov(cvar_string("landmark_pos"));
			vector offset = landmark.origin - old_spot;
			vector new_pos = stov(myPos) + offset;

			self.origin = self.oldorigin = new_pos;
			self.angles = stov(myAng);
			self.velocity = stov(myVel);

			self.chlevel_lastTouchTime = time;

			ChangeLevel_ScheduleTrainRestore(offset);
		}
	}
	else
	{
		self.origin = self.oldorigin = SpawnPoint_SpawnOrigin(spot, self);	// 1998-07-21 Respawning where player died fix by Robert Field
		self.angles = spot.angles;
		self.velocity = '0 0 0';
	}
	self.fixangle = TRUE;

	precache_model(PLAYER_MODEL_FULL);
	Player_WeaponModelPrecache();
	if (Player_UseSplitBody())
	{
		precache_model(PLAYER_MODEL_LEGS);
		precache_model(PLAYER_MODEL_TORSO);
		setmodel(self, PLAYER_MODEL_LEGS);
	}
	else
		setmodel(self, PLAYER_MODEL_FULL);
	setsize(self, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX);
	self.view_ofs = STAND_VIEW_OFS;
	self.scale    = PLAYER_MODEL_SCALE;

	// Resolve spine bone for torso/legs split and clear anim state.
	Player_AnimInit(self);
	if (Player_UseSplitBody())
		Player_TorsoEnsure(self);

	if (Map_IsId1BSP() || cvar("g_startwithsuit"))
		self.weapons = self.weapons | WEAPON_SUIT;

	self.geiger_range = 1000;
	self.dmg_shownhud_bits = 0;

	self.flashlight_battery = 99;
	self.flashlight_on = 0;
	self.flashlight_time = 1;

	self.player_longJump = FALSE;

	// The client entity is reused for every life, so armor has to be cleared explicitly or it carries over into the next spawn.
	self.armorvalue = 0;
	self.armortype  = 0;

	// A multiplayer respawn starts empty; whatever comes next (transfer or the per-mode loadout) fills it back in. Single-player and hub restores keep whatever is already on the entity.
	if (IsMultiplayer() && !hubPending)
		Loadout_ClearInventory(self);

	if (hubPending)
	{
	}
	else if (PlayerTransfer_Load(self))
	{
		Weapon_Update();
	}
	else
	{
		Loadout_ApplyForMode(self);
		Weapon_Update();
	}

	// Give this client the game rules straight away rather than waiting for the next change; their own gamemode cvar is meaningless until they have them.
	PublishGameRulesTo(self);

	// Coop: (re)build this client's private copies of every unclaimed item.
	CoopItem_RefreshFor(self);

	if (!hubPending)
		ChangeLevel_SpawnPendingFireAndDie(self);


	if (g_startdark)
	{
		stuffcmd(self, "scrfade 0 0 0 255 4 0.25 0\n");
	}
}

void ClientDisconnect()
{
	Player_FrictionRelease();   // restore global friction if they left mid-volume
	Player_TorsoRemove(self);   // don't orphan the DP torso child
	Viewmodel_Remove(self);     // ...nor the viewmodel child

	if (IsMultiplayer())
	{
		bprint(strcat(Obituary_NameOf(self), " left the game\n"));
		Scoreboard_BroadcastRemove(self);
	}

	CoopItem_RemoveGhostsFor(self);	// don't orphan their private item copies

	// The slot's xfer cvars are deliberately left alone: the engine also runs ClientDisconnect/ClientConnect around a changelevel, and wiping here would throw away the transfer we just staged.

	Player_Die();
}
