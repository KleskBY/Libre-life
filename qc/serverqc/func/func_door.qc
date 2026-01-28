
#define SF_DOOR_ROTATE_Y			0
#define	SF_DOOR_START_OPEN			1
#define SF_DOOR_ROTATE_BACKWARDS	2
#define SF_DOOR_PASSABLE			8
#define SF_DOOR_ONEWAY				16
#define	SF_DOOR_NO_AUTO_RETURN		32
#define SF_DOOR_ROTATE_Z			64
#define SF_DOOR_ROTATE_X			128
#define SF_DOOR_USE_ONLY			256	// door must be opened by player's use button.
#define SF_DOOR_NOMONSTERS			512	// Monster can't open
#define SF_DOOR_SILENT				0x80000000

void Door_Touch();
void Door_DoorGoDown();
void Door_DoorGoUp();
void Door_DoorHitBottom();
void Door_DoorHitTop();
float Door_Activate();
void Door_Use();

void Door_Precache()
{
	string pszSound;

// set the door's "in-motion" sound
	switch (self.movesnd)
	{
	case	0:
		self.noiseMoving = ("common/null.wav");
		break;
	case	1:
		precache_sound("doors/doormove1.wav");
		self.noiseMoving = ("doors/doormove1.wav");
		break;
	case	2:
		precache_sound("doors/doormove2.wav");
		self.noiseMoving = ("doors/doormove2.wav");
		break;
	case	3:
		precache_sound("doors/doormove3.wav");
		self.noiseMoving = ("doors/doormove3.wav");
		break;
	case	4:
		precache_sound("doors/doormove4.wav");
		self.noiseMoving = ("doors/doormove4.wav");
		break;
	case	5:
		precache_sound("doors/doormove5.wav");
		self.noiseMoving = ("doors/doormove5.wav");
		break;
	case	6:
		precache_sound("doors/doormove6.wav");
		self.noiseMoving = ("doors/doormove6.wav");
		break;
	case	7:
		precache_sound("doors/doormove7.wav");
		self.noiseMoving = ("doors/doormove7.wav");
		break;
	case	8:
		precache_sound("doors/doormove8.wav");
		self.noiseMoving = ("doors/doormove8.wav");
		break;
	case	9:
		precache_sound("doors/doormove9.wav");
		self.noiseMoving = ("doors/doormove9.wav");
		break;
	case	10:
		precache_sound("doors/doormove10.wav");
		self.noiseMoving = ("doors/doormove10.wav");
		break;
	default:
		self.noiseMoving = ("common/null.wav");
		break;
	}

// set the door's 'reached destination' stop sound
	switch (self.stopsnd)
	{
	case	0:
		self.noiseArrived = ("common/null.wav");
		break;
	case	1:
		precache_sound("doors/doorstop1.wav");
		self.noiseArrived = ("doors/doorstop1.wav");
		break;
	case	2:
		precache_sound("doors/doorstop2.wav");
		self.noiseArrived = ("doors/doorstop2.wav");
		break;
	case	3:
		precache_sound("doors/doorstop3.wav");
		self.noiseArrived = ("doors/doorstop3.wav");
		break;
	case	4:
		precache_sound("doors/doorstop4.wav");
		self.noiseArrived = ("doors/doorstop4.wav");
		break;
	case	5:
		precache_sound("doors/doorstop5.wav");
		self.noiseArrived = ("doors/doorstop5.wav");
		break;
	case	6:
		precache_sound("doors/doorstop6.wav");
		self.noiseArrived = ("doors/doorstop6.wav");
		break;
	case	7:
		precache_sound("doors/doorstop7.wav");
		self.noiseArrived = ("doors/doorstop7.wav");
		break;
	case	8:
		precache_sound("doors/doorstop8.wav");
		self.noiseArrived = ("doors/doorstop8.wav");
		break;
	default:
		self.noiseArrived = ("common/null.wav");
		break;
	}

	// get door button sounds, for doors which are directly 'touched' to open
	if (self.locked_sound)
	{
		pszSound = Button_Sound(self.locked_sound);
		precache_sound(pszSound);
		self.noiseLocked = pszSound;
	}

	if (self.unlocked_sound)
	{
		pszSound = Button_Sound(self.unlocked_sound);
		precache_sound(pszSound);
		self.noiseUnlocked = pszSound;
	}

	/*
	// get sentence group names, for doors which are directly 'touched' to open
	switch (m_bLockedSentence)
	{
		case 1: m_ls.sLockedSentence = ("NA"); break; // access denied
		case 2: m_ls.sLockedSentence = ("ND"); break; // security lockout
		case 3: m_ls.sLockedSentence = ("NF"); break; // blast door
		case 4: m_ls.sLockedSentence = ("NFIRE"); break; // fire door
		case 5: m_ls.sLockedSentence = ("NCHEM"); break; // chemical door
		case 6: m_ls.sLockedSentence = ("NRAD"); break; // radiation door
		case 7: m_ls.sLockedSentence = ("NCON"); break; // gen containment
		case 8: m_ls.sLockedSentence = ("NH"); break; // maintenance door
		case 9: m_ls.sLockedSentence = ("NG"); break; // broken door
		
		default: m_ls.sLockedSentence = 0; break;
	}

	switch (m_bUnlockedSentence)
	{
		case 1: m_ls.sUnlockedSentence = ("EA"); break; // access granted
		case 2: m_ls.sUnlockedSentence = ("ED"); break; // security door
		case 3: m_ls.sUnlockedSentence = ("EF"); break; // blast door
		case 4: m_ls.sUnlockedSentence = ("EFIRE"); break; // fire door
		case 5: m_ls.sUnlockedSentence = ("ECHEM"); break; // chemical door
		case 6: m_ls.sUnlockedSentence = ("ERAD"); break; // radiation door
		case 7: m_ls.sUnlockedSentence = ("ECON"); break; // gen containment
		case 8: m_ls.sUnlockedSentence = ("EH"); break; // maintenance door
		
		default: m_ls.sUnlockedSentence = 0; break;
	}
	*/
}





void Door_SetToggleState(float state)
{
	if (state == STATE_TOP)
		setorigin(self, self.pos2);
	else
		setorigin(self, self.pos1);
}

void Door_Touch()
{	
	// Ignore touches by anything but players
	if (other.classname != "player")
		return;

	// If door has master, and it's not ready to trigger, 
	// play 'locked' sound
	if (self.master && !UTIL_IsMasterTriggered(self.master, other))
		PlayLockSounds(TRUE, FALSE);
	
	// If door is somebody's target, then touching does nothing.
	// You have to activate the owner (e.g. button).
	
	if (self.targetname)
	{
		// play locked sound
		PlayLockSounds(TRUE, FALSE);
		return; 
	}
	
	self.enemy = other;// remember who activated the door

	if (Door_Activate())
		self.touch = SUB_Null; // Temporarily disable the touch function, until movement is finished.
}


void Door_Blocked()
{
	if(self.dmg) 
	{	
		T_Damage(other, self, self, self.dmg);
		return;
	}
	
	if (self.wait >= 0)
	{
		if (self.state == STATE_DOWN)
		{
			Door_DoorGoUp();
		}
		else
		{
			Door_DoorGoDown();
		}
	}
		
	// Block all door pieces with the same targetname here.
	if (self.targetname)
	{
		entity pentTarget = find(world, targetname, self.targetname);
		while(pentTarget)
		{
			if (pentTarget != self )
			{
				if (!pentTarget) break;

				if (pentTarget.classname == "func_door" || pentTarget.classname == "func_door_rotating")
				{
					if (pentTarget.wait >= 0)
					{
						if (pentTarget.velocity == self.velocity && pentTarget.avelocity == self.velocity)
						{
							// this is the most hacked, evil, bastardized thing I've ever seen. kjb
							if (pentTarget.classname == "func_door")
							{// set origin to realign normal doors
								pentTarget.origin = self.origin;
								pentTarget.velocity = '0 0 0';// stop!
							}
							else
							{// set angles to realign rotating doors
								pentTarget.angles = self.angles;
								pentTarget.avelocity = '0 0 0';
							}
						}

						if (!FBitSet(spawnflags, SF_DOOR_SILENT))
							sound(self, CHAN_STATIC, self.noiseMoving, 1, ATTN_NORM);

						entity oldself = self;
						self = pentTarget;
						if (pentTarget.state == STATE_DOWN)
							Door_DoorGoUp();
						else
							Door_DoorGoDown();
						self = oldself;
					}
				}
			}
			pentTarget = find(pentTarget, targetname, self.targetname);
		}
	}
	
};

void Door_Use()
{
	self.enemy = activator;
	if(self.state == STATE_BOTTOM || (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.state == STATE_TOP))
		Door_Activate();
}

float Door_Activate()
{
	if (!UTIL_IsMasterTriggered(self.master, self.enemy))
		return 0;

	
	if (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.state == STATE_TOP) // door should close
	{
		Door_DoorGoDown();
	}
	else // door should open
	{
		// give health if player opened the door (medikit)
		if (self.enemy != world && self.enemy.classname == "player")
		{
			// VARS( m_eoActivator )->health += m_bHealthValue;
			T_Heal(self.enemy, self.health, FALSE); //m_hActivator->TakeHealth( m_bHealthValue, DMG_GENERIC );
		}
		// play door unlock sounds
		PlayLockSounds(FALSE, FALSE);
		Door_DoorGoUp();
	}
	return 1;
}


void Door_DoorGoUp( void )
{
	// It could be going-down, if blocked.
	ASSERT(self.state == STATE_BOTTOM || self.state == STATE_DOWN);

	// emit door moving and stop sounds on CHAN_STATIC so that the multicast doesn't
	// filter them out and leave a client stuck with looping door sounds!
	if ( !FBitSet(spawnflags, SF_DOOR_SILENT ) )
	{
		if (self.state != STATE_UP && self.state != STATE_DOWN)
			sound(self, CHAN_STATIC, self.noiseMoving, 1, ATTN_NORM);
	}

	self.state = STATE_UP;
	
	

	//SetMoveDone(&Door_DoorHitTop);
	if (self.classname == "func_door_rotating")		// !!! BUGBUG Triggered doors don't work with this yet
	{
		float sign = 1.0;

		if (self.enemy)
		{			
			if (!FBitSet(spawnflags, SF_DOOR_ONEWAY) && self.movedir_y ) 		// Y axis rotation, move away from the player
			{
				vector vec = self.enemy.origin - self.origin;
				vector ang = self.enemy.angles;
				ang.x = 0;
				ang.z = 0;
				makevectors(ang);
				makevectors(self.enemy.angles);
				vector vnext = (self.enemy.origin + v_forward * 10) - self.origin;
				if ((vec_x * vnext_y - vec_y * vnext_x) < 0)
					sign = -1.0;
			}
		}
		SUB_CalcAngleMove(self.ang2 * sign, self.speed, Door_DoorHitTop);
		//AngularMove(m_vecAngle2 * sign, self.speed);
	}
	else SUB_CalcMove (self.pos2, self.speed, Door_DoorHitTop); //LinearMove(self.pos2, self.speed);

}


//
// The door has reached the "up" position.  Either go back down, or wait for another activation.
//
void Door_DoorHitTop( void )
{
	if (!FBitSet(spawnflags, SF_DOOR_SILENT))
	{
		//STOP_SOUND(ENT(pev), CHAN_STATIC, self.noiseMoving);
		sound(self, CHAN_STATIC, self.noiseArrived, 1, ATTN_NORM);
	}

	ASSERT(self.state == STATE_UP);
	self.state = STATE_TOP;
	
	// toggle-doors don't come down automatically, they wait for refire.
	if (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN))
	{
		// Re-instate touch method, movement is complete
		if (!FBitSet(spawnflags, SF_DOOR_USE_ONLY))
			self.touch = Door_Touch;
	}
	else
	{
		// In flWait seconds, DoorGoDown will fire, unless wait is -1, then door stays open
		self.nextthink = self.ltime + self.wait;
		self.think = Door_DoorGoDown;

		if (self.wait == -1)
		{
			self.nextthink = -1;
		}
	}

	// Fire the close target (if startopen is set, then "top" is closed) - netname is the close target
	// if (self.netname && (self.spawnflags & SF_DOOR_START_OPEN))
		// FireTargets(STRING(self.netname), m_hActivator, this, USE_TOGGLE, 0 );

	// SUB_UseTargets( m_hActivator, USE_TOGGLE, 0 ); // this isn't finished
	
	activator = self.enemy;	
	SUB_UseTargets();
}


//
// Starts the door going to its "down" position (simply ToggleData->vecPosition1).
//
void Door_DoorGoDown( void )
{
	if (!FBitSet(spawnflags, SF_DOOR_SILENT))
	{
		if (self.state != STATE_UP && self.state != STATE_DOWN)
			sound(self, CHAN_STATIC, self.noiseMoving, 1, ATTN_NORM);
	}
	
	ASSERT(self.state == STATE_TOP);
	self.state = STATE_DOWN;

	if (self.classname == "func_door_rotating")
		SUB_CalcAngleMove(self.ang1, self.speed, Door_DoorHitBottom);
	else 
		SUB_CalcMove (self.pos1, self.speed, Door_DoorHitBottom);
}

//
// The door has reached the "down" position.  Back to quiescence.
//
void Door_DoorHitBottom( void )
{
	if (!FBitSet(spawnflags, SF_DOOR_SILENT))
	{
		sound(self, CHAN_STATIC, self.noiseArrived, 1, ATTN_NORM);
	}

	ASSERT(self.state == STATE_DOWN);
	self.state = STATE_BOTTOM;

	// Re-instate touch method, cycle is complete
	if (FBitSet(spawnflags, SF_DOOR_USE_ONLY))// use only door
	{
		self.touch = SUB_Null;
	}
	else // touchable door
		self.touch = Door_Touch;

	activator = self.enemy;	
	SUB_UseTargets();
	// SUB_UseTargets( m_hActivator, USE_TOGGLE, 0 ); // this isn't finished
	
	// Fire the close target (if startopen is set, then "top" is closed) - netname is the close target
	// if ( self.netname && !(self.spawnflags & SF_DOOR_START_OPEN) )
		// FireTargets( STRING(self.netname), m_hActivator, this, USE_TOGGLE, 0 );
}

void Door_ObjectCaps()
{
	if(self.object_caps & FCAP_ACROSS_TRANSITION)
		self.object_caps = self.object_caps - FCAP_ACROSS_TRANSITION;
	if (self.spawnflags & SF_ITEM_USE_ONLY)
		self.object_caps = self.object_caps | FCAP_IMPULSE_USE;
};

void func_door()
{
	Door_Precache();
	SetMovedir();
	
	if (self.skin == 0) //normal door
	{
		if (self.spawnflags & SF_DOOR_PASSABLE)
			self.solid		= SOLID_NOT;
		else
			self.solid		= SOLID_BSP;
	}
	else // special contents
	{
		self.solid		= SOLID_NOT;
		// if(!(self.spawnflags & SF_DOOR_SILENT)) self.spawnflags = self.spawnflags | SF_DOOR_SILENT;
		SetBits(spawnflags, SF_DOOR_SILENT);	// water is silent for now
	}

	self.movetype	= MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);
	if (self.speed == 0) self.speed = 100;

	self.pos1	= self.origin;
	// Subtract 2 from size because the engine expands bboxes by 1 in all directions making the size too big
	self.pos2	= self.pos1 + (self.movedir * (fabs( self.movedir.x * (self.size.x-2) ) + fabs( self.movedir.y * (self.size.y-2) ) + fabs( self.movedir.z * (self.size.z-2) ) - self.lip));
	ASSERTSZ(self.pos1 != self.pos2, "door start/end positions are equal");
	if (FBitSet(spawnflags, SF_DOOR_START_OPEN)) // swap pos1 and pos2, put door at pos2
	{	
		setorigin(self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.state = STATE_BOTTOM;

	// if the door is flagged for USE button activation only, use NULL touch function
	if (FBitSet(spawnflags, SF_DOOR_USE_ONLY))
	{
		self.touch = SUB_Null;
		// self.usable = TRUE;
	}
	else // touchable button
	{
		self.touch = Door_Touch;
		// if(!self.targetname) self.usable = TRUE;
		// else self.usable = FALSE;
	}
	self.use = Door_Use;
	self.blocked = Door_Blocked;
	Door_ObjectCaps();
};


void func_door_rotating()
{
	Door_Precache();
	if (FBitSet(spawnflags, SF_DOOR_ROTATE_Z))
		self.movedir = '0 0 1';	// around z-axis
	else if (FBitSet(spawnflags, SF_DOOR_ROTATE_X))
		self.movedir = '1 0 0';	// around x-axis
	else
		self.movedir = '0 1 0';// around y-axis
		
	if (FBitSet(spawnflags, SF_DOOR_ROTATE_BACKWARDS))
		self.movedir = self.movedir * -1;
		
	self.ang1 = self.angles;
	self.ang2 = self.angles + self.movedir * self.distance;

	ASSERTSZ(self.ang1 != self.ang2, "rotating door start/end positions are equal");
	
	if (FBitSet(spawnflags, SF_DOOR_PASSABLE))
		self.solid		= SOLID_NOT;
	else
		self.solid		= SOLID_BSP;

	self.movetype	= MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);

	if (self.speed == 0) self.speed = 100;
	
// DOOR_START_OPEN is to allow an entity to be lighted in the closed position
// but spawn in the open position
	if (FBitSet(spawnflags, SF_DOOR_START_OPEN))
	{	// swap pos1 and pos2, put door at pos2, invert movement direction
		self.angles = self.ang2;
		vector vecSav = self.ang1;
		self.ang2 = self.ang1;
		self.ang1 = vecSav;
		self.movedir = self.movedir * -1;
	}

	self.state = STATE_BOTTOM;

	// if the door is flagged for USE button activation only, use NULL touch function
	if (FBitSet(spawnflags, SF_DOOR_USE_ONLY))
	{
		self.touch = SUB_Null;
		// self.usable = TRUE;
	}
	else // touchable button
	{
		self.touch = Door_Touch;
		// if(!self.targetname) self.usable = TRUE;
		// else self.usable = FALSE;
	}
		
	self.use = Door_Use;
	self.blocked = Door_Blocked;
	Door_ObjectCaps();
};

void func_water()
{
	func_door();
}