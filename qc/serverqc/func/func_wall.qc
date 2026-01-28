

void func_wall_use()
{	
	self.frame = 1 - self.frame; // change to alternate textures
};

void func_wall()
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	self.use = func_wall_use;
	setmodel (self, self.model);
};