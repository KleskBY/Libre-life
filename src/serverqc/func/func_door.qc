
#define SF_DOOR_ROTATE_Y			0
#define	SF_DOOR_START_OPEN			1
#define SF_DOOR_ROTATE_BACKWARDS	2
#define SF_DOOR_PASSABLE			8
#define SF_DOOR_ONEWAY				16
#define	SF_DOOR_NO_AUTO_RETURN		32
#define SF_DOOR_ROTATE_Z			64
#define SF_DOOR_ROTATE_X			128
#define SF_DOOR_USE_ONLY			256
#define SF_DOOR_NOMONSTERS			512
#define SF_DOOR_SILENT				0x80000000

#define Q1_DOOR_START_OPEN			1
#define Q1_DOOR_DONT_LINK			4
#define Q1_DOOR_GOLD_KEY			8
#define Q1_DOOR_SILVER_KEY			16
#define Q1_DOOR_TOGGLE				32

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

	ResolveLockSentences();
}


void Door_SetToggleState(float state)
{
	if (self.classname == "func_door_rotating")
	{
		self.angles = (state == STATE_TOP) ? self.ang2 : self.ang1;
		return;
	}
	if (state == STATE_TOP)
		setorigin(self, self.pos2);
	else
		setorigin(self, self.pos1);
}

void Door_Touch()
{	
	if (other.classname != "player")
		return;

	if (self.master && !Master_IsTriggered(self.master, other))
		PlayLockSounds(TRUE, FALSE);
	
	if (self.targetname)
	{
		PlayLockSounds(TRUE, FALSE);
		return; 
	}
	
	self.enemy = other;

	if (!(self.state == STATE_BOTTOM || (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.state == STATE_TOP)))
		return;

	if (Door_Activate())
		self.touch = SUB_Null;
}


void Door_Blocked()
{
	if (Blocked_IgnorePhantom(other))
		return;

	if (Blocked_DisposeDebris(other))
		return;

	if(self.dmg)
	{
		T_Damage(other, self, self, self.dmg, DMG_CRUSH);
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
							if (pentTarget.classname == "func_door")
							{
								pentTarget.origin = self.origin;
								pentTarget.velocity = '0 0 0';// stop!
							}
							else
							{
								pentTarget.angles = self.angles;
								pentTarget.avelocity = '0 0 0';
							}
						}

						if (!FBitSet(spawnflags, SF_DOOR_SILENT))
							Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);

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

void Door_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	self.enemy = pActivator;
	if (self.state == STATE_BOTTOM || (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.state == STATE_TOP))
		Door_Activate();
}

float Door_Activate()
{
	if (!Master_IsTriggered(self.master, self.enemy))
		return 0;

	if (!(self.state == STATE_BOTTOM || (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.state == STATE_TOP)))
		return 0;
	
	if (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.state == STATE_TOP)
	{
		Door_DoorGoDown();
	}
	else
	{
		if (self.enemy != world && self.enemy.classname == "player")
		{
			T_Heal(self.enemy, self.health, FALSE);
		}
		PlayLockSounds(FALSE, FALSE);
		Door_DoorGoUp();
	}
	return 1;
}


void Door_DoorGoUp( void )
{
	ASSERT(self.state == STATE_BOTTOM || self.state == STATE_DOWN);

	// emit door moving and stop sounds on CHAN_STATIC to prevent client looping issues
	if ( !FBitSet(spawnflags, SF_DOOR_SILENT ) )
	{
		if (self.state != STATE_UP && self.state != STATE_DOWN)
			Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	}

	self.state = STATE_UP;
	
	
	if (self.classname == "func_door_rotating")
	{
		float sign = 1.0;

		if (self.enemy)
		{			
			if (!FBitSet(spawnflags, SF_DOOR_ONEWAY) && self.movedir_y )
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


// Door reached "up" position. Must go down or wait for activation.
void Door_DoorHitTop( void )
{
	if (!FBitSet(spawnflags, SF_DOOR_SILENT))
	{
		// Stop moving sound, then play arrived sound
		Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, "common/null.wav");
		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, self.noiseArrived);
	}

	ASSERT(self.state == STATE_UP);
	self.state = STATE_TOP;

	if (self.globalname != "")
	{
		float logicalOn = !FBitSet(spawnflags, SF_DOOR_START_OPEN);
		GlobalState_EntitySetState(self, logicalOn ? GLOBAL_ON : GLOBAL_OFF);
	}

	if (FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN))
	{
		if (!FBitSet(spawnflags, SF_DOOR_USE_ONLY))
			self.touch = Door_Touch;
	}
	else
	{
		self.nextthink = self.ltime + self.wait;
		self.think = Door_DoorGoDown;

		if (self.wait == -1)
		{
			self.nextthink = -1;
		}
	}

	if (self.netname && (self.spawnflags & SF_DOOR_START_OPEN))
		SUB_FireTargets(self.netname, self.enemy, self, USE_TOGGLE, 0);

	activator = self.enemy;
	SUB_UseTargets();
}


//
//
void Door_DoorGoDown( void )
{
	if (!FBitSet(spawnflags, SF_DOOR_SILENT))
	{
		if (self.state != STATE_UP && self.state != STATE_DOWN)
			Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	}
	
	self.state = STATE_DOWN;

	if (self.classname == "func_door_rotating")
		SUB_CalcAngleMove(self.ang1, self.speed, Door_DoorHitBottom);
	else 
		SUB_CalcMove (self.pos1, self.speed, Door_DoorHitBottom);
}

//
//
void Door_DoorHitBottom( void )
{
	if (!FBitSet(spawnflags, SF_DOOR_SILENT))
	{
		// Stop moving sound, then play arrived sound
		Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, "common/null.wav");
		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, self.noiseArrived);
	}

	self.state = STATE_BOTTOM;

	if (self.globalname != "")
	{
		float logicalOn = FBitSet(spawnflags, SF_DOOR_START_OPEN);
		GlobalState_EntitySetState(self, logicalOn ? GLOBAL_ON : GLOBAL_OFF);
	}

	if (FBitSet(spawnflags, SF_DOOR_USE_ONLY))
	{
		self.touch = SUB_Null;
	}
	else // touchable door
		self.touch = Door_Touch;

	activator = self.enemy;
	SUB_UseTargets();

	if (self.netname && !(self.spawnflags & SF_DOOR_START_OPEN))
		SUB_FireTargets(self.netname, self.enemy, self, USE_TOGGLE, 0);
}

void Door_ObjectCaps()
{
	if (self.object_caps & FCAP_ACROSS_TRANSITION)
		self.object_caps = self.object_caps - FCAP_ACROSS_TRANSITION;
	if (self.spawnflags & SF_ITEM_USE_ONLY)
		self.object_caps = self.object_caps | FCAP_IMPULSE_USE;
	if (self.solid == SOLID_NOT)
		self.flags = self.flags | FL_FINDABLE_NONSOLID;
};

float Door_ApplyGlobalState()
{
	if (self.globalname == "")
	{
		self.state = STATE_BOTTOM;
		return FALSE;
	}

	if (!GlobalState_EntityInTable(self))
	{
		self.state = STATE_BOTTOM;
		return FALSE;
	}

	float gs = GlobalState_EntityGetState(self);
	if (gs == GLOBAL_DEAD)
	{
		remove(self);
		return TRUE;
	}

	float wantTop = (gs == GLOBAL_ON);
	if (FBitSet(spawnflags, SF_DOOR_START_OPEN)) wantTop = !wantTop;

	Door_SetToggleState(wantTop ? STATE_TOP : STATE_BOTTOM);
	self.state = wantTop ? STATE_TOP : STATE_BOTTOM;

	if (wantTop && !FBitSet(spawnflags, SF_DOOR_NO_AUTO_RETURN) && self.wait != -1)
	{
		self.think = Door_DoorGoDown;
		self.nextthink = time + self.wait;
	}

	return FALSE;
}

void Id1Door_GoDown();
void Id1Door_GoUp();
void Id1Door_Use();
void Id1Door_LinkDoors();

float Id1Door_EntitiesTouching(entity e1, entity e2)
{
	if (e1.mins_x > e2.maxs_x) return FALSE;
	if (e1.mins_y > e2.maxs_y) return FALSE;
	if (e1.mins_z > e2.maxs_z) return FALSE;
	if (e1.maxs_x < e2.mins_x) return FALSE;
	if (e1.maxs_y < e2.mins_y) return FALSE;
	if (e1.maxs_z < e2.mins_z) return FALSE;
	return TRUE;
}

void Id1Door_TriggerTouch()
{
	if (other.health <= 0)
		return;

	if (time < self.attack_finished)
		return;
	self.attack_finished = time + 1;

	activator = other;
	self = self.owner;
	Id1Door_Use();
}

entity Id1Door_SpawnField(vector fmins, vector fmaxs)
{
	entity trigger = spawn();
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.owner = self;
	trigger.touch = Id1Door_TriggerTouch;
	setsize(trigger, fmins - '60 60 8', fmaxs + '60 60 8');
	return trigger;
}

void Id1Door_HitBottom()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise1);
	self.state = STATE_BOTTOM;
}

void Id1Door_HitTop()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise1);
	self.state = STATE_TOP;
	if (self.spawnflags & Q1_DOOR_TOGGLE)
		return;
	if (self.wait < 0)
	{
		self.nextthink = -1;
		self.think = SUB_Null;
		return;
	}
	self.think = Id1Door_GoDown;
	self.nextthink = self.ltime + self.wait;
}

void Id1Door_GoDown()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise2);
	if (self.max_health)
	{
		self.takedamage = DAMAGE_YES;
		self.health = self.max_health;
	}

	self.state = STATE_DOWN;
	SUB_CalcMove(self.pos1, self.speed, Id1Door_HitBottom);
}

void Id1Door_GoUp()
{
	if (self.state == STATE_UP)
		return;

	if (self.state == STATE_TOP)
	{
		if (self.wait >= 0)
			self.nextthink = self.ltime + self.wait;
		return;
	}

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise2);
	self.state = STATE_UP;
	SUB_CalcMove(self.pos2, self.speed, Id1Door_HitTop);
	SUB_UseTargets();
}

void Id1Door_Fire()
{
	entity oself;
	entity starte;

	if (self.owner != self)
		objerror("door_fire: self.owner != self");

	if (self.items)
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise4);

	self.message = "";
	oself = self;

	if (self.spawnflags & Q1_DOOR_TOGGLE)
	{
		if (self.state == STATE_UP || self.state == STATE_TOP)
		{
			starte = self;
			do
			{
				Id1Door_GoDown();
				self = self.enemy;
			} while ((self != starte) && (self != world));
			self = oself;
			return;
		}
	}

	starte = self;
	do
	{
		Id1Door_GoUp();
		self = self.enemy;
	} while ((self != starte) && (self != world));
	self = oself;
}

void Id1Door_Use()
{
	entity oself = self;

	self.message = "";
	if (self.owner) self.owner.message = "";
	if (self.enemy) self.enemy.message = "";
	self = self.owner;
	Id1Door_Fire();
	self = oself;
}

void Id1Door_Killed()
{
	entity oself = self;

	self = self.owner;
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;
	Id1Door_Use();
	self = oself;
}

void Id1Door_Block()
{
	T_Damage(other, self, self, self.dmg, DMG_CRUSH);
	if (self.wait >= 0)
	{
		if (self.state == STATE_DOWN)
			Id1Door_GoUp();
		else
			Id1Door_GoDown();
	}
}

void Id1Door_DisableRingTouches(entity master)
{
	entity oself = self;
	self = master;
	entity starte = self;
	do
	{
		self.touch = SUB_Null;
		self = self.enemy;
	} while ((self != starte) && (self != world));
	self = oself;
}

void Id1Door_Touch()
{
	if (other.classname != "player")
		return;
	if (self.owner.attack_finished > time)
		return;

	self.owner.attack_finished = time + 2;

	if (self.owner.message != "")
	{
		centerprint(other, self.owner.message);
		Sound_Play(other, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "misc/talk.wav");
	}

	if (!self.items)
		return;

	if ((self.items & other.items) != self.items)
	{
		if (self.owner.items == IT_KEY1)
		{
			if (world.worldtype == 2)
				centerprint(other, "You need the silver keycard");
			else if (world.worldtype == 1)
				centerprint(other, "You need the silver runekey");
			else
				centerprint(other, "You need the silver key");
		}
		else
		{
			if (world.worldtype == 2)
				centerprint(other, "You need the gold keycard");
			else if (world.worldtype == 1)
				centerprint(other, "You need the gold runekey");
			else
				centerprint(other, "You need the gold key");
		}
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise3);
		return;
	}

	other.items = other.items - self.items;
	Id1Door_DisableRingTouches(self.owner);
	Id1Door_Use();
}

void Id1Door_LinkDoors()
{
	entity t;
	entity starte;
	vector cmins;
	vector cmaxs;

	if (self.enemy)
		return;
	if (self.spawnflags & Q1_DOOR_DONT_LINK)
	{
		self.owner = self;
		self.enemy = self;
		return;
	}

	cmins = self.mins;
	cmaxs = self.maxs;

	starte = self;
	t = self;

	do
	{
		self.owner = starte;

		if (self.health)
			starte.health = self.health;
		if (self.targetname)
			starte.targetname = self.targetname;
		if (self.message != "")
			starte.message = self.message;

		t = find(t, classname, self.classname);
		if (!t)
		{
			self.enemy = starte;
			self = self.owner;

			if (self.health)
				return;
			if (self.targetname)
				return;
			if (self.items)
				return;

			self.trigger_field = Id1Door_SpawnField(cmins, cmaxs);
			return;
		}

		if (Id1Door_EntitiesTouching(self, t))
		{
			if (t.enemy)
				objerror("cross connected doors");

			self.enemy = t;
			self = t;

			if (t.mins_x < cmins_x) cmins_x = t.mins_x;
			if (t.mins_y < cmins_y) cmins_y = t.mins_y;
			if (t.mins_z < cmins_z) cmins_z = t.mins_z;
			if (t.maxs_x > cmaxs_x) cmaxs_x = t.maxs_x;
			if (t.maxs_y > cmaxs_y) cmaxs_y = t.maxs_y;
			if (t.maxs_z > cmaxs_z) cmaxs_z = t.maxs_z;
		}
	} while (1);
}

void Id1Door_Precache()
{
	if (world.worldtype == 1)
	{
		precache_sound("doors/runetry.wav");
		precache_sound("doors/runeuse.wav");
		self.noise3 = "doors/runetry.wav";
		self.noise4 = "doors/runeuse.wav";
	}
	else if (world.worldtype == 2)
	{
		precache_sound("doors/basetry.wav");
		precache_sound("doors/baseuse.wav");
		self.noise3 = "doors/basetry.wav";
		self.noise4 = "doors/baseuse.wav";
	}
	else
	{
		precache_sound("doors/medtry.wav");
		precache_sound("doors/meduse.wav");
		self.noise3 = "doors/medtry.wav";
		self.noise4 = "doors/meduse.wav";
	}

	if (self.sounds == 1)
	{
		precache_sound("doors/drclos4.wav");
		precache_sound("doors/doormv1.wav");
		self.noise1 = "doors/drclos4.wav";
		self.noise2 = "doors/doormv1.wav";
	}
	else if (self.sounds == 2)
	{
		precache_sound("doors/hydro1.wav");
		precache_sound("doors/hydro2.wav");
		self.noise2 = "doors/hydro1.wav";
		self.noise1 = "doors/hydro2.wav";
	}
	else if (self.sounds == 3)
	{
		precache_sound("doors/stndr1.wav");
		precache_sound("doors/stndr2.wav");
		self.noise2 = "doors/stndr1.wav";
		self.noise1 = "doors/stndr2.wav";
	}
	else if (self.sounds == 4)
	{
		precache_sound("doors/ddoor1.wav");
		precache_sound("doors/ddoor2.wav");
		self.noise1 = "doors/ddoor2.wav";
		self.noise2 = "doors/ddoor1.wav";
	}
	else
	{
		precache_sound("misc/null.wav");
		self.noise1 = "misc/null.wav";
		self.noise2 = "misc/null.wav";
	}
}

void Id1Door_Spawn()
{
	Id1Door_Precache();
	SetMovedir();

	self.max_health = self.health;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);

	self.blocked = Id1Door_Block;
	self.use = Id1Door_Use;
	self.usehl = __NULL__;

	if (self.spawnflags & Q1_DOOR_SILVER_KEY)
		self.items = IT_KEY1;
	if (self.spawnflags & Q1_DOOR_GOLD_KEY)
		self.items = IT_KEY2;

	if (!self.speed) self.speed = 100;
	if (!self.wait) self.wait = 3;
	if (!self.lip) self.lip = 8;
	if (!self.dmg) self.dmg = 2;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir * (fabs(self.movedir * self.size) - self.lip);

	if (self.spawnflags & Q1_DOOR_START_OPEN)
	{
		setorigin(self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.state = STATE_BOTTOM;

	if (self.health)
	{
		self.takedamage = DAMAGE_YES;
		self.th_die = Id1Door_Killed;
	}

	if (self.items)
		self.wait = -1;

	self.touch = Id1Door_Touch;
	self.think = Id1Door_LinkDoors;
	self.nextthink = self.ltime + 0.1;
}

void func_door()
{
	if (Map_IsId1BSP())
	{
		Id1Door_Spawn();
		return;
	}

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
		SetBits(spawnflags, SF_DOOR_SILENT);
	}

	self.movetype	= MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);
	Render_Apply(self);
	Brush_ApplyContents(self);	// "skin" content (e.g. skin -3 = water door)

	if (self.speed == 0) self.speed = 100;
	self.pos1	= self.origin;
	self.pos2	= self.pos1 + (self.movedir * (fabs( self.movedir.x * (self.size.x-2) ) + fabs( self.movedir.y * (self.size.y-2) ) + fabs( self.movedir.z * (self.size.z-2) ) - self.lip));
	ASSERTSZ(self.pos1 != self.pos2, "door start/end positions are equal");
	if (FBitSet(spawnflags, SF_DOOR_START_OPEN))
	{
		setorigin(self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	if (Door_ApplyGlobalState()) return;

	if (FBitSet(spawnflags, SF_DOOR_USE_ONLY))
	{
		self.touch = SUB_Null;
	}
	else // touchable button
	{
		self.touch = Door_Touch;
	}
	self.use = Door_Use;
	self.usehl = Door_UseHL;
	self.blocked = Door_Blocked;
	Door_ObjectCaps();
};


void func_door_rotating()
{
	Door_Precache();

	if (self.speed == 0) self.speed = 100;
	if (self.distance == 0) self.distance = 90;	// 90 degree swing

	if (FBitSet(spawnflags, SF_DOOR_ROTATE_Z))
		self.movedir = '0 0 1';
	else if (FBitSet(spawnflags, SF_DOOR_ROTATE_X))
		self.movedir = '1 0 0';
	else
		self.movedir = '0 1 0';		// around y-axis (default)

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
	Render_Apply(self);
	Brush_ApplyContents(self);

// DOOR_START_OPEN allows an entity to be lighted in the closed position but spawn in the open position
	if (FBitSet(spawnflags, SF_DOOR_START_OPEN))
	{
		self.angles = self.ang2;
		vector vecSav = self.ang1;
		self.ang2 = self.ang1;
		self.ang1 = vecSav;
		self.movedir = self.movedir * -1;
	}

	if (Door_ApplyGlobalState()) return;

	if (FBitSet(spawnflags, SF_DOOR_USE_ONLY))
	{
		self.touch = SUB_Null;
	}
	else // touchable button
	{
		self.touch = Door_Touch;
	}

	self.use = Door_Use;
	self.usehl = Door_UseHL;
	self.blocked = Door_Blocked;
	Door_ObjectCaps();
};

void func_water()
{
	if (Map_IsId1BSP())
	{
		Id1Door_Spawn();
		return;
	}

	func_door();
	if (Content_IsLiquid(self.skin))
	{
		if (IsFTE())
			self.touch = SUB_Null;
		else
			self.touch = WaterBrush_Touch;
	}
}
