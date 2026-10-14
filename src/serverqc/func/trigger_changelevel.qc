.string landmark;
.string changetarget;
.float changedelay;
string nextmap;
#define SF_CHANGELEVEL_USE_ONLY		0x0002

void Q1Intermission_Begin(entity pActivator, string mapTo);

void FireAndDie_Think()
{
	if (self.target)
		SUB_FireTargets(self.target, self.enemy, self, USE_TOGGLE, 0);
	remove(self);
}

void ChangeLevel_StashFireAndDie(string targetName, float delay)
{
	if (!targetName || targetName == "")
	{
		cvar_set("xfer_firetarget", "");
		cvar_set("xfer_firedelay", "0");
		return;
	}
	cvar_set("xfer_firetarget", targetName);
	cvar_set("xfer_firedelay", ftos(delay));
}

void ChangeLevel_SpawnPendingFireAndDie(entity pActivator)
{
	string tgt = cvar_string("xfer_firetarget");
	if (tgt == "") return;

	string tgtPersist = strzone(tgt);
	float  delay      = stof(cvar_string("xfer_firedelay"));

	entity fad        = spawn();
	fad.classname     = "fireanddie";
	fad.target        = tgtPersist;
	fad.enemy         = pActivator;
	fad.think         = FireAndDie_Think;
	fad.nextthink     = time + delay;
	if (pActivator) setorigin(fad, pActivator.origin);

	cvar_set("xfer_firetarget", "");
	cvar_set("xfer_firedelay", "0");
}

entity ChangeLevel_FindLandmark(string pLandmarkName)
{
	entity pentLandmark = find(world, targetname, pLandmarkName);
	while (pentLandmark)
	{
		if (pentLandmark.classname == "info_landmark")
			return pentLandmark;
		else
			pentLandmark = find(pentLandmark, targetname, pLandmarkName);
	}
	// ALERT( at_error, "Can't find landmark %s\n", pLandmarkName );
	return world;
}

void ChangeLevel_ClearTrainTransfer()
{
	cvar_set("landmark_train", "");
	cvar_set("landmark_train_globalname", "");
	cvar_set("landmark_train_pos", "");
	cvar_set("landmark_train_angles", "");
	cvar_set("landmark_train_velocity", "");
	cvar_set("landmark_train_avelocity", "");
	cvar_set("landmark_train_path", "");
	cvar_set("landmark_train_target", "");
	cvar_set("landmark_train_targ", "");
	cvar_set("landmark_train_speed", "");
	cvar_set("landmark_train_mspeed", "");
	cvar_set("landmark_train_startspeed", "");
	cvar_set("landmark_train_dir", "");
	cvar_set("landmark_train_spawnflags", "");
}

entity ChangeLevel_FindTransitionTrain(entity pActivator)
{
	if (pActivator.groundentity && pActivator.groundentity.classname == "func_tracktrain")
		return pActivator.groundentity;

	if (pActivator.train_ent && pActivator.train_ent.classname == "func_tracktrain")
		return pActivator.train_ent;

	entity best = world;
	float bestdist = 999999;
	entity e = findradius(pActivator.origin, 512);
	while (e)
	{
		if (e.classname == "func_tracktrain")
		{
			if (Player_InTrainControls(e, pActivator))
				return e;

			float dist = vlen(e.origin - pActivator.origin);
			if (dist < bestdist)
			{
				bestdist = dist;
				best = e;
			}
		}
		e = e.chain;
	}

	return best;
}

string ChangeLevel_TrainPathName(entity train)
{
	if (train.tracktrain_path && train.tracktrain_path.targetname != "")
		return train.tracktrain_path.targetname;
	if (train.target != "")
		return train.target;
	return "";
}

void ChangeLevel_SaveTrainTransfer(entity pActivator)
{
	ChangeLevel_ClearTrainTransfer();

	entity train = ChangeLevel_FindTransitionTrain(pActivator);
	if (!train)
		return;

	string pathName = ChangeLevel_TrainPathName(train);

	cvar_set("landmark_train", train.targetname);
	cvar_set("landmark_train_globalname", train.globalname);
	cvar_set("landmark_train_pos", vtos(train.origin));
	cvar_set("landmark_train_angles", vtos(train.angles));
	cvar_set("landmark_train_velocity", vtos(train.velocity));
	cvar_set("landmark_train_avelocity", vtos(train.avelocity));
	cvar_set("landmark_train_path", pathName);
	cvar_set("landmark_train_target", train.target);
	cvar_set("landmark_train_targ", pathName);
	cvar_set("landmark_train_speed", ftos(train.speed));
	cvar_set("landmark_train_mspeed", ftos(train.m_speed));
	cvar_set("landmark_train_startspeed", ftos(train.startspeed));
	cvar_set("landmark_train_dir", ftos(train.tracktrain_dir));
	cvar_set("landmark_train_spawnflags", ftos(train.spawnflags));
}

// Checks if the train has staged landmark transition data (read at spawn)
float ChangeLevel_TrainRestorePending(entity train)
{
	string gname = cvar_string("landmark_train_globalname");
	if (strlen(gname) > 0 && train.globalname == gname)
		return TRUE;

	string tname = cvar_string("landmark_train");
	if (strlen(tname) > 0 && train.targetname == tname)
		return TRUE;

	return FALSE;
}

entity ChangeLevel_FindRestoreTrain()
{
	string name = cvar_string("landmark_train_globalname");
	entity e;

	if (strlen(name) > 0)
	{
		e = find(world, globalname, name);
		while (e)
		{
			if (e.classname == "func_tracktrain")
				return e;
			e = find(e, globalname, name);
		}
	}

	name = cvar_string("landmark_train");
	if (strlen(name) > 0)
	{
		e = find(world, targetname, name);
		while (e)
		{
			if (e.classname == "func_tracktrain")
				return e;
			e = find(e, targetname, name);
		}
	}

	return world;
}

entity ChangeLevel_FindPathTrackByName(string name)
{
	if (strlen(name) <= 0)
		return world;

	entity e = find(world, targetname, name);
	while (e)
	{
		if (e.classname == "path_track")
			return e;
		e = find(e, targetname, name);
	}

	return world;
}

entity ChangeLevel_FindNearestPathTrack(vector org)
{
	entity best = world;
	float bestdist = 999999;
	entity e = findradius(org, 1024);
	while (e)
	{
		if (e.classname == "path_track")
		{
			float dist = vlen(e.origin - org);
			if (dist < bestdist)
			{
				bestdist = dist;
				best = e;
			}
		}
		e = e.chain;
	}

	return best;
}

void ChangeLevel_RestoreTrain(vector offset)
{
	entity train = ChangeLevel_FindRestoreTrain();
	if (!train)
	{
		ChangeLevel_ClearTrainTransfer();
		return;
	}

	vector newOrigin = stov(cvar_string("landmark_train_pos")) + offset;
	string pathName = cvar_string("landmark_train_path");
	if (strlen(pathName) <= 0)
		pathName = cvar_string("landmark_train_targ");

	entity path = ChangeLevel_FindPathTrackByName(pathName);
	if (!path)
		path = ChangeLevel_FindNearestPathTrack(newOrigin);

	setorigin(train, newOrigin);
	train.angles = stov(cvar_string("landmark_train_angles"));
	train.velocity = stov(cvar_string("landmark_train_velocity"));
	train.avelocity = stov(cvar_string("landmark_train_avelocity"));
	train.speed = cvar("landmark_train_speed");
	train.m_speed = cvar("landmark_train_mspeed");
	train.startspeed = cvar("landmark_train_startspeed");
	train.tracktrain_dir = cvar("landmark_train_dir");
	train.spawnflags = cvar("landmark_train_spawnflags");
	train.tracktrain_soundPlaying = FALSE;

	if (train.m_speed <= 0)
		train.m_speed = 100;
	if (train.tracktrain_dir == 0)
		train.tracktrain_dir = 1;

	if (path)
	{
		train.tracktrain_path = path;
		train.target = path.targetname;
	}
	else if (strlen(cvar_string("landmark_train_target")) > 0)
	{
		train.target = cvar_string("landmark_train_target");
	}

	if (train.speed != 0 && train.tracktrain_path)
	{
		entity olds = self;
		self = train;
		FuncTrackTrain_Next();
		self = olds;
	}
	else
	{
		train.velocity = '0 0 0';
		train.avelocity = '0 0 0';
		train.think = SUB_Null;
		train.nextthink = -1;
		train.flags &= ~FL_ALWAYSTHINK;
	}

	ChangeLevel_ClearTrainTransfer();
}

void ChangeLevel_ScheduleTrainRestore(vector offset)
{
	if (strlen(cvar_string("landmark_train")) <= 0 && strlen(cvar_string("landmark_train_globalname")) <= 0)
		return;

	// Runs immediately to fix timing issues related to path linking and teleporting
	PathTrack_LinkAll();
	ChangeLevel_RestoreTrain(offset);
}

void ChangeLevel_Now(entity pActivator)
{
	if (!self.map) objerror("chagnelevel trigger doesn't have map");
	if(IsDeathmatch())
		return;

	if (time == self.dmgtime)
		return;

	self.dmgtime = time;

	// heuristic then reads as "fresh start" and nukes ALL cross-map state.
	if (!pActivator || pActivator.classname != "player")
	{
		entity pl = find(world, classname, "player");
		if (pl) pActivator = pl;
	}

	ChangeLevel_StashFireAndDie(self.changetarget, self.changedelay);

	// Object is removed by CHANGE_LEVEL, so copy params to cvars for persistence
	nextmap = self.map;
	self.enemy = pActivator;
	activator = pActivator;	// SUB_UseTargets reads the global state; keep activator consistent with pActivator
	SUB_UseTargetsHL(pActivator, USE_TOGGLE, 0);

	cvar_set("landmark", "");
	ChangeLevel_ClearTrainTransfer();

	// Look for a landmark entity. Single-player only: coop regroups the team on
	entity pentLandmark = world;
	if (cvar("gamemode") == MODE_SP)
		pentLandmark = ChangeLevel_FindLandmark(self.landmark);

	if (pentLandmark)
	{
		cvar_set("landmark", self.landmark);
		cvar_set("landmark_pos", vtos(pentLandmark.origin));
		cvar_set("landmark_player_pos", vtos(pActivator.origin));
		cvar_set("landmark_player_angles", vtos(pActivator.v_angle));
		cvar_set("landmark_player_velocity", vtos(pActivator.velocity));

		// Per-client pose for future modes, using individual offsets
		for (entity mover = find(world, classname, "player"); mover; mover = find(mover, classname, "player"))
		{
			float s = Player_SlotIndex(mover);
			PlayerTransfer_SetS(s, "lm_pos",      vtos(mover.origin));
			PlayerTransfer_SetS(s, "lm_angles",   vtos(mover.v_angle));
			PlayerTransfer_SetS(s, "lm_velocity", vtos(mover.velocity));
		}

		ChangeLevel_SaveTrainTransfer(pActivator);
	}

	float bIsId1Boss = Map_IsId1BSP() &&
		(mapname == "e1m7" || mapname == "e2m6" ||
		 mapname == "e3m6" || mapname == "e4m7");

	if (bIsId1Boss)
	{
		PlayerTransfer_Clear();
		GlobalState_ClearAll();
		// No pending fire-and-die should leak into the new game
		ChangeLevel_StashFireAndDie("", 0);
		cvar_set("id1_serverflags", ftos(serverflags));
	}
	else
	{
		// Everyone travels, not just whoever touched the trigger.
		for (entity trav = find(world, classname, "player"); trav; trav = find(trav, classname, "player"))
			PlayerTransfer_Save(trav);
		if (Map_IsId1BSP())
			cvar_set("id1_serverflags", ftos(serverflags));
		else
			cvar_set("id1_serverflags", "");
	}

	if (Map_IsId1BSP() && !IsDeathmatch())
	{
		Q1Intermission_Begin(pActivator, self.map);
		return;
	}

	Hub_SaveCurrent();

	changelevel(self.map);
}

void ChangeLevel_Use()
{
	ChangeLevel_Now(activator);
}

// Use: pass pActivator straight through to the shared implementation
void ChangeLevel_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	ChangeLevel_Now(pActivator);
}

void ChangeLevel_Touch()
{
	if (other.classname != "player") return;

	if (time == self.dmgtime) return;

	float dt = time - other.chlevel_lastTouchTime;
	other.chlevel_lastTouchTime = time;
	if (dt < 0.1) return;

	ChangeLevel_Now(other);
}

void trigger_changelevel()
{
	if (!self.map) objerror("chagnelevel trigger doesn't have map");

	InitTrigger();

	self.use   = ChangeLevel_Use;
	self.usehl = ChangeLevel_UseHL;

	if (!(self.spawnflags & SF_CHANGELEVEL_USE_ONLY))
		self.touch = ChangeLevel_Touch;
};
