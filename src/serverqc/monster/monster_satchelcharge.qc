// entity-local spawnflags are not supported

void monster_satchel()
{
	SATCHEL_Precache();

	if (!self.owner) self.owner = world;

	self.movetype = MOVETYPE_BOUNCE;
	self.solid    = SOLID_BBOX;
	setmodel(self, SATCHEL_CHARGE_MODEL);
	setsize(self, '-1 -1 -1', '1 1 1');
	setorigin(self, self.origin);
	self.angles    = '270 180 90';
	self.avelocity = '0 400 0';
	self.velocity  = '0 0 0';

	self.touch     = Satchel_Slide;
	self.think     = Satchel_Think;
	self.nextthink = time + 0.1;
}

void monster_satchelcharge()
{
	monster_satchel();
}
