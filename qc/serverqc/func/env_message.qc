
#define SF_MESSAGE_ONCE			0x0001		// Fade in, not out
#define SF_MESSAGE_ALL			0x0002		// Send to all clients

.string messagesound;
.float messagevolume;
.float messageattenuation;

void EnvMessage_Use()
{
	entity pPlayer;

	if (self.spawnflags & SF_MESSAGE_ALL)
		UTIL_ShowMessageAll(self.message);
	else
	{
		if (activator && activator.classname == "player")
			pPlayer = activator;
		else
		{
			pPlayer = find(world, classname, "player");
		}
		if (pPlayer)
			UTIL_ShowMessage(self.message, pPlayer );
	}
	if (self.noise)
	{
		sound(self, CHAN_BODY, self.noise, self.scale, self.speed);
	}
	if (self.spawnflags & SF_MESSAGE_ONCE)
		remove(self);

	SUB_UseTargets();
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

	// No volume, use normal
	if ( self.scale <= 0 )
		self.scale = 1.0;
	self.use = EnvMessage_Use;
}