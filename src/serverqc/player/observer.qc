

void PutObserverInServer()
{
	entity spot = SelectSpawnPoint(self);

	self.classname = "observer";
	self.health = 666;	// Prevents death logic from running if health drops below 0
	self.takedamage = DAMAGE_NO;  
	self.solid = SOLID_NOT;       	
	self.movetype = MOVETYPE_NOCLIP;
	self.show_hostile = 0;			
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.effects = 0;
	

	self.items = IT_QUAD; //blue effect
	self.weapon = 0;
	self.currentammo =  0;
	Viewmodel_Hide(self);

	// Clearing .weapon is not enough
	self.weaponSelect  = SUB_Null;
	self.weaponAttack  = SUB_Null;
	self.weaponAttack2 = SUB_Null;
	self.weaponReload  = SUB_Null;
	self.weaponSwitch  = SUB_Null;
	self.weaponframe   = 0;
	self.reload        = FALSE;

	self.attack_finished = time;	
	self.deadflag = DEAD_NO;
	self.pausetime = 0;	// set by teleporters to prevent movement
	self.origin = spot.origin + '0 0 1';
	self.angles = spot.angles;
	self.fixangle = TRUE;	// forces immediate angle change

	//setcolor(self, -1); //set team
	setmodel(self, ""); 
	setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	
	self.view_ofs = '0 0 23';
	self.viewzoom = 1;
};
