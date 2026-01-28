
#define SF_AUTO_FIREONCE 1
void Trigger_TriggerAutoThink()
{
	SUB_UseTargets();
	if (self.spawnflags & SF_AUTO_FIREONCE)
		remove(self);

}

void trigger_auto()
{
	self.nextthink = time + 0.1;
	self.think = Trigger_TriggerAutoThink;

}