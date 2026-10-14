
#define FGUNTARGET_START_ON	0x0001

.float guntarget_on;

entity GunTarget_GetNextTarget()
{
	if (!self.target || self.target == "")
		return world;
	return find(world, targetname, self.target);
}

vector GunTarget_CornerOrigin(entity corner)
{
	return corner.origin - Math_GetCenterOffset(self);
}

void GunTarget_Stop()
{
	self.guntarget_on = FALSE;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.nextthink = 0;
	self.think = SUB_Null;
	self.takedamage = DAMAGE_NO;
}

void GunTarget_Next();

void GunTarget_Wait()
{
	entity corner = self.goalentity;
	if (!corner)
	{
		GunTarget_Stop();
		return;
	}

	if (corner.message && corner.message != "")
	{
		SUB_FireTargets(corner.message, self, self, USE_TOGGLE, 0);
		if (corner.spawnflags & SF_CORNER_FIREONCE)
			corner.message = "";
	}

	self.wait = corner.wait;
	self.target = corner.target;
	self.think = GunTarget_Next;

	if (self.wait < 0)
	{
		self.nextthink = -1;
		self.think = SUB_Null;
	}
	else if (self.wait != 0)
		self.nextthink = self.ltime + self.wait;
	else
		GunTarget_Next();
}

void GunTarget_Next()
{
	entity corner;

	self.think = SUB_Null;
	corner = GunTarget_GetNextTarget();
	self.goalentity = corner;

	if (!corner)
	{
		GunTarget_Stop();
		return;
	}

	SUB_CalcMove(GunTarget_CornerOrigin(corner), self.speed, GunTarget_Wait);
}

void GunTarget_Start()
{
	if (self.usehl)
		self.usehl(self, self, USE_ON, 0);
}

void GunTarget_Activate()
{
	entity corner = GunTarget_GetNextTarget();
	if (!corner)
		return;

	self.goalentity = corner;
	setorigin(self, GunTarget_CornerOrigin(corner));

	if (self.spawnflags & FGUNTARGET_START_ON)
	{
		self.think = GunTarget_Start;
		self.nextthink = self.ltime + 0.2;
	}
}

float GunTarget_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	if (self.health <= 0)
		return 0;

	self.health = self.health - damage;
	if (self.health <= 0)
	{
		self.health = 0;
		GunTarget_Stop();
		if (self.message && self.message != "")
			SUB_FireTargets(self.message, self, self, USE_TOGGLE, 0);
	}

	return 0;
}

void GunTarget_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	useType = useTypeArg;
	if (!ShouldToggle(self.guntarget_on))
		return;

	if (self.guntarget_on)
	{
		GunTarget_Stop();
		return;
	}

	self.goalentity = GunTarget_GetNextTarget();
	if (!self.goalentity)
		return;

	self.guntarget_on = TRUE;
	self.takedamage = DAMAGE_AIM;
	self.health = self.max_health;
	GunTarget_Next();
}

void GunTarget_Use()
{
	GunTarget_UseHL(activator, self, useType, 0);
}

void func_guntarget()
{
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;

	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);

	if (!self.speed)
		self.speed = 100;

	self.takedamage = DAMAGE_NO;
	self.takeDmgFn = GunTarget_TakeDamage;
	self.flags = self.flags | FL_MONSTER;
	self.guntarget_on = FALSE;
	self.max_health = self.health;

	self.use = GunTarget_Use;
	self.usehl = GunTarget_UseHL;

	self.think = GunTarget_Activate;
	self.nextthink = self.ltime + 0.1;
}
