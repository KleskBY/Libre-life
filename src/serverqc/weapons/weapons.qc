void Player_Think();

void CROWBAR_Select();
void GLOCK_Select();
void MP5_Select();
void SHOTGUN_Select();
void PYTHON_Select();
void CROSSBOW_Select();
void HANDGRENADE_Select();
void RPG_Select();
void SATCHEL_Select();
void TRIPMINE_Select();
void GAUSS_Select();
void EGON_Select();
void HGUN_Select();
void SNARK_Select();
void CyclerWeapon_Select();

void Weapon_RegisterSelectFuncs()
{
	weapon_select_func[WID_CROWBAR]     = CROWBAR_Select;
	weapon_select_func[WID_GLOCK]       = GLOCK_Select;
	weapon_select_func[WID_PYTHON]      = PYTHON_Select;
	weapon_select_func[WID_MP5]         = MP5_Select;
	weapon_select_func[WID_SHOTGUN]     = SHOTGUN_Select;
	weapon_select_func[WID_CROSSBOW]    = CROSSBOW_Select;
	weapon_select_func[WID_HANDGRENADE] = HANDGRENADE_Select;
	weapon_select_func[WID_RPG]         = RPG_Select;
	weapon_select_func[WID_SATCHEL]     = SATCHEL_Select;
	weapon_select_func[WID_TRIPMINE]    = TRIPMINE_Select;
	weapon_select_func[WID_GAUSS]       = GAUSS_Select;
	weapon_select_func[WID_EGON]        = EGON_Select;
	weapon_select_func[WID_HORNETGUN]   = HGUN_Select;
	weapon_select_func[WID_SNARK]       = SNARK_Select;
	weapon_select_func[WID_CYCLER]      = CyclerWeapon_Select;
}

void Weapon_Update()
{
	float id = Weapon_IDFromBit(self.weapon);
	if (id > WID_NONE && id < WID_COUNT && weapon_select_func[id])
		weapon_select_func[id]();
	if (self.weaponSelect) self.weaponSelect();
	self.viewzoom = 0;
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

void Weapon_FireStart()
{
	ClearMultiDamage();
}

void Weapon_FireShot(vector spread, float dist, float dmg, float dmgType)
{
	self.total_shots = self.total_shots + 1;
	makevectors(self.v_angle + self.punchangle);
	if(self.button5) makevectors(self.v_angle);

	vector src = self.origin + v_forward * 10 + self.view_ofs;
	vector dir = v_forward;
	vector end = src + dir * dist - v_right * random(-1,1) * spread_x - v_up * random(-1,1) * spread_y;

	float oldSolid = self.solid; // SOLID_BBOX so the trace sees SOLID_CORPSE: corpses and hitbox proxies
	self.solid = SOLID_BBOX;
	traceline(src, end, cvar("sv_hitmodel") ? MOVE_HITMODEL_4 : MOVE_NORMAL_0, self);
	self.solid = oldSolid;
	Player_HitboxResolve();   // player/torso.qc

	if (trace_fraction != 1.0)
	{
		if(trace_ent.takedamage) self.total_hits = self.total_hits + 1;
		float len = vlen(trace_endpos - self.origin);
		if (len < 250) Combat_TraceAttack(dmg, dir, dmgType);
		else if (len < 350 && len >= 250) Combat_TraceAttack(dmg * 0.9, dir, dmgType);
		else Combat_TraceAttack(dmg * 0.8, dir, dmgType);
	}
}

void Weapon_FireEnd()
{
	ApplyMultiDamage();
}

void Weapon_Fire(vector spread, float dist, float dmg)
{
	Weapon_FireStart();
	Weapon_FireShot(spread, dist, dmg, DMG_BULLET);
	Weapon_FireEnd();
}

void Weapon_Attack()
{
	if (!self.button0 && !self.button6) return;
	if (self.reload) return;
	float afStart = self.attack_finished;   // Weapon_MuzzleflashWorld only for a shot that happened
	if (self.tank_ent) return;
    self.weaponfired = self.weapon;
	makevectors(self.v_angle);
	self.show_hostile = time + 1;

	if(self.button0)
	{
		float af0 = self.attack_finished;
		if(self.weaponAttack) self.weaponAttack();
		if(self.attack_finished != af0)
			Player_AnimOnFire(self);
	}
	if(self.button6)
	{
		float af6 = self.attack_finished;
		if(self.weaponAttack2) self.weaponAttack2();
		if(self.attack_finished != af6)
			Player_AnimOnFire(self);
	}

	if (self.attack_finished != afStart) Weapon_MuzzleflashWorld();
}


void Weapon_Change()
{
	float id = self.impulse;            // impulse N == WID_N (see weapondefs.qc)
	self.impulse = 0;

	if (id <= WID_NONE || id >= WID_COUNT) return;
	float weaponID = weapon_bit[id];
	if (weaponID == self.weapon) return;
	if (!(self.weapons & weaponID))
	{
		sprint(self, "No weapon\n");
		Sound_Play(self, CHAN_AUTO, 0.8, ATTN_NORM, PITCH_NORM, "common/wpn_denyselect.wav");
		return;
	}

	float oldweap = self.weapon;
	self.weapon = weaponID;
	Weapon_Update();

	if (!self.currentammo && !self.currentClip)
	{
		sprint(self, "No ammo\n");
		Sound_Play(self, CHAN_AUTO, 0.8, ATTN_NORM, PITCH_NORM, "common/wpn_denyselect.wav");
		self.weapon = oldweap;
		Weapon_Update();
		return;
	}

	if(self.weaponSwitch) self.weaponSwitch();
}

void CheatCommand()
{
	if(!cvar("sv_cheats")) return;
	
	self.ammo9x18 = 100;
	self.ammo9x19 = 100;
	self.ammo357 = 100;
	self.ammoGrenades = 100;
	self.ammo545x39 = 200;
	self.ammoShells = 100;
	self.ammo762x54 = 200;
	self.ammo9x39 = 200;
	self.ammoVog = 200;
	self.ammoBat = 200;
	self.ammoBolts = 50;
	self.ammoRockets = 10;
	self.ammoSatchels = 5;
	self.ammoTripmines = 5;
	self.ammoUranium = 100;
	self.ammoHornets = 8;
	self.ammoSnarks = 10;
	self.items = self.items | IT_KEY1 | IT_KEY2;
	float allWeapons = WEAPON_SUIT;
	for (float wid = 1; wid < WID_COUNT; wid++)
		if (wid != WID_CYCLER)
			allWeapons = allWeapons | weapon_bit[wid];
	self.weapons = allWeapons;
	self.player_longJump = TRUE;

	self.impulse = 0;
	Weapon_Update();
}

void ImpulseCommands()
{
	if (self.blockSwitch) return;
	else if (self.impulse > WID_NONE && self.impulse < WID_COUNT) Weapon_Change();
	else if (self.impulse == 101) CheatCommand();
	else if (self.impulse == 100)
	{
		self.impulse = 0;
		if(!self.reload && self.weaponReload) self.weaponReload();
	}
}

void RPG_DrawLaser();
void HGUN_Reload();
void Weapon_Frame()
{
	// An observer is not dead as far as any of this is concerned:
	// PutObserverInServer leaves health at 666 and deadflag at DEAD_NO so the
	// death logic cannot push the spectator underground, which means IsAlive
	// says yes and PlayerPostThink runs the whole player frame. Weapon_Attack
	// dispatches off .weaponAttack and never reads .weapon, so a spectator kept
	// firing whatever they died holding. This is the single entry point, so one
	// return also keeps ImpulseCommands, the reload and the RPG laser out of
	// their hands.
	if (self.classname == "observer") return;

	if (self.trainHudState > 0)
	{
		self.impulse = 0;
		self.button0 = 0;
		self.button6 = 0;
		self.reload = FALSE;
		self.ShootsFired = 0;
		return;
	}

	if(self.weapon == WEAPON_HORNETGUN) HGUN_Reload();
	RPG_DrawLaser();
	if (time < self.attack_finished) return;
	ImpulseCommands();
	if (!self.button0) self.ShootsFired = 0;
	Weapon_Attack();
	
}

void Weapon_Reload(.float ammoType, .float clip, float clipSize, float saveRoundInChamber = TRUE)
{
    self.reload = FALSE;
    Weapon_SetFrame(0);

    float maxClip;
    if (self.clip > 0 && saveRoundInChamber) maxClip = clipSize + 1; // round in the chamber
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

    Weapon_Update();
    self.think = Player_Think;
}

void CycleWeaponReverseCommand()
{

}
