

void Player_Precache();


void Precache()
{
	Player_Precache();
	precache_model("models/weapons/shrap.md3");
	precache_sound("weapons/grenade/explosion.wav");
};