// Player train-control integration.

.entity train_ent;		// train the player is currently controlling
.float  train_trainDir;		// last direction sent: -1, 0, or +1
.float  trainUseDown;

float FuncTrackTrain_OnControls(entity pevTest);
void FuncTrackTrain_Use();

// Returns TRUE if 'player' is inside 'pTrain's control volume.
// Must be called with self = caller's entity; swaps self internally.
float Player_InTrainControls(entity pTrain, entity player)
{
	entity oldself = self;
	self = pTrain;
	float result = FuncTrackTrain_OnControls(player);
	self = oldself;
	return result;
}

float Player_TrainUsePressed()
{
	if (IsFTE())
		return self.button5;
	return self.buttonuse;
}

entity Player_FindUsableTrain()
{
	entity e = nextent(world);

	while (e != world)
	{
		if (e.classname == "func_tracktrain" && Player_InTrainControls(e, self))
			return e;
		e = nextent(e);
	}

	return world;
}

void Player_ReleaseTrain()
{
	self.train_ent = world;
	self.flags = self.flags - (self.flags & FL_ONTRAIN);
	self.train_trainDir = 0;
	self.trainHudState = 0;
}

float Player_TrainHudState(entity train)
{
	float norm;

	if (!train || train.speed == 0)
		return 1; // stop

	if (train.speed < 0)
		return 2; // back

	if (train.m_speed > 0)
		norm = fabs(train.speed) / train.m_speed;
	else
		norm = 1;

	if (norm < 0.34) return 3;
	if (norm < 0.67) return 4;
	return 5;
}

void Player_SendTrainCommand(float dir)
{
	entity player = self;

	self = player.train_ent;
	useType = USE_SET;
	useValue = dir;
	activator = player;
	FuncTrackTrain_Use();
	self = player;
}

void Player_SuppressTrainInputs()
{
	self.movement = '0 0 0';
	self.button2 = 0;
	self.impulse = 0;
	self.reload = FALSE;
	self.velocity_x = 0;
	self.velocity_y = 0;
}

// Returns TRUE when +use was consumed by train control.
float Player_TrainControls()
{
	float usePressed = Player_TrainUsePressed();
	float useEdge = usePressed && !self.trainUseDown;
	self.trainUseDown = usePressed;

	if (self.train_ent)
	{
		if (!Player_InTrainControls(self.train_ent, self))
		{
			Player_ReleaseTrain();
			return FALSE;
		}

		if (useEdge)
		{
			Player_ReleaseTrain();
			return TRUE;
		}
	}
	else if (useEdge)
	{
		self.train_ent = Player_FindUsableTrain();
		if (self.train_ent)
		{
			self.flags |= FL_ONTRAIN;
			self.train_trainDir = 0;
			self.trainHudState = Player_TrainHudState(self.train_ent);
			Player_SuppressTrainInputs();
			return TRUE;
		}
	}

	if (!self.train_ent)
	{
		self.flags = self.flags - (self.flags & FL_ONTRAIN);
		self.trainHudState = 0;
		return FALSE;
	}

	float dir;
	if      (self.movement_x > 0) dir =  1;
	else if (self.movement_x < 0) dir = -1;
	else                          dir =  0;

	if (dir != self.train_trainDir)
	{
		self.train_trainDir = dir;
		if (dir != 0)
			Player_SendTrainCommand(dir);
	}

	self.trainHudState = Player_TrainHudState(self.train_ent);
	Player_SuppressTrainInputs();

	return TRUE;
}

void Player_TankFrame()
{
    if (!self.tank_ent) return;

    entity oself = self;
    entity tank  = self.tank_ent;

    // OnControls range gate. If player drifted >30u from the mount position, release the tank (matches FuncTank_OnControls).
    if (vlen(tank.tank_controllerUsePos - self.origin) >= 30)
    {
        self = tank;
        tank.usehl(oself, oself, USE_OFF, 0);
        self = oself;
        self.tank_ent = world;
        return;
    }

    self = tank;
    tank.usehl(oself, oself, USE_SET, 2);
    self = oself;
}
