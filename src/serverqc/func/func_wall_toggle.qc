

#define SF_WALL_START_OFF		0x0001


void FuncWallToggle_TurnOff( void )
{
	self.solid = SOLID_NOT;
	self.effects |= EF_NODRAW;
	setorigin(self, self.origin);
}


void FuncWallToggle_TurnOn()
{
	self.solid = SOLID_BSP;
	Render_Apply(self);
}

float FuncWallToggle_IsOn()
{
	if (self.solid == SOLID_NOT)
		return FALSE;
	return TRUE;
}

void FuncWallToggle_Use()
{
	float status = FuncWallToggle_IsOn();
	// if (ShouldToggle( useType, status ) )
	{
		if (status)
			FuncWallToggle_TurnOff();
		else
			FuncWallToggle_TurnOn();
	}
};

void FuncWallToggle_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	float status = FuncWallToggle_IsOn();
	if (status)
		FuncWallToggle_TurnOff();
	else
		FuncWallToggle_TurnOn();
};


void func_wall_toggle()
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.use = FuncWallToggle_Use;
	self.usehl = FuncWallToggle_UseHL;
	setmodel (self, self.model);
	Render_Apply(self);
	if (self.spawnflags & SF_WALL_START_OFF)
		FuncWallToggle_TurnOff();
};