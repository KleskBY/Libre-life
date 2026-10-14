
#define SF_BUTTON_DONTMOVE		1
#define SF_ROTBUTTON_NOTSOLID	1
#define	SF_BUTTON_TOGGLE		32
#define	SF_BUTTON_SPARK_IF_OFF	64
#define SF_BUTTON_TOUCH_ONLY	256

#define BUTTON_CODE_NOTHING 	0
#define BUTTON_CODE_ACTIVATE 	1
#define BUTTON_CODE_RETURN		2

void Button_Wait();
void Button_Return();
void Button_Activate();
void Button_TriggerAndWait();
void Button_BackHome();

// .string master lives in subs.qc, needed by earlier files too.
.float stayPushed;
.float rotating;

.string noiseLocked;
.string noiseUnlocked;

.vector ang1;
.vector ang2;

.float waitSound;

.float locked_sentence;
.float unlocked_sentence;
.string button_lockedSentenceGroup;
.string button_unlockedSentenceGroup;
.float waitSentence;            // sentence-play debounce (separate from waitSound)

#define DOOR_SENTENCEWAIT 6.0

string LockedSentenceName(float n)
{
	switch (n)
	{
		case 1: return "NA";       // "access denied"
		case 2: return "ND";       // "security lockout"
		case 3: return "NF";       // "blast door"
		case 4: return "NFIRE";    // "fire door"
		case 5: return "NCHEM";    // "chemical door"
		case 6: return "NRAD";     // "radiation door"
		case 7: return "NCON";     // "gen containment"
		case 8: return "NH";       // "maintenance door"
		case 9: return "NG";       // "broken door"
	}
	return "";
}

string UnlockedSentenceName(float n)
{
	switch (n)
	{
		case 1: return "EA";       // "access granted"
		case 2: return "ED";       // "security door"
		case 3: return "EF";       // "blast door"
		case 4: return "EFIRE";    // "fire door"
		case 5: return "ECHEM";    // "chemical door"
		case 6: return "ERAD";     // "radiation door"
		case 7: return "ECON";     // "gen containment"
		case 8: return "EH";       // "maintenance door"
	}
	return "";
}

void ResolveLockSentences()
{
	if (self.locked_sentence > 0)
		self.button_lockedSentenceGroup = LockedSentenceName(self.locked_sentence);
	if (self.unlocked_sentence > 0)
		self.button_unlockedSentenceGroup = UnlockedSentenceName(self.unlocked_sentence);
}

void PlayLockSounds(float flocked, float fbutton)
{
	if(self.waitSound > time) return;
	self.waitSound = time + 1;
	if(flocked) Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, self.noiseLocked);
	else Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, self.noiseUnlocked);

	if (self.waitSentence <= time)
	{
		string grp = flocked ? self.button_lockedSentenceGroup
		                     : self.button_unlockedSentenceGroup;
		if (grp != "" && grp)
		{
			Sentences_Play(self, CHAN_VOICE, grp, 0.85, ATTN_NORM, 100);
			self.waitSentence = time + DOOR_SENTENCEWAIT;
		}
	}
	}

void Button_Wait()
{
	self.state = STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = Button_Return;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;
};

void DoSpark(vector location)
{
	vector tmp = location + self.size * 0.5;
	te_spark(tmp, randomvec(), Math_RandomInt(3, 9));
	float vol = random(0.25, 0.75) * 0.4;
	float rsnd = Math_RandomInt(1, 6);
	string file = strcat("buttons/spark", ftos(rsnd), ".wav");
	Sound_Play(self, CHAN_VOICE, vol, ATTN_NORM, PITCH_NORM, file);
}

void Button_Spark()
{
	self.think = Button_Spark;
	self.nextthink = time + random(0.1, 1.6);
	DoSpark(self.mins);
}

void Button_Use()
{
	if(self.state == STATE_UP || self.state == STATE_DOWN)
		return;

	self.enemy = activator;
	if(self.state == STATE_TOP)
	{
		if(!self.stayPushed && self.spawnflags & SF_BUTTON_TOGGLE)
		{
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
			Button_Return();
		}
	}
	else
		Button_Activate();
};

void Button_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.state == STATE_UP || self.state == STATE_DOWN)
		return;

	self.enemy = pActivator;
	if (self.state == STATE_TOP)
	{
		if (!self.stayPushed && self.spawnflags & SF_BUTTON_TOGGLE)
		{
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
			Button_Return();
		}
	}
	else
		Button_Activate();
}

float Button_ResponseToTouch()
{
	if(self.state == STATE_UP || self.state == STATE_DOWN ||
		(self.state == STATE_TOP && !self.stayPushed && !(self.spawnflags & SF_BUTTON_TOGGLE)))
		return BUTTON_CODE_NOTHING;
		 
	if(self.state == STATE_TOP)
	{
		if((self.spawnflags & SF_BUTTON_TOGGLE) && self.stayPushed)
		{
			return BUTTON_CODE_RETURN;
		}
	}
	else return BUTTON_CODE_ACTIVATE;
	return BUTTON_CODE_NOTHING;
}

void Button_Touch()
{
	if (other.classname != "player") return;

	self.enemy = other;
	float code = Button_ResponseToTouch();
	if(code == BUTTON_CODE_NOTHING) return;
	if (!Master_IsTriggered(self.master, other))
	{
		PlayLockSounds(TRUE, TRUE);
		return;
	}
	
	self.touch = SUB_Null;
	if(code == BUTTON_CODE_RETURN)
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
		activator = self.enemy;
		SUB_UseTargets();
		Button_Return();
	}
	else Button_Activate();
}

void Button_Killed()
{
	self.enemy = damage_attacker;
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	Button_Activate();
	if (self.state == STATE_BOTTOM)
		self.takedamage = DAMAGE_YES;
}

void Button_Activate()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
	
	if (!Master_IsTriggered(self.master, self.enemy/*self.activator*/))
	{
		PlayLockSounds(TRUE, TRUE);
		return;
	}
	else
	{
		PlayLockSounds(FALSE, TRUE);
	}

	ASSERT(self.state == STATE_BOTTOM);
	self.state = STATE_UP;
	
	if (!self.rotating)	
		SUB_CalcMove(self.pos2, self.speed, Button_TriggerAndWait);
	else
		SUB_CalcAngleMove(self.ang2, self.speed, Button_TriggerAndWait);
}

void Button_TriggerAndWait()
{
	ASSERT(self.state == STATE_UP);
	
	if (!Master_IsTriggered(self.master, self.enemy))
		return;
	
	self.state = STATE_TOP;
	if(self.stayPushed || self.spawnflags & SF_BUTTON_TOGGLE)
	{
		if(self.spawnflags & SF_BUTTON_TOUCH_ONLY)
		{
			self.touch = Button_Touch;
		}
		else self.touch = SUB_Null;
	}
	else
	{
		self.nextthink = self.ltime + self.wait;
		self.think = Button_Return;
	}
	self.frame = 1;
	activator = self.enemy;
	SUB_UseTargets();
}

void Button_Return()
{
	self.state = STATE_DOWN;
	if (!self.rotating)	
		SUB_CalcMove(self.pos1, self.speed, Button_BackHome);
	else
		SUB_CalcAngleMove(self.ang1, self.speed, Button_BackHome);
	self.frame = 0;
}

void Button_BackHome()
{
	ASSERT(self.state == STATE_DOWN);
	self.state = STATE_BOTTOM;
	if (self.health)
		self.takedamage = DAMAGE_YES;

	if (self.spawnflags & SF_BUTTON_TOGGLE)
	{		
		activator = self.enemy;
		SUB_UseTargets();
	}


	if (self.target)
	{
		entity pentTarget = find(world, targetname, self.target);
		while(pentTarget)
		{
			if(pentTarget.classname == "multisource")
			{
				entity stemp = self;
				if (pentTarget.usehl)
				{
					self = pentTarget;
					self.usehl(activator, stemp, USE_TOGGLE, 0);
					self = stemp;
				}
				else if (pentTarget.use)
				{
					entity otemp = other;
					self = pentTarget;
					other = stemp;
					self.use();
					self = stemp;
					other = otemp;
				}
			}
			pentTarget = find(pentTarget, targetname, self.target);
		}
	}


	if (self.spawnflags & SF_BUTTON_TOUCH_ONLY)
	{
		self.touch = Button_Touch;
	}
	else self.touch = SUB_Null;

	if (self.spawnflags & SF_BUTTON_SPARK_IF_OFF)
	{
		self.think = Button_Spark;
		self.nextthink = time + 0.5;
	}
}

string Button_Sound(float sound_num)
{ 
	string pszSound;
	switch (sound_num)
	{
		case 0: pszSound = "common/null.wav";        break;
		case 1: pszSound = "buttons/button1.wav";	break;
		case 2: pszSound = "buttons/button2.wav";	break;
		case 3: pszSound = "buttons/button3.wav";	break;
		case 4: pszSound = "buttons/button4.wav";	break;
		case 5: pszSound = "buttons/button5.wav";	break;
		case 6: pszSound = "buttons/button6.wav";	break;
		case 7: pszSound = "buttons/button7.wav";	break;
		case 8: pszSound = "buttons/button8.wav";	break;
		case 9: pszSound = "buttons/button9.wav";	break;
		case 10: pszSound = "buttons/button10.wav";	break;
		case 11: pszSound = "buttons/button11.wav";	break;
		case 12: pszSound = "buttons/latchlocked1.wav";	break;
		case 13: pszSound = "buttons/latchunlocked1.wav";	break;
		case 14: pszSound = "buttons/lightswitch2.wav";break;

		
		case 21: pszSound = "buttons/lever1.wav";	break;
		case 22: pszSound = "buttons/lever2.wav";	break;
		case 23: pszSound = "buttons/lever3.wav";	break;
		case 24: pszSound = "buttons/lever4.wav";	break;
		case 25: pszSound = "buttons/lever5.wav";	break;

		default:pszSound = "buttons/button9.wav";	break;
	}
	return pszSound;
}

void Button_Precache()
{
	precache_sound(self.noise);

	if(self.spawnflags & SF_BUTTON_SPARK_IF_OFF)
	{
		precache_sound("buttons/spark1.wav");
		precache_sound("buttons/spark2.wav");
		precache_sound("buttons/spark3.wav");
		precache_sound("buttons/spark4.wav");
		precache_sound("buttons/spark5.wav");
		precache_sound("buttons/spark6.wav");
	}

	if (self.locked_sound)
	{
		self.noiseLocked = Button_Sound(self.locked_sound);
		precache_sound(self.noiseLocked);
	}
	if (self.unlocked_sound)
	{
		self.noiseUnlocked = Button_Sound(self.unlocked_sound);
		precache_sound(self.noiseUnlocked);
	}

	ResolveLockSentences();
}

void Button_ObjectCaps()
{
	if(self.object_caps & FCAP_ACROSS_TRANSITION)
		self.object_caps = self.object_caps - FCAP_ACROSS_TRANSITION;
	if (!(self.spawnflags & SF_MOMENTARY_DOOR))
		self.object_caps = self.object_caps | FCAP_CONTINUOUS_USE;
	if(!self.takedamage)
		self.object_caps = FCAP_IMPULSE_USE;
}

void Id1Button_Done()
{
	self.state = STATE_BOTTOM;
}

void Id1Button_Return()
{
	self.state = STATE_DOWN;
	SUB_CalcMove(self.pos1, self.speed, Id1Button_Done);
	self.frame = 0;
	if (self.health)
		self.takedamage = DAMAGE_YES;
}

void Id1Button_Wait()
{
	self.state = STATE_TOP;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;

	if (self.wait < 0)
	{
		self.think = SUB_Null;
		self.nextthink = -1;
		return;
	}

	self.nextthink = self.ltime + self.wait;
	self.think = Id1Button_Return;
}

void Id1Button_Blocked()
{
}

void Id1Button_Fire()
{
	if (self.state == STATE_UP || self.state == STATE_TOP)
		return;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
	self.state = STATE_UP;
	SUB_CalcMove(self.pos2, self.speed, Id1Button_Wait);
}

void Id1Button_Use()
{
	self.enemy = activator;
	Id1Button_Fire();
}

void Id1Button_Touch()
{
	if (other.classname != "player")
		return;

	self.enemy = other;
	Id1Button_Fire();
}

void Id1Button_Killed()
{
	self.enemy = damage_attacker;
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	Id1Button_Fire();
}

void Id1Button_Precache()
{
	if (self.sounds == 0)
	{
		precache_sound("buttons/airbut1.wav");
		self.noise = "buttons/airbut1.wav";
	}
	else if (self.sounds == 1)
	{
		precache_sound("buttons/switch21.wav");
		self.noise = "buttons/switch21.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound("buttons/switch02.wav");
		self.noise = "buttons/switch02.wav";
	}
	else if (self.sounds == 3)
	{
		precache_sound("buttons/switch04.wav");
		self.noise = "buttons/switch04.wav";
	}
	else
	{
		precache_sound("buttons/airbut1.wav");
		self.noise = "buttons/airbut1.wav";
	}
}

void Id1Button_Spawn()
{
	Id1Button_Precache();
	SetMovedir();

	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel(self, self.model);

	self.blocked = Id1Button_Blocked;
	self.use = Id1Button_Use;
	self.usehl = __NULL__;

	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = Id1Button_Killed;
		self.takedamage = DAMAGE_YES;
	}
	else
		self.touch = Id1Button_Touch;

	if (!self.speed) self.speed = 40;
	if (!self.wait) self.wait = 1;
	if (!self.lip) self.lip = 4;

	self.state = STATE_BOTTOM;
	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir * (fabs(self.movedir * self.size) - self.lip);
}

void func_button()
{
	if (Map_IsId1BSP())
	{
		Id1Button_Spawn();
		return;
	}

	self.noise = Button_Sound(self.sounds);
	Button_Precache();
	
	if(self.spawnflags & SF_BUTTON_SPARK_IF_OFF)
	{
		self.think = Button_Spark;
		self.nextthink = self.ltime + 0.5;
	}
	
	SetMovedir();

	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel (self, self.model);
	Render_Apply(self);
	if (!self.speed) self.speed = 40;
	if (!self.wait) self.wait = 1;
	if (!self.lip) self.lip = 4;
	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = Button_Killed;
		self.takedamage = DAMAGE_YES;
	}	
	self.state = STATE_BOTTOM;
	self.pos1 = self.origin;
	self.pos2 = self.pos1 + (self.movedir * (fabs(self.movedir.x * (self.size_x - 2)) + fabs(self.movedir_y * (self.size_y - 2)) + fabs(self.movedir_z * (self.size_z - 2)) - self.lip));	// Subtract 2 from size due to engine bbox expansion (1 unit in all directions)
	
	if (vlen(self.pos2 - self.pos1) < 1 || self.spawnflags & SF_BUTTON_DONTMOVE)
		self.pos2 = self.pos1;
		
	self.stayPushed = (self.wait == -1 ? TRUE : FALSE);
	self.rotating = FALSE;
	
	if (self.spawnflags & SF_BUTTON_TOUCH_ONLY)
	{
		self.touch = Button_Touch;
	}
	else self.touch = SUB_Null;
	self.use = Button_Use;
	self.usehl = Button_UseHL;
	Button_ObjectCaps();
};
