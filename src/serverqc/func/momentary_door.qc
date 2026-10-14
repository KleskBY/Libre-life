
void MomentaryDoor_Precache()
{
	switch (self.movesnd)
	{
	case 0:
		self.noiseMoving = "common/null.wav";
		break;
	case 1:
		precache_sound("doors/doormove1.wav");
		self.noiseMoving = "doors/doormove1.wav";
		break;
	case 2:
		precache_sound("doors/doormove2.wav");
		self.noiseMoving = "doors/doormove2.wav";
		break;
	case 3:
		precache_sound("doors/doormove3.wav");
		self.noiseMoving = "doors/doormove3.wav";
		break;
	case 4:
		precache_sound("doors/doormove4.wav");
		self.noiseMoving = "doors/doormove4.wav";
		break;
	case 5:
		precache_sound("doors/doormove5.wav");
		self.noiseMoving = "doors/doormove5.wav";
		break;
	case 6:
		precache_sound("doors/doormove6.wav");
		self.noiseMoving = "doors/doormove6.wav";
		break;
	case 7:
		precache_sound("doors/doormove7.wav");
		self.noiseMoving = "doors/doormove7.wav";
		break;
	case 8:
		precache_sound("doors/doormove8.wav");
		self.noiseMoving = "doors/doormove8.wav";
		break;
	default:
		self.noiseMoving = "common/null.wav";
		break;
	}

	self.noiseArrived = "common/null.wav";
}

void MomentaryDoor_MoveDone()
{
	Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, "common/null.wav");
	Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, self.noiseArrived);
}

void MomentaryDoor_Blocked()
{
	if (self.dmg)
		T_Damage(other, self, self, self.dmg, DMG_CRUSH);
}

void MomentaryDoor_MoveTo(float value)
{
	if (value > 1) value = 1;
	if (value < 0) value = 0;

	vector move = self.pos1 + value * (self.pos2 - self.pos1);
	vector delta = move - self.origin;
	float moveSpeed = vlen(delta) / 0.1;

	if (!moveSpeed)
		return;

	if (self.nextthink <= self.ltime || self.nextthink == 0)
		Sound_Play(self, CHAN_STATIC, 1, ATTN_NORM, PITCH_NORM, self.noiseMoving);
	else if (move == self.finaldest)
		return;

	SUB_CalcMove(move, moveSpeed, MomentaryDoor_MoveDone);
}

void MomentaryDoor_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (useTypeArg != USE_SET)
		return;

	MomentaryDoor_MoveTo(useValueArg);
}

void MomentaryDoor_Use()
{
	if (useType != USE_SET)
		return;

	MomentaryDoor_MoveTo(useValue);
}

void momentary_door()
{
	SetMovedir();

	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);
	Render_Apply(self);

	if (!self.speed)
		self.speed = 100;
	if (!self.dmg)
		self.dmg = 2;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir * (
		fabs(self.movedir_x * (self.size_x - 2))
		+ fabs(self.movedir_y * (self.size_y - 2))
		+ fabs(self.movedir_z * (self.size_z - 2))
		- self.lip);
	ASSERTSZ(self.pos1 != self.pos2, "momentary_door start/end positions are equal");

	if (self.spawnflags & SF_DOOR_START_OPEN)
	{
		setorigin(self, self.pos2);
		self.pos2 = self.pos1;
		self.pos1 = self.origin;
	}

	self.touch = SUB_Null;
	self.use = MomentaryDoor_Use;
	self.usehl = MomentaryDoor_UseHL;
	self.blocked = MomentaryDoor_Blocked;

	MomentaryDoor_Precache();
}
