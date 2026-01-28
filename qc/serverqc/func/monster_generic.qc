

#define	SF_GENERICMONSTER_NOTSOLID					4 

void monster_generic()
{
	self.model = strireplace(".mdl", ".iqm", self.model);
	precache_model(self.model);
	setmodel(self, self.model);

	if (self.model == "models/player.mdl" || self.model == "models/holo.mdl")
		setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	else
		setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

	self.solid			= SOLID_SLIDEBOX;
	self.movetype		= MOVETYPE_STEP;
	self.health			= 8;
	//m_bloodColor		= BLOOD_COLOR_RED;
	// m_flFieldOfView		= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
	// m_MonsterState		= MONSTERSTATE_NONE;
	
	// MonsterInit();
	
	if (self.spawnflags & SF_GENERICMONSTER_NOTSOLID)
	{
		self.solid = SOLID_NOT;
		self.takedamage = DAMAGE_NO;
	}
}