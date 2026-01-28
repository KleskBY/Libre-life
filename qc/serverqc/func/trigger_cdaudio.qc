



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

void TriggerCDAudio_Touch()
{
	if(other.classname != "player") return;
	TriggerCDAudio_PlayTrack();
}

void trigger_cdaudio()
{
	InitTrigger();
	self.touch = TriggerCDAudio_Touch;
	self.use = TriggerCDAudio_Use;

}