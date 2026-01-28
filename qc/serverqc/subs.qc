
void() SUB_Null = {};
void(entity attacker, float damage) SUB_null_pain = {};
void SUB_Remove() = { remove(self); };

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void SUB_CalcMoveEnt(entity ent, vector tdest, float tspeed, void() func)
{
	entity stemp = self;
	self = ent;
	SUB_CalcMove(tdest, tspeed, func);
	self = stemp;
}

void SUB_CalcMoveDone()
{
	setorigin(self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1) self.think1();
};


void SUB_CalcMove(vector tdest, float tspeed, void() func)
{
	if (!tspeed) objerror("No speed is defined!");
	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;
	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	vector vdestdelta = tdest - self.origin; // set destdelta to the vector needed to move
	float traveltime = vlen(vdestdelta) / tspeed; // divide by speed to get time to reach dest
	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}

	self.nextthink = self.ltime + traveltime; // set nextthink to trigger a think when dest is reached
	self.velocity = vdestdelta * (1 / traveltime); // scale the destdelta vector by the time spent traveling to get velocity
};

/*
============
After moving, set origin to exact final destination
============
*/


/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating

The calling function should make sure self.think is valid
===============
*/

//After rotating, set angle to exact final angle
void SUB_CalcAngleMoveDone()
{
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1) self.think1();
};

void SUB_CalcAngleMove(vector destangle, float tspeed, void() func)
{
	if (!tspeed) objerror("No speed is defined!");
	vector destdelta = destangle - self.angles; 	// set destdelta to the vector needed to move
	float len = vlen(destdelta); 					// calculate length ofvector
	float traveltime = len / tspeed; 				// divide by speed to get time to reach dest
	self.nextthink = self.ltime + traveltime; 		// set nextthink to trigger a think when dest is reached
	self.avelocity = destdelta * (1 / traveltime);	// scale the destdelta vector by the time spent traveling to get velocity

	self.think1 = func;
	self.finalangle = destangle;
	self.think = SUB_CalcAngleMoveDone;
};

/*
============
============
*/



//=============================================================================

void DelayThink()
{
	activator = self.enemy;
	SUB_UseTargets();
	remove(self);
};

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for(string)targetname in all entities that
match(string)self.target and call their .use function

==============================
*/
void() SUB_UseTargets =
{
	local entity t;
	local entity stemp;
	local entity otemp;
	local entity act;

	// -------------------------------------------------------------------------
	// Delay support
	// -------------------------------------------------------------------------
	if (self.delay)
	{
		t = spawn();
		t.classname   = "DelayedUse";
		t.nextthink   = time + self.delay;
		t.think       = DelayThink;

		t.enemy       = activator;
		t.message     = self.message;
		t.killtarget  = self.killtarget;
		t.target      = self.target;
		return;
	}

	// -------------------------------------------------------------------------
	// Message to player activator
	// -------------------------------------------------------------------------
	if (activator.classname == "player" && self.message != "")
	{
		centerprint(activator, self.message);

		if (!self.noise)
			sound(activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM);
	}

	// -------------------------------------------------------------------------
	// Kill targets (per spec: do this when we run, not only after firing targets)
	// -------------------------------------------------------------------------
	if (self.killtarget)
	{
		t = world;
		while (1)
		{
			t = find(t, targetname, self.killtarget);
			if (!t)
				break;

			remove(t);
		}
	}

	// -------------------------------------------------------------------------
	// Fire targets
	// -------------------------------------------------------------------------
	if (!self.target)
		return;

	act = activator;
	t = world;

	while (1)
	{
		t = find(t, targetname, self.target);
		if (!t) break;

		stemp = self;
		otemp = other;

		self  = t;
		other = stemp;

		if (self.use)
			self.use();

		self      = stemp;
		other     = otemp;
		activator = act;
	}
};
void() SUB_UseTargets2 =
{
	entity t;
	if (self.delay) // create a temp object to fire at a later time
	{
		t = spawn();
		t.classname = "DelayedUse";
		t.nextthink = time + self.delay;
		t.think = DelayThink;
		t.enemy = activator;
		t.message = self.message;
		t.killtarget = self.killtarget;
		t.target = self.target;
		return;
	}
	
	if (activator.classname == "player" && self.message != "")
	{
		centerprint (activator, self.message);
		if (!self.noise) sound (activator, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM);
	}

	if (self.target) // fire targets
	{
		entity act = activator;
		t = world;
		do
		{
			t = find (t, targetname, self.target);
			if (!t)
			{
				if (self.killtarget) // kill the killtagets
				{
					t = world;
					do
					{
						t = find (t, targetname, self.killtarget);
						if (!t) return;
						remove (t);
					} 
					while ( 1 );
				}
				return;
			}
			entity stemp = self;
			entity otemp = other;
			self = t;
			other = stemp;
			if (self.use) self.use();
			self = stemp;
			other = otemp;
			activator = act;
		} 
		while (TRUE);
	}
	

};


void() SetMovedir =
{
	if (self.angles == '0 -1 0') self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0') self.movedir = '0 0 -1';
	else
	{
		makevectors(self.angles);
		self.movedir = v_forward;
	}
	self.angles = '0 0 0';
};

void() InitTrigger =
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.angles != '0 0 0') SetMovedir();
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	setmodel(self, self.model); // set size and link into world
	self.modelindex = 0;
	self.model = "";
};


float IsAlive(entity e)
{
	if(e.health > 0 && !e.deadflag) return TRUE;
	return FALSE;
};

float IsDeathmatch()
{
	if(deathmatch) return TRUE;
	if(cvar("gamemode") == MODE_DM) return TRUE;
	return FALSE;
}

float IsMultiplayer()
{
	if(deathmatch) return TRUE;
	if(cvar("gamemode") != MODE_SP) return TRUE;
	return FALSE;
}


#define USE_OFF		0
#define USE_ON		1
#define USE_SET		2
#define USE_TOGGLE	3 

float ShouldToggle(float useType, float currentState)
{
	if (useType != USE_TOGGLE && useType != USE_SET)
	{
		if ((currentState && useType == USE_ON) || (!currentState && useType == USE_OFF))
			return 0;
	}
	return 1;
}

float UTIL_Approach( float t, float value, float speed )
{
	float delta = t - value;

	if ( delta > speed )
		value += speed;
	else if ( delta < -speed )
		value -= speed;
	else 
		value = t;

	return value;
}


void SetBits(.float variable, float fl)
{
	if(!(self.variable & fl)) self.variable = self.variable | fl;
}

float FBitSet(.float variable, float fl)
{
	if(self.variable & fl) return TRUE;
	return FALSE;
}

float MultiSource_IsTriggered(entity ms, entity ac);
float UTIL_IsMasterTriggered(string sMaster, entity pActivator)
{
	if (sMaster)
	{
		// edict_t *pentTarget = FIND_ENTITY_BY_TARGETNAME(NULL, STRING(sMaster));
		entity pMaster = find(world, targetname, sMaster);
		if (pMaster)
		{
			return MultiSource_IsTriggered(pMaster, pActivator);
			// if ( pMaster && (pMaster->ObjectCaps() & FCAP_MASTER) )
				// return pMaster->IsTriggered( pActivator );
		}
		dprint("Master was null or not a master!\n");
		// ALERT(at_console, "Master was null or not a master!\n");
	}

	// if this isn't a master entity, just say yes.
	return 1;
}


void PrintMessage(entity c, string msg)
{
	
	centerprint(c, msg);
}

void PlayCDTrack(float track_num)
{
	WriteByte(MSG_ALL, SVC_CDTRACK);
	WriteByte(MSG_ALL, track_num);
	WriteByte(MSG_ALL, track_num);
}


void UTIL_ShowMessageAll(string s)
{
	bprint(s);
	bprint("\n");

}

void UTIL_ShowMessage(string s, entity p)
{
	sprint(p, s);
	sprint(p, "\n");
}


float PackButtons()
{
	float btn;
	if(self.button0) btn = btn | 1;
	if(self.button1) btn = btn | 2;
	if(self.button2) btn = btn | 4;
	if(self.button3) btn = btn | 8;
	if(self.button4) btn = btn | 16;
	if(self.button5) btn = btn | 32;
	if(self.button6) btn = btn | 64;
	if(self.button7) btn = btn | 128;
	if(self.button8) btn = btn | 256;
	if(self.button9) btn = btn | 512;
	if(self.button10) btn = btn | 1024;
	if(self.button11) btn = btn | 2048;
	if(self.button12) btn = btn | 4096;
	if(self.button13) btn = btn | 8192;
	if(self.button14) btn = btn | 16384;
	if(self.button15) btn = btn | 32768;
	if(self.use) btn = btn | 65536;
	return btn;
}