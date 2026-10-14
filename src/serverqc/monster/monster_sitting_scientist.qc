// spawn forces SF_MONSTER_PREDISASTER (0x4000). No entity-local SF_*.
// Anims (framegroup indices from data/models/scientist.iqm.framegroups):
//   sitlookleft=71, sitlookright=72, sitscared=73, sitting2=74, sitting3=75, sitidle=89

#define SITSCI_ANIM_SITLOOKLEFT   71
#define SITSCI_ANIM_SITLOOKRIGHT  72
#define SITSCI_ANIM_SITSCARED     73
#define SITSCI_ANIM_SITTING2      74
#define SITSCI_ANIM_SITTING3      75
#define SITSCI_ANIM_SITIDLE       89

float SittingSci_FrameByName(string name)
{
	if (name == "sitlookleft")  return SITSCI_ANIM_SITLOOKLEFT;
	if (name == "sitlookright") return SITSCI_ANIM_SITLOOKRIGHT;
	if (name == "sitscared")    return SITSCI_ANIM_SITSCARED;
	if (name == "sitting2")     return SITSCI_ANIM_SITTING2;
	if (name == "sitting3")     return SITSCI_ANIM_SITTING3;
	if (name == "sitidle")      return SITSCI_ANIM_SITIDLE;
	return -1;
}

void SittingSci_PlayFrame(float idx)
{
	if (self.frame == idx) return;
	self.frame      = idx;
	self.frame1time = time;
	self.framerate  = 1;
}

float SittingSci_RandomSitAnim()
{
	float r = random() * 5;
	if (r < 1) return SITSCI_ANIM_SITLOOKLEFT;
	if (r < 2) return SITSCI_ANIM_SITLOOKRIGHT;
	if (r < 3) return SITSCI_ANIM_SITTING2;
	if (r < 4) return SITSCI_ANIM_SITTING3;
	return SITSCI_ANIM_SITSCARED;
}

void SittingSci_Think()
{
	self.nextthink = time + 4 + random() * 3;
	if (self.monster_cine && self.monster_cine != world) return;
	if (self.health <= 0) return;
	SittingSci_PlayFrame(SittingSci_RandomSitAnim());
}

void SittingSci_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!pActivator || !(pActivator.flags & FL_CLIENT)) return;
	if (self.health <= 0) return;
	if (self.monster_cine && self.monster_cine != world) return;

	vector dir = pActivator.origin - self.origin;
	makevectors(self.angles);
	if ((dir * v_right) > 0) SittingSci_PlayFrame(SITSCI_ANIM_SITLOOKRIGHT);
	else                     SittingSci_PlayFrame(SITSCI_ANIM_SITLOOKLEFT);

	Scientist_Speak((random() < 0.5) ? "SC_PIDLE" : "SC_PQUEST");
}

void SittingSci_Pain(entity attacker, float damage)
{
	if (self.health <= 0) return;
	if (self.monster_cine && self.monster_cine != world) return;   // scripted sequence owns us
	SittingSci_PlayFrame(SITSCI_ANIM_SITSCARED);
	if (attacker.flags & FL_CLIENT) Scientist_Speak("SC_PLFEAR");
	else                            Scientist_Speak("SC_FEAR");
}

void SittingSci_Die()
{
	Monster_ExitScriptedSequence();

	self.takedamage  = DAMAGE_NO;
	self.solid       = SOLID_CORPSE;
	self.movetype    = MOVETYPE_TOSS;
	self.deadflag    = DEAD_DEAD;
	self.use         = SUB_Null;
	self.usehl       = __NULL__;
	self.object_caps = 0;
	self.flags       = self.flags - (self.flags & FL_MONSTER);

	self.think     = SUB_Null;
	self.nextthink = -1;

	float dieFrame = 31;  // diesimple - reuses scientist.qc Scientist_FrameByName mapping
	if (IsFTE())
	{
		float f = frameforname(self.modelindex, "diesimple");
		if (f >= 0) dieFrame = f;
	}
	self.frame = dieFrame;
}

void monster_sitting_scientist()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	Scientist_Precache();

	setmodel(self, Scientist_GetModel());
	setsize(self, '-14 -14 0', '14 14 36');

	self.solid    = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;
	self.effects  = 0;
	self.health   = 50;
	self.max_health = self.health;

	self.monster_state      = MONSTERSTATE_IDLE;
	self.monster_idealState = MONSTERSTATE_IDLE;
	self.monster_bloodColor        = BLOOD_COLOR_RED;
	self.monster_fieldOfView     = 0.5;
	self.monster_capability      = BITS_CAP_HEAR | BITS_CAP_TURN_HEAD | BITS_CAP_USE;

	Scientist_ApplyBody();	// -1 = random head; Luther gets dark-hands family

	self.frameByName          = SittingSci_FrameByName;
	self.playScriptedSentence = Scientist_PlayScriptedSentence;

	self.th_pain = SittingSci_Pain;
	self.th_die  = SittingSci_Die;

	Monster_InitTakeDamage();

	self.use         = SUB_Null;
	self.usehl       = SittingSci_UseHL;
	self.object_caps = FCAP_IMPULSE_USE;

	SittingSci_PlayFrame(SITSCI_ANIM_SITLOOKLEFT + floor(random() * 5));

	// Force predisaster flag: sitting scientists are always pre-disaster
	self.spawnflags = self.spawnflags | SF_MONSTER_PREDISASTER;

	self.think     = SittingSci_Think;
	self.nextthink = time + 1 + random() * 2;
	total_monsters = total_monsters + 1;
}
