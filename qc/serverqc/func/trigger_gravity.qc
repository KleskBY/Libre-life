
.float gravity;

void Trigger_GravityTouch()
{
	if(other.classname != "player")
		return;
	
	cvar_set("sv_gravity", ftos(self.gravity));

}



void trigger_gravity()
{
	InitTrigger();
	self.touch = Trigger_GravityTouch;
}