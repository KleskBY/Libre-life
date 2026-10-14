
void ItemKey1_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;
	if (other.items & IT_KEY1) return;
	other.items = other.items | IT_KEY1;
	if (world.worldtype == 2)      centerprint(other, "You got the silver keycard");
	else if (world.worldtype == 1) centerprint(other, "You got the silver runekey");
	else                           centerprint(other, "You got the silver key");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "misc/medkey.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}

void ItemKey2_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;
	if (other.items & IT_KEY2) return;
	other.items = other.items | IT_KEY2;
	if (world.worldtype == 2)      centerprint(other, "You got the gold keycard");
	else if (world.worldtype == 1) centerprint(other, "You got the gold runekey");
	else                           centerprint(other, "You got the gold key");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "misc/medkey.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}

void item_key1()
{
	precache_model("progs/w_s_key.mdl");
	precache_sound("misc/medkey.wav");
	setmodel(self, "progs/w_s_key.mdl");
	Item_Start();
	self.touch = ItemKey1_Touch;
}

void item_key2()
{
	precache_model("progs/w_g_key.mdl");
	precache_sound("misc/medkey.wav");
	setmodel(self, "progs/w_g_key.mdl");
	Item_Start();
	self.touch = ItemKey2_Touch;
}

void ItemSigil_Touch()
{
	if (other.classname != "player") return;
	if (other.health <= 0) return;

	serverflags = serverflags | (self.spawnflags & 15);

	sprint(other, "You got a rune!\n");
	Sound_Play(other, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "misc/medkey.wav");
	stuffcmd(other, "bf\n");
	Item_Finish();
}

void item_sigil()
{
	float rune = self.spawnflags & 15;
	string mdl;
	if      (rune & 1) mdl = "progs/end1.mdl";
	else if (rune & 2) mdl = "progs/end2.mdl";
	else if (rune & 4) mdl = "progs/end3.mdl";
	else               mdl = "progs/end4.mdl";

	precache_model(mdl);
	precache_sound("misc/medkey.wav");
	setmodel(self, mdl);
	Item_Start();
	self.touch = ItemSigil_Touch;
}
