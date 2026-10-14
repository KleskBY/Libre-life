
#define SF_MESSAGE_ONCE			0x0001
#define SF_MESSAGE_ALL			0x0002

.string messagesound;
.float messagevolume;
.float messageattenuation;

void EnvMessage_Use()
{
	entity pPlayer;

	if (self.spawnflags & SF_MESSAGE_ALL)
		Message_ShowAll(self.message);
	else
	{
		if (activator && activator.classname == "player")
			pPlayer = activator;
		else
		{
			pPlayer = find(world, classname, "player");
		}
		if (pPlayer)
			Message_Show(self.message, pPlayer );
	}
	if (self.noise)
	{
		Sound_Play(self, CHAN_BODY, self.scale, self.speed, PITCH_NORM, self.noise);
	}
	if (self.spawnflags & SF_MESSAGE_ONCE)
		remove(self);

	SUB_UseTargets();
}

void EnvMessage_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	entity pPlayer;

	dprint("env_message UseHL: msg='"); dprint(self.message);
	dprint("' targetname='"); dprint(self.targetname); dprint("'\n");

	if (self.spawnflags & SF_MESSAGE_ALL)
		Message_ShowAll(self.message);
	else
	{
		if (pActivator && pActivator.classname == "player")
			pPlayer = pActivator;
		else
			pPlayer = find(world, classname, "player");
		if (pPlayer)
			Message_Show(self.message, pPlayer);
	}
	if (self.noise)
		Sound_Play(self, CHAN_BODY, self.scale, self.speed, PITCH_NORM, self.noise);
	if (self.spawnflags & SF_MESSAGE_ONCE)
		remove(self);

	SUB_UseTargetsHL(pActivator, useTypeArg, useValueArg);
}


void env_message()
{
	self.noise = self.messagesound;
	self.scale = self.messagevolume;
	self.impulse = self.messageattenuation;
	if(self.noise) precache_sound(self.noise);

	self.solid			= SOLID_NOT;
	self.movetype		= MOVETYPE_NONE;

	switch( self.impulse )
	{
	case 1: // Medium radius
		self.speed = ATTN_STATIC;
		break;
	
	case 2:	// Large radius
		self.speed = ATTN_NORM;
		break;

	case 3:	//EVERYWHERE
		self.speed = ATTN_NONE;
		break;
	
	default:
	case 0: // Small radius
		self.speed = ATTN_IDLE;
		break;
	}
	self.impulse = 0;

	if ( self.scale <= 0 )
		self.scale = 1.0;
	self.use = EnvMessage_Use;
	self.usehl = EnvMessage_UseHL;
}