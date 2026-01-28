
#define SF_ENDSECTION_USEONLY		0x0001

void Trigger_EndSectionUse()
{
	if(activator && activator.classname != "player") return;
	if(self.message) centerprint(activator, self.message);
	remove(self);
}

void Trigger_EndSectionTouch()
{
	if(other.classname != "player") return;
	if(self.message) centerprint(other, self.message);
	remove(self);
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
	if(!(self.spawnflags & SF_ENDSECTION_USEONLY))
		self.touch = Trigger_EndSectionTouch;
};