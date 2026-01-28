void(entity targ, entity attacker) ClientObituary;
void() monster_death_use;

void(entity targ, entity attacker) ClientObituary
{

}
void monster_death_use()
{

}

#define TakeHeal T_Heal
#define Combat_Heal T_Heal
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0) return 0;
	if (!ignore && e.health >= e.max_health) return 0;
	healamount = ceil(healamount);
	
	e.health = e.health + healamount;
	if (!ignore && e.health >= e.max_health) e.health = e.max_health;
	
	if (e.health > 250) e.health = 250;
	return 1;
};


/*
============
Killed
============
*/
void Combat_Killed(entity attacker)
{
	if (self.health < -99) self.health = -99; // don't let sbar look bad if a player
	if (self.movetype == MOVETYPE_PUSH || self.movetype == MOVETYPE_NONE) // doors, triggers, etc
	{
		if(self.th_die) self.th_die();
		return;
	}

	self.enemy = attacker;

	// bump the monster counter
	if (self.flags & FL_MONSTER)
	{
		killed_monsters = killed_monsters + 1;
		WriteByte(MSG_ALL, SVC_KILLEDMONSTER);
	}
		
	ClientObituary(self, attacker);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;

	monster_death_use();
	if(self.th_die) self.th_die();
};

#define Combat_CanDamage CanDamage
float CanDamage(entity targ, entity inflictor)
{
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1) return TRUE;
		if (trace_ent == targ) return TRUE;
		return FALSE;
	}

	traceline(inflictor.origin, targ.origin, TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;
	traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	if (trace_fraction == 1) return TRUE;

	return FALSE;
}
void FoundTarget()
{

}


void T_Damage(entity targ, entity inflictor, entity attacker, float damage)
{
	if (!targ.takedamage) return;

	// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

	if (targ.classname == "player" && !deathmatch && !skill) damage = rint(damage * 0.75);
	if (attacker.super_damage_finished > time) damage = damage * 4; // check for quad damage powerup on the attacker

	// save damage based on the target's armor level
	float save = ceil(targ.armortype * damage);
	if (save >= targ.armorvalue)
	{
		save = targ.armorvalue;
		targ.armortype = 0; // lost all armor
		targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
	}

	targ.armorvalue = targ.armorvalue - save;
	float take = ceil(damage - save);

// add to the damage total for clients, which will be sent as a single
// message at the end of the frame
// FIXME: remove after combining shotgun blasts?
	if (targ.flags & FL_CLIENT)
	{
		targ.dmg_take = targ.dmg_take + take;
		targ.dmg_save = targ.dmg_save + save;
		targ.dmg_inflictor = inflictor;
	}

	// figure momentum add
	if (inflictor != world && targ.movetype != MOVETYPE_NONE && targ.movetype != MOVETYPE_NOCLIP && targ.classname != "monster_snork" /*&& (targ.movetype == MOVETYPE_WALK)*/)
	{
		vector dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		targ.velocity = targ.velocity + dir * damage * PUSHING_FACTOR;
	}

	if (targ.flags & FL_GODMODE) return; // check for godmode or invincibility
	if (teamplay && targ.classname == "player" && attacker.classname == "player" && targ.team == attacker.team && targ != attacker) return; // team play damage avoidance
	


	// react to the damage
	entity oldself = self;
	self = targ;

	if ((self.flags & FL_MONSTER) && attacker != world)
	{
		if (self != attacker && attacker != self.enemy) // get mad unless of the same class(except for soldiers)
		{
			if (self.classname != attacker.classname)
			{
				if (self.enemy.classname == "player") self.oldenemy = self.enemy;
				self.enemy = attacker;
				FoundTarget();
			}
		}
	}
	
	targ.health = targ.health - take;
	if (targ.health <= 0)
	{
		Combat_Killed(attacker);
		self = oldself;
		return;
	}

	if (self.th_pain)
	{
		self.th_pain(attacker, take);
		if (skill == 3) self.pain_finished = time + 5; // nightmare mode monsters don't go into pain frames often
	}

	self = oldself;
};

#define Combat_TakeDamage TakeDamage
void TakeDamage(entity targ, entity inflictor, entity attacker, float damage, float damageType = 0)
{

}

#define Combat_RadiusDamage T_RadiusDamage
void T_RadiusDamage(entity inflictor, entity attacker, float damage, float radius)
{
	entity head = findradius(inflictor.origin, radius);
	while (head)
	{
		if (head != world)
		{
			if (head.takedamage)
			{
				vector org = head.origin + (head.mins + head.maxs) * 0.5;
				float dist = vlen(inflictor.origin - org);
				float dmg = damage * (1 - (dist / radius));
				if (head == attacker) dmg = dmg * 0.4;
				if (dmg > 0 && Combat_CanDamage(head, inflictor))
				{
					T_Damage(head, inflictor, attacker, dmg);
				}
			}
		}
		head = head.chain;
	}
};


void Shrapnel_Touch()
{
	if (other == self.owner) return;
	if (other.solid == SOLID_TRIGGER) return;	// trigger field, do nothing
	if (pointcontents(self.origin) == CONTENT_SKY)
	{
		remove(self);
		return;
	}	

	if (other.takedamage) // hit something that bleeds
	{
        makevectors(self.v_angle);
		ShootBlood (other.origin,v_forward * 2000);
        T_Damage (other, self, self, 20);
	}
	else
	{
		te_spike(self.origin);
	}
	remove(self);
};

void Shrapnel_Shoot(vector org, vector dir)
{
	newmis = spawn();
	newmis.owner = self.owner;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.angles = vectoangles(dir);
	newmis.touch = Shrapnel_Touch;
    newmis.classname = "shrapnel";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 1.5;
	setmodel (newmis, "models/weapons/shrap.md3");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);
	newmis.modelflags = MF_GRENADE;
	newmis.velocity = dir * 3;
};



void Combat_Explode(float damage, float radius)
{
	T_RadiusDamage(self, self.owner, 155, 250);
	te_explosion(self.origin);
	for (float i = 0; i < 17; i = i + 1)	
	{
		vector shrapdir = randomvec() * random(120, 200);
		Shrapnel_Shoot(self.origin , shrapdir);
	}
	sound (self, CHAN_WEAPON, "weapons/grenade/explosion.wav", 1, SoundRadius(3500));
	remove(self);
};


/*
	==============================================================================
	
	MULTI-DAMAGE
	
	Collects multiple small damages into a single damage
	
	==============================================================================
*/

entity	multi_ent;
float	multi_damage;

void ClearMultiDamage()
{
	multi_ent = world;
	multi_damage = 0;
}

void ApplyMultiDamage() 
{
	if (!multi_ent) return;
	T_Damage(multi_ent, self, self, multi_damage);
}

void AddMultiDamage(entity hit, float damage)
{
	if (!hit) return;
	if (hit != multi_ent)
	{
		ApplyMultiDamage();
		multi_damage = damage;
		multi_ent = hit;
	}
	else multi_damage = multi_damage + damage;
};


float Combat_DetectHitbox(float damage)
{
	if (trace_ent.absmax_z - trace_endpos_z <= 13 && !trace_ent.crouching) //headshot
	{
		damage = rint(damage * 1.7);
		trace_ent.hitbox = HITBOX_HEAD;
	}
	else if(trace_ent.crouching && trace_ent.absmax_z - trace_endpos_z <= 6)
	{
		damage = rint(damage * 1.7);
		trace_ent.hitbox = HITBOX_HEAD;
	}
	else if (trace_ent.absmax_z - trace_endpos_z > 30)	//legshot
	{
		trace_ent.hitbox = HITBOX_LEGS;
		damage = rint(damage * 0.7);
	}
	else trace_ent.hitbox = HITBOX_BODY;
	return damage;
}


void Combat_TraceAttack(float damage, vector dir)
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY || trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)return;
	
	vector vel = normalize(dir + v_up * random(-1, 1) + v_right * random(-1, 1));
	vel = vel + trace_plane_normal * 2;
	vel = vel * 200;
	
	vector org = trace_endpos - dir * 4;
	
	// if(self.weapon == WP_KNIFE) 
	// {
		// if((trace_ent.flags & FL_MONSTER) && (trace_ent.flags & FL_CLIENT)) sound(self, CHAN_WEAPON, "weapons/knife/hit.wav", 1, ATTN_IDLE);
		// else sound(self, CHAN_WEAPON, "weapons/knife/miss.wav", 1, ATTN_IDLE);
	// }
	
	if(trace_ent.takedamage) 
	{
		damage = Combat_DetectHitbox(damage);
		if(trace_ent.traceAttack)
		{
			trace_ent.traceAttack(damage, org, dir);
			// ImpactSoundSurface(trace_endpos);
			return;
		}
		// if(DetectObject(damage, org, dir))
		// {
			// ImpactSoundSurface(trace_endpos);
			// return;
		// }
		
		
		if(self.weapon == WP_KNIFE)
		{
			trace_ent.axhitme = 1;
			sound(self, CHAN_WEAPON, "weapons/knife/hit.wav", 1, ATTN_NORM);
		}
		
		//spawn blood if thing is allive
		if(trace_ent.flags & FL_MONSTER || trace_ent.flags & FL_CLIENT) 
		{
			vector meatdir = randomvec() * 300;
			makevectors(self.v_angle);
			
			if(random() < 0.7 && damage >= 6) 
			{
				SpawnBlood(org, vel * 0.2, damage * 100); 
			}
			
			if(damage >= 20)
			{
				SpawnBlood(org + '10 10 0', v_forward * 200, 10); 
				SpawnBlood(org, v_forward * 200, 10); 
			}
			// ImpactSoundBody(trace_endpos);
		}
		else
		{
			// ImpactSoundSurface(trace_endpos);
		}
	
		AddMultiDamage(trace_ent, damage);
		
	}
	else if(trace_ent.solid == SOLID_CORPSE)
	{
		SpawnBlood(org, vel * 0.2, damage * 100);
		trace_ent.health = trace_ent.health - damage;
		if(trace_ent.health < -250)
		{
			entity oldself = self;
			self = trace_ent;
			Gib();
			self = oldself;
		}
		// ImpactSoundBody(trace_endpos);
	}
	else 
	{
		// ImpactSoundSurface(trace_endpos);
		if(self.weapon == WP_KNIFE) te_spike(org);
		else te_gunshot(org);
	}
};



