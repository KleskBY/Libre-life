

.entity flashlight;

void Flashlight_Think()
{
	if (self.owner.view_ofs == '0 0 0' || self.owner.health <= 0 || self.owner.health >= 666) 
	{
		self.think = SUB_Remove;
		self.owner.flashlight = world;
	}
	
	self.v_angle_x = -self.owner.v_angle_x;
	self.nextthink = time + 0.01;
};

void Flashlight_Enable()
{	
	self.flashlight = spawn();
	setmodel(self.flashlight, ""); 
	setsize(self.flashlight, '0 0 0', '0 0 0');
	self.flashlight.pflags = PFLAGS_FULLDYNAMIC | PFLAGS_NOSHADOW;
	self.flashlight.light_lev = 350;
	self.flashlight.color = '1.95 1.8 1.7'; //'1 1 1.5';
	self.flashlight.skin = 237;
	self.flashlight.owner = self;
	self.flashlight.nodrawtoclient = self;
	self.flashlight.classname = "flashlight";
	
	self.flashlight.movetype = MOVETYPE_FOLLOW;
	self.flashlight.solid = SOLID_NOT;
	self.flashlight.aiment = self;
	self.flashlight.v_angle_x = -self.v_angle_x;
	
	self.flashlight.think = Flashlight_Think;
	self.flashlight.nextthink = time + 0.1;
};


void Flashlight_Toggle()
{
	self.impulse = 0;
	if(self.classname != "player") return;
	if(!IsAlive(self)) return;
	if (self.flashlight)
	{
		remove(self.flashlight);
		self.flashlight = world;
	}
	else
	{
		Flashlight_Enable();
	}
};