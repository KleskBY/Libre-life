
void func_illusionary()
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel(self, self.model);
	Render_Apply(self);
	if (self.rendermode == 0 && !Map_IsId1BSP())
		makestatic(self);
};
