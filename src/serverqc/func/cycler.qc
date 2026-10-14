
#define CYCLER_MAX_FRAMES   32  // wrap-around upper bound for framegroup index

.float cycler_animate;
.float cycler_maxFrame_cs;  
.float cycler_lastTime_cs;
.string cycler_weapon_model;
.float cycler_weapon_sequence;
.float cycler_weapon_maxsequence;

void Item_Finish();

// cycler
void Cycler_Think()
{
	self.nextthink = time + 0.1;
}

void Cycler_AdvanceFrame()
{
	self.frame = self.frame + 1;
	if (self.frame >= CYCLER_MAX_FRAMES)
		self.frame = 0;
	dprint("cycler: frame "); dprint(ftos(self.frame)); dprint("\n");
}

void Cycler_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	self.cycler_animate = !self.cycler_animate;
	if (self.cycler_animate)
		Cycler_AdvanceFrame();
}

void Cycler_Use()
{
	Cycler_UseHL(activator, world, USE_TOGGLE, 0);
}

float Cycler_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	Cycler_AdvanceFrame();
	self.health = 100000;	//invulnerable
	return 0;
}

void cycler()
{
	if (!self.model || self.model == "")
	{
		dprint("cycler at "); dprint(vtos(self.origin));
		dprint(" missing modelname\n");
		remove(self);
		return;
	}

    self.model = strireplace(".mdl", ".iqm", self.model);

	precache_model(self.model);
	setmodel(self, self.model);
	setsize(self, '-16 -16 0', '16 16 72');

	self.solid       = SOLID_SLIDEBOX;
	self.movetype    = MOVETYPE_NONE;
	self.takedamage  = DAMAGE_YES;
	self.health      = 80000;
	self.yaw_speed   = 5;
	self.ideal_yaw   = self.angles_y;
	self.effects     = 0;
	self.cycler_animate   = 1;
	self.frame       = 0;

	self.use         = Cycler_Use;
	self.usehl       = Cycler_UseHL;
	self.takeDmgFn   = Cycler_TakeDamage;
	self.object_caps = FCAP_IMPULSE_USE;

	self.think       = Cycler_Think;
	self.nextthink   = time + 1.0;
}

// cycler_sprite
void CyclerSprite_Animate(float frames)
{
	self.frame = self.frame + frames;
	if (self.cycler_maxFrame_cs > 0)
		self.frame = mod(self.frame, self.cycler_maxFrame_cs);
}

void CyclerSprite_Think()
{
	if (self.cycler_animate && self.cycler_maxFrame_cs > 1.0)
		CyclerSprite_Animate(self.framerate * (time - self.cycler_lastTime_cs));

	self.nextthink   = time + 0.1;
	self.cycler_lastTime_cs = time;
}

void CyclerSprite_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	self.cycler_animate = !self.cycler_animate;
	dprint("Sprite: "); dprint(self.model); dprint("\n");
}

void CyclerSprite_Use()
{
	CyclerSprite_UseHL(activator, world, USE_TOGGLE, 0);
}

float CyclerSprite_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType)
{
	if (self.cycler_maxFrame_cs > 1.0)
		CyclerSprite_Animate(1.0);
	return 1;
}

void cycler_sprite()
{
	self.solid       = SOLID_SLIDEBOX;
	self.movetype    = MOVETYPE_NONE;
	self.takedamage  = DAMAGE_YES;
	self.effects     = 0;
	self.frame       = 0;
	self.cycler_animate   = 1;
	self.cycler_lastTime_cs = time;

	if (!self.framerate) self.framerate = 10;

	precache_model(self.model);
	setmodel(self, self.model);

	self.cycler_maxFrame_cs = MODEL_FRAMES(self.modelindex) - 1;
	self.use         = CyclerSprite_Use;
	self.usehl       = CyclerSprite_UseHL;
	self.takeDmgFn   = CyclerSprite_TakeDamage;
	self.object_caps = FCAP_IMPULSE_USE;

	self.think       = CyclerSprite_Think;
	self.nextthink   = time + 0.1;
}

// cycler_wreckage
.float cycler_startTime;

void Wreckage_Think()
{
	self.nextthink = time + 0.2;

	if (self.dmgtime && self.dmgtime < time)
	{
		remove(self);
		return;
	}
}

void cycler_wreckage()
{
	self.solid      = SOLID_NOT;
	self.movetype   = MOVETYPE_NONE;
	self.takedamage = 0;
	self.frame      = 0;

	if (self.model && self.model != "")
	{
		precache_model(self.model);
		setmodel(self, self.model);
	}

	self.effects     = self.effects | EF_FLAME;  // engine-side fire
	self.cycler_startTime = time;

	self.think       = Wreckage_Think;
	self.nextthink   = time + 0.1;
}

void CyclerWeapon_PrimaryAttack()
{
	self.weaponframe = self.cycler_weapon_sequence;
	self.attack_finished = time + 0.3;
	self.think = Player_Think;
	self.nextthink = time + 0.3;
}

void CyclerWeapon_SecondaryAttack()
{
	self.cycler_weapon_sequence = self.cycler_weapon_sequence + 1;
	if (self.cycler_weapon_sequence >= 8)
		self.cycler_weapon_sequence = 0;
	if (self.cycler_weapon_maxsequence > 0 && self.cycler_weapon_sequence >= self.cycler_weapon_maxsequence)
		self.cycler_weapon_sequence = 0;

	self.weaponframe = self.cycler_weapon_sequence;
	self.attack_finished = time + 0.3;
	self.think = Player_Think;
	self.nextthink = time + 0.3;
}

void CyclerWeapon_Switch()
{
	self.weaponframe = 0;
	self.reload = TRUE;
	self.attack_finished = time + 1.0;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

void CyclerWeapon_Select()
{
	if (!self.cycler_weapon_model || self.cycler_weapon_model == "")
		self.cycler_weapon_model = "models/v_crowbar.iqm";
	if (self.cycler_weapon_maxsequence <= 0)
		self.cycler_weapon_maxsequence = 8;

	self.currentClip = 1;
	self.currentammo = 1;
	self.weaponmodel = self.cycler_weapon_model;
	self.weaponframe = self.cycler_weapon_sequence;
	self.weaponSwitch = CyclerWeapon_Switch;
	self.weaponAttack = CyclerWeapon_PrimaryAttack;
	self.weaponAttack2 = CyclerWeapon_SecondaryAttack;
	self.weaponReload = SUB_Null;
	self.weaponSelect = CyclerWeapon_Select;
}

void CyclerWeapon_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;

	other.cycler_weapon_model = self.model;
	other.cycler_weapon_sequence = self.frame;
	other.cycler_weapon_maxsequence = MODEL_FRAMES(self.modelindex);
	if (other.cycler_weapon_maxsequence <= 0 || other.cycler_weapon_maxsequence > 8)
		other.cycler_weapon_maxsequence = 8;

	other.items = other.items | WEAPON_CYCLER;
	other.weapons = other.weapons | WEAPON_CYCLER;
	if (!other.reload)
		other.impulse = WID_CYCLER;

	sprint(other, "You got the weapon cycler\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");

	if (cvar("gamemode") == MODE_COOP) return;
	Item_Finish();
}

void cycler_weapon()
{
	if (!self.model)
	{
		dprint("cycler_weapon at "); 
		dprint(vtos(self.origin));
		dprint(" missing model\n");
		remove(self);
		return;
	}

	precache_model(self.model);
	precache_sound("items/gunpickup2.wav");
	setmodel(self, self.model);
	setsize(self, '-16 -16 0', '16 16 16');
	setorigin(self, self.origin);

	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_NONE;
	self.touch = CyclerWeapon_Touch;
	self.frame = 0;
}
