
////////////////// ATTACK /////////////////

void AI_Face();

void AI_Charge(float d)
{
	AI_Face();	
	movetogoal(d);
}

void AI_ChargeSide()
{
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	ChangeYaw ();

	makevectors (self.angles);
	vector dtemp = self.enemy.origin - 30*v_right;
	float heading = vectoyaw(dtemp - self.origin);
	
	walkmove(heading, 20);
}


void AI_RunMissile()
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw();
	if (FacingIdeal())
	{
		self.th_missile();
		self.attack_state = AS_STRAIGHT;
	}
}

void AI_Melee()
{
	if (!self.enemy) return;		// removed before stroke
	vector dist = self.enemy.origin - self.origin;
	if (vlen(dist) > 90) return;
	float ldmg = random(1, 12); //(random() + random() + random()) * 4;
	T_Damage (self.enemy, self, self, ldmg);
	if(vlen(self.enemy.punchangle) < 1) self.enemy.punchangle = randomvec() * 10;
}

void AI_MeleeSide()
{
	if (!self.enemy) return;		// removed before stroke
	AI_ChargeSide();
	vector dist = self.enemy.origin - self.origin;
	if (vlen(dist) > 90) return;
	if (!CanDamage (self.enemy, self)) return;
	float ldmg = random(1, 9); //(random() + random() + random()) * 3;
	T_Damage (self.enemy, self, self, ldmg);
}


void AI_RunMelee()
{
	self.ideal_yaw = enemy_yaw;
	ChangeYaw();

	if (FacingIdeal())
	{
		self.th_melee();
		self.attack_state = AS_STRAIGHT;
	}
}


float CheckAttack()
{
	float chance;
	entity targ = self.enemy;
	
	// check if entities block the shot
	
	traceline(self.origin + self.view_ofs, targ.origin + targ.view_ofs, FALSE, self);
	if(trace_ent != targ) return FALSE;				// don't have a clear shot
	if(trace_inopen && trace_inwater) return FALSE;


	// melee attack
	if(enemy_range == RANGE_MELEE)
	{	
		if (self.th_melee)
		{
			self.th_melee();
			return TRUE;
		}
	}
	
// missile attack
	if (!self.th_missile) return FALSE;
	if (time < self.attack_finished) return FALSE;
	if (enemy_range == RANGE_FAR) return FALSE;
		
	if (enemy_range == RANGE_MELEE)
	{
		chance = 0.9;
		self.attack_finished = 0;
	}
	else if (enemy_range == RANGE_NEAR)
	{
		if (self.th_melee) chance = 0.2;
		else chance = 0.4;
	}
	else if (enemy_range == RANGE_MID)
	{
		if (self.th_melee) chance = 0.05;
		else chance = 0.1;
	}
	else chance = 0;

	if (random() < chance)
	{
		self.th_missile();
		self.attack_finished = time + 2 * random();
		return TRUE;
	}

	return FALSE;
};

