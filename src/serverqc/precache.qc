

void Player_Precache();
void Weapon_Precache();
void Gib_Precache();

void Muzzle_Precache();	// weapons/muzzleflash.qc

void Precache()
{
	Muzzle_Precache();
	Player_Precache();
	Weapon_Precache();
	Gib_Precache();

	precache_model("models/shrap.md3");
	precache_sound("weapons/explode3.wav");
	precache_sound("weapons/lock4.wav");

	precache_sound("buttons/spark1.wav");
	precache_sound("buttons/spark2.wav");
	precache_sound("buttons/spark3.wav");
	precache_sound("buttons/spark4.wav");
	precache_sound("buttons/spark5.wav");
	precache_sound("buttons/spark6.wav");
};
