
#define SF_TRACK_ACTIVATETRAIN	0x00000001
#define SF_TRACK_RELINK		0x00000002
#define SF_TRACK_ROTMOVE	0x00000004
#define SF_TRACK_STARTBOTTOM	0x00000008
#define SF_TRACK_DONT_MOVE	0x00000010

#define TRAIN_SAFE		0
#define TRAIN_BLOCKING		1
#define TRAIN_FOLLOWING	2

.string train;
.string toptrack;
.string bottomtrack;
.entity trackTop;
.entity trackBottom;
.entity trackTrain;
.float trainCode;
.float targetState;
.float useEnabled;

void TrackChange_Find();
void TrackChange_HitTop();
void TrackChange_HitBottom();
void TrackAuto_UpdateAutoTargets(float toggleState);

void TrackChange_UpdateAutoTargets(float toggleState)
{
	if (self.classname == "func_trackautochange")
	{
		TrackAuto_UpdateAutoTargets(toggleState);
		return;
	}

	if (!self.trackTop || !self.trackBottom)
		return;

	if (toggleState == STATE_TOP)
		self.trackTop.spawnflags &= ~SF_PATH_DISABLED;
	else
		self.trackTop.spawnflags |= SF_PATH_DISABLED;

	if (toggleState == STATE_BOTTOM)
		self.trackBottom.spawnflags &= ~SF_PATH_DISABLED;
	else
		self.trackBottom.spawnflags |= SF_PATH_DISABLED;
}

float TrackChange_EvaluateTrain(entity pcurrent)
{
	vector dist;
	float len;

	if (!pcurrent || !self.trackTrain)
		return TRAIN_SAFE;

	if (self.trackTrain.tracktrain_path == pcurrent
		|| (pcurrent.pathtrack_prev && self.trackTrain.tracktrain_path == pcurrent.pathtrack_prev)
		|| (pcurrent.pathtrack_next && self.trackTrain.tracktrain_path == pcurrent.pathtrack_next))
	{
		if (self.trackTrain.speed != 0)
			return TRAIN_BLOCKING;

		dist = self.origin - self.trackTrain.origin;
		dist_z = 0;
		len = vlen(dist);

		if (len < self.trackTrain.pathtrack_length)
			return TRAIN_FOLLOWING;
		if (len > 150 + self.trackTrain.pathtrack_length)
			return TRAIN_SAFE;

		return TRAIN_BLOCKING;
	}

	return TRAIN_SAFE;
}

void TrackChange_UpdateTrain(vector destAngle)
{
	float moveTime = self.nextthink - self.ltime;
	entity trackChange = self;
	vector offset;
	vector delta;
	vector localOffset;

	self.trackTrain.velocity = self.velocity;
	self.trackTrain.avelocity = self.avelocity;
	self.trackTrain.think = FuncTrackTrain_Next;
	self = trackChange.trackTrain;
	FuncTrackTrain_NextThink(self.ltime + moveTime, FALSE);
	self = trackChange;

	if (moveTime <= 0)
		return;

	offset = self.trackTrain.origin - self.origin;
	delta = Math_AnglesDifference(self.angles, destAngle);

	makevectors(delta * -1);
	localOffset_x = Math_DotProduct(offset, v_forward);
	localOffset_y = Math_DotProduct(offset, v_right);
	localOffset_z = Math_DotProduct(offset, v_up);

	localOffset = localOffset - offset;
	self.trackTrain.velocity = self.velocity + localOffset * (1 / moveTime);
}

void TrackChange_GoDown()
{
	if (self.trainCode == TRAIN_BLOCKING)
		return;

	TrackChange_UpdateAutoTargets(STATE_DOWN);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	self.state = STATE_DOWN;

	if (self.spawnflags & SF_TRACK_DONT_MOVE)
	{
		SUB_CalcAngleMove(self.platrot_start, self.speed, TrackChange_HitBottom);
	}
	else
	{
		SUB_CalcMove(self.pos2, self.speed, TrackChange_HitBottom);
		PlatRot_RotMove(self.platrot_start, self.nextthink - self.ltime);
	}

	if (self.trainCode == TRAIN_FOLLOWING)
	{
		TrackChange_UpdateTrain(self.platrot_start);
		self.trackTrain.tracktrain_path = world;
	}
}

void TrackChange_GoUp()
{
	if (self.trainCode == TRAIN_BLOCKING)
		return;

	TrackChange_UpdateAutoTargets(STATE_UP);
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	self.state = STATE_UP;

	if (self.spawnflags & SF_TRACK_DONT_MOVE)
	{
		SUB_CalcAngleMove(self.platrot_end, self.speed, TrackChange_HitTop);
	}
	else
	{
		SUB_CalcMove(self.pos1, self.speed, TrackChange_HitTop);
		PlatRot_RotMove(self.platrot_end, self.nextthink - self.ltime);
	}

	if (self.trainCode == TRAIN_FOLLOWING)
	{
		TrackChange_UpdateTrain(self.platrot_end);
		self.trackTrain.tracktrain_path = world;
	}
}

void TrackChange_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!self.useEnabled)
		return;

	if (self.state != STATE_TOP && self.state != STATE_BOTTOM)
		return;

	if (self.state == STATE_TOP)
		self.trainCode = TrackChange_EvaluateTrain(self.trackTop);
	else if (self.state == STATE_BOTTOM)
		self.trainCode = TrackChange_EvaluateTrain(self.trackBottom);
	else
		self.trainCode = TRAIN_BLOCKING;

	if (self.trainCode == TRAIN_BLOCKING)
	{
		Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "buttons/button11.wav");
		return;
	}

	self.useEnabled = FALSE;
	if (self.state == STATE_TOP)
		TrackChange_GoDown();
	else
		TrackChange_GoUp();
}

void TrackChange_Use()
{
	TrackChange_UseHL(activator, self, useType, 0);
}

void TrackAuto_UpdateAutoTargets(float toggleState)
{
	entity pTarget;
	entity pNextTarget;
	entity trackChange;

	if (!self.trackTop || !self.trackBottom)
		return;

	if (self.targetState == STATE_TOP)
	{
		pTarget = PathTrack_GetNext(self.trackTop);
		pNextTarget = PathTrack_GetNext(self.trackBottom);
	}
	else
	{
		pTarget = PathTrack_GetNext(self.trackBottom);
		pNextTarget = PathTrack_GetNext(self.trackTop);
	}

	if (pTarget)
	{
		pTarget.spawnflags &= ~SF_PATH_DISABLED;
		if (self.trainCode == TRAIN_FOLLOWING && self.trackTrain && self.trackTrain.speed == 0)
		{
			trackChange = self;
			activator = trackChange;
			useType = USE_ON;
			useValue = 0;
			self = trackChange.trackTrain;
			FuncTrackTrain_Use();
			self = trackChange;
		}
	}

	if (pNextTarget)
		pNextTarget.spawnflags |= SF_PATH_DISABLED;
}

void TrackAuto_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	entity pTarget;

	if (!self.useEnabled)
		return;

	if (self.state == STATE_TOP)
		pTarget = self.trackTop;
	else if (self.state == STATE_BOTTOM)
		pTarget = self.trackBottom;
	else
		pTarget = world;

	if (pActivator && pActivator.classname == "func_tracktrain")
	{
		self.trainCode = TrackChange_EvaluateTrain(pTarget);
		if (self.trainCode == TRAIN_FOLLOWING && self.state != self.targetState)
		{
			self.useEnabled = FALSE;
			if (self.state == STATE_TOP)
				TrackChange_GoDown();
			else
				TrackChange_GoUp();
		}
	}
	else
	{
		if (pTarget)
			pTarget = PathTrack_GetNext(pTarget);

		useType = useTypeArg;
		if (pTarget && self.trackTrain && self.trackTrain.tracktrain_path != pTarget && ShouldToggle(self.targetState))
		{
			if (self.targetState == STATE_TOP)
				self.targetState = STATE_BOTTOM;
			else
				self.targetState = STATE_TOP;
		}

		TrackAuto_UpdateAutoTargets(self.targetState);
	}
}

void TrackAuto_Use()
{
	TrackAuto_UseHL(activator, self, useType, 0);
}

void TrackChange_HitBottom()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseArrived);
	self.state = STATE_BOTTOM;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	setorigin(self, self.pos2);
	self.angles = self.platrot_start;

	if (self.trainCode == TRAIN_FOLLOWING && self.trackTrain)
		self.trackTrain.tracktrain_path = PathTrack_Nearest(self.trackBottom, self.trackTrain.origin);

	self.think = SUB_Null;
	self.nextthink = -1;
	TrackChange_UpdateAutoTargets(self.state);
	self.useEnabled = TRUE;
}

void TrackChange_HitTop()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseArrived);
	self.state = STATE_TOP;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	setorigin(self, self.pos1);
	self.angles = self.platrot_end;

	if (self.trainCode == TRAIN_FOLLOWING && self.trackTrain)
		self.trackTrain.tracktrain_path = PathTrack_Nearest(self.trackTop, self.trackTrain.origin);

	self.think = SUB_Null;
	self.nextthink = -1;
	TrackChange_UpdateAutoTargets(self.state);
	self.useEnabled = TRUE;
}

void TrackChange_Find()
{
	entity targetEnt;
	vector center;

	targetEnt = find(world, targetname, self.toptrack);
	if (!targetEnt)
	{
		dprint("Can't find top track for track change! ");
		dprint(self.toptrack);
		dprint("\n");
		return;
	}
	self.trackTop = PathTrack_Instance(targetEnt);

	targetEnt = find(world, targetname, self.bottomtrack);
	if (!targetEnt)
	{
		dprint("Can't find bottom track for track change! ");
		dprint(self.bottomtrack);
		dprint("\n");
		return;
	}
	self.trackBottom = PathTrack_Instance(targetEnt);

	targetEnt = find(world, targetname, self.train);
	if (!targetEnt)
	{
		dprint("Can't find train for track change! ");
		dprint(self.train);
		dprint("\n");
		return;
	}
	self.trackTrain = FuncTrackTrain_Instance(targetEnt);
	if (!self.trackTrain)
	{
		dprint("Track change train target is not func_tracktrain! ");
		dprint(self.train);
		dprint("\n");
		return;
	}

	center = (self.absmin + self.absmax) * 0.5;
	self.trackBottom = PathTrack_Nearest(self.trackBottom, center);
	self.trackTop = PathTrack_Nearest(self.trackTop, center);
	TrackChange_UpdateAutoTargets(self.state);

	self.think = SUB_Null;
	self.nextthink = -1;
}

void func_trackchange()
{
	vector savedAngles = self.angles;

	Plat_Precache();
	precache_sound("buttons/button11.wav");

	if (!self.speed)
		self.speed = 150;

	self.mangle = self.angles;
	self.angles = savedAngles;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
	self.blocked = Plat_Blocked;

	self.pos1 = self.origin;
	self.pos2 = self.origin;
	if (self.height)
		self.pos2_z = self.origin_z - self.height;
	else
		self.pos2_z = self.origin_z - self.size_z + 8;

	if (self.spawnflags & SF_TRACK_DONT_MOVE)
		self.pos2_z = self.origin_z;

	PlatRot_SetupRotation();

	if (self.spawnflags & SF_TRACK_STARTBOTTOM)
	{
		setorigin(self, self.pos2);
		self.state = STATE_BOTTOM;
		self.angles = self.platrot_start;
		self.targetState = STATE_TOP;
	}
	else
	{
		setorigin(self, self.pos1);
		self.state = STATE_TOP;
		self.angles = self.platrot_end;
		self.targetState = STATE_BOTTOM;
	}

	self.platGoUp = TrackChange_GoUp;
	self.platGoDown = TrackChange_GoDown;
	self.use = TrackChange_Use;
	self.usehl = TrackChange_UseHL;
	self.object_caps = FCAP_IMPULSE_USE;
	self.useEnabled = TRUE;

	self.nextthink = self.ltime + 2;
	self.think = TrackChange_Find;
}

void func_trackautochange()
{
	func_trackchange();
	self.use = TrackAuto_Use;
	self.usehl = TrackAuto_UseHL;
}
