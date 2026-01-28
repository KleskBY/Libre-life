
#define	SF_TRAIN_WAIT_RETRIGGER	1
#define SF_TRAIN_START_ON		4		// Train is initially moving
#define SF_TRAIN_PASSABLE		8		// Train is not solid -- used to make water trains

#define SF_CORNER_WAITFORTRIG	0x001
#define SF_CORNER_TELEPORT		0x002
#define SF_CORNER_FIREONCE		0x004


.float activated;       		// m_activated (bool)
.float train_activate_finished;	// m_flActivateFinished (time gate for Blocked)

// -----------------------------------------------------------------------------
// Find next target corner (HL GetNextTarget)
// In HL: uses self.target (current corner name) to find a corner entity.
// -----------------------------------------------------------------------------
entity(entity train) Train_GetNextTarget =
{
    if (train.target == "")
        return world;
    return find(world, targetname, train.target);
};

// -----------------------------------------------------------------------------
// Sound helpers (STOP_SOUND is engine-specific; we only play stop sound reliably)
// -----------------------------------------------------------------------------
void(entity train) Train_PlayStopSound =
{
    if (train.noiseArrived != "")
        sound(train, CHAN_VOICE, train.noiseArrived, train.volume, ATTN_NORM);
};

void(entity train) Train_PlayMoveSound =
{
    if (train.noiseMoving != "")
        sound(train, CHAN_VOICE, train.noiseMoving, train.volume, ATTN_NORM);
};

// -----------------------------------------------------------------------------
// Blocked: damage once per 0.5s (HL m_flActivateFinished gate)
// -----------------------------------------------------------------------------
void() train_blocked =
{
    if (time < self.train_activate_finished)
        return;

    self.train_activate_finished = time + 0.5;

    if (self.dmg > 0)
        T_Damage(other, self, self, self.dmg);
};

// -----------------------------------------------------------------------------
// Wait: fires pass target, then either stops (wait-retrigger) or schedules Next()
// -----------------------------------------------------------------------------
void() FuncTrain_Next; // forward

void() FuncTrain_Wait =
{
    entity corner = self.goalentity;
    // Fire pass target if present (corner.message)
    if (corner && corner.message != "")
    {
        // FireTargets(name, activator, caller, USE_TOGGLE, 0) -> SUB_UseTargets contract
        entity oldself = self;
		self = corner;
		string otarget = self.target;
        self.target = corner.message;
        SUB_UseTargets();
        self.target = otarget;
        if (corner.spawnflags & SF_CORNER_FIREONCE) corner.message = ""; // fire once?
        self = oldself;
    }

    // Corner or train requests WAIT_RETRIGGER: stop and wait for Use()
	// need pointer to LAST target.
	if ((corner.spawnflags & SF_TRAIN_WAIT_RETRIGGER) || (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER) )
    // if ((corner && (corner.spawnflags & SF_CORNER_WAIT_RETRIGGER)) || (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER))
    {
        self.spawnflags = self.spawnflags | SF_TRAIN_WAIT_RETRIGGER;

        // stop motion
        // self.velocity = '0 0 0';
        // self.avelocity = '0 0 0';
        // self.nextthink = -1;
        // self.think = SUB_Null;

        Train_PlayStopSound(self);
		self.nextthink = 0;
        return;
    }

    // Wait time handling
    if (self.wait != 0) // -1 wait will wait forever!		
    {
		// self.nextthink = self.ltime + self.wait;
        // if (self.wait == -1)
        // {
            // self.nextthink = -1;
            // self.think = SUB_Null;
            // Train_PlayStopSound(self);
            // return;
        // }

		self.nextthink = self.ltime + self.wait;
        self.think = FuncTrain_Next;
        Train_PlayStopSound(self);
        return;
    }
	else
	{
		FuncTrain_Next(); // do it RIGHT now!
	}
};

// -----------------------------------------------------------------------------
// Next: advance to next corner and move/teleport to it
// -----------------------------------------------------------------------------
void FuncTrain_Next()
{
    vector dest;
    entity pTarg = Train_GetNextTarget(self);
    if (!pTarg)
    {
        // end of path
        // self.velocity = '0 0 0';
        // self.avelocity = '0 0 0';
        // self.nextthink = -1;
        // self.think = SUB_Null;

        Train_PlayStopSound(self);
        return;
    }

    // Save last target in case we need to find it again
    self.message = self.target;

    self.target = pTarg.target;
    self.wait = pTarg.wait;

    // Copy speed from *previous* current target
    if (self.goalentity && self.goalentity.speed != 0)
        self.speed = self.goalentity.speed;

    // Update current corner pointer (m_pevCurrentTarget)
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

// -----------------------------------------------------------------------------
// Use: toggles "wait retrigger" state like HL
// - If waiting: clear flag and move toward target (Next)
// - Else: set flag, snap target back to last corner, stop moving immediately
// -----------------------------------------------------------------------------
void FuncTrain_Use()
{
    if (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER)
    {
        // Move toward my target
        self.spawnflags = self.spawnflags - (self.spawnflags & SF_TRAIN_WAIT_RETRIGGER);
        FuncTrain_Next();
        return;
    }

    // Enter wait-retrigger mode
    self.spawnflags = self.spawnflags | SF_TRAIN_WAIT_RETRIGGER;

    // Pop back to last target if available (HL: if self.enemy) self.target = self.enemy->v.targetname
    if (self.enemy)
        self.target = self.enemy.targetname;

    // Stop immediately
    self.nextthink = -1;
    // self.think = SUB_Null;
    self.velocity = '0 0 0';
    self.avelocity = '0 0 0';
    Train_PlayStopSound(self);
}

// -----------------------------------------------------------------------------
// Activate: first-time initialization (teleport to first corner)
// In HL this happens during Activate().
// In QC we do it via a delayed think from Spawn.
// -----------------------------------------------------------------------------
void FuncTrain_Activate()
{
    if (self.activated) return;
    self.activated = TRUE;
	
    entity first = Train_GetNextTarget(self);
    if (!first) return;

    // After activation, train.target becomes first->target (so Next() searches properly)
    self.target = first.target;
    self.goalentity = first;
    setorigin(self, first.origin - Math_GetCenterOffset(self)); // Teleport to first corner origin - center offset

    if (self.targetname == "")
    {
        // not triggered, start immediately
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
// set the plat's "in-motion" sound
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

// set the plat's 'reached destination' stop sound
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

void func_train()
{
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
	self.activated = FALSE;
    if (self.volume == 0) self.volume = 0.85;

    self.blocked = train_blocked;
    self.use = FuncTrain_Use;

    // Start activation after targets spawn
    self.think = FuncTrain_Activate;
    self.nextthink = self.ltime + 0.1;
}
