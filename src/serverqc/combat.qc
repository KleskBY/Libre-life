void(entity targ, entity attacker) ClientObituary;	// obituary.qc
void() monster_death_use;

void FoundTarget();

float damage_kill_type;

float Monster_ShouldGib(float dmgType, float health)
{
	if (dmgType & DMG_ALWAYSGIB) return TRUE;
	if (dmgType & DMG_NEVERGIB)  return FALSE;
	return (health < GIB_HEALTH_VALUE);
}

#define Combat_Heal T_Heal
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0) return 0;
	if (!ignore && e.health >= e.max_health) return 0;
	healamount = ceil(healamount);
	
	e.health = e.health + healamount;
	if (!ignore && e.health >= e.max_health) e.health = e.max_health;
	
	if (e.health > 200) e.health = 200;
	return 1;
};


void CorpseFade_Think()
{
	entity c = self.enemy;
	if (!c || wasfreed(c) || c.classname != self.netname || c.health > 0)
	{
		remove(self);
		return;
	}
	c.alpha = c.alpha - 0.05;
	if (c.alpha <= 0.05)
	{
		remove(c);
		remove(self);
		return;
	}
	self.nextthink = time + 0.1;
}

void Monster_ScheduleCorpseFade(entity corpse)
{
	entity w = spawn();
	w.classname = "corpse_fader";
	w.enemy     = corpse;
	w.netname   = corpse.classname;   // recycle guard for CorpseFade_Think
	corpse.alpha = 1;
	w.think     = CorpseFade_Think;
	w.nextthink = time + 3;           // let the death anim settle first
}

void BodyDrop_Think()
{
	entity c = self.enemy;
	if (!c || wasfreed(c) || c.classname != self.netname || c.health > 0)
	{
		remove(self);
		return;
	}
	if ((c.flags & FL_ONGROUND) || time > self.ltime)
	{
		Sound_Play(c, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, "common/bodydrop3.wav", "common/bodydrop4.wav");
		remove(self);
		return;
	}
	self.nextthink = time + 0.1;
}

void Monster_ScheduleBodyDrop(entity corpse)
{
	entity w = spawn();
	w.classname = "bodydrop_watcher";
	w.enemy     = corpse;
	w.netname   = corpse.classname;   // recycle guard for BodyDrop_Think
	w.ltime     = time + 3;           // fallback: play even if never onground
	w.think     = BodyDrop_Think;
	w.nextthink = time + 0.6;         // mid death anim, body reaching floor
}

void Combat_Killed(entity attacker)
{
	if (self.health < -99) self.health = -99; // don't let sbar look bad if a player
	GlobalState_MarkEntityDead(self);
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

		Monster_CheckAITriggerDeath();

		if (self.spent_token)
			Spent_Mark(self);

		if (self.owner.classname == "monstermaker" && self.owner.monster_liveChildren > 0)
			self.owner.monster_liveChildren = self.owner.monster_liveChildren - 1;
	}

	ClientObituary(self, attacker);

	self.takedamage = DAMAGE_NO;
	self.touch = SUB_Null;

	monster_death_use();

	if (Monster_ShouldGib(damage_kill_type, self.health))
	{
		if (self.th_gib) self.th_gib();
		else if (self.th_die) self.th_die();
	}
	else
	{
		if (self.th_die) self.th_die();
	}

	// Remember the schedule th_die just installed. A monster can be killed from inside its own think (own grenade, self-blast); when that stack unwinds the still-running think re-arms itself and clobbers this. Monster_YieldIfDead restores it on the next tick so the death animation still runs.
	if (self.modelindex)
	{
		self.monster_deathThink     = self.think;
		self.monster_deathThinkTime = self.nextthink;
	}

	if ((self.flags & FL_MONSTER) && self.modelindex && self.health <= 0
		&& (((self.spawnflags & SF_MONSTER_FADECORPSE) && !self.q1_monster)
			|| self.owner.classname == "monstermaker"))
		Monster_ScheduleCorpseFade(self);

	if ((self.flags & FL_MONSTER) && self.modelindex && self.health <= 0)
		Monster_ScheduleBodyDrop(self);
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

float Monster_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType);
float Player_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType);

void T_Damage(entity targ, entity inflictor, entity attacker, float damage, float damageType = 0)
{
	if (!targ.takedamage) return;

	// used by buttons and triggers to set activator for target firing
	damage_attacker = attacker;

	if (attacker.classname == "player" &&
	    (attacker.items & IT_QUAD) && attacker.super_damage_finished > time)
		damage *= 4;

	if (targ.takeDmgFn)
	{
		entity oldself2 = self;
		self = targ;
		targ.takeDmgFn(inflictor, attacker, damage, damageType);
		self = oldself2;
		return;
	}

	if (targ.classname == "player" && !deathmatch && !skill) damage = rint(damage * 0.75);

	// Club damage (crowbar) is instant-kill against barnacles
	if ((damageType & DMG_CLUB) && targ.classname == "monster_barnacle")
		damage = targ.health;

	float save = 0;
	float take = ceil(damage);
	if (!(damageType & (DMG_FALL | DMG_DROWN | DMG_SHOCK)))
	{
		save = ceil(targ.armortype * damage);
		if (save >= targ.armorvalue)
		{
			save = targ.armorvalue;
			targ.armortype = 0;
			targ.items = targ.items - (targ.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		}
		targ.armorvalue = targ.armorvalue - save;
		take = ceil(damage - save);
	}

	if (targ.flags & FL_CLIENT)
	{
		targ.dmg_take = targ.dmg_take + take;
		targ.dmg_save = targ.dmg_save + save;
		targ.dmg_inflictor = inflictor;
	}

	if (inflictor != world && targ.movetype != MOVETYPE_NONE && targ.movetype != MOVETYPE_NOCLIP && targ.classname != "monster_snork" /*&& (targ.movetype == MOVETYPE_WALK)*/)
	{
		vector dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		targ.velocity = targ.velocity + dir * damage * PUSHING_FACTOR;
	}

	if (targ.flags & FL_GODMODE) return;
	if (teamplay && targ.classname == "player" && attacker.classname == "player" && targ.team == attacker.team && targ != attacker) return;
	

	entity oldself = self;
	self = targ;

	if ((self.flags & FL_MONSTER) && attacker != world && (self.q1_monster || !(self.spawnflags & SF_MONSTER_PRISONER)))
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
		damage_kill_type = damageType;
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
	T_Damage(targ, inflictor, attacker, damage, damageType);
}

//
// Polymorphic TakeDamage handlers
//

float Monster_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	if (!deathmatch && !skill) damage = rint(damage * 0.75);

	// DMG_CLUB (crowbar) instakills barnacles.
	if ((dmgType & DMG_CLUB) && self.classname == "monster_barnacle")
		damage = self.health;

	float take = ceil(damage);

	if (inflictor != world
		&& self.movetype != MOVETYPE_NONE
		&& self.movetype != MOVETYPE_NOCLIP
		&& self.classname != "monster_snork")
	{
		vector dir = self.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		self.velocity = self.velocity + dir * damage * PUSHING_FACTOR;
	}

	if (self.flags & FL_GODMODE) return 0;

	if (self.monster_isAsleep)
	{
		self.monster_isAsleep = FALSE;
		self.monster_state = MONSTERSTATE_ALERT;
		if (!self.q1_monster)
			self.spawnflags = self.spawnflags & ~SF_MONSTER_WAIT_TILL_SEEN;
	}
	if (!self.q1_monster)
		self.spawnflags = self.spawnflags & ~SF_MONSTER_WAIT_FOR_SCRIPT;

	if ((self.q1_monster || !(self.spawnflags & SF_MONSTER_PRISONER)) && attacker != world && self != attacker && attacker != self.enemy
		&& (self.th_run || self.th_missile))
	{
		if (self.classname != attacker.classname)
		{
			if (self.enemy.classname == "player") self.oldenemy = self.enemy;
			self.enemy = attacker;
			FoundTarget();
		}
	}

	self.health = self.health - take;
	if (self.health <= 0)
	{
		damage_kill_type = dmgType;
		Combat_Killed(attacker);
		return 1;
	}

	if (self.th_pain)
	{
		self.th_pain(attacker, take);
		if (skill == 3) self.pain_finished = time + 5;	// nightmare: less pain stagger
	}
	return 1;
}

float Player_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	if (teamplay && attacker.classname == "player"
		&& self.team == attacker.team && self != attacker) return 0;

	if (self.flags & FL_GODMODE) return 0;
	if ((self.items & IT_INVULNERABILITY) && self.invincible_finished > time) return 0;

	// Armor bypass for fall, drown, shock (already true in legacy T_Damage).
	float save = 0;
	if (!(dmgType & (DMG_FALL | DMG_DROWN | DMG_SHOCK)) && self.armorvalue > 0)
	{
		float flNew = damage * ARMOR_RATIO;
		float flArmor = (damage - flNew) * ARMOR_BONUS;
		if (flArmor > self.armorvalue)
		{
			flArmor = self.armorvalue;
			flArmor = flArmor * (1.0 / ARMOR_BONUS);
			flNew = damage - flArmor;
			self.armorvalue = 0;
			self.items = self.items - (self.items & (IT_ARMOR1 | IT_ARMOR2 | IT_ARMOR3));
		}
		else
		{
			self.armorvalue = self.armorvalue - flArmor;
		}
		save = damage - flNew;
		damage = flNew;
	}

	float take = ceil(damage);

	self.dmg_take = self.dmg_take + take;
	self.dmg_save = self.dmg_save + save;
	self.dmg_inflictor = inflictor;

	if (dmgType & DMG_SHOWNHUD)
	{
		self.dmg_shownhud_bits = self.dmg_shownhud_bits | (dmgType & DMG_SHOWNHUD);
		self.dmg_shownhud_time = time + 0.5;
	}

	// Momentum push on the player.
	if (inflictor != world && self.movetype != MOVETYPE_NONE && self.movetype != MOVETYPE_NOCLIP)
	{
		vector dir = self.origin - (inflictor.absmin + inflictor.absmax) * 0.5;
		dir = normalize(dir);
		self.velocity = self.velocity + dir * damage * PUSHING_FACTOR;
	}

	if (attacker != world && attacker != self)
		self.last_attacker_dir = normalize(attacker.origin - self.origin);

	self.health = self.health - take;
	if (self.health <= 0)
	{
		damage_kill_type = dmgType;
		Combat_Killed(attacker);
		return 1;
	}

	if (self.th_pain)
		self.th_pain(attacker, take);

	return 1;
}

void T_RadiusDamage(entity inflictor, entity attacker, float damage, float radius, float dmgType = DMG_BLAST)
{
	entity head = Chain_Freeze(findradius(inflictor.origin, radius));
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
					T_Damage(head, inflictor, attacker, dmg, dmgType);
				}
			}
		}
		head = head.dmg_chain;
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

	if (other.takedamage)
	{
        makevectors(self.v_angle);
		// Color-aware: aliens bleed alien blood (ShootBlood hardcodes red).
		float shrapBlood = Blood_ColorFor(other);
		if (shrapBlood)
			Blood_SpawnImpact(other.origin, v_forward * 2000, shrapBlood, 10);
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
	entity newmis = spawn();
	newmis.owner = self.owner;
	newmis.movetype = MOVETYPE_BOUNCE;
	newmis.solid = SOLID_BBOX;
	newmis.angles = vectoangles(dir);
	newmis.touch = Shrapnel_Touch;
    newmis.classname = "shrapnel";
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 1.5;
	setmodel (newmis, "models/shrap.md3");
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, org);
	newmis.modelflags = MF_GRENADE;
	newmis.velocity = dir * 3;
};


void Combat_Explode(float damage, float radius)
{
	if (damage > 0 && radius > 0)
		T_RadiusDamage(self, self.owner, damage, radius);
	te_explosion(self.origin);
	for (float i = 0; i < 17; i = i + 1)	
	{
		vector shrapdir = randomvec() * random(120, 200);
		Shrapnel_Shoot(self.origin , shrapdir);
	}
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(3500), PITCH_NORM, "weapons/explode3.wav");
	remove(self);
};

void env_explosion();
void Combat_ExplosionCreate(vector center, vector ang, entity pOwner, float magnitude, float doDamage)
{
	entity pExplosion = spawn();
	setorigin(pExplosion, center);
	pExplosion.angles = ang;
	pExplosion.owner = pOwner;
	pExplosion.iMagnitude = magnitude;
	if (!doDamage) pExplosion.spawnflags |= SF_ENVEXPLOSION_NODAMAGE;
	entity oself = self;
	self = pExplosion;
	env_explosion();
	if (self.usehl)
		self.usehl(pOwner, self, USE_TOGGLE, 0);
	else if (self.use)
		self.use();
	self = oself;
}


entity	multi_ent;
float	multi_damage;
float	multi_dmgType;

void ClearMultiDamage()
{
	multi_ent = world;
	multi_damage = 0;
	multi_dmgType = 0;
}

void ApplyMultiDamage()
{
	if (!multi_ent) return;
	T_Damage(multi_ent, self, self, multi_damage, multi_dmgType);
	multi_ent = world;
	multi_damage = 0;
	multi_dmgType = 0;
}

void AddMultiDamage(entity hit, float damage, float dmgType)
{
	if (!hit) return;
	if (hit != multi_ent || dmgType != multi_dmgType)
	{
		ApplyMultiDamage();
		multi_damage = damage;
		multi_ent = hit;
		multi_dmgType = dmgType;
	}
	else multi_damage = multi_damage + damage;
};


.float hitbox_time;    // frame the zone above was measured, see Combat_TraceAttack

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


void Combat_TraceAttack(float damage, vector dir, float dmgType)
{
	if(trace_dphitq3surfaceflags & Q3SURFACEFLAG_SKY || trace_dphitq3surfaceflags & Q3SURFACEFLAG_NOIMPACT)return;

	vector vel = normalize(dir + v_up * random(-1, 1) + v_right * random(-1, 1));
	vel = vel + trace_plane_normal * 2;
	vel = vel * 200;

	vector org = trace_endpos - dir * 4;

	entity hitEnt = trace_ent;

	if(hitEnt.takedamage)
	{
		damage = Combat_DetectHitbox(damage);
		hitEnt.hitbox_time = time;

		float owned = FALSE;
		if(hitEnt.traceAttack)
		{
			entity oself = self;
			self = hitEnt;
			self.traceAttack(oself, damage, dir, dmgType);
			self = oself;
			owned = TRUE;
		}

		float bloodColor = Blood_ColorFor(hitEnt);
		if (bloodColor)
		{
			if (owned) return;
			Blood_SpawnImpact(org, dir, bloodColor, damage);
			Blood_TraceBleed(hitEnt, trace_endpos, dir, damage, dmgType);
		}
		else
		{
			if (dmgType & DMG_CLUB) te_spike(org);
			else te_gunshot(org);
			if (hitEnt.monster_bloodColor < 0)
				te_spark(org, -dir, Math_RandomInt(3, 8));
		}

		if (!owned) AddMultiDamage(hitEnt, damage, dmgType);
	}
	else if(hitEnt.solid == SOLID_CORPSE)
	{
		float corpseBloodColor = Blood_ColorFor(hitEnt);
		if (corpseBloodColor)
			Blood_SpawnImpact(org, dir, corpseBloodColor, damage);
		hitEnt.health = hitEnt.health - damage;
		if(hitEnt.health < GIB_HEALTH_VALUE * 2)
		{
			entity oldself = self;
			self = hitEnt;
			Gib();
			self = oldself;
		}
	}
	else
	{
		if (dmgType & DMG_CLUB) te_spike(org);
		else te_gunshot(org);
	}
};

float Combat_DamageForce(float damage)
{
    float sz = (self.size_x * self.size_y * self.size_z);
    if (sz <= 0) sz = 1;
    float force = damage * ((32.0 * 32.0 * 72.0) / sz) * 5.0;
    if (force > 1000.0) force = 1000.0;
    return force;
}

entity Combat_CheckTraceHullAttack(float flDist, float iDamage, float iDmgType)
{
	makevectors(self.angles);

	vector vecSrc = self.origin + self.view_ofs;
	if (vecSrc == self.origin)
		vecSrc = self.origin + Math_GetCenterOffset(self);

	vector vecDest = vecSrc + (v_forward * flDist);

	traceline(vecSrc, vecDest, FALSE, self);
	if (trace_ent != world && trace_ent.takedamage != DAMAGE_NO)
	{
		entity pHurt = trace_ent;
		if (iDamage > 0)
			Combat_TakeDamage(pHurt, self, self, iDamage, iDmgType);
		return pHurt;
	}

	tracebox(vecSrc, '-16 -16 -16', '16 16 16', vecDest, FALSE, self);
	if (trace_ent != world && trace_ent.takedamage != DAMAGE_NO)
	{
		if (iDamage > 0)
			Combat_TakeDamage(trace_ent, self, self, iDamage, iDmgType);
		return trace_ent;
	}

	entity best = world;
	float bestForward = 999999;
	entity e = findradius(vecSrc + v_forward * (flDist * 0.5), flDist);
	while (e)
	{
		if (e != self && e.takedamage != DAMAGE_NO)
		{
			vector toCenter = GetCenter(e) - vecSrc;
			float forwardDist = toCenter * v_forward;
			if (forwardDist >= 0 && forwardDist <= flDist + 16)
			{
				vector lateral = toCenter - v_forward * forwardDist;
				if (vlen(lateral) <= 24 && forwardDist < bestForward)
				{
					best = e;
					bestForward = forwardDist;
				}
			}
		}
		e = e.chain;
	}

	if (best != world)
	{
		if (iDamage > 0)
			Combat_TakeDamage(best, self, self, iDamage, iDmgType);
		return best;
	}

	return world;
}

void DelayedMeleeThink()
{
	if(!IsAlive(self)) return;
	if(!self.owner.enemy) return;		// removed before stroke
	if(!IsAlive(self.owner.enemy)) return;
	vector dist = self.owner.enemy.origin - self.owner.origin;
	if (vlen(dist) > 90) return;
	float ldmg = random(1, 12); //(random() + random() + random()) * 4;
	T_Damage (self.owner.enemy, self.owner, self.owner, ldmg);
}

void Combat_Melee(entity attacker, entity targ, float dmg, float t)
{
	entity atk = spawn();
	atk.owner = attacker;
	atk.movetype = MOVETYPE_FOLLOW;
	
	atk.nextthink = time + t;
	atk.think = DelayedMeleeThink;
}
