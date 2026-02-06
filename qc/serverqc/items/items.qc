
#define ITEM_HEALTHKIT		1
#define ITEM_ANTIDOTE		2
#define ITEM_SECURITY		3
#define ITEM_BATTERY		4

#define WEAPON_NONE				0
#define WEAPON_CROWBAR			1
#define	WEAPON_GLOCK			2
#define WEAPON_PYTHON			3
#define WEAPON_MP5				4
#define WEAPON_CHAINGUN			5
#define WEAPON_CROSSBOW			6
#define WEAPON_SHOTGUN			7
#define WEAPON_RPG				8
#define WEAPON_GAUSS			9
#define WEAPON_EGON				10
#define WEAPON_HORNETGUN		11
#define WEAPON_HANDGRENADE		12
#define WEAPON_TRIPMINE			13
#define	WEAPON_SATCHEL			14
#define	WEAPON_SNARK			15

#define WEAPON_ALLWEAPONS		(~(1<<WEAPON_SUIT))

#define WEAPON_SUIT				31	// ?????

#define MAX_WEAPONS			32

#define VECTOR_CONE_1DEGREES	'0.00873 0.00873 0.00873'
#define VECTOR_CONE_2DEGREES	'0.01745 0.01745 0.01745'
#define VECTOR_CONE_3DEGREES	'0.02618 0.02618 0.02618'
#define VECTOR_CONE_4DEGREES	'0.03490 0.03490 0.03490'
#define VECTOR_CONE_5DEGREES	'0.04362 0.04362 0.04362'
#define VECTOR_CONE_6DEGREES	'0.05234 0.05234 0.05234'
#define VECTOR_CONE_7DEGREES	'0.06105 0.06105 0.06105'
#define VECTOR_CONE_8DEGREES	'0.06976 0.06976 0.06976'
#define VECTOR_CONE_9DEGREES	'0.07846 0.07846 0.07846'
#define VECTOR_CONE_10DEGREES	'0.08716 0.08716 0.08716'
#define VECTOR_CONE_15DEGREES	'0.13053 0.13053 0.13053'
#define VECTOR_CONE_20DEGREES	'0.17365 0.17365 0.17365'

void Item_Respawn()
{
	self.model = self.mdl;		// restore original model
	self.solid = SOLID_TRIGGER;	// allow it to be touched again
	sound (self, CHAN_VOICE, "misc/item_respawn.wav", 1, ATTN_NORM);	// play respawn sound
	setorigin (self, self.origin);
}

void Item_Finish()
{
	self.model = string_null; //remove it
	self.solid = SOLID_NOT;
	if (cvar("gamemode") == MODE_DM || cvar("gamemode") == MODE_TDM) self.nextthink = time + 30;
	self.think = Item_Respawn;
	activator = other;
	SUB_UseTargets(); // fire all targets / killtargets
}


void Item_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;
	other.picked_items = other.picked_items + 1;
	
	// if (cvar("gamemode") == MODE_COOP && other.weapons & self.weapon) return;
	if(!(other.weapons & self.weapon))
	{
		other.items = other.items | self.weapon;
		other.weapons = other.weapons | self.weapon;
		
		if(!other.reload) //Select new weapon
		{
			if(self.weapon == WP_KNIFE) other.impulse = 1;
			else if(self.weapon == WP_PISTOL) other.impulse = 2;
			else if(self.weapon == WP_RIFLE) other.impulse = 3;
			else if(self.weapon == WP_SHOTGUN) other.impulse = 4;
			else if(self.weapon == WP_VAL) other.impulse = 5;
			else if(self.weapon == WP_SNIPER) other.impulse = 6;
			else if(self.weapon == WP_OC14) other.impulse = 8;
		}
	}
	
	sprint(other, "You got the ");
	sprint(other, self.netname);
	sprint(other, "\n");
	sound(other, CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM);
	stuffcmd(other, "bf\n");
	
	if (cvar("gamemode") == MODE_COOP) return;
	Item_Finish();
}

void Item_Place()
{
	self.mdl = self.model;		// so it can be restored on respawn
	self.flags = FL_ITEM;		// make extra wide
	self.solid = SOLID_TRIGGER;
	self.movetype = MOVETYPE_TOSS;	
	self.velocity = '0 0 0';
}

void Item_Start()
{
	setsize(self, '-16 -16 0', '16 16 32');
	self.item = TRUE;
	self.nextthink = time + 0.2;	// items start after other solids
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
	setmodel(self, "models/w_crowbar.iqm");
	self.weapon = WEAPON_CROWBAR;
	self.netname = "glock";
	Item_Start();
}



void MP5_Precache();
void weapon_9mmAR()
{
	self.classname = "weapon_9mmAR"; // hack to allow for old names
	MP5_Precache();
	setmodel(self, "models/w_9mmar.iqm");
	self.weapon = WEAPON_MP5;
	self.netname = "MP5";
	Item_Start();
}