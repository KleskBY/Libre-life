
void PowerUp_Tick()
{
	if (self.invincible_finished && time > self.invincible_finished)
	{
		self.items = self.items - (self.items & IT_INVULNERABILITY);
		self.invincible_finished = 0;
		self.invincible_time = 0;
	}
	if (self.invisible_finished && time > self.invisible_finished)
	{
		self.items = self.items - (self.items & IT_INVISIBILITY);
		self.invisible_finished = 0;
		self.invisible_time = 0;
	}
	if (self.super_damage_finished && time > self.super_damage_finished)
	{
		self.items = self.items - (self.items & IT_QUAD);
		self.super_damage_finished = 0;
		self.super_time = 0;
	}
	if (self.radsuit_finished && time > self.radsuit_finished)
	{
		self.items = self.items - (self.items & IT_SUIT);
		self.radsuit_finished = 0;
		self.rad_time = 0;
	}
}

void Powerup_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;

	sprint(other, "You got the ");
	sprint(other, self.netname);
	sprint(other, "\n");
	Sound_Play(other, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, self.noise);
	stuffcmd(other, "bf\n");

	other.items = other.items | self.items;

	if (self.classname == "item_artifact_envirosuit")
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 30;
	}
	if (self.classname == "item_artifact_invulnerability")
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}
	if (self.classname == "item_artifact_invisibility")
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
	}
	if (self.classname == "item_artifact_super_damage")
	{
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}

	Item_Finish();
}

void item_artifact_invulnerability()
{
	precache_model("progs/invulner.mdl");
	precache_sound("items/protect.wav");
	precache_sound("items/protect2.wav");
	precache_sound("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel(self, "progs/invulner.mdl");
	self.netname = "Pentagram of Protection";
	self.items = IT_INVULNERABILITY;
	Item_Start();
	self.touch = Powerup_Touch;
}

void item_artifact_envirosuit()
{
	precache_model("progs/suit.mdl");
	precache_sound("items/suit.wav");
	precache_sound("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel(self, "progs/suit.mdl");
	self.netname = "Biosuit";
	self.items = IT_SUIT;
	Item_Start();
	self.touch = Powerup_Touch;
}

void item_artifact_invisibility()
{
	precache_model("progs/invisibl.mdl");
	precache_sound("items/inv1.wav");
	precache_sound("items/inv2.wav");
	precache_sound("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel(self, "progs/invisibl.mdl");
	self.netname = "Ring of Shadows";
	self.items = IT_INVISIBILITY;
	Item_Start();
	self.touch = Powerup_Touch;
}

void item_artifact_super_damage()
{
	precache_model("progs/quaddama.mdl");
	precache_sound("items/damage.wav");
	precache_sound("items/damage2.wav");
	precache_sound("items/damage3.wav");
	self.noise = "items/damage.wav";
	setmodel(self, "progs/quaddama.mdl");
	self.netname = "Quad Damage";
	self.items = IT_QUAD;
	Item_Start();
	self.touch = Powerup_Touch;
}
