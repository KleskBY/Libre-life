
#define SF_MOMENTARY_AUTO_RETURN	16

.float mrb_lastUsed;
.float mrb_direction;
.float mrb_value;        // authoritative normalized position 0..1
.float returnspeed;
.vector mrb_start;
.vector mrb_end;

void MomentaryRotButton_AxisDir()
{
	if (self.spawnflags & SF_DOOR_ROTATE_Z)
		self.movedir = '0 0 1';
	else if (self.spawnflags & SF_DOOR_ROTATE_X)
		self.movedir = '1 0 0';
	else
		self.movedir = '0 1 0';

	if (self.spawnflags & SF_DOOR_ROTATE_BACKWARDS)
		self.movedir = self.movedir * -1;
}

void MomentaryRotButton_PlaySound()
{
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
}

void MomentaryRotButton_UpdateTarget(float value)
{
	if (!self.target || self.target == "")
		return;

	SUB_FireTargets(self.target, self, self, USE_SET, value);
}

void MomentaryRotButton_SetPos(float value)
{
	value = bound(0, value, 1);
	self.mrb_value  = value;
	self.avelocity  = '0 0 0';
	self.angles     = self.mrb_start + self.movedir * (self.distance * value);
}

void MomentaryRotButton_ApplyToLinked(float value)
{
	entity oldself = self;

	if (!oldself.target || oldself.target == "")
	{
		MomentaryRotButton_SetPos(value);
		return;
	}

	entity scan = nextent(world);
	while (scan != world)
	{
		if (scan.classname == "momentary_rot_button" && scan.target == oldself.target)
		{
			self = scan;
			MomentaryRotButton_SetPos(value);
		}
		scan = nextent(scan);
	}
	self = oldself;
}

void MomentaryRotButton_Off();
void MomentaryRotButton_Return();

void MomentaryRotButton_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.distance <= 0)
		return;

	if (!self.mrb_lastUsed)
	{
		if (self.spawnflags & SF_MOMENTARY_AUTO_RETURN)
			self.mrb_direction = 1;
		else
			self.mrb_direction = -self.mrb_direction;
		MomentaryRotButton_PlaySound();
	}
	self.mrb_lastUsed = TRUE;

	float step  = (self.speed / self.distance) * frametime;
	float value = bound(0, self.mrb_value + self.mrb_direction * step, 1);

	MomentaryRotButton_ApplyToLinked(value);
	MomentaryRotButton_UpdateTarget(value);

	self.nextthink = self.ltime + 0.1;
	self.think     = MomentaryRotButton_Off;
}

void MomentaryRotButton_Use()
{
	MomentaryRotButton_UseHL(activator, self, useType, useValue);
}

// USE released (Off think fired because USE stopped re-arming nextthink).
void MomentaryRotButton_Off()
{
	self.mrb_lastUsed = FALSE;
	self.avelocity = '0 0 0';

	if ((self.spawnflags & SF_MOMENTARY_AUTO_RETURN) && self.returnspeed > 0)
	{
		self.mrb_direction = -1;
		self.think = MomentaryRotButton_Return;
		self.nextthink = self.ltime + 0.1;
	}
	else
	{
		self.think = SUB_Null;
		self.nextthink = -1;
	}
}

// Auto-return drive-back toward the start position.
void MomentaryRotButton_Return()
{
	float step  = (self.returnspeed / self.distance) * 0.1;	// per 0.1s tick
	float value = bound(0, self.mrb_value - step, 1);

	MomentaryRotButton_ApplyToLinked(value);
	MomentaryRotButton_UpdateTarget(value);

	if (value > 0)
	{
		self.think = MomentaryRotButton_Return;
		self.nextthink = self.ltime + 0.1;
	}
	else
	{
		self.avelocity = '0 0 0';
		self.think = SUB_Null;
		self.nextthink = -1;
	}
}

void momentary_rot_button()
{
	MomentaryRotButton_AxisDir();

	if (!self.speed)
		self.speed = 100;

	if (self.distance < 0)
	{
		// Authored at the OPEN end; starts behind it, begins at value 1
		self.mrb_start = self.angles + self.movedir * self.distance;
		self.mrb_end = self.angles;
		self.mrb_direction = 1;
		self.distance = -self.distance;
		self.mrb_value = 1;
	}
	else
	{
		// Authored at the CLOSED start, begins at value 0
		self.mrb_start = self.angles;
		self.mrb_end = self.angles + self.movedir * self.distance;
		self.mrb_direction = -1;
		self.mrb_value = 0;
	}

	Brush_SanitizeSkin(self);	// HL maps ship "skin" "minus one" here; FTE would un-solid it

	if (self.spawnflags & SF_MOMENTARY_DOOR)
		self.solid = SOLID_BSP;
	else
	{
		self.solid = SOLID_NOT;
		self.object_caps = self.object_caps | FCAP_CONTINUOUS_USE;
		self.flags = self.flags | FL_FINDABLE_NONSOLID;
	}

	self.movetype = MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);

	self.noise = Button_Sound(self.sounds);
	precache_sound(self.noise);

	self.mrb_lastUsed = FALSE;
	self.use = MomentaryRotButton_Use;
	self.usehl = MomentaryRotButton_UseHL;
}
