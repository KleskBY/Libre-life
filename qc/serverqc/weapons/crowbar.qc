
/*

int Crowbar_Swing( int fFirst )
{
	float fDidHit = FALSE;

	makevectors(self.owner.v_angle);
	vector vecSrc = self.owner.origin + self.owner.view_ofs;
	vector vecEnd = vecSrc + v_forward * 32;

	traceline(vecSrc, vecEnd, FALSE, self.owner);
	if (trace_fraction >= 1.0)
	{
		UTIL_TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, ENT( self.owner.pev ), &tr );
		if (trace_fraction < 1.0 )
		{
			// CBaseEntity *pHit = CBaseEntity::Instance( tr.pHit );
			// if (!pHit || pHit->IsBSPModel())
				// FindHullIntersection(vecSrc, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, self.owner.edict());
			// vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
		}
	}

	if (fFirst)
	{
		PLAYBACK_EVENT_FULL( FEV_NOTHOST, self.owner.edict(), m_usCrowbar,
							0.0, (float *)&g_vecZero, (float *)&g_vecZero, 0, 0, 0,
							0.0, 0, 0.0 );
	}


	if (trace_fraction >= 1.0)
	{
		if (fFirst)
		{
			// miss
			// m_flNextPrimaryAttack = GetNextAttackDelay(0.5);
			self.attack_finished = time + 0.5;
			
			// player "shoot" animation
			self.owner.SetAnimation( PLAYER_ATTACK1 );
		}
	}
	else
	{
		switch(((m_iSwing++) % 2) + 1)
		{
		case 0:
			SendWeaponAnim( CROWBAR_ATTACK1HIT ); break;
		case 1:
			SendWeaponAnim( CROWBAR_ATTACK2HIT ); break;
		case 2:
			SendWeaponAnim( CROWBAR_ATTACK3HIT ); break;
		}

		// player "shoot" animation
		self.owner.SetAnimation( PLAYER_ATTACK1 );
		
		// hit
		fDidHit = TRUE;
		entity pEntity = trace_ent;
		ClearMultiDamage();

		// JoshA: Changed from < -> <= to fix the full swing logic since client weapon prediction.
		// -1.0f + 1.0f = 0.0f. UTIL_WeaponTimeBase is always 0 with client weapon prediction (0 time base vs curtime base)
		if ((m_flNextPrimaryAttack + 1.0f <= UTIL_WeaponTimeBase()) || g_pGameRules->IsMultiplayer())
		{
			// first swing does full damage
			TraceAttack(self.owner, 
			pEntity->TraceAttack(self.owner.pev, gSkillData.plrDmgCrowbar, gpGlobals->v_forward, &tr, DMG_CLUB ); 
		}
		else
		{
			// subsequent swings do half
			pEntity->TraceAttack(self.owner.pev, gSkillData.plrDmgCrowbar / 2, gpGlobals->v_forward, &tr, DMG_CLUB ); 
		}	
		ApplyMultiDamage();

		// play thwack, smack, or dong sound
		float flVol = 1.0;
		int fHitWorld = TRUE;
		if (pEntity)
		{
			//if (pEntity->Classify() != CLASS_NONE && pEntity->Classify() != CLASS_MACHINE)
			{
				// play thwack or smack sound
				switch(RandomInt(0,2))
				{
				case 0:
					sound(self, CHAN_ITEM, "weapons/cbar_hitbod1.wav", 1, ATTN_NORM); break;
				case 1:
					sound(self, CHAN_ITEM, "weapons/cbar_hitbod2.wav", 1, ATTN_NORM); break;
				case 2:
					sound(self, CHAN_ITEM, "weapons/cbar_hitbod3.wav", 1, ATTN_NORM); break;
				}
				self.owner.m_iWeaponVolume = CROWBAR_BODYHIT_VOLUME;
				if (IsAlive(pEntity))
					  return TRUE;
				else
					  flVol = 0.1;

				fHitWorld = FALSE;
			}
		}

		// play texture hit sound
		// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

		if (fHitWorld)
		{
			float fvolbar = TEXTURETYPE_PlaySound(&tr, vecSrc, vecSrc + (vecEnd-vecSrc)*2, BULLET_PLAYER_CROWBAR);
			if (IsMultiplayer())
			{
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;
			}

			// also play crowbar strike
			switch(RandomInt(0,1))
			{
			case 0:
				sound(self.owner, CHAN_ITEM, "weapons/cbar_hit1.wav", fvolbar, ATTN_NORM, 0, 98 + RANDOM_LONG(0,3)); 
				break;
			case 1:
				sound(self.owner, CHAN_ITEM, "weapons/cbar_hit2.wav", fvolbar, ATTN_NORM, 0, 98 + RANDOM_LONG(0,3)); 
				break;
			}

			// delay the decal a bit
			m_trHit = tr;
		}

		self.owner.m_iWeaponVolume = flVol * CROWBAR_WALLHIT_VOLUME;
		self.attack_finished = time + 0.25; //m_flNextPrimaryAttack = GetNextAttackDelay(0.25);
		
		self.think = Crowbar_Smack; // SetThink( &CCrowbar::Smack );
		self.nextthink = time + 0.2;
	}
	return fDidHit;
}
*/

float CROWBAR_DAMAGE = 25;
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
string CROWBAR_PLAYER_MODEL = 	"models/p_crowbar.iqm";
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
.float m_iSwing;

float CROWBAR_Swing(float fFirst)
{
	float fDidHit = FALSE;
	makevectors(self.v_angle);
	vector vecSrc = self.origin + self.view_ofs;
	vector vecEnd = vecSrc + v_forward * CROWBAR_DISTANCE;
	vector dir = v_forward;
	traceline(vecSrc, vecEnd, FALSE, self);
	if (trace_fraction >= 1.0) // miss
	{
		self.think = Player_Think;
		self.nextthink = time + CROWBAR_RATE;
		self.attack_finished = time + CROWBAR_RATE;
		sound(self, CHAN_ITEM, "weapons/cbar_miss1.wav", 1, ATTN_NORM); 
		switch( ((self.m_iSwing++) % 2) + 1 )
		{
		case 0:
			self.weaponframe = CROWBAR_ATTACK1MISS; break;
		case 1:
			self.weaponframe = CROWBAR_ATTACK2MISS; break;
		case 2:
			self.weaponframe = CROWBAR_ATTACK3MISS; break;
		}
	}
	else // hit
	{
		switch( ((self.m_iSwing++) % 2) + 1 )
		{
		case 0:
			self.weaponframe = CROWBAR_ATTACK1HIT; break;
		case 1:
			self.weaponframe = CROWBAR_ATTACK2HIT; break;
		case 2:
			self.weaponframe = CROWBAR_ATTACK3HIT; break;
		}
		
		fDidHit = TRUE;
		entity pEntity = trace_ent;
		ClearMultiDamage();
		Combat_TraceAttack(CROWBAR_DAMAGE, dir);
		ApplyMultiDamage();

		// play thwack, smack, or dong sound
		float flVol = 1.0;
		int fHitWorld = TRUE;
		if (pEntity)
		{
			//if (pEntity->Classify() != CLASS_NONE && pEntity->Classify() != CLASS_MACHINE)
			{
				switch(RandomInt(0,2))
				{
				case 0:
					sound(self, CHAN_ITEM, CROWBAR_HITBOD1_SOUND, flVol, ATTN_NORM); break;
				case 1:
					sound(self, CHAN_ITEM, CROWBAR_HITBOD2_SOUND, flVol, ATTN_NORM); break;
				case 2:
					sound(self, CHAN_ITEM, CROWBAR_HITBOD3_SOUND, flVol, ATTN_NORM); break;
				}
				// self.owner.m_iWeaponVolume = CROWBAR_BODYHIT_VOLUME;
				// if (IsAlive(pEntity))
				// {
					// self.attack_finished = time + (CROWBAR_RATE / 2); 
					// return TRUE;
				// }
				// else flVol = 0.1;
				flVol = 0.1;
				fHitWorld = FALSE;
			}
		}

		if (fHitWorld)
		{
			switch(RandomInt(0,1))
			{
			case 0:
				sound7(self, CHAN_ITEM, CROWBAR_HIT1_SOUND, flVol, ATTN_NORM, 98 + RandomInt(0,3), 0); 
				break;
			case 1:
				sound7(self, CHAN_ITEM, CROWBAR_HIT2_SOUND, flVol, ATTN_NORM, 98 + RandomInt(0,3), 0); 
				break;
			}
		}

		self.attack_finished = time + (CROWBAR_RATE / 2); //m_flNextPrimaryAttack = GetNextAttackDelay(0.25);
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
	self.weaponframe = 1;
	self.reload = 1;
	self.think = Player_Think;
	self.nextthink = time + 0.5;
}

/////////////////////// SELECT //////////////////////

void CROWBAR_Select()
{
	self.currentClip = 1;
	self.weaponframe = 0;
	self.weaponmodel = CROWBAR_VIEW_MODEL;
	// setmodel(self, CROWBAR_PLAYER_MODEL);
	self.weaponSwitch = CROWBAR_Switch;
	self.weaponAttack = CROWBAR_Attack;
	self.weaponReload = SUB_Null;
	self.weaponSelect = CROWBAR_Select;
	// SetGun(CROWBAR_WORLD_MODEL);
}

//////////////// PRECACHE //////////////////////////

void CROWBAR_Precache()
{
	precache_model(CROWBAR_VIEW_MODEL);
	precache_model(CROWBAR_PLAYER_MODEL);
	precache_model(CROWBAR_WORLD_MODEL);
	precache_sound(CROWBAR_HIT1_SOUND);
	precache_sound(CROWBAR_HIT2_SOUND);
	precache_sound(CROWBAR_MISS_SOUND);
	precache_sound(CROWBAR_HITBOD1_SOUND);
	precache_sound(CROWBAR_HITBOD2_SOUND);
	precache_sound(CROWBAR_HITBOD3_SOUND);
}


