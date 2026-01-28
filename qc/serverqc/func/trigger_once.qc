
void trigger_once()
{
	self.wait = -1;
	InitTrigger();
	ASSERT(self.health == 0, "trigger_once with health");
	self.touch = Trigger_MultipleTouch;
};