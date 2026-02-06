.string landmark;
.string changetarget;
.float changedelay;
string nextmap;
#define SF_CHANGELEVEL_USEONLY		0x0002

entity ChangeLevel_FindLandmark(string pLandmarkName)
{
	entity pentLandmark = find(world, targetname, pLandmarkName);
	while (pentLandmark)
	{
		// Found the landmark
		if (pentLandmark.classname == "info_landmark")
			return pentLandmark;
		else
			pentLandmark = find(pentLandmark, targetname, pLandmarkName);
	}
	// ALERT( at_error, "Can't find landmark %s\n", pLandmarkName );
	return world;
}

void ChangeLevel_ChangeLevelNow(entity pActivator)
{
	if (time < 5) return;
	if (!self.map) objerror("chagnelevel trigger doesn't have map");
	// Don't work in deathmatch
	if(IsDeathmatch()) 
		return;
		
	// Some people are firing these multiple times in a frame, disable
	if (time == self.dmgtime)
		return;
		
	self.dmgtime = time;
	
	// Create an entity to fire the changetarget
	if (self.changetarget)
	{
		entity pFireAndDie = spawn();
		pFireAndDie.target = self.changetarget;
		pFireAndDie.wait = self.changedelay;
		setorigin(pFireAndDie, self.origin);
	}
	// This object will get removed in the call to CHANGE_LEVEL, copy the params into "safe" memory
	nextmap = self.map;
	self.enemy = pActivator;
	SUB_UseTargets();
	cvar_set("landmark", "");
	
	// look for a landmark entity		
	entity pentLandmark = ChangeLevel_FindLandmark(self.landmark);
	if (pentLandmark)
	{
		cvar_set("landmark", self.landmark);
		cvar_set("landmark_pos", vtos(pentLandmark.origin));
		cvar_set("landmark_player_pos", vtos(self.enemy.origin));
		cvar_set("landmark_player_angles", vtos(self.enemy.v_angle));
		cvar_set("landmark_player_velocity", vtos(self.enemy.velocity));
	}
	changelevel(self.map);
	// CHANGE_LEVEL(self.map, st_szNextSpot);
}

void ChangeLevel_UseChangeLevel()
{
	ChangeLevel_ChangeLevelNow(activator);
}

void ChangeLevel_TouchChangeLevel()
{
	if (other.classname != "player") return;
	ChangeLevel_ChangeLevelNow(other);
}

void trigger_changelevel()
{
	// self.solid = SOLID_NOT;
	// self.movetype = MOVETYPE_NONE;
	// setmodel(self, self.model);    // set size and link into world
	// self.model = "";
	// self.modelindex = 0;

	if (!self.map) objerror("chagnelevel trigger doesn't have map");
	// if (!self.landmark) objerror("trigger_changelevel doesn't have a landmark");
	if (!self.targetname)
	{
		self.use = ChangeLevel_UseChangeLevel;
	}
	
	InitTrigger();
	if (!(self.spawnflags & SF_CHANGELEVEL_USEONLY))
		self.touch = ChangeLevel_TouchChangeLevel;
		
};