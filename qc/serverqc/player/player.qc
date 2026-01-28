
#define PLAYER_FATAL_FALL_SPEED		1024// approx 60 feet
#define PLAYER_MAX_SAFE_FALL_SPEED	580// approx 20 feet
#define DAMAGE_FOR_FALL_SPEED		(float) 100 / ( PLAYER_FATAL_FALL_SPEED - PLAYER_MAX_SAFE_FALL_SPEED )// damage per unit per second.
#define PLAYER_MIN_BOUNCE_SPEED		200
#define PLAYER_FALL_PUNCH_THRESHHOLD (float)350 // won't punch player's screen/make scrape noise unless player falling at least this fast.


.float next_frame;
float PLAYER_ANIM_TIME = 0.03;
void PlayerAnim()
{
	self.angles_x = 0;
	self.angles_z = 0;
	if(self.next_frame > time) return;
	self.next_frame = time + PLAYER_ANIM_TIME;
	
	if(self.button0) 
	{
		self.frame = self.frame + 1;
		self.lerpfrac = 0.5;
		self.frame1time = time;
		self.button0 = 0;
	}
	
	// if(vlen(self.velocity) < 40)
	// {
		// if(self.frame != 0) self.frame = 0;
	// }
	// self.frame = self.frame + 1;
	// if(self.frame > 32) self.frame = 1;
	self.angles_x = 0;
}

float Combat_PlayerFallDamage()
{
	self.jump_flag += PLAYER_MAX_SAFE_FALL_SPEED;
	return self.jump_flag * DAMAGE_FOR_FALL_SPEED;
}

void PlayerPostThink()
{
	if (gameover)
		goto pt_end;         // intermission or finale

	if (!IsAlive(self))
		goto pt_end;

	PlayerAnim();
	Weapon_Frame();
// do weapon stuff
	// ItemPostFrame();

// check to see if player landed hard enough to make a sound
// falling farther than half of the maximum safe distance, but not as far a max safe distance will
// play a bootscrape sound, and no damage will be inflicted. Fallling a distance shorter than half
// of maximum safe distance will make no sound. Falling farther than max safe distance will play a 
// fallpain sound, and damage will be inflicted based on how far the player fell

	//if ( (FBitSet(flags, FL_ONGROUND)) && (self.health > 0) && m_flFallVelocity >= PLAYER_FALL_PUNCH_THRESHHOLD )
	if(self.jump_flag < -150 && self.flags & FL_ONGROUND && self.health > 0) //Landing
	{
		// ALERT ( at_console, "%f\n", m_flFallVelocity );
		if (self.watertype == CONTENT_WATER)
		{
			// Did he hit the world or a non-moving entity?
			// BUG - this happens all the time in water, especially when 
			// BUG - water has current force
			// if ( !self.groundentity || VARS(self.groundentity)->velocity.z == 0 )
				// sound(self, CHAN_BODY, "player/pl_wade1.wav", 1, ATTN_NORM);
		}
		else if (self.jump_flag < -PLAYER_MAX_SAFE_FALL_SPEED) // after this point, we start doing damage
		{
			float flFallDamage = Combat_PlayerFallDamage();
			if (flFallDamage > self.health) //splat
			{
				// note: play on item channel because we play footstep landing on body channel
				sound(self, CHAN_ITEM, "common/bodysplat.wav", 1, ATTN_NORM);
			}

			if (flFallDamage > 0)
			{
				Combat_TakeDamage(self, world, world, flFallDamage, DMG_FALL); 
				self.punchangle.x = 0;
			}
		}

		if (IsAlive(self))
		{
			// SetAnimation(PLAYER_WALK);
		}
    }

	if (FBitSet(flags, FL_ONGROUND))
	{		
		if (self.jump_flag < -64 && !IsMultiplayer())
		{
			// CSoundEnt::InsertSound (bits_SOUND_PLAYER, self.origin, m_flFallVelocity, 0.2);
			// ALERT( at_console, "fall %f\n", m_flFallVelocity );
		}
		self.jump_flag = 0;
	}

	// select the proper animation for the player character	
	// if (IsAlive(self))
	// {
		// if (!self.velocity.x && !self.velocity.y)
			// SetAnimation( PLAYER_IDLE );
		// else if ((self.velocity.x || self.velocity.y) && (FBitSet(self.flags, FL_ONGROUND)))
			// SetAnimation( PLAYER_WALK );
		// else if (self.waterlevel > 1)
			// SetAnimation( PLAYER_WALK );
	// }

	// StudioFrameAdvance();
	// CheckPowerups(pev);

	// UpdatePlayerSound();

pt_end:
	// Decay timers on weapons
	// go through all of the weapons and make a list of the ones to pack
	/*
	for ( int i = 0 ; i < MAX_ITEM_TYPES ; i++ )
	{
		if (m_rgpPlayerItems[ i ])
		{
			CBasePlayerItem *pPlayerItem = m_rgpPlayerItems[ i ];
			while ( pPlayerItem )
			{
				CBasePlayerWeapon *gun;

				gun = (CBasePlayerWeapon *)pPlayerItem->GetWeaponPtr();
				
				if ( gun && gun->UseDecrement() )
				{
					gun->m_flNextPrimaryAttack		= max( gun->m_flNextPrimaryAttack - gpGlobals->frametime, -1.0f );
					gun->m_flNextSecondaryAttack	= max( gun->m_flNextSecondaryAttack - gpGlobals->frametime, -0.001f );

					if ( gun->m_flTimeWeaponIdle != 1000 )
					{
						gun->m_flTimeWeaponIdle		= max( gun->m_flTimeWeaponIdle - gpGlobals->frametime, -0.001f );
					}

					if ( gun->self.fuser1 != 1000 )
					{
						gun->self.fuser1	= max( gun->self.fuser1 - gpGlobals->frametime, -0.001f );
					}
				}
				pPlayerItem = pPlayerItem->m_pNext;
			}
		}
	}

	m_flNextAttack -= gpGlobals->frametime;
	if ( m_flNextAttack < -0.001 )
		m_flNextAttack = -0.001;
	
	if ( m_flNextAmmoBurn != 1000 )
	{
		m_flNextAmmoBurn -= frametime;
		if (m_flNextAmmoBurn < -0.001)
			m_flNextAmmoBurn = -0.001;
	}

	if (m_flAmmoStartCharge != 1000)
	{
		m_flAmmoStartCharge -= frametime;
		if (m_flAmmoStartCharge < -0.001)
			m_flAmmoStartCharge = -0.001;
	}

	// Track button info so we can detect 'pressed' and 'released' buttons next frame
	m_afButtonLast = self.button;
	*/
}



void SetNewParms()
{

}

void SetChangeParms()
{

}

void Player_Think()
{
	self.weaponframe = 0;
	// if(self.weapon == WEAPON_CROWBAR)
	// {
		// if(self.weaponframe < 1 || self.weaponframe > 435)
		// {
			// self.weaponframe = 0;
		// }
		// else self.weaponframe = self.weaponframe + 1;
		// print(ftos(self.weaponframe), "\n");
	// }
	self.reload = FALSE;
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void Player_Pain()
{
	if (self.health < 0) return;
	if (self.pain_finished > time) return;
	self.pain_finished = time + 0.1; // don't make multiple pain sounds right after each other
	
	float rsnd = RandomInt(1, 3);
	if (rsnd == 1) sound (self, CHAN_VOICE, "player/pl_pain5.wav", 1, SoundRadius(800)); 
	else if (rsnd == 2) sound (self, CHAN_VOICE, "player/pl_pain6.wav", 1, SoundRadius(800)); 
	else if (rsnd == 3) sound (self, CHAN_VOICE, "player/pl_pain7.wav", 1, SoundRadius(800)); 
};

/*
void Player_CheckTimeBasedDamage() 
{
	int i;
	float bDuration = 0;

	if (!(m_bitsDamageType & DMG_TIMEBASED))
		return;

	// only check for time based damage approx. every 2 seconds
	if (abs(gpGlobals->time - m_tbdPrev) < 2.0)
		return;
	
	m_tbdPrev = gpGlobals->time;

	for (i = 0; i < CDMG_TIMEBASED; i++)
	{
		// make sure bit is set for damage type
		if (m_bitsDamageType & (DMG_PARALYZE << i))
		{
			switch (i)
			{
			case itbd_Paralyze:
				// UNDONE - flag movement as half-speed
				bDuration = PARALYZE_DURATION;
				break;
			case itbd_NerveGas:
//				TakeDamage(pev, pev, NERVEGAS_DAMAGE, DMG_GENERIC);	
				bDuration = NERVEGAS_DURATION;
				break;
			case itbd_Poison:
				TakeDamage(pev, pev, POISON_DAMAGE, DMG_GENERIC);
				bDuration = POISON_DURATION;
				break;
			case itbd_Radiation:
//				TakeDamage(pev, pev, RADIATION_DAMAGE, DMG_GENERIC);
				bDuration = RADIATION_DURATION;
				break;
			case itbd_DrownRecover:
				// NOTE: this hack is actually used to RESTORE health
				// after the player has been drowning and finally takes a breath
				if (m_idrowndmg > m_idrownrestored)
				{
					int idif = min(m_idrowndmg - m_idrownrestored, 10);

					TakeHealth(idif, DMG_GENERIC);
					m_idrownrestored += idif;
				}
				bDuration = 4;	// get up to 5*10 = 50 points back
				break;
			case itbd_Acid:
//				TakeDamage(pev, pev, ACID_DAMAGE, DMG_GENERIC);
				bDuration = ACID_DURATION;
				break;
			case itbd_SlowBurn:
//				TakeDamage(pev, pev, SLOWBURN_DAMAGE, DMG_GENERIC);
				bDuration = SLOWBURN_DURATION;
				break;
			case itbd_SlowFreeze:
//				TakeDamage(pev, pev, SLOWFREEZE_DAMAGE, DMG_GENERIC);
				bDuration = SLOWFREEZE_DURATION;
				break;
			default:
				bDuration = 0;
			}

			if (m_rgbTimeBasedDamage[i])
			{
				// use up an antitoxin on poison or nervegas after a few seconds of damage					
				if (((i == itbd_NerveGas) && (m_rgbTimeBasedDamage[i] < NERVEGAS_DURATION)) ||
					((i == itbd_Poison)   && (m_rgbTimeBasedDamage[i] < POISON_DURATION)))
				{
					if (m_rgItems[ITEM_ANTIDOTE])
					{
						m_rgbTimeBasedDamage[i] = 0;
						m_rgItems[ITEM_ANTIDOTE]--;
						SetSuitUpdate("!HEV_HEAL4", FALSE, SUIT_REPEAT_OK);
					}
				}


				// decrement damage duration, detect when done.
				if (!m_rgbTimeBasedDamage[i] || --m_rgbTimeBasedDamage[i] == 0)
				{
					m_rgbTimeBasedDamage[i] = 0;
					// if we're done, clear damage bits
					m_bitsDamageType &= ~(DMG_PARALYZE << i);	
				}
			}
			else
				// first time taking this damage type - init damage duration
				m_rgbTimeBasedDamage[i] = bDuration;
		}
	}
}
*/

//Called every frame before physics are run
void PlayerPreThink()
{
	if(gameover) return;
	if(self.deadflag == DEAD_DYING) return;	// dying, so do nothing
	if(self.flags & FL_ONGROUND) self.flags = self.flags - (self.flags & FL_LADDERJUMP);
	
	if (self.deadflag >= DEAD_DYING)
	{
		Player_DeathThink();
		return;
	}
	
	Player_Swim();
	Player_Jump();
	Player_Use();
	Player_Footsteps();
	Player_Stance();
	Player_FixMovement();
	// PlayerAnimation();

	if (time < self.pausetime) self.velocity = '0 0 0'; // teleporters can force a non-moving pause time
};


void Player_TraceAttack(vector org, vector vel, float damage)
{
	if(!self.takedamage) return;
	// damage = DetectHitbox(damage);
	// SpawnBlood(ptr->vecEndPos, vel * 0.2, damage);// a little surface blood.
	// TraceBleed( flDamage, vecDir, ptr, bitsDamageType );
	// AddMultiDamage( pevAttacker, this, flDamage, bitsDamageType );
}

/*
float m_lastDamageAmount;
float Player_TakeDamage(entity pevInflictor, entity pAttacker, float flDamage, float bitsDamageType)
{
	// have suit diagnose the problem - ie: report damage type
	int bitsDamage = bitsDamageType;
	int ffound = TRUE;
	int fmajor;
	int fcritical;
	int fTookDamage;
	int ftrivial;
	
	float flHealthPrev = self.health;
	float flBonus = ARMOR_BONUS;
	float flRatio = ARMOR_RATIO;

	if ((bitsDamageType & DMG_BLAST) && cvar("gamemode") != MODE_SP)
	{
		// blasts damage armor more.
		flBonus *= 2;
	}

	// Already dead
	if (!IsAlive(self))
		return FALSE;
	// go take the damage first

	
	if (!Combat_CanDamage(self, pAttacker))
	{
		// Refuse the damage
		return FALSE;
	}

	// keep track of amount of damage last sustained
	m_lastDamageAmount = flDamage;

	// Armor. 
	if (self.armorvalue && !(bitsDamageType & (DMG_FALL | DMG_DROWN)))// armor doesn't protect against fall or drown damage!
	{
		float flNew = flDamage * flRatio;
		float flArmor = (flDamage - flNew) * flBonus;
		// Does this use more armor than we have?
		if (flArmor > self.armorvalue)
		{
			flArmor = self.armorvalue;
			flArmor *= (1/flBonus);
			flNew = flDamage - flArmor;
			self.armorvalue = 0;
		}
		else
			self.armorvalue -= flArmor;
		
		flDamage = flNew;
	}

	// this cast to INT is critical!!! If a player ends up with 0.5 health, the engine will get that
	// as an int (zero) and think the player is dead! (this will incite a clientside screentilt, etc)
	fTookDamage = Combat_TakeDamage(pevInflictor, pevAttacker, (int)flDamage, bitsDamageType);

	// reset damage time countdown for each type of time based damage player just sustained

	{
		for (int i = 0; i < CDMG_TIMEBASED; i++)
			if (bitsDamageType & (DMG_PARALYZE << i))
				m_rgbTimeBasedDamage[i] = 0;
	}

	// tell director about it
	
	// MESSAGE_BEGIN( MSG_SPEC, SVC_DIRECTOR );
		// WRITE_BYTE ( 9 );	// command length in bytes
		// WRITE_BYTE ( DRC_CMD_EVENT );	// take damage event
		// WRITE_SHORT( ENTINDEX(this->edict()) );	// index number of primary entity
		// WRITE_SHORT( ENTINDEX(ENT(pevInflictor)) );	// index number of secondary entity
		// WRITE_LONG( 5 );   // eventflags (priority and flags)
	// MESSAGE_END();
	

	// how bad is it, doc?
	int ftrivial = (self.health > 75 || m_lastDamageAmount < 5);
	int fmajor = (m_lastDamageAmount > 25);
	int fcritical = (self.health < 30);

	// handle all bits set in this damage message,
	// let the suit give player the diagnosis

	// UNDONE: add sounds for types of damage sustained (ie: burn, shock, slash )

	// UNDONE: still need to record damage and heal messages for the following types

		// DMG_BURN	
		// DMG_FREEZE
		// DMG_BLAST
		// DMG_SHOCK

	m_bitsDamageType |= bitsDamage; // Save this so we can report it to the client
	m_bitsHUDDamage = -1;  // make sure the damage bits get resent

	while (fTookDamage && (!ftrivial || (bitsDamage & DMG_TIMEBASED)) && ffound && bitsDamage)
	{
		ffound = FALSE;

		if (bitsDamage & DMG_CLUB)
		{
			if (fmajor)
				SetSuitUpdate("!HEV_DMG4", FALSE, SUIT_NEXT_IN_30SEC);	// minor fracture
			bitsDamage &= ~DMG_CLUB;
			ffound = TRUE;
		}
		if (bitsDamage & (DMG_FALL | DMG_CRUSH))
		{
			if (fmajor)
				SetSuitUpdate("!HEV_DMG5", FALSE, SUIT_NEXT_IN_30SEC);	// major fracture
			else
				SetSuitUpdate("!HEV_DMG4", FALSE, SUIT_NEXT_IN_30SEC);	// minor fracture
	
			bitsDamage &= ~(DMG_FALL | DMG_CRUSH);
			ffound = TRUE;
		}
		
		if (bitsDamage & DMG_BULLET)
		{
			if (m_lastDamageAmount > 5)
				SetSuitUpdate("!HEV_DMG6", FALSE, SUIT_NEXT_IN_30SEC);	// blood loss detected
			//else
			//	SetSuitUpdate("!HEV_DMG0", FALSE, SUIT_NEXT_IN_30SEC);	// minor laceration
			
			bitsDamage &= ~DMG_BULLET;
			ffound = TRUE;
		}

		if (bitsDamage & DMG_SLASH)
		{
			if (fmajor)
				SetSuitUpdate("!HEV_DMG1", FALSE, SUIT_NEXT_IN_30SEC);	// major laceration
			else
				SetSuitUpdate("!HEV_DMG0", FALSE, SUIT_NEXT_IN_30SEC);	// minor laceration

			bitsDamage &= ~DMG_SLASH;
			ffound = TRUE;
		}
		
		if (bitsDamage & DMG_SONIC)
		{
			if (fmajor)
				SetSuitUpdate("!HEV_DMG2", FALSE, SUIT_NEXT_IN_1MIN);	// internal bleeding
			bitsDamage &= ~DMG_SONIC;
			ffound = TRUE;
		}

		if (bitsDamage & (DMG_POISON | DMG_PARALYZE))
		{
			SetSuitUpdate("!HEV_DMG3", FALSE, SUIT_NEXT_IN_1MIN);	// blood toxins detected
			bitsDamage &= ~(DMG_POISON | DMG_PARALYZE);
			ffound = TRUE;
		}

		if (bitsDamage & DMG_ACID)
		{
			SetSuitUpdate("!HEV_DET1", FALSE, SUIT_NEXT_IN_1MIN);	// hazardous chemicals detected
			bitsDamage &= ~DMG_ACID;
			ffound = TRUE;
		}

		if (bitsDamage & DMG_NERVEGAS)
		{
			SetSuitUpdate("!HEV_DET0", FALSE, SUIT_NEXT_IN_1MIN);	// biohazard detected
			bitsDamage &= ~DMG_NERVEGAS;
			ffound = TRUE;
		}

		if (bitsDamage & DMG_RADIATION)
		{
			SetSuitUpdate("!HEV_DET2", FALSE, SUIT_NEXT_IN_1MIN);	// radiation detected
			bitsDamage &= ~DMG_RADIATION;
			ffound = TRUE;
		}
		if (bitsDamage & DMG_SHOCK)
		{
			bitsDamage &= ~DMG_SHOCK;
			ffound = TRUE;
		}
	}

	self.punchangle.x = -2;

	if (fTookDamage && !ftrivial && fmajor && flHealthPrev >= 75) 
	{
		// first time we take major damage...
		// turn automedic on if not on
		SetSuitUpdate("!HEV_MED1", FALSE, SUIT_NEXT_IN_30MIN);	// automedic on

		// give morphine shot if not given recently
		SetSuitUpdate("!HEV_HEAL7", FALSE, SUIT_NEXT_IN_30MIN);	// morphine shot
	}
	
	if (fTookDamage && !ftrivial && fcritical && flHealthPrev < 75)
	{

		// already took major damage, now it's critical...
		if (self.health < 6)
			SetSuitUpdate("!HEV_HLTH3", FALSE, SUIT_NEXT_IN_10MIN);	// near death
		else if (self.health < 20)
			SetSuitUpdate("!HEV_HLTH2", FALSE, SUIT_NEXT_IN_10MIN);	// health critical
	
		// give critical health warnings
		if (!RANDOM_LONG(0,3) && flHealthPrev < 50)
			SetSuitUpdate("!HEV_DMG7", FALSE, SUIT_NEXT_IN_5MIN); //seek medical attention
	}

	// if we're taking time based damage, warn about its continuing effects
	if (fTookDamage && (bitsDamageType & DMG_TIMEBASED) && flHealthPrev < 75)
		{
			if (flHealthPrev < 50)
			{
				if (!RANDOM_LONG(0,3))
					SetSuitUpdate("!HEV_DMG7", FALSE, SUIT_NEXT_IN_5MIN); //seek medical attention
			}
			else
				SetSuitUpdate("!HEV_HLTH1", FALSE, SUIT_NEXT_IN_10MIN);	// health dropping
		}

	return fTookDamage;
}
*/