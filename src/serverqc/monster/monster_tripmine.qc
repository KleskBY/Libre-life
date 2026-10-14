// spawnflag bit 1 = quick powerup (1.0s vs 2.5s default).
#define SF_TRIPMINE_QUICKARM    1

void monster_tripmine()
{
	if (Monster_RemoveIfSpent()) return;	// detonated on a previous visit

	TRIPMINE_Precache();

	if (!self.owner) self.owner = world;

	self.movetype   = MOVETYPE_FLY;
	self.solid      = SOLID_NOT;
	setmodel(self, TRIPMINE_WORLD_MODEL);
	setsize(self, '-4 -4 -3', '4 4 3');
	setorigin(self, self.origin);
	self.frame      = TRIPMINE_WORLD;

	makevectors(self.angles);
	self.tripmine_beamDir = v_forward;

	float armDelay = (self.spawnflags & SF_TRIPMINE_QUICKARM) ? 1.0 : TRIPMINE_POWERUP_TIME;
	self.tripmine_powerupAt = time + armDelay;

	self.takedamage = DAMAGE_YES;
	self.health     = 1;
	self.max_health = 1;
	self.th_pain    = Tripmine_Pain;
	self.th_die     = Tripmine_Explode;
	self.think      = Tripmine_PowerupThink;
	self.nextthink  = time + 0.2;

	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, TRIPMINE_DEPLOY_SOUND);
	Sound_Play(self, CHAN_BODY, 0.2, ATTN_NORM, PITCH_NORM, TRIPMINE_CHARGE_SOUND);
}
