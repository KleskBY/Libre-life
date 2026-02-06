.vector		m_controlMins;
.vector		m_controlMaxs;
.float 		m_soundPlaying;

void FuncTrackTrain_NextThink(float thinkTime, float alwaysThink)
{
	if (alwaysThink) self.flags |= FL_ALWAYSTHINK;
	else self.flags &= ~FL_ALWAYSTHINK;
	self.nextthink = thinkTime;
}


void FuncTrackTrain_Blocked()
{
	entvars_t	*pevOther = pOther->pev;

	// Blocker is on-ground on the train
	if (FBitSet(flags, FL_ONGROUND) && other.groundentity == self)
	{
		float deltaSpeed = fabs(self.speed);
		if (deltaSpeed > 50) deltaSpeed = 50;
		if (!other.velocity_z)
			other.velocity_z += deltaSpeed;
		return;
	}
	else
		other.velocity = normalize(other.origin - self.origin) * self.dmg;

	// ALERT( at_aiconsole, "TRAIN(%s): Blocked by %s (dmg:%.2f)\n", STRING(self.targetname), STRING(pOther->self.classname), self.dmg );
	if (self.dmg <= 0)
		return;
	// we can't hurt this thing, so we're not concerned with it
	Combat_TakeDamage(other, self, self, self.dmg, DMG_CRUSH); //pOther->TakeDamage(pev, pev, self.dmg, DMG_CRUSH);
}


void FuncTrackTrain_Use()
{
	if ( useType != USE_SET )
	{
		if ( !ShouldToggle( useType, (self.speed != 0) ) )
			return;

		if ( self.speed == 0 )
		{
			self.speed = m_speed * m_dir;
			
			Next();
		}
		else
		{
			self.speed = 0;
			self.velocity = g_vecZero;
			self.avelocity = g_vecZero;
			StopSound();
			SetThink( NULL );
		}
	}
	else
	{
		float delta = value;
		delta = (rint(self.speed * 4) / rint(m_speed)) * 0.25 + 0.25 * delta;
		if (delta > 1) delta = 1;
		else if (delta < -1) delta = -1;
		if (self.spawnflags & SF_TRACKTRAIN_FORWARDONLY)
		{
			if (delta < 0) delta = 0;
		}
		self.speed = m_speed * delta;
		Next();	
		// ALERT( at_aiconsole, "TRAIN(%s), speed to %.2f\n", STRING(self.targetname), self.speed );
	}
}


#define TRAIN_STARTPITCH	60
#define TRAIN_MAXPITCH		200
#define TRAIN_MAXSPEED		1000	// approx max speed for sound pitch calculation

void FuncTrackTrain_StopSound()
{
	// if sound playing, stop it
	if (self.m_soundPlaying && self.noise)
	{
		float us_encode;
		float us_sound  = (m_sounds & 0x0007) << 12;

		// us_encode = us_sound;

		// PLAYBACK_EVENT_FULL( FEV_RELIABLE | FEV_UPDATE, edict(), m_usAdjustPitch, 0.0, 
			// (float *)&g_vecZero, (float *)&g_vecZero, 0.0, 0.0, us_encode, 0, 1, 0 );

		/*
		STOP_SOUND(ENT(pev), CHAN_STATIC, (char*)STRING(self.noise));
		*/
		sound7(self, CHAN_ITEM, "plats/ttrain_brake1.wav", self.volume, ATTN_NORM, 100, 0);
	}

	m_soundPlaying = 0;
}

// update pitch based on speed, start sound if not playing
// NOTE: when train goes through transition, m_soundPlaying should go to 0, 
// which will cause the looped sound to restart.

void FuncTrackTrain_UpdateSound( void )
{
	if (!self.noise) return;
	float flpitch = TRAIN_STARTPITCH + (fabs(self.speed) * (TRAIN_MAXPITCH - TRAIN_STARTPITCH) / TRAIN_MAXSPEED);

	if (!self.m_soundPlaying)
	{
		// play startup sound for train
		sound7(self, CHAN_ITEM, "plats/ttrain_start1.wav", self.volume, ATTN_NORM, 100, 0);
		sound7(self, CHAN_STATIC, self.noise, self.volume, ATTN_NORM, flpitch, 0);
		self.m_soundPlaying = 1;
	} 
	else
	{
		// unsigned short us_encode;
		// unsigned short us_sound  = ( ( unsigned short )( m_sounds ) & 0x0007 ) << 12;
		// unsigned short us_pitch  = ( ( unsigned short )( flpitch / 10.0 ) & 0x003f ) << 6;
		// unsigned short us_volume = ( ( unsigned short )( m_flVolume * 40.0 ) & 0x003f );

		// us_encode = us_sound | us_pitch | us_volume;

		// PLAYBACK_EVENT_FULL( FEV_RELIABLE | FEV_UPDATE, edict(), m_usAdjustPitch, 0.0, 
			// (float *)&g_vecZero, (float *)&g_vecZero, 0.0, 0.0, us_encode, 0, 0, 0 );
	}
}


void FuncTrackTrain_Next()
{
	float t = 0.5;
	if (!self.speed)
	{
		ALERT( at_aiconsole, "TRAIN(%s): Speed is 0\n", STRING(self.targetname) );
		StopSound();
		return;
	}

//	if ( !m_ppath )
//		m_ppath = CPathTrack::Instance(FIND_ENTITY_BY_TARGETNAME( NULL, STRING(self.target) ));
	if ( !m_ppath )
	{	
		ALERT( at_aiconsole, "TRAIN(%s): Lost path\n", STRING(self.targetname) );
		StopSound();
		return;
	}

	UpdateSound();

	Vector nextPos = self.origin;

	nextPos.z -= m_height;
	CPathTrack *pnext = m_ppath->LookAhead( &nextPos, self.speed * 0.1, 1 );
	nextPos.z += m_height;

	self.velocity = (nextPos - self.origin) * 10;
	Vector nextFront = self.origin;

	nextFront.z -= m_height;
	if ( m_length > 0 )
		m_ppath->LookAhead( &nextFront, m_length, 0 );
	else
		m_ppath->LookAhead( &nextFront, 100, 0 );
	nextFront.z += m_height;

	Vector delta = nextFront - self.origin;
	Vector angles = UTIL_VecToAngles( delta );
	// The train actually points west
	angles.y += 180;

	// !!!  All of this crap has to be done to make the angles not wrap around, revisit this.
	FixupAngles( angles );
	FixupAngles( self.angles );

	if ( !pnext || (delta.x == 0 && delta.y == 0) )
		angles = self.angles;

	float vy, vx;
	if ( !(self.spawnflags & SF_TRACKTRAIN_NOPITCH) )
		vx = UTIL_AngleDistance( angles.x, self.angles.x );
	else
		vx = 0;
	vy = UTIL_AngleDistance( angles.y, self.angles.y );

	self.avelocity.y = vy * 10;
	self.avelocity.x = vx * 10;

	if ( m_flBank != 0 )
	{
		if ( self.avelocity.y < -5 )
			self.avelocity.z = UTIL_AngleDistance( UTIL_ApproachAngle( -m_flBank, self.angles.z, m_flBank*2 ), self.angles.z);
		else if ( self.avelocity.y > 5 )
			self.avelocity.z = UTIL_AngleDistance( UTIL_ApproachAngle( m_flBank, self.angles.z, m_flBank*2 ), self.angles.z);
		else
			self.avelocity.z = UTIL_AngleDistance( UTIL_ApproachAngle( 0, self.angles.z, m_flBank*4 ), self.angles.z) * 4;
	}
		
	if ( pnext )
	{
		if ( pnext != m_ppath )
		{
			CPathTrack *pFire;
			if ( self.speed >= 0 )
				pFire = pnext;
			else 
				pFire = m_ppath;

			m_ppath = pnext;
			// Fire the pass target if there is one
			if ( pFire->self.message )
			{
				FireTargets( STRING(pFire->self.message), this, this, USE_TOGGLE, 0 );
				if ( FBitSet( pFire->self.spawnflags, SF_PATH_FIREONCE ) )
					pFire->self.message = 0;
			}

			if ( pFire->self.spawnflags & SF_PATH_DISABLE_TRAIN )
				self.spawnflags |= SF_TRACKTRAIN_NOCONTROL;
			
			// Don't override speed if under user control
			if ( self.spawnflags & SF_TRACKTRAIN_NOCONTROL )
			{
				if ( pFire->self.speed != 0 )
				{// don't copy speed from target if it is 0 (uninitialized)
					self.speed = pFire->self.speed;
					ALERT( at_aiconsole, "TrackTrain %s speed to %4.2f\n", STRING(self.targetname), self.speed );
				}
			}

		}
		SetThink( &CFuncTrackTrain::Next );
		NextThink( self.ltime + t, TRUE );
	}
	else	// end of path, stop
	{
		StopSound();
		self.velocity = (nextPos - self.origin);
		self.avelocity = g_vecZero;
		float distance = self.velocity.Length();
		m_oldSpeed = self.speed;


		self.speed = 0;
		
		// Move to the dead end
		
		// Are we there yet?
		if ( distance > 0 )
		{
			// no, how long to get there?
			time = distance / m_oldSpeed;
			self.velocity = self.velocity * (m_oldSpeed / distance);
			SetThink( &CFuncTrackTrain::DeadEnd );
			NextThink( self.ltime + t, FALSE );
		}
		else
		{
			DeadEnd();
		}
	}
}


void CFuncTrackTrain::DeadEnd( void )
{
	// Fire the dead-end target if there is one
	CPathTrack *pTrack, *pNext;

	pTrack = m_ppath;

	ALERT( at_aiconsole, "TRAIN(%s): Dead end ", STRING(self.targetname) );
	// Find the dead end path node
	// HACKHACK -- This is bugly, but the train can actually stop moving at a different node depending on it's speed
	// so we have to traverse the list to it's end.
	if ( pTrack )
	{
		if ( m_oldSpeed < 0 )
		{
			do
			{
				pNext = pTrack->ValidPath( pTrack->GetPrevious(), TRUE );
				if ( pNext )
					pTrack = pNext;
			} while ( pNext );
		}
		else
		{
			do
			{
				pNext = pTrack->ValidPath( pTrack->GetNext(), TRUE );
				if ( pNext )
					pTrack = pNext;
			} while ( pNext );
		}
	}

	self.velocity = g_vecZero;
	self.avelocity = g_vecZero;
	if ( pTrack )
	{
		ALERT( at_aiconsole, "at %s\n", STRING(pTrack->self.targetname) );
		if ( pTrack->self.netname )
			FireTargets( STRING(pTrack->self.netname), this, this, USE_TOGGLE, 0 );
	}
	else
		ALERT( at_aiconsole, "\n" );
}


void CFuncTrackTrain :: SetControls( entvars_t *pevControls )
{
	Vector offset = pevControls->origin - self.oldorigin;

	m_controlMins = pevControls->mins + offset;
	m_controlMaxs = pevControls->maxs + offset;
}


BOOL CFuncTrackTrain :: OnControls( entvars_t *pevTest )
{
	Vector offset = pevTest->origin - self.origin;

	if ( self.spawnflags & SF_TRACKTRAIN_NOCONTROL )
		return FALSE;

	// Transform offset into local coordinates
	UTIL_MakeVectors( self.angles );
	Vector local;
	local.x = DotProduct( offset, gpGlobals->v_forward );
	local.y = -DotProduct( offset, gpGlobals->v_right );
	local.z = DotProduct( offset, gpGlobals->v_up );

	if ( local.x >= m_controlMins.x && local.y >= m_controlMins.y && local.z >= m_controlMins.z &&
		 local.x <= m_controlMaxs.x && local.y <= m_controlMaxs.y && local.z <= m_controlMaxs.z )
		 return TRUE;

	return FALSE;
}


void CFuncTrackTrain :: Find( void )
{
	m_ppath = CPathTrack::Instance(FIND_ENTITY_BY_TARGETNAME( NULL, STRING(self.target) ));
	if ( !m_ppath )
		return;

	entvars_t *pevTarget = m_ppath->pev;
	if ( !FClassnameIs( pevTarget, "path_track" ) )
	{
		ALERT( at_error, "func_track_train must be on a path of path_track\n" );
		m_ppath = NULL;
		return;
	}

	Vector nextPos = pevTarget->origin;
	nextPos.z += m_height;

	Vector look = nextPos;
	look.z -= m_height;
	m_ppath->LookAhead( &look, m_length, 0 );
	look.z += m_height;

	self.angles = UTIL_VecToAngles( look - nextPos );
	// The train actually points west
	self.angles.y += 180;

	if ( self.spawnflags & SF_TRACKTRAIN_NOPITCH )
		self.angles.x = 0;
    UTIL_SetOrigin( pev, nextPos );
	NextThink( self.ltime + 0.1, FALSE );
	SetThink( &CFuncTrackTrain::Next );
	self.speed = m_startSpeed;

	UpdateSound();
}


void CFuncTrackTrain :: NearestPath( void )
{
	CBaseEntity *pTrack = NULL;
	CBaseEntity *pNearest = NULL;
	float dist, closest;

	closest = 1024;

	while ((pTrack = UTIL_FindEntityInSphere( pTrack, self.origin, 1024 )) != NULL)
	{
		// filter out non-tracks
		if ( !(pTrack->self.flags & (FL_CLIENT|FL_MONSTER)) && FClassnameIs( pTrack->pev, "path_track" ) )
		{
			dist = (self.origin - pTrack->self.origin).Length();
			if ( dist < closest )
			{
				closest = dist;
				pNearest = pTrack;
			}
		}
	}

	if ( !pNearest )
	{
		ALERT( at_console, "Can't find a nearby track !!!\n" );
		SetThink(NULL);
		return;
	}

	ALERT( at_aiconsole, "TRAIN: %s, Nearest track is %s\n", STRING(self.targetname), STRING(pNearest->self.targetname) );
	// If I'm closer to the next path_track on this path, then it's my real path
	pTrack = ((CPathTrack *)pNearest)->GetNext();
	if ( pTrack )
	{
		if ( (self.origin - pTrack->self.origin).Length() < (self.origin - pNearest->self.origin).Length() )
			pNearest = pTrack;
	}

	m_ppath = (CPathTrack *)pNearest;

	if ( self.speed != 0 )
	{
		NextThink( self.ltime + 0.1, FALSE );
		SetThink( &CFuncTrackTrain::Next );
	}
}


void FuncTrackTrain_OverrideReset()
{
	NextThink( self.ltime + 0.1, FALSE );
	SetThink( &CFuncTrackTrain::NearestPath );
}


CFuncTrackTrain *CFuncTrackTrain::Instance( edict_t *pent )
{ 
	if ( FClassnameIs( pent, "func_tracktrain" ) )
		return (CFuncTrackTrain *)GET_PRIVATE(pent);
	return NULL;
}


void FuncTrackTrain_Precache()
{
	switch (self.sounds)
	{
	default:
		// no sound
		self.noise = 0;
		break;
	case 1: precache_sound("plats/ttrain1.wav"); self.noise = MAKE_STRING("plats/ttrain1.wav");break;
	case 2: precache_sound("plats/ttrain2.wav"); self.noise = MAKE_STRING("plats/ttrain2.wav");break;
	case 3: precache_sound("plats/ttrain3.wav"); self.noise = MAKE_STRING("plats/ttrain3.wav");break; 
	case 4: precache_sound("plats/ttrain4.wav"); self.noise = MAKE_STRING("plats/ttrain4.wav");break;
	case 5: precache_sound("plats/ttrain6.wav"); self.noise = MAKE_STRING("plats/ttrain6.wav");break;
	case 6: precache_sound("plats/ttrain7.wav"); self.noise = MAKE_STRING("plats/ttrain7.wav");break;
	}
	
	precache_sound("plats/ttrain_brake1.wav");
	precache_sound("plats/ttrain_start1.wav");

};

void func_tracktrain()
{
	if (self.speed == 0) self.speed = 100;
	else self.speed = self.speed;
	
	self.speed = 0;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.impulse = self.speed;

	self.dir = 1;

	if(!self.target) objerror("FuncTrain with no target\n");
	
	if (self.spawnflags & SF_TRACKTRAIN_PASSABLE)
		self.solid = SOLID_NOT;
	else
		self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	
	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);

	// Cache off placed origin for train controls
	self.oldorigin = self.origin;

	m_controlMins = self.mins;
	m_controlMaxs = self.maxs;
	m_controlMaxs_z += 72;
// start trains on the next frame, to make sure their targets have had
// a chance to spawn/activate
	self.nextthink = self.ltime + 0.1;
	seld.think = FuncTrackTrain_Find;
	FuncTrackTrain_Precache();
}