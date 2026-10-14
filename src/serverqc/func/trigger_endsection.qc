// The map names an end-of-section script in a `section` keyvalue:
//   t0a0d   "_oem_end_training"   (fired by the "donemm" multi_manager)
//   hldemo1 "_oem_end_demo"       (fired by the "ending_mm" multi_manager)

#define SF_ENDSECTION_USE_ONLY		0x0001

.string section;

void Trigger_EndSectionRun(entity pActivator)
{
	if (!pActivator || pActivator.classname != "player") return;

	// Disarm first so a second touch/use in the same frame can't re-fire.
	self.use   = SUB_Null;
	self.usehl = __NULL__;
	self.touch = SUB_Null;

	dprint(strcat("trigger_endsection: ", self.section, "\n"));

	dropclient(pActivator);
	remove(self);
}

void Trigger_EndSectionUse()
{
	Trigger_EndSectionRun(activator);
}

// Uses the explicit pActivator argument instead of the global self
void Trigger_EndSectionUseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	Trigger_EndSectionRun(pActivator);
}

void Trigger_EndSectionTouch()
{
	Trigger_EndSectionRun(other);
}

void trigger_endsection()
{
	if(IsDeathmatch())
	{
		remove(self);
		return;
	}
	InitTrigger();
	self.use = Trigger_EndSectionUse;
	self.usehl = Trigger_EndSectionUseHL;
	if(!(self.spawnflags & SF_ENDSECTION_USE_ONLY))
		self.touch = Trigger_EndSectionTouch;
};
