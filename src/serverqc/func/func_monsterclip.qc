
void MonsterClip_Use()
{
}

void MonsterClip_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
}

void func_monsterclip()
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	self.solid = SOLID_NOT;
	self.flags = self.flags | FL_MONSTERCLIP;
	self.use = MonsterClip_Use;
	self.usehl = MonsterClip_UseHL;
	setmodel(self, self.model);
}
