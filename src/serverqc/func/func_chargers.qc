
#define CHARGER_HEALTH_CAPACITY		Skill_GetValue("sk_healthcharger", 50)
#define CHARGER_ARMOR_CAPACITY		Skill_GetValue("sk_suitcharger", 75)

.float dmdelay;

float Charger_RechargeTime(float defaultDelay)
{
	if (!IsDeathmatch()) return 0;	// SP / coop: single use
	if (self.dmdelay > 0) return self.dmdelay;
	return defaultDelay;
}

.float charger_juice;
.float charger_on;
.float charger_soundTime;
.float charger_nextCharge;
.float charger_reactivate;

//HEALTH
void HealthCharger_Precache()
{
	precache_sound("items/medshot4.wav");
	precache_sound("items/medshotno1.wav");
	precache_sound("items/medcharge4.wav");
	precache_sound("common/null.wav");
}

void HealthCharger_Recharge()
{
	Sound_Play(self, CHAN_ITEM, 1.0, ATTN_NORM, PITCH_NORM, "items/medshot4.wav");
	self.charger_juice = CHARGER_HEALTH_CAPACITY;
	self.frame = 0;
	self.think = SUB_Null;
}

void HealthCharger_Off()
{
	if (self.charger_on > 1)
		Sound_Play(self, CHAN_STATIC, 1.0, ATTN_NORM, PITCH_NORM, "common/null.wav");	// stop loop
	self.charger_on = 0;

	self.charger_reactivate = Charger_RechargeTime(60);
	if (self.charger_juice <= 0 && self.charger_reactivate > 0)
	{
		self.nextthink = self.ltime + self.charger_reactivate;
		self.think = HealthCharger_Recharge;
	}
	else
	{
		self.think = SUB_Null;
	}
}

void HealthCharger_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (pActivator == world) return;
	if (!(pActivator.flags & FL_CLIENT)) return;

	if (self.charger_juice <= 0)
	{
		self.frame = 1;
		HealthCharger_Off();
	}

	if (self.charger_juice <= 0 || !(pActivator.weapons & WEAPON_SUIT))
	{
		if (self.charger_soundTime <= time)
		{
			self.charger_soundTime = time + 0.62;
			Sound_Play(self, CHAN_ITEM, 1.0, ATTN_NORM, PITCH_NORM, "items/medshotno1.wav");
		}
		return;
	}

	self.nextthink = self.ltime + 0.25;
	self.think = HealthCharger_Off;

	if (self.charger_nextCharge >= time)
		return;

	if (!self.charger_on)
	{
		self.charger_on = 1;
		Sound_Play(self, CHAN_ITEM, 1.0, ATTN_NORM, PITCH_NORM, "items/medshot4.wav");
		self.charger_soundTime = time + 0.56;
	}
	if (self.charger_on == 1 && self.charger_soundTime <= time)
	{
		self.charger_on = 2;
		Sound_Play(self, CHAN_STATIC, 1.0, ATTN_NORM, PITCH_NORM, "items/medcharge4.wav");
	}

	entity oldself = self;
	self = pActivator;
	float gave = T_Heal(pActivator, 1, FALSE);
	self = oldself;
	
	if (gave)
		self.charger_juice = self.charger_juice - 1;

	self.charger_nextCharge = time + 0.1;
}

void func_healthcharger()
{
	HealthCharger_Precache();

	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);

	self.charger_juice = CHARGER_HEALTH_CAPACITY;
	self.frame = 0;
	self.usehl = HealthCharger_UseHL;
	self.object_caps = self.object_caps | FCAP_CONTINUOUS_USE;
}

//CHARGER
void Recharger_Precache()
{
	precache_sound("items/suitcharge1.wav");
	precache_sound("items/suitchargeno1.wav");
	precache_sound("items/suitchargeok1.wav");
	precache_sound("common/null.wav");
}

void Recharger_Recharge()
{
	self.charger_juice = CHARGER_ARMOR_CAPACITY;
	self.frame = 0;
	self.think = SUB_Null;
}

void Recharger_Off()
{
	if (self.charger_on > 1)
		Sound_Play(self, CHAN_STATIC, 1.0, ATTN_NORM, PITCH_NORM, "common/null.wav");	// stop loop
	self.charger_on = 0;

	self.charger_reactivate = Charger_RechargeTime(30);
	if (self.charger_juice <= 0 && self.charger_reactivate > 0)
	{
		self.nextthink = self.ltime + self.charger_reactivate;
		self.think = Recharger_Recharge;
	}
	else
	{
		self.think = SUB_Null;
	}
}

void Recharger_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (pActivator == world) return;
	if (pActivator.classname != "player") return;

	if (self.charger_juice <= 0)
	{
		self.frame = 1;
		Recharger_Off();
	}

	if (self.charger_juice <= 0 || !(pActivator.weapons & WEAPON_SUIT))
	{
		if (self.charger_soundTime <= time)
		{
			self.charger_soundTime = time + 0.62;
			Sound_Play(self, CHAN_ITEM, 0.85, ATTN_NORM, PITCH_NORM, "items/suitchargeno1.wav");
		}
		return;
	}

	self.nextthink = self.ltime + 0.25;
	self.think = Recharger_Off;

	if (self.charger_nextCharge >= time)
		return;

	if (!self.charger_on)
	{
		self.charger_on = 1;
		Sound_Play(self, CHAN_ITEM, 0.85, ATTN_NORM, PITCH_NORM, "items/suitchargeok1.wav");
		self.charger_soundTime = time + 0.56;
	}
	if (self.charger_on == 1 && self.charger_soundTime <= time)
	{
		self.charger_on = 2;
		Sound_Play(self, CHAN_STATIC, 0.85, ATTN_NORM, PITCH_NORM, "items/suitcharge1.wav");
	}

	if (pActivator.armorvalue < 100)
	{
		self.charger_juice = self.charger_juice - 1;
		pActivator.armorvalue = pActivator.armorvalue + 1;
		if (pActivator.armorvalue > 100)
			pActivator.armorvalue = 100;
	}

	self.charger_nextCharge = time + 0.1;
}

void func_recharge()
{
	Recharger_Precache();

	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	setorigin(self, self.origin);
	setmodel(self, self.model);

	self.charger_juice = CHARGER_ARMOR_CAPACITY;
	self.frame = 0;
	self.usehl = Recharger_UseHL;
	self.object_caps = self.object_caps | FCAP_CONTINUOUS_USE;
}
