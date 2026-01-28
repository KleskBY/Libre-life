
vector VelocityForDamage(float dm)
{
	vector v = [ random(-100, 100), random(-100, 100), random(200, 300) ];
	if (dm > -50) v = v * 0.7;
	else if (dm > -200) v = v * 2;
	else v = v * 10;
	return v;
};

void SpawnBlood(vector org, vector vel, float damage)
{
	particle(org, vel * 0.1, 73, damage * 2);
};

void ShootBlood(vector position, vector direction)
{
	SpawnBlood(position, direction, 10);
};

void Gib_ThrowGib(string gibname, float dm)
{
	if(self.solid == SOLID_CORPSE) dm = dm * 0.1;
	entity new = spawn();
	new.origin = self.origin;
	setmodel (new, gibname);
	setsize (new, '0 0 0', '0 0 0');
	new.modelflags = MF_ZOMGIB;
	new.scale = 0.8;
	new.velocity = VelocityForDamage(dm);
	new.movetype = MOVETYPE_BOUNCE;
	new.solid = SOLID_NOT;
	new.avelocity = randomvec() * 600;
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + 10 + random() * 10;
	new.frame = 0;
	new.flags = 0;
};

void Gib_ThrowHead(string gibname, float dm)
{
	if(self.solid == SOLID_CORPSE) dm = dm * 0.1;
	setmodel (self, gibname);
	if(!(self.flags & FL_CLIENT)) self.modelflags = MF_GIB; //Bug bleed after respawn if on player
	self.frame = 0;
	self.nextthink = -1;
	self.movetype = MOVETYPE_BOUNCE;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_TRIGGER;
	self.view_ofs = '0 0 8';
	setsize (self, '-2 -2 0', '2 2 2');
	self.velocity = VelocityForDamage(dm);
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = random(-1, 1) * '0 600 0';
	
	if(self.flags & FL_MONSTER)
	{
		self.think = SUB_Remove;
		self.nextthink = time + random(20, 50);
	}
};

void Gib_ThrowChunk(string gibname, float dm)
{
	entity new = spawn();
	new.origin = self.origin;
	setmodel(new, gibname);
	new.view_ofs = '0 0 8';
	setsize(new, '0 0 0', '1 1 1');
	new.velocity = VelocityForDamage(dm) * 0.5;
	new.movetype = MOVETYPE_BOUNCE;
	new.solid = SOLID_BBOX;
	new.avelocity = random(-1, 1) * '0 600 0';
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + random(10, 30);
	new.frame = 0;
	new.flags = new.flags - (new.flags & FL_ONGROUND);
}




void Gib_Precache()
{
	precache_model("models/gibs/gib1.md3");
	precache_model("models/gibs/gib2.md3");
	precache_model("models/gibs/gib3.md3");
};

void Gib()
{
	Gib_ThrowGib("models/gibs/gib1.md3", self.health);
	Gib_ThrowGib("models/gibs/gib1.md3", self.health);
	Gib_ThrowGib("models/gibs/gib1.md3", self.health);
	Gib_ThrowGib("models/gibs/gib1.md3", self.health);
	Gib_ThrowGib("models/gibs/gib3.md3", self.health);
	Gib_ThrowGib("models/gibs/gib3.md3", self.health);
	Gib_ThrowHead("models/gibs/gib2.md3", self.health);

	self.deadflag = DEAD_DEAD;
	sound(self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NORM);
}

