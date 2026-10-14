
#define TRAIN_STARTPITCH	60
#define TRAIN_MAXPITCH		200
#define TRAIN_MAXSPEED		1000

.vector		tracktrain_controlMins;
.vector		tracktrain_controlMaxs;
.float 		tracktrain_soundPlaying;
.float 		bank;
.float		height;
.float		oldspeed;
.entity 	tracktrain_path;
.float		wheels;
.float		startspeed;
.float		tracktrain_dir;   // direction (+1/-1)
.float		m_speed;


// pathtrack_lookahead_origin is declared in path_track.qc (compiles first);
// PathTrack_LookAhead/Project's "out parameter"
void FuncTrackTrain_Next();
void FuncTrackTrain_StopSound();
void FuncTrackTrain_DeadEnd();
float ChangeLevel_TrainRestorePending(entity train);	// trigger_changelevel.qc

void FuncTrackTrain_NextThink(float thinkTime, float alwaysThink)
{
	if (alwaysThink) self.flags |= FL_ALWAYSTHINK;
	else self.flags &= ~FL_ALWAYSTHINK;
	self.nextthink = thinkTime;
}

// FL_ONGROUND alone misses riders: the push clears it whenever the carried move
// is clipped, and a rider is airborne for a frame on every bump. groundentity
// survives that, so it gates; the deck probe confirms the rider is still over
// the train rather than carrying a stale link after jumping off.
float FuncTrackTrain_IsRider(entity e)
{
	if (e.groundentity != self) return FALSE;
	if (e.flags & FL_ONGROUND) return TRUE;

	vector c = (e.absmin + e.absmax) * 0.5;
	float inX = (e.maxs_x - e.mins_x) * 0.5 - 2;
	float inY = (e.maxs_y - e.mins_y) * 0.5 - 2;
	float probe = e.absmin_z + 18;          // above a deck the rider has sunk into, below a hood it is hit by
	for (float i = 0; i < 5; i++)
	{
		vector p = [c_x, c_y, probe];
		if (i == 1) p = p + [ inX,  inY, 0];
		if (i == 2) p = p + [ inX, -inY, 0];
		if (i == 3) p = p + [-inX,  inY, 0];
		if (i == 4) p = p + [-inX, -inY, 0];
		traceline(p, p - '0 0 42', TRUE, e);
		if (trace_ent == self && !trace_startsolid && trace_plane_normal_z > 0.7)
			return TRUE;
	}
	return FALSE;
}

void FuncTrackTrain_Blocked()
{
	if (FuncTrackTrain_IsRider(other))
	{
		float deltaSpeed = fabs(self.speed);
		if (deltaSpeed > 50) deltaSpeed = 50;
		if (!other.velocity_z) other.velocity_z += deltaSpeed;
		return;                             // never crush whoever is riding
	}

	if (Blocked_IgnorePhantom(other))
		return;

	other.velocity = normalize(other.origin - self.origin) * self.dmg;

	dprint("TRAIN(");
	dprint(self.targetname);
	dprint("): Blocked by ");
	dprint(other.classname);
	dprint(" (dmg:");
	dprint(ftos(self.dmg));
	dprint(")\n");
	
	if (self.dmg <= 0) return;
	// cannot be hurt, so we ignore it
	entity blocker = other;
	Combat_TakeDamage(blocker, self, self, self.dmg, DMG_CRUSH);

	if (blocker.health <= 0 || blocker.takedamage == DAMAGE_NO)
	{
		blocker.solid    = SOLID_NOT;
		blocker.movetype = MOVETYPE_NONE;
		setorigin(blocker, blocker.origin);
	}
}


void FuncTrackTrain_DoUse(float utype, float uvalue)
{
	if (utype != USE_SET)
	{
		useType = utype;	// ShouldToggle() reads global
		if (!ShouldToggle(self.speed != 0))
			return;

		if (self.speed == 0)
		{
			self.speed = self.m_speed * self.tracktrain_dir;
			FuncTrackTrain_Next();
			dprint("TRAIN(");
			dprint(self.targetname);
			dprint("): USE -> started, speed=");
			dprint(ftos(self.speed));
			dprint("\n");
		}
		else
		{
			self.speed = 0;
			self.velocity = '0 0 0';
			self.avelocity = '0 0 0';
			FuncTrackTrain_StopSound();
			self.think = SUB_Null;
			dprint("TRAIN(");
			dprint(self.targetname);
			dprint("): USE -> stopped\n");
		}
	}
	else
	{
		float delta = uvalue;
		delta = (rint(self.speed * 4) / rint(self.m_speed)) * 0.25 + 0.25 * delta;
		if (delta > 1) delta = 1;
		else if (delta < -1) delta = -1;
		if (self.spawnflags & SF_TRACKTRAIN_FORWARDONLY)
		{
			if (delta < 0) delta = 0;
		}
		self.speed = self.m_speed * delta;
		FuncTrackTrain_Next();
		dprint("TRAIN(");
		dprint(self.targetname);
		dprint("), speed to ");
		dprint(ftos(self.speed));
		dprint("\n");
	}
}

void FuncTrackTrain_Use()
{
	FuncTrackTrain_DoUse(useType, useValue);
}

void FuncTrackTrain_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	FuncTrackTrain_DoUse(useTypeArg, useValueArg);
}


void FuncTrackTrain_StopSound()
{
	if (self.tracktrain_soundPlaying && self.noise)
	{


				Sound_Play(self, CHAN_ITEM, self.volume, ATTN_NORM, 100, "plats/ttrain_brake1.wav");
	}

	self.tracktrain_soundPlaying = FALSE;
}

// NOTE: when train transitions, tracktrain_soundPlaying must go to 0

void FuncTrackTrain_UpdateSound( void )
{
	if (!self.noise) return;
	float flpitch = TRAIN_STARTPITCH + (fabs(self.speed) * (TRAIN_MAXPITCH - TRAIN_STARTPITCH) / TRAIN_MAXSPEED);

	if (!self.tracktrain_soundPlaying)
	{
		Sound_Play(self, CHAN_ITEM, self.volume, ATTN_NORM, 100, "plats/ttrain_start1.wav");
		Sound_Play(self, CHAN_STATIC, self.volume, ATTN_NORM, flpitch, self.noise);
		self.tracktrain_soundPlaying = 1;
	} 
	else
	{


	}
}


void FuncTrackTrain_Next()
{
	float t = 0.1;
	if (!self.speed)
	{
		dprint("TRAIN(");
		dprint(self.targetname);
		dprint("): Speed is 0\n");
		FuncTrackTrain_StopSound();
		return;
	}

	if (!self.tracktrain_path)
	{	
		dprint("TRAIN(");
		dprint(self.targetname);
		dprint("): Lost path\n");
		FuncTrackTrain_StopSound();
		return;
	}

	FuncTrackTrain_UpdateSound();
	vector nextPos = self.origin;

	nextPos_z -= self.height;
	entity pnext = PathTrack_LookAhead(self.tracktrain_path, nextPos, self.speed * 0.1, TRUE);
	nextPos = pathtrack_lookahead_origin;
	nextPos_z += self.height;
	self.velocity = (nextPos - self.origin) * 10;
	vector nextFront = self.origin;

	nextFront_z -= self.height;
	if (self.wheels > 0)
	{
		PathTrack_LookAhead(self.tracktrain_path, nextFront, self.wheels, FALSE);
		nextFront = pathtrack_lookahead_origin;
	}
	else
	{
		PathTrack_LookAhead(self.tracktrain_path, nextFront, 100, FALSE);
		nextFront = pathtrack_lookahead_origin;
	}
	nextFront_z += self.height;


	vector delta = nextFront - self.origin;
	if (vlen(delta) > 0.001)
	{
		vector ang = vectoangles(delta);
		ang_y += 180;
		
		// All of this must be done to prevent angle wrapping; revisit this.
		ang = Math_FixupAngles(ang);
		self.angles = Math_FixupAngles(self.angles);

		if (!pnext || (delta_x == 0 && delta_y == 0))
			ang = self.angles;

		float vy, vx;
		if (!(self.spawnflags & SF_TRACKTRAIN_NOPITCH))
			vx = Math_AngleDistance(ang_x, self.angles_x);
		else
			vx = 0;
		vy = Math_AngleDistance(ang_y, self.angles_y);

		self.avelocity_y = vy * 10;
		self.avelocity_x = vx * 10;
		
		if (self.bank != 0)
		{
			if (self.avelocity_y < -5)
				self.avelocity_z = Math_AngleDistance(Math_ApproachAngle(-self.bank, self.angles_z, self.bank*2), self.angles_z);
			else if (self.avelocity_y > 5)
				self.avelocity_z = Math_AngleDistance(Math_ApproachAngle(self.bank, self.angles_z, self.bank*2), self.angles_z);
			else
				self.avelocity_z = Math_AngleDistance(Math_ApproachAngle(0, self.angles_z, self.bank*4), self.angles_z) * 4;
		}
	}
		
	if (pnext)
	{
		if (pnext != self.tracktrain_path)
		{
			entity pFire;
			if (self.speed >= 0) pFire = pnext;
			else pFire = self.tracktrain_path;

			self.tracktrain_path = pnext;
			if (pFire.message)
			{
				SUB_FireTargets(pFire.message, self, self, USE_TOGGLE, 0); // FireTargets(pFire.message, this, this, USE_TOGGLE, 0 );
				if (pFire.spawnflags & SF_PATH_FIREONCE)
					pFire.message = "";
			}

			if (pFire.spawnflags & SF_PATH_DISABLE_TRAIN)
				self.spawnflags |= SF_TRACKTRAIN_NOCONTROL;
			
			if (self.spawnflags & SF_TRACKTRAIN_NOCONTROL)
			{
				if (pFire.speed != 0)
				{
					self.speed = pFire.speed;
					dprint("TrackTrain ");
					dprint(self.targetname);
					dprint(" speed to ");
					dprint(ftos(self.speed));
					dprint("\n");
				}
			}

		}
		self.think = FuncTrackTrain_Next;
		FuncTrackTrain_NextThink(self.ltime + t, TRUE);
	}
	else
	{
		FuncTrackTrain_StopSound();
		self.velocity = (nextPos - self.origin);
		self.avelocity = '0 0 0';
		float distance = vlen(self.velocity);
		self.oldspeed = self.speed;
		self.speed = 0;
		
		if (distance > 0)
		{
			t = distance / self.oldspeed;
			self.velocity = self.velocity * (self.oldspeed / distance);
			self.think = FuncTrackTrain_DeadEnd;
			FuncTrackTrain_NextThink(self.ltime + t, FALSE);
		}
		else
		{
			FuncTrackTrain_DeadEnd();
		}
	}
}


void FuncTrackTrain_DeadEnd()
{

	entity pTrack = self.tracktrain_path;
	entity pNext;
	dprint("TRAIN(");
	dprint(self.targetname);
	dprint("): Dead end ");
	if (pTrack)
	{
		if (self.oldspeed < 0)
		{
			do
			{
				pNext = PathTrack_ValidPath(PathTrack_GetPrevious(pTrack), TRUE);
				if (pNext != world) pTrack = pNext;
			} 
			while (pNext != world);
		}
		else
		{
			do
			{
				pNext = PathTrack_ValidPath(PathTrack_GetNext(pTrack), TRUE);
				if (pNext != world) pTrack = pNext;
			} 
			while (pNext != world);
		}
	}

	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	if (pTrack)
	{
		dprint("at ");
		dprint(pTrack.targetname);
		if (pTrack.netname)
		{
			SUB_FireTargets(pTrack.netname, self, self, USE_TOGGLE, 0);
		}
	}
	dprint("\n");
}


void FuncTrackTrain_SetControls(entity ptrain, entity pevControls)
{
	vector offset = pevControls.origin - ptrain.oldorigin;
	ptrain.tracktrain_controlMins = pevControls.mins + offset;
	ptrain.tracktrain_controlMaxs = pevControls.maxs + offset;
}


float FuncTrackTrain_OnControls(entity pevTest)
{
	vector offset = pevTest.origin - self.origin;

	if (self.spawnflags & SF_TRACKTRAIN_NOCONTROL)
		return FALSE;

	makevectors(self.angles);
	vector loc;
	loc_x = Math_DotProduct(offset, v_forward);
	loc_y = -Math_DotProduct(offset, v_right);
	loc_z = Math_DotProduct(offset, v_up);

	if (loc_x >= self.tracktrain_controlMins_x && loc_y >= self.tracktrain_controlMins_y && loc_z >= self.tracktrain_controlMins_z &&
		 loc_x <= self.tracktrain_controlMaxs_x && loc_y <= self.tracktrain_controlMaxs_y && loc_z <= self.tracktrain_controlMaxs_z )
		 return TRUE;

	return FALSE;
}


void FuncTrackTrain_Find()
{
	dprint("TRAIN(");
	dprint(self.targetname);
	dprint("): Find target='");
	dprint(self.target);
	dprint("' startspeed=");
	dprint(ftos(self.startspeed));
	dprint(" m_speed=");
	dprint(ftos(self.m_speed));
	dprint("\n");

	self.tracktrain_path = find(world, targetname, self.target);
	if (self.tracktrain_path == world)
	{
		dprint("TRAIN(");
		dprint(self.targetname);
		dprint("): find returned world (no path_track with that targetname)\n");
		return;
	}

	if (self.tracktrain_path.classname != "path_track")
	{
		dprint("func_track_train must be on a path of path_track (got classname=");
		dprint(self.tracktrain_path.classname);
		dprint(")\n");
		self.tracktrain_path = world;
		return;
	}

	vector nextPos = self.tracktrain_path.origin;
	nextPos_z += self.height;

	vector look = nextPos;
	look_z -= self.height;
	PathTrack_LookAhead(self.tracktrain_path, look, self.wheels, 0);
	look = pathtrack_lookahead_origin;
	look_z += self.height;

	self.angles = vectoangles(look - nextPos);
	self.angles.y += 180;

	if (self.spawnflags & SF_TRACKTRAIN_NOPITCH)
		self.angles.x = 0;
    setorigin(self, nextPos);
	FuncTrackTrain_NextThink( self.ltime + 0.1, FALSE );
	self.think = FuncTrackTrain_Next;
	self.speed = self.startspeed;

	dprint("TRAIN(");
	dprint(self.targetname);
	dprint("): Find done, speed=");
	dprint(ftos(self.speed));
	dprint(" tracktrain_path=");
	dprint(self.tracktrain_path.targetname);
	dprint("\n");

	FuncTrackTrain_UpdateSound();
}


void FuncTrackTrain_NearestPath()
{
	entity pTrack;
	entity pNearest;
	float dist;
	float closest = 1024;

	pTrack = findradius(self.origin, 1024);
	while (pTrack)
	{
		if (!(pTrack.flags & (FL_CLIENT|FL_MONSTER)) && pTrack.classname == "path_track")
		{
			dist = vlen(self.origin - pTrack.origin);
			if (dist < closest)
			{
				closest = dist;
				pNearest = pTrack;
			}
		}
		pTrack = pTrack.chain;
	}

	if (!pNearest)
	{
		dprint( "Can't find a nearby track !!!\n" );
		self.think = SUB_Null;
		return;
	}

	dprint("TRAIN: ");
	dprint(self.targetname);
	dprint(", Nearest track is ");
	dprint(pNearest.targetname);
	dprint("\n");
	
	pTrack = PathTrack_GetNext(pNearest);
	if (pTrack)
	{
		if (vlen(self.origin - pTrack.origin) < vlen(self.origin - pNearest.origin))
			pNearest = pTrack;
	}

	self.tracktrain_path = pNearest;

	if (self.speed != 0)
	{
		FuncTrackTrain_NextThink( self.ltime + 0.1, FALSE );
		self.think = FuncTrackTrain_Next;
	}
}


void FuncTrackTrain_OverrideReset()
{
	FuncTrackTrain_NextThink(self.ltime + 0.1, FALSE);
	self.think = FuncTrackTrain_NearestPath;
}


entity FuncTrackTrain_Instance(entity pent)
{ 
	if (pent.classname == "func_tracktrain")
	{
		return pent;
	}
	return world;
}


void FuncTrackTrain_Precache()
{
	if(!self.volume) self.volume = 1;
	else if(self.volume > 1) self.volume = self.volume / 10;
	
	switch (self.sounds)
	{
	default:
		// no sound
		self.noise = 0;
		break;
	case 1: precache_sound("plats/ttrain1.wav"); self.noise = ("plats/ttrain1.wav"); break;
	case 2: precache_sound("plats/ttrain2.wav"); self.noise = ("plats/ttrain2.wav"); break;
	case 3: precache_sound("plats/ttrain3.wav"); self.noise = ("plats/ttrain3.wav"); break; 
	case 4: precache_sound("plats/ttrain4.wav"); self.noise = ("plats/ttrain4.wav"); break;
	case 5: precache_sound("plats/ttrain6.wav"); self.noise = ("plats/ttrain6.wav"); break;
	case 6: precache_sound("plats/ttrain7.wav"); self.noise = ("plats/ttrain7.wav"); break;
	}
	
	precache_sound("plats/ttrain_brake1.wav");
	precache_sound("plats/ttrain_start1.wav");

};

// Armed instead of Find() when a landmark transition has this train staged.
// If the restore ran, it replaced this think, so reaching here means the
// arriving-player code never fired (no info_landmark, transfer invalid, plain
// respawn) and the train would otherwise never start. Take the normal path.
void FuncTrackTrain_RestoreFallback()
{
	if (ChangeLevel_TrainRestorePending(self))
		FuncTrackTrain_Find();
}

void func_tracktrain()
{
	dprint("func_tracktrain spawn: targetname='");
	dprint(self.targetname);
	dprint("' target='");
	dprint(self.target);
	dprint("' speed=");
	dprint(ftos(self.speed));
	dprint(" startspeed=");
	dprint(ftos(self.startspeed));
	dprint(" spawnflags=");
	dprint(ftos(self.spawnflags));
	dprint("\n");

	// Base speed (m_speed) is stored separately; self.speed is runtime speed (0 when stopped).
	if (self.speed == 0) self.m_speed = 100;
	else self.m_speed = self.speed;

	self.speed = 0;
	self.velocity = '0 0 0';
	self.avelocity = '0 0 0';
	self.impulse = self.m_speed;
	self.tracktrain_dir = 1;

	if (self.target == "") objerror("func_tracktrain with no target\n");
	
	if (self.spawnflags & SF_TRACKTRAIN_PASSABLE)
		self.solid = SOLID_NOT;
	else
		self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	
	setmodel(self, self.model);
	setsize(self, self.mins, self.maxs);
	setorigin(self, self.origin);
	Render_Apply(self);
	Brush_ApplyContents(self);

	// Static config off the map's "wheels" key, so it exists on every path into
	// the entity. Find() is not one of them, as a landmark arrival skips it, and
	// func_trackautochange's TrackChange_EvaluateTrain reads pathtrack_length to
	// decide FOLLOWING vs BLOCKING. At 0 every train reads BLOCKING and the
	// autochange refuses to move (c0a0b: train parks forever at path_track
	// "upper1" instead of riding the lift down to "lower1").
	if (self.wheels <= 0) self.wheels = 100;
	self.pathtrack_length = self.wheels;

	self.oldorigin = self.origin;

	self.tracktrain_controlMins = self.mins;
	self.tracktrain_controlMaxs = self.maxs;
	self.tracktrain_controlMaxs_z += 72;

	self.use   = FuncTrackTrain_Use;
	self.usehl = FuncTrackTrain_UseHL;
	self.object_caps = FCAP_IMPULSE_USE;
	self.blocked = FuncTrackTrain_Blocked;

	if (ChangeLevel_TrainRestorePending(self))
	{
		// A landmark transition owns this train's origin, angles, path and
		// speed. Find() would snap it onto path node 0 and re-derive its
		// angles, which is the CFuncTrackTrain::OverrideReset case, on a
		// restore code deliberately does NOT call Find(). ChangeLevel_RestoreTrain
		// installs the real think.
		self.think = FuncTrackTrain_RestoreFallback;
		self.nextthink = self.ltime + 0.5;
	}
	else
	{
		self.nextthink = self.ltime + 0.1;
		self.think = FuncTrackTrain_Find;
	}
	FuncTrackTrain_Precache();
}
