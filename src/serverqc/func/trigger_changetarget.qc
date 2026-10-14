

.string m_iszNewTarget;

void Trigger_ChangeTargetUse()
{
	entity e = find(world, targetname, self.target);
	if(e)
	{
		e.target = self.m_iszNewTarget;
		if(e.flags & FL_MONSTER)
		{
			e.goalentity = world;
		}
	}
}

void Trigger_ChangeTargetUseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	entity e = find(world, targetname, self.target);
	if(e)
	{
		e.target = self.m_iszNewTarget;
		if(e.flags & FL_MONSTER)
		{
			e.goalentity = world;
		}
	}
}


void trigger_changetarget()
{
	InitTrigger();
	self.use = Trigger_ChangeTargetUse;
	self.usehl = Trigger_ChangeTargetUseHL;
}