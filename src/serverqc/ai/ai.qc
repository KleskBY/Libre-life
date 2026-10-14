
float enemy_vis, enemy_infront, enemy_range;
float enemy_yaw;

entity sight_entity;
float  sight_entity_time;

float Monster_Range(entity targ)
{
	vector spot1 = self.origin + self.view_ofs;
	vector spot2 = targ.origin + targ.view_ofs;
	
	float r = vlen (spot1 - spot2);
	if (r < 80) return RANGE_MELEE;
	if (r < 500) return RANGE_NEAR;
	if (r < 1000) return RANGE_MID;
	return RANGE_FAR;
}


void HuntTarget()
{
	self.goalentity = self.enemy;
	if (self.th_missile && random() > 0.73 && IsVisible(self.enemy))
		self.think = self.th_missile;
	else if (self.th_run)
		self.think = self.th_run;
	self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
	self.nextthink = time + 0.1;
	self.attack_finished = time + 1; // wait a while before first attack
}

void FoundTarget()
{
	if (self.enemy.classname == "player") // let other monsters see this monster for a while
	{ 
		sight_entity = self;
		sight_entity_time = time;
	}

	self.show_hostile = time + 1; // wake up other monsters

	if(sight_entity && IsAlive(sight_entity) && self.sightSound) self.sightSound();
	HuntTarget();
}

/*
===========
FindTarget

Self is currently not attacking anything, so try to find a target

Returns TRUE if an enemy was sighted

When a player fires a missile, the point of impact becomes a fakeplayer so
that monsters that see the impact will respond as if they had seen the
player.

To avoid spending too much time, only a single client(or fakeclient) is
checked each frame.  This means multi player games will have slightly
slower noticing monsters.
============
*/
entity FindZombies()
{
	if(self.classname != "monster_grunt") return world;
	entity z = FindNearest("monster_zombie", self.origin);
	if(IsVisible(z)) return z;
	return world;
}
entity FindHumans()
{
	if(self.classname != "monster_zombie") return world;
	entity z = FindNearest("monster_grunt", self.origin);
	if(IsVisible(z)) return z;
	return world;
}

.float ignore_player_for;
float FindTarget()
{
	entity client;
	float r;

	// A scripted_sequence owning the monster prevents combat scheduling
	if (self.monster_cine && self.monster_cine != world) return FALSE;

	// Q1 monsters exempt: their spawnflag bits mean different things.
	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_PRISONER)) return FALSE;

	if (sight_entity_time >= time - 0.1 && !(self.spawnflags & SF_MONSTER_WAIT_TILL_SEEN))
	{
		client = sight_entity;
		if (client.enemy == self.enemy) return FALSE;
	}
	else
	{
		client = checkclient();
		if(client.classname == "observer") client = world;
		if(!client) return FALSE; // current check entity isn't in PVS
	}

	if (client == self.enemy) return FALSE;
	if (client.flags & FL_NOTARGET) return FALSE;
	if (client.items & IT_INVISIBILITY) return FALSE;
	if (!client.q1_monster && (client.spawnflags & SF_MONSTER_PRISONER)) return FALSE;
	if (self.ignore_player_for > time) return FALSE;

	r = Monster_Range(client);
	if (r == RANGE_FAR) return FALSE;
	if (!IsVisible(client)) return FALSE;

	if (!self.q1_monster && (self.spawnflags & SF_MONSTER_WAIT_TILL_SEEN) && client.classname == "player")
	{
		makevectors(client.v_angle);
		vector look = normalize((self.origin + self.view_ofs) - (client.origin + client.view_ofs));
		if (look * v_forward < 0.35) return FALSE;
		self.spawnflags = self.spawnflags & ~SF_MONSTER_WAIT_TILL_SEEN;
		self.monster_isAsleep = FALSE;
	}

	if (r == RANGE_NEAR)
	{
		if (client.show_hostile < time && !Math_InFront(client.origin))
			return FALSE;
	}
	else if (r == RANGE_MID)
	{
		if (!Math_InFront(client.origin)) return FALSE;
	}


	// got one
	self.enemy = client;
	if (self.enemy.classname != "player")
	{
		self.enemy = self.enemy.enemy;
		if (self.enemy.classname != "player")
		{
			self.enemy = world;
			return FALSE;
		}
	}

	FoundTarget();

	return TRUE;
}

float FacingIdeal()
{
	float delta = Math_AngleMod(self.angles_y - self.ideal_yaw);
	if (delta > 45 && delta < 315) return FALSE;
	return TRUE;
}

