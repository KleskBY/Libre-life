

#define CROWBAR_DAMAGE Skill_GetValue("sk_plr_crowbar", 10)	// one-shots 8-HP dead scientists, two-shots headcrabs.
float CROWBAR_RATE = 0.5;
float CROWBAR_DISTANCE = 64;	//32;

float CROWBAR_RELOAD_START_FRAME = 36;
float CROWBAR_RELOAD_END_FRAME = 156;
float CROWBAR_DRAW_START_FRAME = 1;
float CROWBAR_DRAW_END_FRAME = 25;
float CROWBAR_ATTACK_START_FRAME = 26;
float CROWBAR_ATTACK_END_FRAME = 35;
float CROWBAR_FRAMERATE = 0.01;

string CROWBAR_VIEW_MODEL = 	"models/v_crowbar.iqm";
string CROWBAR_WORLD_MODEL = 	"models/w_crowbar.iqm";

string CROWBAR_HIT1_SOUND = 	"weapons/cbar_hit1.wav";
string CROWBAR_HIT2_SOUND = 	"weapons/cbar_hit2.wav";
string CROWBAR_HITBOD1_SOUND = 	"weapons/cbar_hitbod1.wav";
string CROWBAR_HITBOD2_SOUND = 	"weapons/cbar_hitbod2.wav";
string CROWBAR_HITBOD3_SOUND = 	"weapons/cbar_hitbod3.wav";
string CROWBAR_MISS_SOUND = 	"weapons/cbar_miss1.wav";

//ANIMS
#define	CROWBAR_IDLE 		0
#define CROWBAR_DRAW 		1
#define CROWBAR_HOLSTER 	2
#define CROWBAR_ATTACK1HIT 	3
#define CROWBAR_ATTACK1MISS 4
#define CROWBAR_ATTACK2MISS 5
#define CROWBAR_ATTACK2HIT 	6
#define CROWBAR_ATTACK3MISS 7
#define CROWBAR_ATTACK3HIT 	8

////////////////////////// ATTACK //////////////////////////////
.float swingCount;

float CROWBAR_Swing(float fFirst)
{
	float fDidHit = FALSE;
	makevectors(self.v_angle);
	vector vecSrc = self.origin + self.view_ofs;
	vector vecEnd = vecSrc + v_forward * CROWBAR_DISTANCE;
	vector dir = v_forward;
	float oldSolid = self.solid; //Corpse hit fix
	self.solid = SOLID_BBOX;
	traceline(vecSrc, vecEnd, FALSE, self);
	self.solid = oldSolid;
	if (trace_fraction >= 1.0) // miss
	{
		self.think = Player_Think;
		self.nextthink = time + CROWBAR_RATE;
		self.attack_finished = time + CROWBAR_RATE;
		Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "weapons/cbar_miss1.wav"); 
		switch( ((self.swingCount++) % 2) + 1 )
		{
		case 0:
			Weapon_SetFrame(CROWBAR_ATTACK1MISS); break;
		case 1:
			Weapon_SetFrame(CROWBAR_ATTACK2MISS); break;
		case 2:
			Weapon_SetFrame(CROWBAR_ATTACK3MISS); break;
		}
	}
	else // hit
	{
		switch( ((self.swingCount++) % 2) + 1 )
		{
		case 0:
			Weapon_SetFrame(CROWBAR_ATTACK1HIT); break;
		case 1:
			Weapon_SetFrame(CROWBAR_ATTACK2HIT); break;
		case 2:
			Weapon_SetFrame(CROWBAR_ATTACK3HIT); break;
		}
		
		fDidHit = TRUE;
		entity pEntity = trace_ent;
		float pEntityWasDamageable = pEntity.takedamage;
		ClearMultiDamage();
		Combat_TraceAttack(CROWBAR_DAMAGE, dir, DMG_CLUB);
		ApplyMultiDamage();

		float flVol = 1.0;
		int fHitWorld = TRUE;
		if (pEntity)
		{
			if((Classify(pEntity) != CLASS_NONE && Classify(pEntity) != CLASS_MACHINE) || pEntity.solid == SOLID_CORPSE)
			{
				Sound_Play(self, CHAN_ITEM, flVol, ATTN_NORM, 100, CROWBAR_HITBOD1_SOUND, CROWBAR_HITBOD2_SOUND, CROWBAR_HITBOD3_SOUND);

				if (!IsAlive(pEntity))
				{
					self.attack_finished = time + (CROWBAR_RATE / 2);
					return TRUE;
				}
				else flVol = 0.1;
				fHitWorld = FALSE;
			}
			else if ((pEntity.classname == "func_breakable" || pEntity.classname == "func_pushable") && pEntityWasDamageable != DAMAGE_NO)
			{
				fHitWorld = FALSE; // Breakable_DamageSound already played the material sound
			}
		}

		if (fHitWorld)
		{
			Sound_Play(self, CHAN_ITEM, flVol, ATTN_NORM, 100, CROWBAR_HIT1_SOUND, CROWBAR_HIT2_SOUND);
		}

		self.attack_finished = time + (CROWBAR_RATE / 2);
		self.think = Player_Think;
		self.nextthink = time + 0.2;
	}
	return fDidHit;
}

void CROWBAR_Attack()
{
	CROWBAR_Swing(TRUE);
}

///////////////// WEAPON CHANGE ///////////////////

void CROWBAR_Switch()
{
	Weapon_SetFrame(1);
	self.reload = 1;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

/////////////////////// SELECT //////////////////////

void CROWBAR_Select()
{
	self.currentClip = 1;
	Weapon_SetFrame(0);
	self.weaponmodel = CROWBAR_VIEW_MODEL;
	self.weaponSwitch = CROWBAR_Switch;
	self.weaponAttack = CROWBAR_Attack;
	self.weaponAttack2 = SUB_Null;
	self.weaponReload = SUB_Null;
	self.weaponSelect = CROWBAR_Select;
}

//////////////// PRECACHE //////////////////////////

void CROWBAR_Precache()
{
	precache_model(CROWBAR_VIEW_MODEL);
	precache_model(CROWBAR_WORLD_MODEL);
	precache_sound(CROWBAR_HIT1_SOUND);
	precache_sound(CROWBAR_HIT2_SOUND);
	precache_sound(CROWBAR_MISS_SOUND);
	precache_sound(CROWBAR_HITBOD1_SOUND);
	precache_sound(CROWBAR_HITBOD2_SOUND);
	precache_sound(CROWBAR_HITBOD3_SOUND);
}

