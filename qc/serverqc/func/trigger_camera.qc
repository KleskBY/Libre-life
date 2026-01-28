
#define SF_CAMERA_PLAYER_POSITION	1
#define SF_CAMERA_PLAYER_TARGET		2
#define SF_CAMERA_PLAYER_TAKECONTROL 4
#define SF_CORNER_WAITFORTRIG	0x001
#define SF_CORNER_TELEPORT		0x002
#define SF_CORNER_FIREONCE		0x004

.float acceleration;
.float deceleration;
.float return_time;
.float initial_speed;
.float target_speed;
.string moveto;
.entity pentPath;
.float stop_time;

void TriggerCamera_Move();
void TriggerCamera_FollowTarget();

void Trigger_CameraUse()
{
	// if(!ShouldToggle(
	self.state = !self.state;
	if (self.state == 0)
	{
		self.return_time = time;
		return;
	}
	
	if(!activator || activator.classname != "player")
	{
		activator = find(world, classname, "player");	
	}
	
	self.owner = activator;
	self.return_time = time + self.wait;
	self.speed = self.initial_speed;
	self.target_speed = self.initial_speed;
	
	if(self.spawnflags & SF_CAMERA_PLAYER_TARGET)
	{
		self.goalentity = activator;
	}
	else
	{
		self.goalentity = find(world, targetname, self.target);
	}
	
	if(!self.goalentity) return;
	
	if(self.spawnflags & SF_CAMERA_PLAYER_TAKECONTROL)
	{
		//Freeze player
	}
	
	if (self.moveto)
	{
		self.movetarget = find(world, targetname, self.moveto);
	}
	else
	{
		self.movetarget = world;
	}

	self.stop_time = time;
	if (self.movetarget)
	{
		if (self.movetarget.speed != 0 )
			self.target_speed = self.movetarget.speed;
		
		self.stop_time += self.movetarget.delay;
	}

	// copy over player information
	if (self.spawnflags & SF_CAMERA_PLAYER_POSITION)
	{
		setorigin(self, activator.origin + activator.view_ofs);
		self.angles_x = -activator.angles.x;
		self.angles_y = activator.angles.y;
		self.angles_z = 0;
		self.velocity = activator.velocity;
	}
	else
	{
		self.velocity = '0 0 0';
	}

	//SET_VIEW( pActivator->edict(), edict() );
	setmodel(self, activator.model);

	// follow the player down
	self.think = TriggerCamera_FollowTarget;
	self.nextthink = time;
	

	self.distance = 0;
	TriggerCamera_Move();
}


void TriggerCamera_FollowTarget()
{
	if (self.enemy == world)
		return;

	if (self.goalentity == world || self.return_time < time)
	{
		if (IsAlive(self.enemy))
		{
			// SET_VIEW( m_hPlayer->edict(), m_hPlayer->edict() );
			// ((CBasePlayer *)((CBaseEntity *)m_hPlayer))->EnableControl(TRUE);
		}
		SUB_UseTargets();
		self.avelocity = '0 0 0';
		self.state = 0;
		return;
	}

	vector vecGoal = vectoangles(self.goalentity.origin - self.origin);
	vecGoal_x = -vecGoal_x;

	if (self.angles_y > 360)
		self.angles_y -= 360;

	if (self.angles_y < 0)
		self.angles_y += 360;

	float dx = vecGoal_x - self.angles_x;
	float dy = vecGoal_y - self.angles_y;

	if (dx < -180) 
		dx += 360;
	if (dx > 180) 
		dx = dx - 360;
	
	if (dy < -180) 
		dy += 360;
	if (dy > 180) 
		dy = dy - 360;

	self.avelocity_x = dx * 40 * frametime;
	self.avelocity_y = dy * 40 * frametime;


	if (!(self.spawnflags & SF_CAMERA_PLAYER_TAKECONTROL))	
	{
		self.velocity = self.velocity * 0.8;
		if (vlen(self.velocity) < 10.0)
			self.velocity = '0 0 0';
	}

	self.nextthink = time;
	TriggerCamera_Move();
}



void TriggerCamera_Move()
{
	if(!self.movetarget) return;
	
	self.distance -= self.speed * frametime;
	if(self.distance <= 0)
	{
		if(self.movetarget.message)
		{
			// FireTargets
			SUB_UseTargets();
			if(self.movetarget.spawnflags & SF_CORNER_FIREONCE)
				self.movetarget.message = "";
		}
		// Time to go to the next target
		// m_pentPath = m_pentPath->GetNextTarget();
		self.movetarget = find(world, targetname, self.movetarget.target);
		
		if(!self.movetarget)
		{
			self.velocity = '0 0 0';
		}
		else
		{
			if(self.movetarget.speed != 0)
				self.target_speed = self.movetarget.speed;
				
			vector delta = self.movetarget.origin - self.origin;
			self.distance = vlen(delta);
			self.movedir = normalize(delta);
			self.stop_time = time + self.movetarget.delay;
		}
	}
	
	if(self.stop_time > time)
		self.speed = UTIL_Approach(0, self.speed, self.deceleration * frametime);
	else
		self.speed = UTIL_Approach(self.target_speed, self.speed, self.acceleration * frametime);
		
	float fraction = 2 * frametime;
	self.velocity = ((self.movedir * self.speed) * fraction) + (self.velocity * (1-fraction));
	
}

void trigger_camera()
{
	self.movetype = MOVETYPE_NOCLIP;
	self.solid = SOLID_NOT;
	
	self.initial_speed = self.speed;
	if (self.acceleration == 0 )
		self.acceleration = 500;
	if (self.deceleration == 0 )
		self.deceleration = 500;

}