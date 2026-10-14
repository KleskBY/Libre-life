
.float pose;
void Scientist_ApplyBody();	// defined in monster_scientist.qc

string DeadScientist_GetScientistModel()
{
	string pszOverride = cvar_string("_sv_override_scientist_mdl");
	if(pszOverride && strlen(pszOverride) > 5)
	{
		return pszOverride;
	}
	return "models/scientist.iqm";
} 

void Monster_CorpseFallThink()
{
	if ( self.flags & FL_ONGROUND )
	{
		self.think = SUB_Null;
		setorigin(self, self.origin );
	}
	else
		self.nextthink = time + 0.1;
}


void monster_scientist_dead()
{
	precache_model(DeadScientist_GetScientistModel());
	setmodel(self, DeadScientist_GetScientistModel());
	Scientist_ApplyBody();	// -1 selects a random head, used for Luther's dark hands
	self.effects = 0;
	self.frame = 0;
	self.health = 8;
	self.max_health = self.health;
	self.solid    = SOLID_CORPSE;
	self.movetype = MOVETYPE_TOSS;
	setsize(self, '-10 -10 0', '10 10 10');
	setorigin(self, self.origin);
	self.takedamage = DAMAGE_YES;
	self.think = Monster_CorpseFallThink;
	self.nextthink = time + 0.5;
	self.monster_bloodColor = GIB_BLOOD_RED;
	self.frame = 37 + self.pose;
}