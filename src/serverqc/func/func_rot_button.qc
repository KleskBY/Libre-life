#define SF_DOOR_ROTATE_Y			0
#define SF_DOOR_START_OPEN			1
#define SF_DOOR_ROTATE_BACKWARDS		2
#define SF_DOOR_PASSABLE			8
#define SF_DOOR_ONEWAY				16
#define SF_DOOR_NO_AUTO_RETURN		32
#define SF_DOOR_ROTATE_Z			64
#define SF_DOOR_ROTATE_X			128
#define SF_DOOR_USE_ONLY			256
#define SF_DOOR_NOMONSTERS			512
#define SF_DOOR_SILENT				0x80000000

void func_rot_button()
{
	if (self.spawnflags & SF_DOOR_ROTATE_Z)
		self.movedir = '0 0 1';
	else if (self.spawnflags & SF_DOOR_ROTATE_X)
		self.movedir = '1 0 0';
	else
		self.movedir = '0 1 0';		// default: Y axis

	if (self.spawnflags & SF_DOOR_ROTATE_BACKWARDS)
		self.movedir = self.movedir * -1;

	self.noise = Button_Sound(self.sounds);
	precache_sound(self.noise);

	self.movetype = MOVETYPE_PUSH;

	if (self.spawnflags & SF_ROTBUTTON_NOTSOLID)
		self.solid = SOLID_NOT;
	else
		self.solid = SOLID_BSP;

	setmodel(self, self.model);
	Render_Apply(self);

	if (!self.speed) self.speed = 40;
	if (!self.wait)  self.wait  = 1;

	if (self.health)
	{
		self.max_health = self.health;
		self.takedamage = DAMAGE_YES;
	}

	self.state    = STATE_BOTTOM;
	self.ang1     = self.angles;
	self.ang2     = self.angles + self.movedir * self.distance;

	self.stayPushed = (self.wait == -1 ? TRUE : FALSE);
	self.rotating   = TRUE;

	if (self.spawnflags & SF_BUTTON_TOUCH_ONLY)
		self.touch = Button_Touch;
	else
		self.touch = SUB_Null;

	self.use = Button_Use;
	self.usehl = Button_UseHL;
	Button_ObjectCaps();
}
