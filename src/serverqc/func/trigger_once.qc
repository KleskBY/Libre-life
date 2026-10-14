
void trigger_once()
{
	Spent_Capture(self);
	if (Spent_IsSpent(self)) { remove(self); return; }

	self.wait = -1;
	InitTrigger();
	ASSERT(self.health == 0, "trigger_once with health");
	self.touch = Trigger_MultipleTouch;
	self.use = Trigger_MultipleUse;
};