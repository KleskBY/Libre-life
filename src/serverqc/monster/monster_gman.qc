// Anims (data/models/gman.iqm.framegroups): idle01=0, idlebrush=1, idlelook=2, idle02=3, open=4, stand=5, walk=6, yes=7, no=8, bigno=9, bigyes=10, listen=11, lookdown=12, lookdown2=13

#define GMAN_MODEL  "models/gman.iqm"

#define GMAN_FR_IDLE01     0
#define GMAN_FR_IDLEBRUSH  1
#define GMAN_FR_IDLELOOK   2
#define GMAN_FR_IDLE02     3
#define GMAN_FR_OPEN       4
#define GMAN_FR_STAND      5
#define GMAN_FR_WALK       6
#define GMAN_FR_YES        7
#define GMAN_FR_NO         8
#define GMAN_FR_BIGNO      9
#define GMAN_FR_BIGYES    10
#define GMAN_FR_LISTEN    11
#define GMAN_FR_LOOKDOWN  12
#define GMAN_FR_LOOKDOWN2 13

float GMan_FrameByName(string name)
{
	if (name == "idle01")     return GMAN_FR_IDLE01;
	if (name == "idlebrush")  return GMAN_FR_IDLEBRUSH;
	if (name == "idlelook")   return GMAN_FR_IDLELOOK;
	if (name == "idle02")     return GMAN_FR_IDLE02;
	if (name == "open")       return GMAN_FR_OPEN;
	if (name == "stand")      return GMAN_FR_STAND;
	if (name == "walk")       return GMAN_FR_WALK;
	if (name == "yes")        return GMAN_FR_YES;
	if (name == "no")         return GMAN_FR_NO;
	if (name == "bigno")      return GMAN_FR_BIGNO;
	if (name == "bigyes")     return GMAN_FR_BIGYES;
	if (name == "listen")     return GMAN_FR_LISTEN;
	if (name == "lookdown")   return GMAN_FR_LOOKDOWN;
	if (name == "lookdown2")  return GMAN_FR_LOOKDOWN2;
	return -1;
}

float GMan_TakeDamage(entity inflictor, entity attacker, float damage, float dtype)
{
	self.health = self.max_health * 0.5;
	return TRUE;
}

void GMan_Think()
{
	self.nextthink = time + 5 + random() * 3;
	if (self.monster_cine && self.monster_cine != world) return;

	// Cycle through idle variants for life.
	float r = floor(random() * 4);
	if      (r == 0) self.frame = GMAN_FR_IDLE01;
	else if (r == 1) self.frame = GMAN_FR_IDLEBRUSH;
	else if (r == 2) self.frame = GMAN_FR_IDLELOOK;
	else             self.frame = GMAN_FR_IDLE02;
}

void GMan_Precache()
{
	precache_model(GMAN_MODEL);
}

void monster_gman()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	GMan_Precache();

	setmodel(self, GMAN_MODEL);
	setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

	self.solid          = SOLID_SLIDEBOX;
	self.movetype       = MOVETYPE_STEP;
	self.health         = 100;
	self.max_health     = 100;
	self.monster_bloodColor   = DONT_BLEED;
	self.monster_fieldOfView = 0.5;
	self.monster_state = MONSTERSTATE_NONE;
	self.view_ofs       = '0 0 50';
	self.yaw_speed      = YAW_HL(90);	// Sets the yaw speed

	self.flags          = self.flags | FL_MONSTER;

	self.frameByName = GMan_FrameByName;
	self.takedamage  = DAMAGE_YES;
	self.takeDmgFn   = GMan_TakeDamage;

	self.frame      = GMAN_FR_IDLE01;
	self.think      = GMan_Think;
	self.nextthink  = time + 2 + random() * 3;
	total_monsters  = total_monsters + 1;
}
