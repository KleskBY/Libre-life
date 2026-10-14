void TriggerSetSkill_Touch()
{
	if (other.classname != "player") return;

	cvar_set("skill", self.message); // takes effect on the next map load
}


void trigger_setskill()
{
	InitTrigger();
	self.touch = TriggerSetSkill_Touch;
}
