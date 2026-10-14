#define SF_RELAY_FIREONCE		0x0001

.float triggerstate;
.float relay_useType;

void Trigger_RelayUse()
{
	SUB_UseTargetsHL(activator, self.relay_useType, 0);
	if(self.spawnflags & SF_RELAY_FIREONCE)
		remove(self);
}

void Trigger_RelayUseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	SUB_UseTargetsHL(pActivator, self.relay_useType, useValueArg);
	if(self.spawnflags & SF_RELAY_FIREONCE)
		remove(self);
}

void trigger_relay()
{
	switch ((float)self.triggerstate)
	{
	case 0:  self.relay_useType = USE_OFF;    break;
	case 2:  self.relay_useType = USE_TOGGLE; break;
	default: self.relay_useType = USE_ON;     break;
	}
	self.use = Trigger_RelayUse;
	self.usehl = Trigger_RelayUseHL;
};