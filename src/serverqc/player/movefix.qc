// How much faster than the walk input noclip travels, and again with sprint
// held. The input vector already carries the stance speed, so these only scale
// what the player asked for.
#define NOCLIP_SCALE        3
#define NOCLIP_SPRINT_SCALE 3

void BetterNoclip()
{
	if (self.movetype != MOVETYPE_NOCLIP) return;
	if (self.button2 || self.button3) return;

	// Only FTE needs this. Zircon's MOVETYPE_NOCLIP integrates the velocity its
	// own client physics set and replaces whatever PreThink wrote, so the branch
	// below would do nothing there; the legacy boost after it is left untouched
	// so that engine keeps exactly the feel it has.
	if (IsFTE())
	{
		makevectors(self.v_angle);

		// movement_x is forward, _y strafe, _z up. The version this replaces fed
		// movement_z into v_right at thirty times scale and never read movement_y,
		// so jump and crouch slid the camera sideways and strafing did nothing.
		vector wish = v_forward * self.movement_x
		            + v_right   * self.movement_y
		            + v_up      * self.movement_z;

		float scale = NOCLIP_SCALE;
		if (self.button4) scale = scale * NOCLIP_SPRINT_SCALE;

		// ASSIGNED, never accumulated, and that is the whole fix. The old code
		// added to velocity and then multiplied velocity_z by ten EVERY FRAME,
		// with a further times four while sprint was held. On Zircon the engine
		// overwrote velocity each frame so it never compounded; on FTE it does,
		// and ten to the power of the frame count put the player through the
		// floor within a few frames of touching a movement key.
		self.velocity = wish * scale;
		return;
	}

	if (self.button4) self.velocity = self.velocity * 4;
}

void ResetMovetypeAfterLadder()
{
	if(self.movetype == MOVETYPE_FLY && self.lastTouch < time)
	{
		self.movetype = MOVETYPE_WALK;
	}
}

void Player_TouchGroundEntity()
{
	entity g = self.groundentity;
	if (!g || g == world || !g.touch) return;
	if (g.classname != "func_button" && g.classname != "func_rot_button") return;

	entity oself = self;
	entity oother = other;
	other = self;			// toucher
	self = g;				// touch handlers run with self == the brush entity
	g.touch();
	self = oself;
	other = oother;
}

void Player_FixMovement()
{
	if(self.groundentity && self.groundentity.classname == "func_conveyor")
	{
		self.velocity = self.velocity + self.groundentity.speed * self.groundentity.movedir * frametime * 2;
	}
	Player_TouchGroundEntity();
	BetterNoclip();
	ResetMovetypeAfterLadder();
	self.angles_x = 0; // Fix ugly vertical model lean
}