// Keys:
//   intarget    targetname fired per player inside the volume
//   outtarget   targetname fired per player outside
//   incount     targetname receiving USE_SET (count_in) once
//   outcount    targetname receiving USE_SET (count_out) once
//   master      master gate
//
// No spawnflags.

.string intarget;
.string outtarget;
.string incount;
.string outcount;

float GamePlayerZone_PointInside(entity zone, vector p)
{
	return (p_x >= zone.absmin_x && p_x <= zone.absmax_x &&
	        p_y >= zone.absmin_y && p_y <= zone.absmax_y &&
	        p_z >= zone.absmin_z && p_z <= zone.absmax_z);
}

void GamePlayerZone_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	float countIn = 0;
	float countOut = 0;

	entity p = find(world, classname, "player");
	while (p)
	{
		if (GamePlayerZone_PointInside(self, p.origin))
		{
			countIn++;
			if (self.intarget != "")
				SUB_FireTargets(self.intarget, p, pActivator, useTypeArg, useValueArg);
		}
		else
		{
			countOut++;
			if (self.outtarget != "")
				SUB_FireTargets(self.outtarget, p, pActivator, useTypeArg, useValueArg);
		}
		p = find(p, classname, "player");
	}

	if (self.incount != "")
		SUB_FireTargets(self.incount, pActivator, self, USE_SET, countIn);
	if (self.outcount != "")
		SUB_FireTargets(self.outcount, pActivator, self, USE_SET, countOut);
}

void GamePlayerZone_Use()
{
	GamePlayerZone_UseHL(activator, self, useType, 0);
}

void game_zone_player()
{
	// remain non-solid and invisible.
	setmodel(self, self.model);
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
	self.use   = GamePlayerZone_Use;
	self.usehl = GamePlayerZone_UseHL;
}
