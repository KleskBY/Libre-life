

/////////////////// MOVE //////////////////

void AI_Stand()
{
	if (FindTarget()) return;
	if (time > self.pausetime)
	{
		if (self.th_walk) self.th_walk();
		return;
	}
};

void AI_Walk(float dist)
{
	movedist = dist;
	if (FindTarget()) return; // check for noticing a player (see AI_Stand)
	// Following a node route around an obstacle? Step it, skip direct move.
	if (self.monster_movementGoal == MOVEGOAL_NODE) { Monster_AdvanceRoute(dist); Monster_MoveDebug("ROUTE", TRUE, TRUE); return; }
	if (Monster_SlideStep(dist)) { Monster_MoveDebug("SLIDE", TRUE, TRUE); return; }
	// straight-line fast path; falls through to engine avoidance on block.
	if (!self.goalentity || self.goalentity == world || wasfreed(self.goalentity))
		self.goalentity = self.movetarget;
	if (self.goalentity && self.goalentity != world && Monster_DirectStep(self.goalentity.origin, dist)) return;
	if (!self.goalentity || self.goalentity == world) return;
	movetogoal(dist);
	Monster_MoveDebug("GOAL", TRUE, TRUE);
	Monster_StuckCheck(dist);
};

void AI_Forward(float dist)
{
	walkmove(self.angles_y, dist);
};

void AI_Back(float dist)
{
	walkmove(self.angles_y + 180, dist);
};

void AI_PainForward(float dist) 
{
	walkmove(self.ideal_yaw, dist);
};

void AI_StrafeLeft(float dist)
{
	walkmove(self.angles_y + 90, dist);
};

void AI_StrafeRight(float dist)
{
	walkmove(self.angles_y + 270, dist);
};

void AI_Face()
{
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw ();
};

void AI_RunSlide() 
{
	float ofs;

	self.ideal_yaw = enemy_yaw;
	ChangeYaw();
	if (self.lefty) ofs = 90;
	else ofs = -90;

	if (walkmove(self.ideal_yaw + ofs, movedist))
		return;

	self.lefty = 1 - self.lefty;
	
	walkmove(self.ideal_yaw - ofs, movedist);
};

void AI_Run(float dist)
{
	movedist = dist;

	if (self.enemy.health <= 0) // see if the enemy is dead
	{
		self.enemy = world;
	
		if (self.oldenemy.health > 0) // grudge target first (Quake behaviour)
		{
			self.enemy = self.oldenemy;
			self.oldenemy = world;
			HuntTarget();
		}
		else if (FindTarget()) // otherwise scan for a fresh target
		{
			return;	// FoundTarget installed enemy + hunt for us
		}
		else
		{
			if (self.movetarget) { if (self.th_walk) self.th_walk(); }
			else if (self.th_stand) self.th_stand();
			return;
		}
	}

	self.show_hostile = time + 1; // wake up other monsters
	enemy_vis = IsVisible(self.enemy); // check knowledge of enemy
	if (enemy_vis) self.search_time = time + 5;
	if (self.search_time < time) // look for other coop players
	{
		if (FindTarget()) return;
	}

	enemy_infront = Math_InFront(self.enemy.origin);
	enemy_range = Monster_Range(self.enemy);
	enemy_yaw = vectoyaw(self.enemy.origin - self.origin);

	if (self.attack_state == AS_MISSILE)
	{
		AI_RunMissile();
		return;
	}
	if (self.attack_state == AS_MELEE)
	{
		AI_RunMelee();
		return;
	}
	
	if(self.checkAttack)
	{
		if (enemy_vis && self.checkAttack()) return;
	}
	else 
	{
		if(enemy_vis && CheckAttack()) return;
	}

	if (self.attack_state == AS_SLIDING)
	{
		AI_RunSlide();
		return;
	}

	// Following a node route around an obstacle? Step it, skip direct move.
	if (self.monster_movementGoal == MOVEGOAL_NODE) { Monster_AdvanceRoute(dist); Monster_MoveDebug("ROUTE", TRUE, TRUE); return; }
	if (Monster_SlideStep(dist)) { Monster_MoveDebug("SLIDE", TRUE, TRUE); return; }
	// scripted_sequence cleanup and Monster_AdvanceRoute both leave goalentity
	// null; movetogoal would then chase world.origin '0 0 0'.
	if (!self.goalentity || self.goalentity == world || wasfreed(self.goalentity))
		self.goalentity = self.enemy;
	// straight-line fast path; falls through to engine avoidance on block.
	if (self.goalentity && self.goalentity != world && Monster_DirectStep(self.goalentity.origin, dist)) return;
	if (!self.goalentity || self.goalentity == world) return;
	movetogoal(dist); //head straight in. done in C code...
	Monster_MoveDebug("GOAL", TRUE, TRUE);
	Monster_StuckCheck(dist);
};


void AI_Jump(float power)
{
	makevectors(self.angles);
	self.origin_z = self.origin_z + 1;
	self.velocity = v_forward * power + '0 0 250'; 
	if (self.flags & FL_ONGROUND) self.flags = self.flags - FL_ONGROUND;
};
