

void FuncTrainControls_Find()
{
	entity pTarget = find(world, targetname, self.target);
	while(pTarget && pTarget.classname != "func_tracktrain")
	{
		pTarget = find(pTarget, targetname, self.target);
	}
	
	if (!pTarget)
	{
		dprint("No train ");
		dprint(self.target);
		dprint("\n");
		return;
	}

	entity ptrain = FuncTrackTrain_Instance(pTarget);
	FuncTrackTrain_SetControls(ptrain, self);
	remove(self);
}


void func_traincontrols()
{
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_NONE;
	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
	
	self.think = FuncTrainControls_Find;
	self.nextthink = time;
}

