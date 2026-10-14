
//   dmg        damage per touch (default 10)
//   delay      minimum time between hits on same entity (default 0.5)
//   spawnflags 1 = start OFF, 2 = only hurt player, 4 = no kill (clamp to 1 hp)

#define SF_TRIGGER_HURT_TARGETONCE	1
#define	SF_TRIGGER_HURT_START_OFF	2
#define	SF_TRIGGER_HURT_NO_CLIENTS	8	// spawnflag that restricts hurt to non-players
#define SF_TRIGGER_HURT_CLIENTONLYFIRE	16
#define SF_TRIGGER_HURT_CLIENTONLYTOUCH 32

.float hurt_nextdmgtime;	// per-entity next-damage timer

void TriggerHurt_Touch()
{
	if (!other.takedamage) return;
	
	if ((self.spawnflags & SF_TRIGGER_HURT_CLIENTONLYTOUCH) && other.classname != "player") 
		return;
	
	if ( (self.spawnflags & SF_TRIGGER_HURT_NO_CLIENTS) && other.classname == "player")
		return;
		
	if (self.dmgtime > time && time != self.pain_finished)
	{
		return;
	}

	if (!Trigger_Contains(self, other))
		return;

	
	float fldmg = self.dmg * 0.5;
	if ( fldmg < 0 )
	{
		float bApplyHeal = TRUE;

		if (IsMultiplayer() && other.classname == "player")
		{
			bApplyHeal = (other.deadflag == DEAD_NO);
		}

		if (bApplyHeal) 
		{
			Combat_Heal(other, -fldmg, 0);
		}
	}
	else
		Combat_TakeDamage(other, self, self, fldmg, self.damagetype );
	
	self.pain_finished = time;
	self.dmgtime = time + 0.5;
	
	if ( self.target )
	{
		if ( self.spawnflags & SF_TRIGGER_HURT_CLIENTONLYFIRE )
		{
			if (other.classname != "player")
			{
				return;
			}
		}

		SUB_UseTargetsHL(other, USE_TOGGLE, 0);
		if (self.spawnflags & SF_TRIGGER_HURT_TARGETONCE )
			self.target = 0;
	}
}


void TriggerHurt_RadiationThink()
{
	vector org = self.origin;
	vector viewofs = self.view_ofs;

	self.origin = (self.absmin + self.absmax) * 0.5;
	self.view_ofs = self.view_ofs * 0.0;

	entity pentPlayer = checkclient();

	self.origin = org;
	self.view_ofs = viewofs;

	// reset origin

	if (pentPlayer)
	{

		vector vecSpot1 = (self.absmin + self.absmax) * 0.5;
		vector vecSpot2 = (pentPlayer.absmin + pentPlayer.absmax) * 0.5;
		
		vector vecRange = vecSpot1 - vecSpot2;
		float flRange = vlen(vecRange);

		// update player's geiger counter range if current range is smaller than distance

		if (pentPlayer.geiger_range >= flRange || pentPlayer.geiger_range == 0)
			pentPlayer.geiger_range = flRange;
	}

	self.nextthink = time + 0.25;
}

void TriggerHurt_Use()
{
	if (self.solid == SOLID_NOT)
	{
		self.solid = SOLID_TRIGGER;
		// Force retouch
		force_retouch++;
	}
	else
	{
		self.solid = SOLID_NOT;
	}
	setorigin(self, self.origin);
}

void TriggerHurt_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	TriggerHurt_Use();
}

void trigger_hurt()
{
	InitTrigger();
	if (!self.dmg) self.dmg = 10;

	self.touch = TriggerHurt_Touch;
	if(self.targetname)
	{
		self.use   = TriggerHurt_Use;
		self.usehl = TriggerHurt_UseHL;
	}

	if(self.damagetype & DMG_RADIATION)
	{
		self.think = TriggerHurt_RadiationThink;
		self.nextthink = time + random(0, 0.5);
	}

	if (self.spawnflags & SF_TRIGGER_HURT_START_OFF)
		self.solid = SOLID_NOT;

	setorigin(self, self.origin);
}
