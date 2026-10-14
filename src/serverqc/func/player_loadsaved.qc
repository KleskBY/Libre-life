// Keys:
//   duration       seconds to fade out
//   holdtime       seconds to hold at full fade
//   messagetime    seconds after Use before showing self.message
//   loadtime       seconds after Use before issuing reload
//   rendercolor    "r g b" fade tint (stock field)
//   renderamt      peak fade alpha 0..255 (stock field)

string SP_PickRespawnLoad();

.float messagetime;
.float loadtime;

void PlayerLoadSaved_SendFadeOne(entity dest)
{
	if (!dest || dest.classname != "player") return;
	stuffcmd(dest, sprintf("scrfade %d %d %d %d %f %f %d\n",
		(float)self.rendercolor_x,
		(float)self.rendercolor_y,
		(float)self.rendercolor_z,
		(float)self.renderamt,
		self.duration,
		self.holdtime,
		FFADE_OUT));
}

void PlayerLoadSaved_FadeAll()
{
	entity p = find(world, classname, "player");
	while (p)
	{
		PlayerLoadSaved_SendFadeOne(p);
		p = find(p, classname, "player");
	}
}

void PlayerLoadSaved_LoadThink()
{
	if (cvar("gamemode") != MODE_SP) return;

	string slot = SP_PickRespawnLoad();
	if (slot != "")
		localcmd(strcat("load ", slot, "\n"));
	else
		localcmd("reload\n");
}

void PlayerLoadSaved_MessageThink()
{
	if (self.message && self.message != "")
		Message_ShowAll(self.message);

	float nextDelay = self.loadtime - self.messagetime;
	if (nextDelay > 0)
	{
		self.think = PlayerLoadSaved_LoadThink;
		self.nextthink = time + nextDelay;
	}
	else
	{
		PlayerLoadSaved_LoadThink();
	}
}

void PlayerLoadSaved_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	PlayerLoadSaved_FadeAll();
	self.think = PlayerLoadSaved_MessageThink;
	self.nextthink = time + self.messagetime;
}

void PlayerLoadSaved_Use()
{
	PlayerLoadSaved_UseHL(activator, self, USE_TOGGLE, 0);
}

void player_loadsaved()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;
	self.model    = "";

	self.use   = PlayerLoadSaved_Use;
	self.usehl = PlayerLoadSaved_UseHL;
}
