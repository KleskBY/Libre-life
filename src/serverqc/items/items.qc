
void Item_Respawn()
{
	self.model = self.mdl;
	self.solid = SOLID_TRIGGER;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "items/suitchargeok1.wav");
	setorigin (self, self.origin);
}

void Item_Finish()
{
	// Coop: item is consumed per player, master entity stays put
	if (self.coopIsMaster)
	{
		CoopItem_Consume(self, other);
		activator = other;
		SUB_UseTargets();
		return;
	}

	self.model = "";
	self.solid = SOLID_NOT;
	if (cvar("gamemode") == MODE_DM) self.nextthink = time + 30;
	self.think = Item_Respawn;
	activator = other;
	SUB_UseTargets();
}

// Shared preamble for item touch handlers. Rejects non-players, corpses,
// and players who already consumed the item, preventing re-triggering.
float Item_TouchReject(entity toucher)
{
	if (toucher.classname != "player") return TRUE;
	if (toucher.health <= 0) return TRUE;
	if (CoopItem_Taken(self, toucher)) return TRUE;
	return FALSE;
}


void Item_GiveAmmo(entity player, float weaponBit)
{
	if (weaponBit == WEAPON_GLOCK)          player.ammo9x19       += 17;
	else if (weaponBit == WEAPON_PYTHON)    player.ammo357        += 6;
	else if (weaponBit == WEAPON_MP5)       player.ammo9x19       += 25;
	else if (weaponBit == WEAPON_SHOTGUN)   player.ammoShells     += 12;
	else if (weaponBit == WEAPON_CROSSBOW)  player.ammoBolts      += 5;
	else if (weaponBit == WEAPON_RPG)       player.ammoRockets    += 1;
	else if (weaponBit == WEAPON_HANDGRENADE) player.ammoGrenades += 5;
	else if (weaponBit == WEAPON_SATCHEL)   player.ammoSatchels   += 1;
	else if (weaponBit == WEAPON_TRIPMINE)  player.ammoTripmines  += 1;
	else if (weaponBit == WEAPON_GAUSS)     player.ammoUranium    += 20;
	else if (weaponBit == WEAPON_EGON)      player.ammoUranium    += 20;
	else if (weaponBit == WEAPON_HORNETGUN) player.ammoHornets    += 8;
	else if (weaponBit == WEAPON_SNARK)     player.ammoSnarks     += 5;
}

void Weapon_Update();
void Ammo_SyncHUD(entity picker)
{
	entity saved = self;
	self = picker;
	Weapon_Update();
	self = saved;
}

void Item_Touch()
{
	if (Item_TouchReject(other)) return;
	other.picked_items = other.picked_items + 1;

	if(!(other.weapons & self.weapon))
	{
		other.items = other.items | self.weapon;
		other.weapons = other.weapons | self.weapon;

		if(!other.reload) //Select new weapon
			other.impulse = Weapon_IDFromBit(self.weapon);
	}

	// Grant ammo on pickup
	Item_GiveAmmo(other, self.weapon);
	Ammo_SyncHUD(other);

	sprint(other, "You got the ");
	sprint(other, self.netname);
	sprint(other, "\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");

	Item_Finish();
}

void Ammo_Touch()
{
	if (Item_TouchReject(other)) return;
	other.picked_items = other.picked_items + 1;

	Item_GiveAmmo(other, self.weapon);
	Ammo_SyncHUD(other);

	sprint(other, "You picked up ");
	sprint(other, self.netname);
	sprint(other, "\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}

void Item_Place()
{
	self.mdl = self.model;
	self.flags = FL_ITEM;
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;
	self.velocity = '0 0 0';
	droptofloor();

	// Coop: must run after droptofloor so ghosts inherit settled origin
	CoopItem_MakeMaster(self);
}

void Item_Start()
{
	setsize(self, '-16 -16 0', '16 16 16');
	self.item = TRUE;
	self.nextthink = time + 0.2;
	self.think = Item_Place;
	self.touch = Item_Touch;
}

void CROWBAR_Precache();
void weapon_crowbar()
{
	CROWBAR_Precache();
	setmodel(self, "models/w_crowbar.iqm");
	self.weapon = WEAPON_CROWBAR;
	self.netname = "crowbar";
	Item_Start();
}

void GLOCK_Precache();
void weapon_9mmhandgun()
{
	self.classname = "weapon_9mmhandgun";
	GLOCK_Precache();
	setmodel(self, "models/w_9mmhandgun.iqm");
	self.weapon = WEAPON_GLOCK;
	self.netname = "9mm Handgun";
	Item_Start();
}
void weapon_glock()
{
	weapon_9mmhandgun();
}


void MP5_Precache();
void weapon_9mmAR()
{
	self.classname = "weapon_9mmAR";
	MP5_Precache();
	setmodel(self, "models/w_9mmar.iqm");
	self.weapon = WEAPON_MP5;
	self.netname = "MP5";
	Item_Start();
}

void CROSSBOW_Precache();
void weapon_crossbow()
{
	self.classname = "weapon_crossbow";
	CROSSBOW_Precache();
	setmodel(self, "models/w_crossbow.iqm");
	self.weapon = WEAPON_CROSSBOW;
	self.netname = "Crossbow";
	Item_Start();
}

void HANDGRENADE_Precache();
void weapon_handgrenade()
{
	self.classname = "weapon_handgrenade";
	HANDGRENADE_Precache();
	setmodel(self, "models/w_grenade.iqm");
	self.weapon = WEAPON_HANDGRENADE;
	self.netname = "Hand Grenade";
	Item_Start();
}

void RPG_Precache();
void weapon_rpg()
{
	self.classname = "weapon_rpg";
	RPG_Precache();
	setmodel(self, "models/w_rpg.iqm");
	self.weapon = WEAPON_RPG;
	self.netname = "RPG";
	Item_Start();
}

void SATCHEL_Precache();
void weapon_satchel()
{
	self.classname = "weapon_satchel";
	SATCHEL_Precache();
	setmodel(self, "models/w_satchel.iqm");
	self.weapon = WEAPON_SATCHEL;
	self.netname = "Satchel Charge";
	Item_Start();
}

void TRIPMINE_Precache();
void weapon_tripmine()
{
	self.classname = "weapon_tripmine";
	TRIPMINE_Precache();
	setmodel(self, "models/w_tripmine.iqm");
	self.weapon = WEAPON_TRIPMINE;
	self.netname = "Trip Mine";
	Item_Start();
}

void GAUSS_Precache();
void weapon_gauss()
{
	self.classname = "weapon_gauss";
	GAUSS_Precache();
	setmodel(self, "models/w_gauss.iqm");
	self.weapon = WEAPON_GAUSS;
	self.netname = "Tau Cannon";
	Item_Start();
}

void HGUN_Precache();
void weapon_hornetgun()
{
	self.classname = "weapon_hornetgun";
	HGUN_Precache();
	setmodel(self, "models/w_hgun.iqm");
	self.weapon = WEAPON_HORNETGUN;
	self.netname = "Hornet Gun";
	Item_Start();
}

void SNARK_Precache();
void weapon_snark()
{
	self.classname = "weapon_snark";
	SNARK_Precache();
	setmodel(self, "models/w_sqknest.iqm");
	self.weapon = WEAPON_SNARK;
	self.netname = "Squeak Grenade";
	Item_Start();
}

//
// AMMO
//
void ammo_glockclip()
{
	self.classname = "ammo_glockclip";
	precache_model("models/w_9mmclip.iqm");
	setmodel(self, "models/w_9mmclip.iqm");
	self.weapon  = WEAPON_GLOCK;
	self.netname = "9mm Clip";
	Item_Start();
	self.touch = Ammo_Touch;
}

void ammo_9mmclip() { ammo_glockclip(); }

void ammo_buckshot()
{
	self.classname = "ammo_buckshot";
	precache_model("models/w_shotbox.iqm");
	setmodel(self, "models/w_shotbox.iqm");
	self.weapon  = WEAPON_SHOTGUN;
	self.netname = "Shotgun Shells";
	Item_Start();
	self.touch = Ammo_Touch;
}

void ammo_357()
{
	self.classname = "ammo_357";
	precache_model("models/w_357ammobox.iqm");
	setmodel(self, "models/w_357ammobox.iqm");
	self.weapon  = WEAPON_PYTHON;
	self.netname = ".357 Rounds";
	Item_Start();
	self.touch = Ammo_Touch;
}

void ammo_9mmAR()
{
	self.classname = "ammo_9mmAR";
	precache_model("models/w_9mmARclip.iqm");
	setmodel(self, "models/w_9mmARclip.iqm");
	self.weapon  = WEAPON_MP5;
	self.netname = "9mm AR Clip";
	Item_Start();
	self.touch = Ammo_Touch;
}
void ammo_mp5clip() { ammo_9mmAR(); }
void weapon_mp5() { weapon_9mmAR(); }

void Ammo9mmBox_Touch()
{
	if (Item_TouchReject(other)) return;
	other.picked_items++;
	other.ammo9x19 += 100;
	Ammo_SyncHUD(other);
	sprint(other, "You picked up 9mm rounds\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}
void ammo_9mmbox()
{
	self.classname = "ammo_9mmbox";
	precache_model("models/w_chainammo.iqm");
	setmodel(self, "models/w_chainammo.iqm");
	self.netname = "9mm Rounds";
	Item_Start();
	self.touch = Ammo9mmBox_Touch;
}

void ammo_ARgrenades_touch()
{
	if (Item_TouchReject(other)) return;
	other.picked_items++;
	other.ammoGrenades += 2;
	Ammo_SyncHUD(other);
	sprint(other, "You picked up AR Grenades\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}
void ammo_ARgrenades()
{
	self.classname = "ammo_ARgrenades";
	precache_model("models/w_ARgrenade.iqm");
	setmodel(self, "models/w_ARgrenade.iqm");
	self.netname = "AR Grenades";
	Item_Start();
	self.touch = ammo_ARgrenades_touch;
}
void ammo_mp5grenades() { ammo_ARgrenades(); }

void ammo_crossbow()
{
	self.classname = "ammo_crossbow";
	precache_model("models/w_crossbow_clip.iqm");
	setmodel(self, "models/w_crossbow_clip.iqm");
	self.weapon  = WEAPON_CROSSBOW;
	self.netname = "Crossbow Bolts";
	Item_Start();
	self.touch = Ammo_Touch;
}

void ammo_gaussclip()
{
	self.classname = "ammo_gaussclip";
	precache_model("models/w_gaussammo.iqm");
	setmodel(self, "models/w_gaussammo.iqm");
	self.weapon  = WEAPON_GAUSS;
	self.netname = "Uranium Ammo";
	Item_Start();
	self.touch = Ammo_Touch;
}

void AmmoRPGClip_Touch()
{
	if (Item_TouchReject(other)) return;
	other.picked_items++;
	other.ammoRockets += 2;
	Ammo_SyncHUD(other);
	sprint(other, "You picked up rockets\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}
void ammo_rpgclip()
{
	self.classname = "ammo_rpgclip";
	precache_model("models/w_rpgammo.iqm");
	setmodel(self, "models/w_rpgammo.iqm");
	self.netname = "RPG Rockets";
	Item_Start();
	self.touch = AmmoRPGClip_Touch;
}

void SHOTGUN_Precache();
void weapon_shotgun()
{
	self.classname = "weapon_shotgun";
	SHOTGUN_Precache();
	precache_model("models/w_shotgun.iqm");
	setmodel(self, "models/w_shotgun.iqm");
	self.weapon  = WEAPON_SHOTGUN;
	self.netname = "SPAS-12";
	Item_Start();
}

void PYTHON_Precache();
void weapon_357()
{
	self.classname = "weapon_357";
	PYTHON_Precache();
	precache_model("models/w_357.iqm");
	setmodel(self, "models/w_357.iqm");
	self.weapon  = WEAPON_PYTHON;
	self.netname = ".357 Magnum";
	Item_Start();
}

void weapon_python() { weapon_357(); }

void EGON_Precache();
void weapon_egon()
{
	self.classname = "weapon_egon";
	EGON_Precache();
	precache_model("models/w_egon.iqm");
	setmodel(self, "models/w_egon.iqm");
	self.weapon  = WEAPON_EGON;
	self.netname = "Egon Gun";
	Item_Start();
}

//
// HEALTH
//

void ItemHealthkit_Touch()
{
	if (Item_TouchReject(other)) return;
	if (other.health >= other.max_health) return;

	other.health += Skill_GetValue("sk_healthkit", 15);
	if (other.health > other.max_health) other.health = other.max_health;
	sprint(other, "You picked up a health kit.\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/smallmedkit1.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}

void item_healthkit()
{
	self.classname = "item_healthkit";
	precache_model("models/w_medkit.iqm");
	precache_sound("items/smallmedkit1.wav");
	setmodel(self, "models/w_medkit.iqm");
	Item_Start();
	self.touch = ItemHealthkit_Touch;
}

void ItemBattery_Touch()
{
	if (Item_TouchReject(other)) return;
	if (other.armorvalue >= 100) return;

	other.armorvalue += Skill_GetValue("sk_battery", 15);
	if (other.armorvalue > 100) other.armorvalue = 100;
	if (!other.armortype) other.armortype = 0.2;	// HEV absorption fraction
	sprint(other, "HEV battery acquired.\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "items/gunpickup2.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}

void item_battery()
{
	self.classname = "item_battery";
	precache_model("models/w_battery.iqm");
	setmodel(self, "models/w_battery.iqm");
	Item_Start();
	self.touch = ItemBattery_Touch;
}

//
// SUIT
//

#define SF_SUIT_SHORTLOGON  1

void ItemSuit_Touch()
{
	if (Item_TouchReject(other)) return;
	if (other.weapons & WEAPON_SUIT) return;

	if (self.spawnflags & SF_SUIT_SHORTLOGON)
		Sentences_Play(other, CHAN_AUTO, "HEV_A0",  1.0, ATTN_NORM, 100); //CHAN_AUTO so it can't be override
	else
		Sentences_Play(other, CHAN_AUTO, "HEV_AAx", 1.0, ATTN_NORM, 100);

	other.weapons = other.weapons | WEAPON_SUIT;
	other.picked_items = other.picked_items + 1;

	Item_Finish();
}

void item_suit()
{
	self.classname = "item_suit";
	precache_model("models/w_suit.iqm");
	setmodel(self, "models/w_suit.iqm");
	Item_Start();
	self.touch = ItemSuit_Touch;
}


//LJ
void ItemLongjump_Touch()
{
	if (Item_TouchReject(other)) return;
	if (other.player_longJump) return;              // already have it
	if (!(other.weapons & WEAPON_SUIT)) return;	// suit required

	other.player_longJump = TRUE;
	other.picked_items = other.picked_items + 1;
	Sentences_Play(other, CHAN_ITEM, "HEV_A1", 1.0, ATTN_NORM, 100);
	sprint(other, "Long jump module acquired.\n");
	stuffcmd(other, "bf\n");

	Item_Finish();
}

void item_longjump()
{
	self.classname = "item_longjump";
	precache_model("models/w_longjump.iqm");
	setmodel(self, "models/w_longjump.iqm");
	Item_Start();
	self.touch = ItemLongjump_Touch;
}

void ItemAntidote_Touch()
{
	if (Item_TouchReject(other)) return;
	Sentences_Play(other, CHAN_VOICE, "!HEV_DET4", 1.0, ATTN_NORM, 100);
}


//Trash
void item_antidote()
{ 
	precache_model("models/w_antidote.iqm");
	setmodel(self, "models/w_antidote.iqm");
	Item_Start();
	self.touch = ItemAntidote_Touch;
}


void ItemSecurity_Touch()
{

}

void item_security()
{ 
	precache_model("models/w_security.iqm");
	setmodel(self, "models/w_security.iqm");
	Item_Start();
	self.touch = ItemSecurity_Touch;
}


void world_items()
{
	entity pEntity;
	switch(self.type)
	{
		case 44: // ITEM_BATTERY:
			pEntity = Entity_Create(item_battery, self.origin, self.angles);
			break;
		case 42: // ITEM_ANTIDOTE:
			pEntity = Entity_Create(item_antidote, self.origin, self.angles );
			break;
		case 43: // ITEM_SECURITY:
			pEntity = Entity_Create(item_security, self.origin, self.angles );
			break;
		case 45: // ITEM_SUIT:
			pEntity = Entity_Create(item_suit, self.origin, self.angles );
			break;
	}
	if (!pEntity)
	{
		dprint("unable to create world_item"); dprint(ftos(self.type)); dprint("\n");
	}
	else
	{
		pEntity.target = self.target;
		pEntity.targetname = self.targetname;
		pEntity.spawnflags = self.spawnflags;
	}

	remove(self);
}

