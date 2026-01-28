#define SF_RELAY_FIREONCE		0x0001


void Trigger_RelayUse()
{
	SUB_UseTargets();
	if(self.spawnflags & SF_RELAY_FIREONCE)
		remove(self);
}

void trigger_relay()
{
	self.use = Trigger_RelayUse;
};