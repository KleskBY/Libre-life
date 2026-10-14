
.float  rotation;
.vector platrot_start;
.vector platrot_end;

void PlatRot_RotMove(vector destAngle, float dt)
{
	vector delta = Math_AnglesDifference(self.angles, destAngle);
	if (dt >= 0.1)
	{
		self.avelocity = delta * (1 / dt);
	}
	else
	{
		self.avelocity = delta;
		self.nextthink = self.ltime + 1;
	}
}

void PlatRot_HitTop()
{
	Plat_HitTop();
	self.avelocity = '0 0 0';
	self.angles    = self.platrot_end;
}

void PlatRot_HitBottom()
{
	Plat_HitBottom();
	self.avelocity = '0 0 0';
	self.angles    = self.platrot_start;
}

void PlatRot_GoUp()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	self.state = STATE_UP;
	SUB_CalcMove(self.pos1, self.speed, PlatRot_HitTop);
	PlatRot_RotMove(self.platrot_end, self.nextthink - self.ltime);
}

void PlatRot_GoDown()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	self.state = STATE_DOWN;
	SUB_CalcMove(self.pos2, self.speed, PlatRot_HitBottom);
	PlatRot_RotMove(self.platrot_start, self.nextthink - self.ltime);
}

void PlatRot_SetupRotation()
{
	if (self.rotation != 0)
	{
		if      (self.spawnflags & SF_DOOR_ROTATE_Z) self.movedir = '0 0 1';
		else if (self.spawnflags & SF_DOOR_ROTATE_X) self.movedir = '1 0 0';
		else                                          self.movedir = '0 1 0';

		if (self.spawnflags & SF_DOOR_ROTATE_BACKWARDS)
			self.movedir = self.movedir * -1;

		self.platrot_start = self.angles;
		self.platrot_end   = self.angles + self.movedir * self.rotation;
	}
	else
	{
		self.platrot_start = '0 0 0';
		self.platrot_end   = '0 0 0';
	}

	if (self.targetname)
		self.angles = self.platrot_end;
}

void func_platrot()
{
	vector savedAngles = self.angles;

	func_plat();

	self.angles = savedAngles;

	self.platGoUp   = PlatRot_GoUp;
	self.platGoDown = PlatRot_GoDown;

	PlatRot_SetupRotation();
}
