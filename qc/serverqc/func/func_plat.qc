

void() Plat_CenterTouch;
void() Plat_OutsideTouch;
void() Plat_TriggerUse;
void() Plat_GoUp;
void() Plat_GoDown;
float PLAT_LOW_TRIGGER = 1;
#define SF_PLAT_TOGGLE		0x0001

// middle trigger
void Plat_SpawnInsideTrigger()
{
	entity trigger = spawn();
	trigger.touch = Plat_CenterTouch;
	trigger.movetype = MOVETYPE_NONE;
	trigger.solid = SOLID_TRIGGER;
	trigger.enemy = self;
	
	vector tmin = self.mins + '25 25 0';
	vector tmax = self.maxs - '25 25 -8';
	tmin_z = tmax_z - (self.pos1_z - self.pos2_z + 8);
	if (self.spawnflags & PLAT_LOW_TRIGGER)
		tmax_z = tmin_z + 8;
	
	if (self.size_x <= 50)
	{
		tmin_x = (self.mins_x + self.maxs_x) / 2;
		tmax_x = tmin_x + 1;
	}
	if (self.size_y <= 50)
	{
		tmin_y = (self.mins_y + self.maxs_y) / 2;
		tmax_y = tmin_y + 1;
	}
	
	setsize (trigger, tmin, tmax);
}

void Plat_HitTop()
{
	sound (self, CHAN_VOICE, self.noiseArrived, 1, ATTN_NORM);
	self.state = STATE_TOP;
	self.think = Plat_GoDown;
	self.nextthink = self.ltime + 3;
}

void Plat_HitBottom()
{
	sound(self, CHAN_VOICE, self.noiseArrived, 1, ATTN_NORM);
	self.state = STATE_BOTTOM;
}

void Plat_GoDown()
{
	sound(self, CHAN_VOICE, self.noiseMoving, 1, ATTN_NORM);
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos2, self.speed, Plat_HitBottom);
}

void Plat_GoUp()
{
	sound(self, CHAN_VOICE, self.noiseMoving, 1, ATTN_NORM);
	self.state = STATE_UP;
	SUB_CalcMove (self.pos1, self.speed, Plat_HitTop);
}

void Plat_CenterTouch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;
	self = self.enemy;
	if (self.state == STATE_BOTTOM) Plat_GoUp();
	else if (self.state == STATE_TOP) self.nextthink = self.ltime + 1;	// delay going down
}

void Plat_OutsideTouch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;
	//dprint ("Plat_OutsideTouch\n");
	self = self.enemy;
	if (self.state == STATE_TOP) Plat_GoDown();
}

void Plat_TriggerUse()
{
	if (self.think) return;		// allready activated
	Plat_GoDown();
}

void Plat_Blocked()
{
	T_Damage(other, self, self, 1);
	if (self.state == STATE_UP) Plat_GoDown();
	else if (self.state == STATE_DOWN) Plat_GoUp();
	else objerror ("plat_crush: bad self.state\n");
}

void Plat_Use()
{
	if(self.spawnflags & SF_PLAT_TOGGLE)
	{
		if (self.state == STATE_TOP)
			Plat_GoDown();
		else if (self.state == STATE_BOTTOM)
			Plat_GoUp();
	}
	else
	{
		self.use = SUB_Null;
		if (self.state != STATE_UP) objerror ("plat_use: not in up state");
		Plat_GoDown();
	}
}


/*QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed	default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determined by the model's height.
Set "sounds" to one of the following:
1) base fast
2) chain slow
*/

void Plat_Precache()
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


void func_plat()
{
	Plat_Precache();
	if (!self.t_length) self.t_length = 80;
	if (!self.t_width) self.t_width = 10;

	self.mangle = self.angles;
	self.angles = '0 0 0';

	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin (self, self.origin);	
	setmodel (self, self.model);
	setsize (self, self.mins , self.maxs);

	self.blocked = Plat_Blocked;
	if (!self.speed) self.speed = 150;

	// pos1 is the top position, pos2 is the bottom
	self.pos1 = self.origin;
	self.pos2 = self.origin;
	if (self.height) self.pos2_z = self.origin_z - self.height;
	else self.pos2_z = self.origin_z - self.size_z + 8;

	// self.use = Plat_TriggerUse;

	if(!(self.spawnflags & SF_PLAT_TOGGLE))
		Plat_SpawnInsideTrigger();	// the "start moving" trigger	

	if (self.targetname)
	{
		setorigin(self, self.pos1);
		self.state = STATE_UP;
		self.use = Plat_Use;
	}
	else
	{
		setorigin (self, self.pos2);
		self.state = STATE_BOTTOM;
	}
}
