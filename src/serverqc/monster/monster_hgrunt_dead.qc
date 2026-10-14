// No entity-local spawnflags; KeyValue "pose" 0..2 selects corpse anim.
//   pose 0 = deadstomach, 1 = deadside, 2 = deadsitting
// Frame indices from data/models/hgrunt.iqm.framegroups (deadstomach starts at idx 44).

.float pose;

void monster_hgrunt_dead()
{
	precache_model("models/hgrunt.iqm");
	setmodel(self, "models/hgrunt.iqm");

	self.effects       = 0;
	self.yaw_speed     = 8;

	// 0 = grunt+mp5, 1 = commander+mp5, 2 = grunt no gun, 3 = commander no gun.
	float deadBody = self.body;
	self.body = 0;
	self.skinFamily = 0;
	if (deadBody == 1 || deadBody == 3)
		Body_SetGroup(self, "heads", HGRUNT_HEAD_COMMANDER);
	if (deadBody == 2 || deadBody == 3)
		Body_SetGroup(self, "weapons", HGRUNT_GUN_NONE);
	Body_Apply(self);
	self.monster_bloodColor  = BLOOD_COLOR_RED;
	self.health        = 8;
	self.max_health    = self.health;

	self.solid    = SOLID_CORPSE;
	self.movetype = MOVETYPE_TOSS;
	setsize(self, '-16 -16 0', '16 16 36');
	setorigin(self, self.origin);
	self.takedamage = DAMAGE_YES;
	self.think      = Monster_CorpseFallThink;
	self.nextthink  = time + 0.5;

	if (self.pose < 0 || self.pose > 2) self.pose = 0;
	self.frame = 44 + self.pose;
}
