
#define SF_FADE_IN                 0x0001
#define SF_FADE_MODULATE           0x0002     // modulate blend instead of alpha
#define SF_FADE_ONLYONE            0x0004     // fade activator only, not all

#define FFADE_IN			0x0000
#define FFADE_OUT			0x0001
#define FFADE_MODULATE		0x0002
#define FFADE_STAYOUT		0x0004
#define FFADE_LONGFADE		0x0008

.float duration;
.float holdtime;
void EnvFade_SendOne(entity dest, float flags)
{
	if (!dest || dest.classname != "player") return;
	stuffcmd(dest, sprintf("scrfade %d %d %d %d %f %f %d\n",
		self.rendercolor_x,
		self.rendercolor_y,
		self.rendercolor_z,
		self.renderamt,
		self.duration,
		self.holdtime,
		flags));
}

void EnvFade_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	float flags = 0;
	if (!(self.spawnflags & SF_FADE_IN))       flags = flags | FFADE_OUT;
	if (self.spawnflags & SF_FADE_MODULATE)    flags = flags | FFADE_MODULATE;

	if (self.spawnflags & SF_FADE_ONLYONE)
	{
		EnvFade_SendOne(pActivator, flags);
	}
	else
	{
		entity p = find(world, classname, "player");
		while (p)
		{
			EnvFade_SendOne(p, flags);
			p = find(p, classname, "player");
		}
	}

	SUB_UseTargetsHL(pActivator, USE_TOGGLE, 0);
}

void EnvFade_Use()
{
	EnvFade_UseHL(activator, self, useType, 0);
}

void env_fade()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;

	self.use   = EnvFade_Use;
	self.usehl = EnvFade_UseHL;
}
