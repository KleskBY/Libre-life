

void weapon_crowbar();
void weapon_9mmhandgun();
void weapon_9mmAR();
void weapon_357();
void weapon_crossbow();
void weapon_egon();
void weapon_gauss();
void weapon_handgrenade();
void weapon_hornetgun();
void weapon_rpg();
void weapon_satchel();
void weapon_shotgun();
void weapon_snark();
void weapon_tripmine();

void Item_RandomWeapon()
{
	float i = Math_RandomInt(2, 13);
	switch(i)
	{
		case 0:  weapon_crowbar();      break;
		case 1:  weapon_9mmhandgun();   break;
		case 2:  weapon_9mmAR();        break;
		case 3:  weapon_357();          break;
		case 4:  weapon_crossbow();     break;
		case 5:  weapon_egon();         break;
		case 6:  weapon_gauss();        break;
		case 7:  weapon_handgrenade();  break;
		case 8:  weapon_hornetgun();    break;
		case 9:  weapon_rpg();          break;
		case 10: weapon_satchel();      break;
		case 11: weapon_shotgun();      break;
		case 12: weapon_snark();        break;
		case 13: weapon_tripmine();     break;
	}
}

void weapon_axe()            { Item_RandomWeapon(); }
void weapon_nailgun()        { Item_RandomWeapon(); }
void weapon_supernailgun()   { Item_RandomWeapon(); }
void weapon_supershotgun()   { Item_RandomWeapon(); }
void weapon_grenadelauncher(){ Item_RandomWeapon(); }
void weapon_rocketlauncher() { Item_RandomWeapon(); }
void weapon_lightning()      { Item_RandomWeapon(); }

void Item_RandomAmmo()
{
	float i = Math_RandomInt(0, 7);
	switch(i)
	{
		case 0: ammo_357(); 		break;
		case 1: ammo_9mmAR(); 		break;
		case 2: ammo_9mmclip(); 	break;
		case 3: ammo_ARgrenades();	break;
		case 4: ammo_buckshot(); 	break;
		case 5: ammo_crossbow(); 	break;
		case 6: ammo_gaussclip();	break;
		case 7: ammo_rpgclip(); 	break;
	}
}


void item_shells()
{
	Item_RandomAmmo();
}

void item_cells()
{
	Item_RandomAmmo();
}

void item_rockets()
{
	Item_RandomAmmo();
}

void item_spikes()
{
	Item_RandomAmmo();
}

void item_health()
{
	item_healthkit();
}

void item_armor1()
{
	item_battery();
}

void item_armor2()
{
	item_battery();
	vector ofs = randomvec();
	ofs_z = 0;
	ofs = normalize(ofs) * 25;
	entity e = spawn();
	setorigin(e, self.origin + ofs);
	self = e;
	item_battery();
}

void item_armor3()
{
	item_battery();
	entity e = spawn();
	setorigin(e, self.origin + '25 12 0');
	self = e;
	item_battery();
	e = spawn();
	setorigin(e, self.origin + '-12 -25 0');
	self = e;
	item_battery();
}