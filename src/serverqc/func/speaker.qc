//   message   sentence group name, or "!sentence" for one-shot specific line
// preset 1..12 index, overrides message with hardcoded groups
#define SF_SPEAKER_START_SILENT  1

#define SPEAKER_ANNOUNCE_MIN  (0.25 * 60)
#define SPEAKER_ANNOUNCE_MAX  (2.25 * 60)

// Shared talk-arbitration clock for speaker announcements and talkmonster sentences
// (monster_barney.qc, monster_scientist.qc) all yield to it so they never speak
// over each other. Declared here only; do not redeclare it in those files.
float g_talkWaitTime;

.float preset;

string Speaker_PresetGroup(float preset)
{
	switch (preset)
	{
		case 1:  return "C1A0_";
		case 2:  return "C1A1_";
		case 3:  return "C1A2_";
		case 4:  return "C1A3_";
		case 5:  return "C1A4_";
		case 6:  return "C2A1_";
		case 7:  return "C2A2_";
		case 8:  return "C2A3_";
		case 9:  return "C2A4_";
		case 10: return "C2A5_";
		case 11: return "C3A1_";
		case 12: return "C3A2_";
	}
	return "";
}

void Speaker_Think()
{
	float flvolume    = self.health * 0.1;
	float flattenuation = 0.3;
	float pitch       = 100;

	if (time <= g_talkWaitTime)
	{
		self.nextthink = g_talkWaitTime + random(5, 10);
		return;
	}

	string szSoundFile;
	if (self.preset)
		szSoundFile = Speaker_PresetGroup(self.preset);
	else
		szSoundFile = self.message;

	if (szSoundFile == "")
	{
		self.nextthink = 0;
		return;
	}

	if (str2chr(szSoundFile, 0) == ASCII_BANG)
	{
		Sentences_Play(self, CHAN_VOICE, szSoundFile, flvolume, flattenuation, pitch);
		self.nextthink = 0;
	}
	else
	{
		if (Sentences_Play(self, CHAN_VOICE, szSoundFile, flvolume, flattenuation, pitch) <= 0)
		{
			dprint("SPEAKER: bad sentence group '");
			dprint(szSoundFile);
			dprint("'\n");
		}
		self.nextthink = time + random(SPEAKER_ANNOUNCE_MIN, SPEAKER_ANNOUNCE_MAX);
		g_talkWaitTime = time + 5;
	}
}

void Speaker_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	float fActive = (self.nextthink > 0);

	if (useTypeArg != USE_TOGGLE)
	{
		if ((fActive && useTypeArg == USE_ON) || (!fActive && useTypeArg == USE_OFF))
			return;
	}

	if (useTypeArg == USE_ON)
	{
		self.nextthink = time + 0.1;
		return;
	}
	if (useTypeArg == USE_OFF)
	{
		self.nextthink = 0;
		return;
	}

	if (fActive)
		self.nextthink = 0;
	else
		self.nextthink = time + 0.1;
}

void Speaker_Use()
{
	Speaker_UseHL(activator, self, USE_TOGGLE, 0);
}

void speaker()
{
	if (!self.preset && (!self.message || self.message == ""))
	{
		dprint("SPEAKER with no Level/Sentence at ");
		dprint(vtos(self.origin));
		dprint("\n");
		self.think = SUB_Remove;
		self.nextthink = time + 0.1;
		return;
	}

	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.model    = "";

	self.think = Speaker_Think;
	self.nextthink = 0;

	self.use   = Speaker_Use;
	self.usehl = Speaker_UseHL;

	if (!(self.spawnflags & SF_SPEAKER_START_SILENT))
		self.nextthink = time + random(5, 15);
}
