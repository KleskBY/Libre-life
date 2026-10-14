
#define		SF_PENDULUM_SWING			2
#define 	SF_BRUSH_ROTATE_INSTANT		1

.float accel;
.float maxSpeed;
.float dampSpeed;
.float damp;
.float distance;
.vector start;
.vector center;

void Pendulum_Stop()
{
	self.angles = self.start;
	self.speed = 0;
	self.think = SUB_Null;
	self.avelocity = '0 0 0';
}

void Pendulum_Blocked()
{
	self.timer = time;
}

void Pendulum_Swing();
void Pendulum_Use();
void Pendulum_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg);

void Pendulum_SUB_CallUseToggle()
{
	useType = USE_TOGGLE;
	Pendulum_Use();
	useType = 0;

}

float Toggle_AxisDelta(float fl, vector angle1, vector angle2)
{
	if (fl & SF_DOOR_ROTATE_Z)
		return Math_AngleDistance(angle1_z, angle2_z);
	
	if (fl & SF_DOOR_ROTATE_X)
		return Math_AngleDistance(angle1_x, angle2_x);

	return Math_AngleDistance(angle1_y, angle2_y);
}


void Pendulum_Swing()
{
	float delta, dt;
	
	delta = Toggle_AxisDelta(self.spawnflags, self.angles, self.center);
	dt = time - self.timer;
	self.timer = time;

	if (delta > 0 && self.accel > 0)
		self.speed -= self.accel * dt;	// Integrate velocity
	else 
		self.speed += self.accel * dt;

	if (self.speed > self.maxSpeed )
		self.speed = self.maxSpeed;
	else if (self.speed < -self.maxSpeed )
		self.speed = -self.maxSpeed;
	self.avelocity = self.speed * self.movedir;

	self.nextthink = self.ltime + 0.1;

	if (self.damp)
	{
		self.dampSpeed -= self.damp * self.dampSpeed * dt;
		if (self.dampSpeed < 30.0)
		{
			self.angles = self.center;
			self.speed = 0;
			self.think = SUB_Null;
			self.avelocity = '0 0 0';
		}
		else if (self.speed > self.dampSpeed )
			self.speed = self.dampSpeed;
		else if (self.speed < -self.dampSpeed )
			self.speed = -self.dampSpeed;
	}
}


void Pendulum_Touch()
{
	if (self.dmg <= 0 )
		return;

	if (!other.takedamage)
		return;

	float damage = self.dmg * self.speed * 0.01;
	if (damage < 0) damage = -damage;

	Combat_TakeDamage(other, self, self, damage, DMG_CRUSH);
	
	other.velocity = normalize(other.origin - VecBModelOrigin(self)) * damage;
}

void Pendulum_Use()
{
	if (self.speed)
	{
		if (self.spawnflags & SF_PENDULUM_AUTO_RETURN)
		{
			float delta = Toggle_AxisDelta( self.spawnflags, self.angles, self.start );

			self.avelocity = self.maxSpeed * self.movedir;
			self.nextthink = self.ltime + (delta / self.maxSpeed);
			self.think = Pendulum_Stop;
		}
		else
		{
			self.speed = 0;		// Dead stop
			self.think = SUB_Null;
			self.avelocity = '0 0 0';
		}
	}
	else
	{
		self.nextthink = self.ltime + 0.1;
		self.timer = time;
		self.think = Pendulum_Swing;
		self.dampSpeed = self.maxSpeed;
	}
}

// handler reads only self.speed and spawnflags to decide start/stop.
void Pendulum_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.speed)
	{
		if (self.spawnflags & SF_PENDULUM_AUTO_RETURN)
		{
			float delta = Toggle_AxisDelta(self.spawnflags, self.angles, self.start);

			self.avelocity = self.maxSpeed * self.movedir;
			self.nextthink = self.ltime + (delta / self.maxSpeed);
			self.think = Pendulum_Stop;
		}
		else
		{
			self.speed = 0;
			self.think = SUB_Null;
			self.avelocity = '0 0 0';
		}
	}
	else
	{
		self.nextthink = self.ltime + 0.1;
		self.timer = time;
		self.think = Pendulum_Swing;
		self.dampSpeed = self.maxSpeed;
	}
}

void Pendulum_RopeTouch()
{
	if (other.classname != "player")
	{
		dprint("Not a client\n");
		return;
	}

	if (other == self.enemy)
	{
		return;
	}

	self.enemy = other;
	other.velocity = '0 0 0';
	other.movetype = MOVETYPE_NONE;
}

void func_pendulum()
{
	if (self.spawnflags & SF_DOOR_ROTATE_Z)
		self.movedir = '0 0 1';
	else if (self.spawnflags & SF_DOOR_ROTATE_X)
		self.movedir = '1 0 0';
	else
		self.movedir = '0 1 0';

	if (self.spawnflags & SF_DOOR_PASSABLE)
		self.solid		= SOLID_NOT;
	else
		self.solid		= SOLID_BSP;
	self.movetype	= MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);
	Render_Apply(self);

	if (self.distance == 0) return;
	if (self.speed == 0) self.speed = 100;
	if (self.damp) self.damp = self.damp * 0.001;
	self.accel = (self.speed * self.speed) / (2 * fabs(self.distance));
	self.maxSpeed = self.speed;
	self.start = self.angles;
	self.center = self.angles + (self.distance * 0.5) * self.movedir;

	if (self.spawnflags & SF_BRUSH_ROTATE_INSTANT)
	{	
		self.think = Pendulum_SUB_CallUseToggle;
		self.nextthink = time + 0.1;
	}
	self.speed = 0;
	self.use = Pendulum_Use;
	self.usehl = Pendulum_UseHL;

	if (self.spawnflags & SF_PENDULUM_SWING)
	{
		self.touch = Pendulum_RopeTouch;
	}
}