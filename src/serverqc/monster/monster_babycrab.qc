// Differences from parent CHeadCrab:
//   - model: baby_headcrab.mdl
//   - rendermode kRenderTransTexture, renderamt 192
//   - size 12 wide vs 16
//   - health 0.25× headcrab

#define BABYCRAB_MODEL "models/baby_headcrab.iqm"

void monster_babycrab()
{
	if (Monster_RemoveIfSpent()) return;
	if (RemoveInDeathmatch()) return;

	Headcrab_Precache();
	precache_model(BABYCRAB_MODEL);

	self.solid          = SOLID_SLIDEBOX;
	self.movetype       = MOVETYPE_STEP;
	self.yaw_speed      = YAW_HL(30);	// default yaw speed
	self.health         = HEADCRAB_HEALTH * 0.25;
	self.max_health     = self.health;
	self.view_ofs       = '0 0 14';
	self.monster_state = MONSTERSTATE_NONE;
	self.monster_bloodColor   = BLOOD_COLOR_YELLOW;

	setmodel(self, BABYCRAB_MODEL);
	setsize(self, '-12 -12 0', '12 12 24');

	self.rendermode = 4;   // kRenderTransTexture
	self.renderamt  = 192;

	self.headcrab_dmgmult = 0.3;

	self.th_stand    = Headcrab_Stand;
	self.th_walk     = Headcrab_Walk;
	self.th_run      = Headcrab_Run;
	self.th_melee    = Headcrab_Attack;
	self.th_pain     = Headcrab_Pain;
	self.th_die      = Headcrab_Die;
	self.sightSound  = Headcrab_AlertSound;
	self.checkAttack = Headcrab_CheckAttack;

	Monster_InitTakeDamage();
	WalkMonster_Start();
}
