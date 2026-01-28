

void Intermission_Think()
{
	entity t = find(world, targetname, self.target);
	if(!t) return;
	self.v_angle = vectoangles(normalize(t.origin-self.origin));
	self.v_angle_x = -self.v_angle_x;

}

void info_intermission()
{
	setorigin(self, self.origin);
	self.solid = SOLID_NOT;
	self.effects = EF_NODRAW;
	self.v_angle = '0 0 0';
	self.nextthink = time + 2;// let targets spawn!
	self.think = Intermission_Think;
}