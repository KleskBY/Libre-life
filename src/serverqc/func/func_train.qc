
#define	SF_TRAIN_WAIT_RETRIGGER	1
#define SF_TRAIN_START_ON		4
#define SF_TRAIN_PASSABLE		8

#define SF_CORNER_WAITFORTRIG	0x001
#define SF_CORNER_TELEPORT		0x002
#define SF_CORNER_FIREONCE		0x004


.float activated;       		// m_activated (bool)
.float train_activate_finished;

// Find next target corner
// Uses self.target (current corner name) to find a corner entity
entity(entity train) Train_GetNextTarget =
{
    if (train.target == "")
        return world;
    return find(world, targetname, train.target);
};

// Sound helpers (STOP_SOUND is engine-specific; we only play stop sound reliably)
void(entity train) Train_PlayStopSound =
{
    if (train.noiseArrived != "")
        Sound_Play(train, CHAN_VOICE, train.volume, ATTN_NORM, PITCH_NORM, train.noiseArrived);
};

void(entity train) Train_PlayMoveSound =
{
    if (train.noiseMoving != "")
        Sound_Play(train, CHAN_VOICE, train.volume, ATTN_NORM, PITCH_NORM, train.noiseMoving);
};

void() Train_Blocked =
{
    if (Blocked_DisposeDebris(other))
        return;

    if (time < self.train_activate_finished)
        return;

    self.train_activate_finished = time + 0.5;

    if (self.dmg > 0)
        T_Damage(other, self, self, self.dmg);
};

// Wait: fires pass target, then either stops (wait-retrigger) or schedules Next()
void() FuncTrain_Next; // forward

void() FuncTrain_Wait =
{
    entity corner = self.goalentity;
    // the NAME of a target to fire when the train passes, not screen text.
    // Fire it directly so SUB_UseTargetsHL's message-centerprint path never
    // treats the fire-on-pass name as a centerprint string.
    if (corner && corner.message != "")
    {
        SUB_FireTargets(corner.message, activator, self, USE_TOGGLE, 0);
        if (corner.spawnflags & SF_CORNER_FIREONCE) corner.message = ""; // fire once?
    }

    // Corner or train requests WAIT_RETRIGGER: stop and wait for Use()
	if ((corner.spawnflags & SF_TRAIN_WAIT_RETRIGGER) || (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER) )
    // if ((corner && (corner.spawnflags & SF_CORNER_WAIT_RETRIGGER)) || (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER))
    {
        self.spawnflags = self.spawnflags | SF_TRAIN_WAIT_RETRIGGER;

        // stop motion

        Train_PlayStopSound(self);
		self.nextthink = 0;
        return;
    }

    // Wait time handling
    if (self.wait != 0)
    {

		self.nextthink = self.ltime + self.wait;
        self.think = FuncTrain_Next;
        Train_PlayStopSound(self);
        return;
    }
	else
	{
		FuncTrain_Next();
	}
};

// Next: advance to next corner and move/teleport to it
void FuncTrain_Next()
{
    vector dest;
    entity pTarg = Train_GetNextTarget(self);
    if (!pTarg)
    {
        // end of path

        Train_PlayStopSound(self);
        return;
    }

    self.message = self.target;

    self.target = pTarg.target;
    self.wait = pTarg.wait;

    // Copy speed from *previous* current target
    if (self.goalentity && self.goalentity.speed != 0)
        self.speed = self.goalentity.speed;

    self.goalentity = pTarg;
    self.enemy = pTarg;
	dest = pTarg.origin - Math_GetCenterOffset(self);
    // Teleport corner?
    if (pTarg.spawnflags & SF_CORNER_TELEPORT)
    {
        setorigin(self, dest);
        FuncTrain_Wait();
        return;
    }

    Train_PlayMoveSound(self);
	SUB_CalcMove(dest, self.speed, FuncTrain_Wait);
}

// Use: toggles "wait retrigger" state
// If waiting: clear flag and move toward target (Next); else: set flag, snap target back to last corner, stop moving immediately
void FuncTrain_Use()
{
    if (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER)
    {
        self.spawnflags = self.spawnflags - (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER);
        FuncTrain_Next();
        return;
    }

    // Enter wait-retrigger mode
    self.spawnflags = self.spawnflags | SF_TRAIN_WAIT_RETRIGGER;

    if (self.enemy)
        self.target = self.enemy.targetname;

    // Stop immediately
    self.nextthink = -1;
    // self.think = SUB_Null;
    self.velocity = '0 0 0';
    self.avelocity = '0 0 0';
    Train_PlayStopSound(self);
}

void FuncTrain_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER)
    {
        self.spawnflags = self.spawnflags - (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER);
        FuncTrain_Next();
        return;
    }

    self.spawnflags = self.spawnflags | SF_TRAIN_WAIT_RETRIGGER;
    if (self.enemy)
        self.target = self.enemy.targetname;

    self.nextthink = -1;
    self.velocity = '0 0 0';
    self.avelocity = '0 0 0';
    Train_PlayStopSound(self);
}

// Activate: first-time initialization (teleport to first corner)
// Happens during Activate()
// In QC we do it via a delayed think from Spawn.
void FuncTrain_Activate()
{
    if (self.activated) return;
    self.activated = TRUE;
	
    entity first = Train_GetNextTarget(self);
    if (!first) return;

    self.target = first.target;
    self.goalentity = first;
    setorigin(self, first.origin - Math_GetCenterOffset(self)); // Teleport to first corner origin - center offset

    if (self.targetname == "")
    {
        self.think = FuncTrain_Next;
        self.nextthink = self.ltime + 0.1;
    }
    else self.spawnflags |= SF_TRAIN_WAIT_RETRIGGER;
   /*
   {
        // triggered trains start in wait-retrigger mode
        self.spawnflags = self.spawnflags | SF_TRAIN_WAIT_RETRIGGER;
        self.think = SUB_Null;
        self.nextthink = -1;
    }
	*/
}


void FuncTrain_Precache()
{
	switch (self.movesnd)
	{
	case	0:
		self.noiseMoving = ("common/null.wav");
		break;
	case	1:
		precache_sound("plats/bigmove1.wav");
		self.noiseMoving = ("plats/bigmove1.wav");
		break;
	case	2:
		precache_sound("plats/bigmove2.wav");
		self.noiseMoving = ("plats/bigmove2.wav");
		break;
	case	3:
		precache_sound("plats/elevmove1.wav");
		self.noiseMoving = ("plats/elevmove1.wav");
		break;
	case	4:
		precache_sound("plats/elevmove2.wav");
		self.noiseMoving = ("plats/elevmove2.wav");
		break;
	case	5:
		precache_sound("plats/elevmove3.wav");
		self.noiseMoving = ("plats/elevmove3.wav");
		break;
	case	6:
		precache_sound("plats/freightmove1.wav");
		self.noiseMoving = ("plats/freightmove1.wav");
		break;
	case	7:
		precache_sound("plats/freightmove2.wav");
		self.noiseMoving = ("plats/freightmove2.wav");
		break;
	case	8:
		precache_sound("plats/heavymove1.wav");
		self.noiseMoving = ("plats/heavymove1.wav");
		break;
	case	9:
		precache_sound("plats/rackmove1.wav");
		self.noiseMoving = ("plats/rackmove1.wav");
		break;
	case	10:
		precache_sound("plats/railmove1.wav");
		self.noiseMoving = ("plats/railmove1.wav");
		break;
	case	11:
		precache_sound("plats/squeekmove1.wav");
		self.noiseMoving = ("plats/squeekmove1.wav");
		break;
	case	12:
		precache_sound("plats/talkmove1.wav");
		self.noiseMoving = ("plats/talkmove1.wav");
		break;
	case	13:
		precache_sound("plats/talkmove2.wav");
		self.noiseMoving = ("plats/talkmove2.wav");
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
		precache_sound("plats/bigstop1.wav");
		self.noiseArrived = ("plats/bigstop1.wav");
		break;
	case	2:
		precache_sound("plats/bigstop2.wav");
		self.noiseArrived = ("plats/bigstop2.wav");
		break;
	case	3:
		precache_sound("plats/freightstop1.wav");
		self.noiseArrived = ("plats/freightstop1.wav");
		break;
	case	4:
		precache_sound("plats/heavystop2.wav");
		self.noiseArrived = ("plats/heavystop2.wav");
		break;
	case	5:
		precache_sound("plats/rackstop1.wav");
		self.noiseArrived = ("plats/rackstop1.wav");
		break;
	case	6:
		precache_sound("plats/railstop1.wav");
		self.noiseArrived = ("plats/railstop1.wav");
		break;
	case	7:
		precache_sound("plats/squeekstop1.wav");
		self.noiseArrived = ("plats/squeekstop1.wav");
		break;
	case	8:
		precache_sound("plats/talkstop1.wav");
		self.noiseArrived = ("plats/talkstop1.wav");
		break;

	default:
		self.noiseArrived = ("common/null.wav");
		break;
	}
}

void Id1Train_Next();
void Id1Train_Find();

void Id1Train_Blocked()
{
	if (time < self.attack_finished)
		return;
	self.attack_finished = time + 0.5;
	T_Damage(other, self, self, self.dmg, DMG_CRUSH);
}

void Id1Train_Use()
{
	if (self.think != Id1Train_Find)
		return;
	Id1Train_Next();
}

void Id1Train_Wait()
{
	if (self.wait)
	{
		self.nextthink = self.ltime + self.wait;
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	}
	else
		self.nextthink = self.ltime + 0.1;

	self.think = Id1Train_Next;
}

void Id1Train_Next()
{
	entity targ = find(world, targetname, self.target);
	if (!targ)
		objerror("train_next: no next target");

	self.target = targ.target;
	if (!self.target)
		objerror("train_next: no next target");

	if (targ.wait)
		self.wait = targ.wait;
	else
		self.wait = 0;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseArrived);
	SUB_CalcMove(targ.origin - self.mins, self.speed, Id1Train_Wait);
}

void Id1Train_Find()
{
	entity targ = find(world, targetname, self.target);
	if (!targ)
		objerror("func_train without a valid target");

	self.target = targ.target;
	setorigin(self, targ.origin - self.mins);

	if (!self.targetname)
	{
		self.nextthink = self.ltime + 0.1;
		self.think = Id1Train_Next;
	}
	else
	{
		self.nextthink = -1;
		self.think = Id1Train_Find;
	}
}

void Id1Train_Precache()
{
	if (self.sounds == 1)
	{
		precache_sound("plats/train2.wav");
		precache_sound("plats/train1.wav");
		self.noiseMoving = "plats/train2.wav";
		self.noiseArrived = "plats/train1.wav";
	}
	else
	{
		precache_sound("misc/null.wav");
		self.noiseMoving = "misc/null.wav";
		self.noiseArrived = "misc/null.wav";
	}
}

void Id1Train_SetupCommon()
{
	if (!self.speed) self.speed = 100;
	if (!self.target) objerror("func_train without a target");
	if (!self.dmg) self.dmg = 2;

	self.cnt = 1;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = Id1Train_Blocked;
	self.use = Id1Train_Use;
	self.usehl = __NULL__;

	self.nextthink = self.ltime + 0.1;
	self.think = Id1Train_Find;
}

void Id1Train_Spawn()
{
	Id1Train_Precache();
	self.solid = SOLID_BSP;
	Id1Train_SetupCommon();
	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
}

void misc_teleporttrain()
{
	if (!Map_IsId1BSP())
	{
		remove(self);
		return;
	}

	self.solid = SOLID_NOT;
	self.avelocity = '100 200 300';
	precache_model2("progs/teleport.mdl");
	setmodel(self, "progs/teleport.mdl");
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
	Id1Train_Precache();
	Id1Train_SetupCommon();
}

void func_train()
{
	if (Map_IsId1BSP())
	{
		Id1Train_Spawn();
		return;
	}

    FuncTrain_Precache();
    if (self.speed == 0) self.speed = 100;
    if (self.target == "")  dprint("FuncTrain with no target\n");
    if (self.dmg == 0) self.dmg = 2;

    self.movetype = MOVETYPE_PUSH;
    if (self.spawnflags & SF_TRAIN_PASSABLE) self.solid = SOLID_NOT;
    else self.solid = SOLID_BSP;

    setmodel(self, self.model);
    setsize(self, self.mins, self.maxs);
    setorigin(self, self.origin);
    Render_Apply(self);
    Brush_ApplyContents(self);	// "skin" content (e.g. skin -3 = water train)
	self.activated = FALSE;
    if (self.volume == 0) self.volume = 0.85;

    self.blocked = Train_Blocked;
    self.use = FuncTrain_Use;
    self.usehl = FuncTrain_UseHL;

    // Start activation after targets spawn
    self.think = FuncTrain_Activate;
    self.nextthink = self.ltime + 0.1;
}
