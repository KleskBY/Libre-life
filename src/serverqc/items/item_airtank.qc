
.float airtank_state;

void Airtank_Die()
{
	T_RadiusDamage(self, self.enemy, self.dmg, self.dmg * 2.5, DMG_BLAST);
	te_explosion(self.origin);
	Sound_Play(self, CHAN_WEAPON, 1, Sound_Radius(3500), PITCH_NORM, "weapons/explode3.wav");
	remove(self);
}

void Airtank_Think()
{
	self.airtank_state = 1;
	SUB_UseTargetsHL(world, USE_TOGGLE, 0);
}

void Airtank_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;

	if (!self.airtank_state)
	{
		Sound_Play(self, CHAN_BODY, 1, ATTN_NORM, PITCH_NORM, "player/pl_swim2.wav");	// no oxygen
		return;
	}

	other.air_finished = time + 12;
	Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "doors/aliendoor3.wav");

	self.nextthink = time + 30;
	self.airtank_state = 0;
	SUB_UseTargetsHL(other, USE_TOGGLE, 1);
}

void item_airtank()
{
	precache_model("models/w_oxygen.iqm");
	precache_sound("doors/aliendoor3.wav");
	precache_sound("player/pl_swim2.wav");
	precache_sound("weapons/explode3.wav");

	self.solid    = SOLID_BBOX;
	self.movetype = MOVETYPE_NONE;
	setmodel(self, "models/w_oxygen.iqm");
	setsize(self, '-16 -16 0', '16 16 36');
	setorigin(self, self.origin);

	self.touch      = Airtank_Touch;
	self.think      = Airtank_Think;
	self.takedamage = DAMAGE_YES;
	self.health     = 20;
	self.dmg        = 50;
	self.th_die     = Airtank_Die;
	self.airtank_state = 1;
}
