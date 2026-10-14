// spawnflags are not entity-local

void monster_snark()
{
	SNARK_Precache();

	if (!self.owner) self.owner = world;

	self.movetype   = MOVETYPE_STEP;
	self.solid      = SOLID_SLIDEBOX;
	self.takedamage = DAMAGE_AIM;
	self.health     = SNARK_HEALTH;
	self.max_health = self.health;
	self.flags      = self.flags | FL_MONSTER;

	setmodel(self, SNARK_PROJ_MODEL);
	setsize(self, '-1 -1 -1', '1 1 1');
	setorigin(self, self.origin);
	self.avelocity = '0 100 0';

	self.snark_die        = time + SNARK_FUSE_TIME;
	self.snark_nextHunt   = time + 1;
	self.snark_nextBounce = 0;
	self.snark_nextBite   = 0;

	self.touch     = Snark_BounceTouch;
	self.think     = Snark_HuntThink;
	self.nextthink = time + 0.1;
	self.th_die    = Snark_Detonate;
}
