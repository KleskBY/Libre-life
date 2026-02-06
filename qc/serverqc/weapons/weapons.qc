void Player_Think();

/*
	================
	SHELL
	================
*/

void Shell_Touch() 
{
	if (other.classname == "func_door" || other.classname == "func_door_rotating") 
	{
		remove(self);
		return;
	}
	
	if (self.owner.weapon == WP_SHOTGUN) sound (self, CHAN_WEAPON, "weapons/shell2.wav", 0.5, ATTN_NORM);
	else sound (self, CHAN_WEAPON, "weapons/shell1.wav", 0.5, ATTN_NORM);
}


void Shell_Eject(string mdl, vector offset)
{	
	makevectors(self.v_angle);
	newmis = spawn();
	newmis.owner = self;
	newmis.movetype = MOVETYPE_BOUNCE;
	if (random() < 0.5) newmis.solid = SOLID_BBOX;
	else newmis.solid = SOLID_NOT;
	newmis.angles = v_forward * (random() + 1);
	newmis.classname = "shell";
	setmodel (newmis, mdl);
	setsize (newmis, VEC_ORIGIN, VEC_ORIGIN);
	setorigin (newmis, self.origin + self.view_ofs + v_forward * offset_x + v_right * offset_y + v_up * offset_z);
	newmis.avelocity_x = random(4000, 9000);
	newmis.avelocity_y = random(4000, 9000);
	newmis.velocity = (v_forward * random(10, 20)) + (v_right * random(60, 120)) + (v_up * random(70, 110));
	newmis.touch = Shell_Touch;
	newmis.think = SUB_Remove;
	newmis.nextthink = time + 1.5;
};


/*
	================
	Muzzle
	================
*/
entity Sprite_Create(string pSpriteName, vector origin, float animate);
void Weapon_Muzzleflash(vector org, float scl)
{
	newmis = spawn();
	newmis = Sprite_Create("sprites/muzzleflash.spr", org, TRUE);
	newmis.movetype = MOVETYPE_NONE;
	newmis.solid = SOLID_NOT;
	newmis.viewmodelforclient = self;
	newmis.owner = self;
	newmis.alpha = 0.7;
	newmis.effects = EF_FULLBRIGHT;
	// if(random() >= 0.5) setmodel(newmis, "models/weapons/muzzle2.md3");
	// else setmodel(newmis, "models/weapons/muzzle1.md3");
	newmis.scale = scl;
	setsize(newmis, '0 0 0', '0 0 0');
	setorigin(newmis, org);
	newmis.angles_z = random(0, 359);
	newmis.nextthink = time + 0.05;
	newmis.think = SUB_Remove;
	// Sprite_Create("sprites/muzzleflash1.spr", org, TRUE);
}





void CROWBAR_Select();
void GLOCK_Select();
void MP5_Select();
void Weapon_Update()
{
	if(self.weapon == WEAPON_CROWBAR) CROWBAR_Select();
	else if(self.weapon == WEAPON_GLOCK) GLOCK_Select();
	else if(self.weapon == WEAPON_MP5) MP5_Select();
}
void Weapon_SetCurrentAmmo()
{
	// SelectCurrentWeapon();
	Weapon_Update();
	if(self.weaponSelect) self.weaponSelect();
}


vector Weapon_Spread(vector spread)
{
	float f;
	if (self.ShootsFired <= 0) f = 1;
	else if (self.ShootsFired == 1) f = 1.5;
	else if (self.ShootsFired == 2) f = 2;
	else if (self.ShootsFired == 3) f = 3;
	else if (self.ShootsFired == 4) f = 3.5;
	else f = 5;

	if (self.state != STATE_AIM) f *= 4;
	if (self.crouching) f *= 0.75;

	return spread * f;
}

void Weapon_Fire(vector spread, float dist, float dmg)
{	
	self.total_shots = self.total_shots + 1;
	makevectors(self.v_angle + self.punchangle);
	if(self.button5) makevectors(self.v_angle);
	
	vector src = self.origin + v_forward * 10 + self.view_ofs;
	vector dir = v_forward;
	vector end = src + dir * dist - v_right * random(-1,1) * spread_x - v_up * random(-1,1) * spread_y;
	
	ClearMultiDamage();
	
	float oldSolid = self.solid; //Corpse hit fix
	self.solid = SOLID_BBOX;
	#ifdef SHOTS_HIT_MODEL
		traceline(src, end, MOVE_HITMODEL, self);
	#else
		traceline(src, end, FALSE, self);
	#endif
	self.solid = oldSolid;
	
	if (trace_fraction != 1.0)
	{
		if(trace_ent.takedamage) self.total_hits = self.total_hits + 1;
		float len = vlen(trace_endpos - self.origin);
		if (len < 250) Combat_TraceAttack(dmg, dir);
		else if (len < 350 && len >= 250) Combat_TraceAttack(dmg * 0.9, dir);
		else Combat_TraceAttack(dmg * 0.8, dir);
	}
	ApplyMultiDamage();
}

void Weapon_Attack()
{
	if (!self.button0 && !self.button6) return;
	if (self.reload) return;
    self.weaponfired = self.weapon;
	makevectors(self.v_angle);		// calculate forward angle for velocity
	self.show_hostile = time + 1;	// wake monsters up
	if(self.button0)
	{
		if(self.weaponAttack) self.weaponAttack();
	}
	if(self.button6)
	{
		if(self.weaponAttack2) self.weaponAttack2();
	}
}


void Weapon_Change() 
{
	float weaponID = 1;
	for(float i = 1; i < self.impulse; i++)
	{
		weaponID = weaponID * 2;
	}
	self.impulse = 0;
	
	if(weaponID == self.weapon) return;
	if (!(self.weapons & weaponID)) { sprint (self, "No weapon\n"); return; }
	
	float oldweap = self.weapon;
	self.weapon = weaponID;
	Weapon_SetCurrentAmmo();
	if (!self.currentammo && !self.currentClip) 
	{ 
		sprint(self, "No ammo\n"); 
		self.weapon = oldweap;
		Weapon_SetCurrentAmmo();
		return; 
	}
	
	sound(self, CHAN_AUTO, "player/switch.wav", random(0.3, 0.8), SoundRadius(400));
	if(self.weaponSwitch) self.weaponSwitch();
}

void() CheatCommand =
{
	// if (cvar("gamemode") != MODE_SP) return;
	if(!cvar("sv_cheats")) return;
	
	self.ammo9x18 = 100;
	self.ammo9x19 = 100;
	self.ammoGrenades = 100;
	self.ammo545x39 = 200;
	self.ammoShells = 100;
	self.ammo762x54 = 200;
	self.ammo9x39 = 200;
	self.ammoVog = 200;
	self.ammoBat = 200;
	self.items = self.items | IT_KEY1 | IT_KEY2;
	self.weapons = 65535;
	
	self.impulse = 0;
	Weapon_SetCurrentAmmo();
};

void() ImpulseCommands =
{
	if (self.blockSwitch) return;
	else if (self.impulse >= 1 && self.impulse <= 8) Weapon_Change();
	else if (self.impulse == 9 || self.impulse == 101) CheatCommand();
	// else if (self.impulse == 10) CycleWeaponCommand();
	// else if (self.impulse == 12) CycleWeaponReverseCommand();
	// else if (self.impulse == 14) FlashlightToggle();
	// else if (self.impulse == 15) PlayerHeal();
	else if (self.impulse == 100)
	{
		self.impulse = 0;
		if(!self.reload && self.weaponReload) self.weaponReload();
	}
}
void Weapon_Frame()
{
	if (time < self.attack_finished) return;
	ImpulseCommands();
	if (!self.button0) self.ShootsFired = 0;
	Weapon_Attack();
};


void Weapon_Reload(.float ammoType, .float clip, float clipSize)
{
    self.reload = FALSE;
    self.weaponframe = 0;

    float maxClip;
    if (self.clip > 0) maxClip = clipSize + 1; // round in chamber
    else maxClip = clipSize;    

    float needed = maxClip - self.clip;
    if (needed < 0) needed = 0;

    if (self.ammoType >= needed)
    {
        self.ammoType -= needed;
        self.clip = maxClip;
    }
    else
    {
        self.clip += self.ammoType;
        self.ammoType = 0;

        if (self.clip > maxClip) self.clip = maxClip;
    }

    self.currentClip = self.clip;

    if (self.ammoType < 0)
        self.ammoType = 0;

    Weapon_SetCurrentAmmo();
    self.think = Player_Think;
};


void CycleWeaponReverseCommand()
{

}




