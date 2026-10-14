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
.float saved_movetype;
.float saved_solid;
.float cam_active_flag;	// 1 if view override is active for self.enemy
.float cam_send_t;	// Throttle stuffcmd to ~60Hz
void TriggerCamera_Move();
void TriggerCamera_FollowTarget();

// Wire format (matches CSQC_Ent_Update parser in clientqc/main.qc):
//   byte type   (ENT_CAMERA)
//   byte active (0 = release override, 1 = active payload follows)
//   if active:
//     coord origin xyz
//     angle pitch
//     angle yaw
float Cam_SendEntity(entity ePlayer, float dFlags)
{
	if (ePlayer != self.enemy) return FALSE;
	WriteByte(MSG_ENTITY, ENT_CAMERA);
	WriteByte(MSG_ENTITY, self.cam_active_flag);
	if (self.cam_active_flag)
	{
		WriteCoord(MSG_ENTITY, self.origin_x);
		WriteCoord(MSG_ENTITY, self.origin_y);
		WriteCoord(MSG_ENTITY, self.origin_z);
		WriteAngle(MSG_ENTITY, self.angles_x);
		WriteAngle(MSG_ENTITY, self.angles_y);
	}
	return TRUE;
}

void Cam_StuffPush(entity p)
{
	stuffcmd(p, sprintf("cam %f %f %f %f %f\n",
		self.origin_x, self.origin_y, self.origin_z,
		self.angles_x, self.angles_y));
}
void TriggerCamera_StartFor(entity pActivator)
{
	self.state = !self.state;
	if (self.state == 0)
	{
		self.return_time = time;
		return;
	}
	if (!pActivator || pActivator.classname != "player")
		pActivator = find(world, classname, "player");
	if (!pActivator)
		return;
	self.owner = pActivator;
	self.enemy = pActivator;
	self.return_time = time + self.wait;
	self.speed = self.initial_speed;
	self.target_speed = self.initial_speed;
	if (self.spawnflags & SF_CAMERA_PLAYER_TARGET)
		self.goalentity = pActivator;
	else
		self.goalentity = find(world, targetname, self.target);
	if (!self.goalentity) return;
	if (self.spawnflags & SF_CAMERA_PLAYER_TAKECONTROL)
	{
		self.saved_movetype = pActivator.movetype;
		self.saved_solid    = pActivator.solid;
		pActivator.movetype = MOVETYPE_NONE;
		pActivator.velocity = '0 0 0';
		pActivator.flags    = pActivator.flags | FL_NOTARGET;
	}
	if (self.moveto != "")
		self.movetarget = find(world, targetname, self.moveto);
	else
		self.movetarget = world;
	self.stop_time = time;
	if (self.movetarget)
	{
		if (self.movetarget.speed != 0)
			self.target_speed = self.movetarget.speed;
		self.stop_time += self.movetarget.delay;
	}
	if (self.spawnflags & SF_CAMERA_PLAYER_POSITION)
	{
		setorigin(self, pActivator.origin + pActivator.view_ofs);
		self.angles_x = -pActivator.v_angle_x;
		self.angles_y = pActivator.v_angle_y;
		self.angles_z = 0;
		self.velocity = pActivator.velocity;
	}
	else
	{
		self.velocity = '0 0 0';
	}
	self.cam_active_flag = 1;
	if (IsFTE())
	{
		setsize(self, '-16384 -16384 -16384', '16384 16384 16384');
		self.SendEntity = Cam_SendEntity;
		self.SendFlags  = 1;
	}
	else
	{
		self.cam_send_t = 0;
		Cam_StuffPush(pActivator);
	}
	self.think = TriggerCamera_FollowTarget;
	self.nextthink = time;

	if (self.movetarget)
	{
		vector delta = self.movetarget.origin - self.origin;
		self.distance = vlen(delta);
		self.movedir  = normalize(delta);
		self.stop_time = time + self.movetarget.delay;
		if (self.movetarget.speed != 0)
			self.target_speed = self.movetarget.speed;
	}
	else
	{
		self.distance = 0;
	}
	TriggerCamera_Move();
}
void Trigger_CameraUseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	TriggerCamera_StartFor(pActivator);
}
void Trigger_CameraUse()
{
	TriggerCamera_StartFor(activator);
}
void TriggerCamera_FollowTarget()
{
	if (self.enemy == world)
		return;
	if (self.goalentity == world || self.return_time < time)
	{
		entity p = self.enemy;
		if (p != world && IsAlive(p))
		{
			if (self.spawnflags & SF_CAMERA_PLAYER_TAKECONTROL)
			{
				p.movetype = self.saved_movetype;
				p.solid    = self.saved_solid;
				p.flags    = p.flags - (p.flags & FL_NOTARGET);
			}
		}
		// Release the override.
		self.cam_active_flag = 0;
		if (IsFTE())
		{
			// Final CSQC update (active=0) then disable callback to stop networking
			self.SendFlags  = 1;
			self.SendEntity = __NULL__;
		}
		else if (p != world)
		{
			stuffcmd(p, "camend\n");
		}
		SUB_UseTargetsHL(p, USE_TOGGLE, 0);
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
	if (IsFTE())
	{
		self.SendFlags = 1;
	}
	else if (self.enemy != world && time >= self.cam_send_t)
	{
		self.cam_send_t = time + 0.05;
		Cam_StuffPush(self.enemy);
	}
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
		self.speed = Math_Approach(0, self.speed, self.deceleration * frametime);
	else
		self.speed = Math_Approach(self.target_speed, self.speed, self.acceleration * frametime);
	float fraction = 2 * frametime;
	self.velocity = ((self.movedir * self.speed) * fraction) + (self.velocity * (1-fraction));
}
void trigger_camera()
{
	self.movetype = MOVETYPE_NOCLIP;
	self.solid = SOLID_NOT;
	self.effects = self.effects | EF_NODRAW;
	self.initial_speed = self.speed;
	if (self.acceleration == 0 )
		self.acceleration = 500;
	if (self.deceleration == 0 )
		self.deceleration = 500;
	self.use   = Trigger_CameraUse;
	self.usehl = Trigger_CameraUseHL;
}