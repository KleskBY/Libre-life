
.float pose;

void monster_hevsuit_dead()
{
	precache_model("models/player.iqm");
	setmodel(self, "models/player.iqm");
	
	self.effects		= 0;
	self.yaw_speed		= 8;
	self.frame			= 0;
	self.body			= 1;
	Body_Apply(self);	// no-op until player.iqm ships a .bodyinfo
	self.monster_bloodColor	= BLOOD_COLOR_RED;
	self.health = 8;
	self.max_health = self.health;
	
	self.solid    = SOLID_CORPSE;
	self.movetype = MOVETYPE_TOSS;
	setsize(self, '-10 -10 0', '10 10 10');
	setorigin(self, self.origin);
	self.takedamage = DAMAGE_YES;
	self.think = Monster_CorpseFallThink;
	self.nextthink = time + 0.5;
	
	self.frame = 73 + self.pose;
}