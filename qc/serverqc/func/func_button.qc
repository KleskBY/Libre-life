
#define SF_BUTTON_DONTMOVE		1
#define SF_ROTBUTTON_NOTSOLID	1
#define	SF_BUTTON_TOGGLE		32	// button stays pushed until reactivated
#define	SF_BUTTON_SPARK_IF_OFF	64	// button sparks in OFF state
#define SF_BUTTON_TOUCH_ONLY	256	// button only fires as a result of USE key.

#define BUTTON_CODE_NOTHING 	0
#define BUTTON_CODE_ACTIVATE 	1
#define BUTTON_CODE_RETURN		2

void Button_Wait();
void Button_Return();
void Button_Activate();
void Button_TriggerAndWait();
void Button_BackHome();

.string master;
.float stayPushed;
.float rotating;

.string noiseLocked;
.string noiseUnlocked;

.vector ang1;
.vector ang2;

.float waitSound;
void PlayLockSounds(float flocked, float fbutton)
{
	if(self.waitSound > time) return;
	self.waitSound = time + 1;
	if(flocked) sound(self, CHAN_ITEM, self.noiseLocked, 1, ATTN_NORM);
	else sound(self, CHAN_ITEM, self.noiseUnlocked, 1, ATTN_NORM);
	/*
	float flsoundwait;
	// if (fbutton) flsoundwait = BUTTON_SOUNDWAIT;
	// else flsoundwait = DOOR_SOUNDWAIT;

	if (flocked)
	{
		float fplaysound = (self.lockedNoise && time > pls->flwaitSound);
		float fplaysentence = (pls->sLockedSentence && !pls->bEOFLocked && time > pls->flwaitSentence);
		float fvol;

		if (fplaysound && fplaysentence) fvol = 0.25;
		else fvol = 1.0;

		// if there is a locked sound, and we've debounced, play sound
		if (fplaysound)
		{
			// play 'door locked' sound
			sound(self, CHAN_ITEM, self.lockedNoise, fvol, ATTN_NORM);
			pls->flwaitSound = time + flsoundwait;
		}

		// if there is a sentence, we've not played all in list, and we've debounced, play sound
		if (fplaysentence)
		{
			// play next 'door locked' sentence in group
			float iprev = pls->iLockedSentence;
			
			pls->iLockedSentence = SENTENCEG_PlaySequentialSz(ENT(pev), STRING(pls->sLockedSentence), 0.85, ATTN_NORM, 0, 100, pls->iLockedSentence, FALSE);
			pls->iUnlockedSentence = 0;

			// make sure we don't keep calling last sentence in list
			pls->bEOFLocked = (iprev == pls->iLockedSentence);
			pls->flwaitSentence = time + DOOR_SENTENCEWAIT;
		}
	}
	else
	{
		// UNLOCKED SOUND

		float fplaysound = (pls->sUnlockedSound && time > pls->flwaitSound);
		float fplaysentence = (pls->sUnlockedSentence && !pls->bEOFUnlocked && time > pls->flwaitSentence);
		float fvol;

		// if playing both sentence and sound, lower sound volume so we hear sentence
		if (fplaysound && fplaysentence) fvol = 0.25;
		else fvol = 1.0;

		// play 'door unlocked' sound if set
		if (fplaysound)
		{
			sound(self, CHAN_ITEM, pls->sUnlockedSound), fvol, ATTN_NORM);
			pls->flwaitSound = time + flsoundwait;
		}

		// play next 'door unlocked' sentence in group
		if (fplaysentence)
		{
			float iprev = pls->iUnlockedSentence;
			
			pls->iUnlockedSentence = SENTENCEG_PlaySequentialSz(ENT(pev), STRING(pls->sUnlockedSentence), 0.85, ATTN_NORM, 0, 100, pls->iUnlockedSentence, FALSE);
			pls->iLockedSentence = 0;

			// make sure we don't keep calling last sentence in list
			pls->bEOFUnlocked = (iprev == pls->iUnlockedSentence);
			pls->flwaitSentence = time + DOOR_SENTENCEWAIT;
		}
	}
	*/
}

void Button_Wait()
{
	self.state = STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = Button_Return;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;	// use alternate textures
};

void DoSpark(vector location)
{
	vector tmp = location + self.size * 0.5;
	te_spike(tmp);
	float vol = random(0.25, 0.75) * 0.4;//random volume range
	float rsnd = RandomInt(1, 6);
	string file = strcat("buttons/spark", ftos(rsnd), ".wav");
	sound(self, CHAN_VOICE, file, vol, ATTN_NORM);
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
			sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
			Button_Return();
		}
	}
	else 
		Button_Activate();
};

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
	if (!UTIL_IsMasterTriggered(self.master, other))
	{
		// play button locked sound
		PlayLockSounds(TRUE, TRUE);
		return;
	}
	
	self.touch = SUB_Null;
	if(code == BUTTON_CODE_RETURN)
	{
		sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
		SUB_UseTargets();
		Button_Return();
	}
	else Button_Activate();
}

void Button_Activate()
{
	sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	
	if (!UTIL_IsMasterTriggered(self.master, self.enemy/*self.activator*/))
	{
		// button is locked, play locked sound
		PlayLockSounds(TRUE, TRUE);
		return;
	}
	else
	{
		// button is unlocked, play unlocked sound
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
	
	if (!UTIL_IsMasterTriggered(self.master, self.enemy))
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

	if (self.spawnflags & SF_BUTTON_TOGGLE)
	{		
		SUB_UseTargets();
	}


	if (self.target)
	{
		entity pentTarget = find(world, targetname, self.target);
		while(pentTarget)
		{
			if(pentTarget.classname == "multisource")
			{
				if(pentTarget.use)
				{
					entity stemp = self;
					entity otemp = other;
					self = pentTarget;
					other = stemp;
					if (self.use) self.use();
					self = stemp;
					other = otemp;
				}
			}
			pentTarget = find(pentTarget, targetname, self.target);
		}
	}


// Re-instate touch method, movement cycle is complete.
	if (self.spawnflags & SF_BUTTON_TOUCH_ONLY) // this button only works if USED, not touched!
	{
		self.touch = Button_Touch;
	}
	else self.touch = SUB_Null;

// reset think for a sparking button
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

// next 6 slots reserved for any additional sliding button sounds we may add
		
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
	if(self.spawnflags & SF_BUTTON_SPARK_IF_OFF)
	{
		precache_sound("buttons/spark1.wav");
		precache_sound("buttons/spark2.wav");
		precache_sound("buttons/spark3.wav");
		precache_sound("buttons/spark4.wav");
		precache_sound("buttons/spark5.wav");
		precache_sound("buttons/spark6.wav");
	}
	if (self.sounds == 1) precache_sound("func/button1.wav");
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

void func_button()
{
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
	if (!self.speed) self.speed = 40;
	if (!self.wait) self.wait = 1;
	if (!self.lip) self.lip = 4;
	if (self.health)
	{
		self.max_health = self.health;
		// self.th_die = button_killed;
		self.takedamage = DAMAGE_YES;
	}	
	self.state = STATE_BOTTOM;
	self.pos1 = self.origin;
	self.pos2 = self.pos1 + (self.movedir * (fabs(self.movedir.x * (self.size_x - 2)) + fabs(self.movedir_y * (self.size_y - 2)) + fabs(self.movedir_z * (self.size_z - 2)) - self.lip)); // Subtract 2 from size because the engine expands bboxes by 1 in all directions making the size too big
	// self.pos2 = self.pos1 + (self.movedir * self.lip); //self.origin;
	
	if (vlen(self.pos2 - self.pos1) < 1 || self.spawnflags & SF_BUTTON_DONTMOVE)
		self.pos2 = self.pos1;
		
	self.stayPushed = (self.wait == -1 ? TRUE : FALSE);
	self.rotating = FALSE;
	
	if (self.spawnflags & SF_BUTTON_TOUCH_ONLY) // this button only works if USED, not touched!
	{
		self.touch = Button_Touch;
	}
	else self.touch = SUB_Null;
	self.use = Button_Use;	
	//self.blocked = button_blocked;
	Button_ObjectCaps();
};
