
void func_episodegate()
{
	if (!(serverflags & self.spawnflags))
	{
		remove(self);
		return;
	}

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.use = FuncWall_Use;
	setmodel(self, self.model);
}
