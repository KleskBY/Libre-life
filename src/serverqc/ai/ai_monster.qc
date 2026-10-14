
///////////////// MONSTER /////////////////

void Monster_WakeFromDormancy()
{
	if (self.monster_isAsleep)
	{
		self.monster_isAsleep = FALSE;
		self.monster_state = MONSTERSTATE_ALERT;
	}

	// Don't strip Q1 spawnflag bits; bit 1 is Ambush and must persist.
	if (!self.q1_monster)
	{
		self.spawnflags = self.spawnflags & ~SF_MONSTER_WAIT_TILL_SEEN;
		self.spawnflags = self.spawnflags & ~SF_MONSTER_WAIT_FOR_SCRIPT;
	}
}

void Monster_Use()
{
	if (self.health <= 0) return;

	// Wake from targetname or WAIT_TILL_SEEN dormancy regardless of activator.
	if (self.monster_isAsleep || (self.spawnflags & SF_MONSTER_WAIT_FOR_SCRIPT))
		Monster_WakeFromDormancy();

	if (self.enemy) return;
	if (activator.items & IT_INVISIBILITY) return;
	if (activator.flags & FL_NOTARGET) return;
	if (activator.classname != "player") return;

	// Delay reaction so the monster's sound is still heard if it is teleported
	self.enemy = activator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
}

void Monster_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (self.health <= 0) return;

	// Wake from targetname or WAIT_TILL_SEEN dormancy.
	if (self.monster_isAsleep || (self.spawnflags & SF_MONSTER_WAIT_FOR_SCRIPT))
		Monster_WakeFromDormancy();

	if (self.enemy) return;
	if (pActivator.items & IT_INVISIBILITY) return;
	if (pActivator.flags & FL_NOTARGET) return;

	if (pActivator.classname != "player") return;

	self.enemy = pActivator;
	self.nextthink = time + 0.1;
	self.think = FoundTarget;
}

void monster_death_use()
{
	// fall to ground
	if (self.flags & FL_FLY) self.flags = self.flags - FL_FLY;
	if (self.flags & FL_SWIM) self.flags = self.flags - FL_SWIM;
	if (!self.target) return;

	activator = self.enemy;
	SUB_UseTargets();
}

void WalkMonster_StartGo()
{
	// For crabs perched in vents or on shelves that should stay put.
	if (!(self.spawnflags & SF_MONSTER_FALL_TO_GROUND))
	{
		self.origin_z = self.origin_z + 1; // raise off floor a bit
		droptofloor();
		if (!walkmove(0,0))
		{
			dprint("walkmonster in wall at: ");
			dprint(vtos(self.origin));
			dprint("\n");
		}
	}

	self.takedamage = DAMAGE_AIM;
	self.ideal_yaw = self.angles * '0 1 0';
	if (!self.yaw_speed) self.yaw_speed = 15;
	self.view_ofs = [0, 0, self.absmax_z - self.origin_z - 10];
	self.use = Monster_Use;
	self.usehl = Monster_UseHL;

	self.flags = self.flags | FL_MONSTER;
	
	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_HITMONSTERCLIP))
		self.flags = self.flags | FL_MONSTERCLIP;

	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_WAIT_TILL_SEEN))
	{
		self.monster_isAsleep = TRUE;
		self.monster_state = MONSTERSTATE_IDLE;
	}

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint("Monster can't find target at ");
			dprint(vtos(self.origin));
			dprint("\n");
		}
		
		if (self.movetarget.classname == "path_corner") 
		{ 
			if (self.th_walk) self.th_walk(); 
		}
		else
		{
			self.pausetime = 99999999;
		}
		
		if (self.th_stand) self.th_stand();
	}
	else
	{
		self.pausetime = 99999999;
		if (self.th_stand) self.th_stand();
	}

	self.nextthink = self.nextthink + random() * 0.5;
}


void WalkMonster_Start()
{
	self.nextthink = self.nextthink + random() * 0.5;	// Delay drop to floor to ensure all doors have been spawned and spread think times are applied.
	self.think = WalkMonster_StartGo;
	total_monsters = total_monsters + 1;
}

void FlyMonster_StartGo()
{
	if (!walkmove(0, 0))
	{
		dprint("flymonster in wall at: ");
		dprint(vtos(self.origin));
		dprint("\n");
	}

	self.takedamage = DAMAGE_AIM;
	self.ideal_yaw  = self.angles * '0 1 0';
	if (!self.yaw_speed) self.yaw_speed = 10;
	self.view_ofs   = '0 0 25';
	self.use   = Monster_Use;
	self.usehl = Monster_UseHL;
	self.flags = self.flags | FL_MONSTER | FL_FLY;

	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_HITMONSTERCLIP))
		self.flags = self.flags | FL_MONSTERCLIP;

	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_WAIT_TILL_SEEN))
	{
		self.monster_isAsleep = TRUE;
		self.monster_state = MONSTERSTATE_IDLE;
	}

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint("flymonster can't find target at ");
			dprint(vtos(self.origin));
			dprint("\n");
		}
		if (self.movetarget.classname == "path_corner") { if (self.th_walk) self.th_walk(); }
		else self.pausetime = 99999999;
		if (self.th_stand) self.th_stand();
	}
	else
	{
		self.pausetime = 99999999;
		if (self.th_stand) self.th_stand();
	}

	self.nextthink = self.nextthink + random() * 0.5;
}

void FlyMonster_Start()
{
	self.nextthink = self.nextthink + random() * 0.5;
	self.think = FlyMonster_StartGo;
	total_monsters = total_monsters + 1;
}


void SwimMonster_StartGo()
{
	if (!walkmove(0, 0))
	{
		dprint("swimmonster in wall at: ");
		dprint(vtos(self.origin));
		dprint("\n");
	}

	self.takedamage = DAMAGE_AIM;
	self.ideal_yaw  = self.angles * '0 1 0';
	if (!self.yaw_speed) self.yaw_speed = 10;
	self.view_ofs   = '0 0 10';
	self.use   = Monster_Use;
	self.usehl = Monster_UseHL;
	self.flags = self.flags | FL_MONSTER | FL_SWIM;
	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_HITMONSTERCLIP))
		self.flags = self.flags | FL_MONSTERCLIP;

	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_WAIT_TILL_SEEN))
	{
		self.monster_isAsleep = TRUE;
		self.monster_state = MONSTERSTATE_IDLE;
	}

	if (self.target)
	{
		self.goalentity = self.movetarget = find(world, targetname, self.target);
		self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
		if (!self.movetarget)
		{
			dprint("swimmonster can't find target at ");
			dprint(vtos(self.origin));
			dprint("\n");
		}
		if (self.movetarget.classname == "path_corner") { if (self.th_walk) self.th_walk(); }
		else self.pausetime = 99999999;
		if (self.th_stand) self.th_stand();
	}
	else
	{
		self.pausetime = 99999999;
		if (self.th_stand) self.th_stand();
	}

	self.nextthink = self.nextthink + random() * 0.5;
}

void SwimMonster_Start()
{
	self.nextthink = self.nextthink + random() * 0.5;
	self.think = SwimMonster_StartGo;
	total_monsters = total_monsters + 1;
}


/*
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which allways heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
*/

void() MoveTarget_Touch;
void() MoveTarget_Init =
{
	if (!self.targetname)
		objerror("monster_movetarget: no targetname");

	self.solid = SOLID_TRIGGER;
	self.touch = MoveTarget_Touch;
	setsize(self, '-8 -8 -8', '8 8 8');

};


/*
=============
MoveTarget_Touch

Something has bumped into a movetarget.  If it is a monster
moving towards it, change the next destination and continue.
==============
*/
void MoveTarget_Touch()
{
	if (other.movetarget != self) return;
	if (other.enemy) return;

	entity temp = self;
	self = other;
	other = temp;
	self.goalentity = self.movetarget = find(world, targetname, other.target);
	self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
	if (!self.movetarget)
	{
		self.pausetime = time + 999999;
		if (self.th_stand) self.th_stand();
		return;
	}
}
