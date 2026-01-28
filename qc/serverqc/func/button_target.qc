
#define SF_BTARGET_USE		0x0001
#define SF_BTARGET_ON		0x0002





void ButtonTarget_ObjectCaps()
{
	if (FBitSet(spawnflags, SF_BTARGET_USE))
		self.object_caps = self.object_caps | FCAP_IMPULSE_USE;
}

void ButtonTarget_Use()
{
	self.frame = 1 - self.frame;
	SUB_UseTargets();
}

void ButtonTarget_TakeDamage()
{
	ButtonTarget_Use();
}

void button_target()
{
	ButtonTarget_ObjectCaps();
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel(self, self.model);
	self.takedamage = DAMAGE_YES;
	
	if (FBitSet(spawnflags, SF_BTARGET_ON))
		self.frame = 1;

}