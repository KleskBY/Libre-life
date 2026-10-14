

void FuncWall_Use()
{
	self.frame = 1 - self.frame; // change to alternate textures
};

// Use: toggles alternate texture frame. Params unused.
void FuncWall_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	self.frame = 1 - self.frame;
};

void func_wall()
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.use = FuncWall_Use;
	self.usehl = FuncWall_UseHL;
	setmodel (self, self.model);
	Render_Apply(self);
	Brush_ApplyContents(self);	// "skin" content override (water/ladder/etc)
};