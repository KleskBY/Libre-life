void ItemSoda_CanTouch();
void ItemSoda_CanThink();

void ItemSoda_CanThink()
{
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, PITCH_NORM, "weapons/g_bounce3.wav");

	self.solid = SOLID_TRIGGER;
	setsize(self, '-8 -8 0', '8 8 8');
    self.think = SUB_Null;
	self.touch = ItemSoda_CanTouch;
}

void ItemSoda_CanTouch()
{
    if (other.classname != "player") return;
    T_Heal(other, 1, FALSE);

    if (self.owner && self.owner != world)
        self.owner.frags = 0;

    self.solid    = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.effects  = EF_NODRAW;
    self.touch    = SUB_Null;
    self.think    = SUB_Remove;
    self.nextthink = time;
}

void item_sodacan()
{
    precache_model("models/can.iqm");
    precache_sound("weapons/g_bounce3.wav");
	
	self.solid    = SOLID_NOT;
    self.movetype = MOVETYPE_TOSS;
    setmodel(self, "models/can.iqm");
	setsize(self, '0 0 0', '0 0 0');

    self.think     = ItemSoda_CanThink;
    self.nextthink = time + 0.5;
}
