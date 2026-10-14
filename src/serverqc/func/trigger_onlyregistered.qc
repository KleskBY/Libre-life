
void TriggerOnlyRegistered_Touch()
{
	if (other.classname != "player") return;
	if (self.attack_finished > time) return;

	self.attack_finished = time + 2;

	if (cvar("registered"))
	{
		self.message = "";
		SUB_UseTargets();
	}
	else
	{
		if (self.message != "")
		{
			centerprint(other, self.message);
			Sound_Play(other, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, "misc/talk.wav");
		}
	}
};


void trigger_onlyregistered()
{
	precache_sound ("misc/talk.wav");
	InitTrigger();
	self.touch = TriggerOnlyRegistered_Touch;
}
