

void TriggerCDAudio_PlayTrack()
{
	PlayCDTrack(self.health);
	self.touch = SUB_Null;
	remove(self);
}


void TriggerCDAudio_Use()
{
	TriggerCDAudio_PlayTrack();
}

// Use function: parameters unused.
void TriggerCDAudio_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	TriggerCDAudio_PlayTrack();
}

void TriggerCDAudio_Touch()
{
	if(other.classname != "player") return;
	TriggerCDAudio_PlayTrack();
}

void trigger_cdaudio()
{
	print("CD AUDIO ", etos(self), "\n");
	InitTrigger();
	self.touch = TriggerCDAudio_Touch;
	self.use = TriggerCDAudio_Use;
	self.usehl = TriggerCDAudio_UseHL;

}