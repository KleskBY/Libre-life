#define	PITCH_NORM		100

float Sound_Radius(float radius)
{
	return (800 / radius);
}

// The only thing in the codebase that touches the engine sound builtin.
// Non-variadic on purpose: it is the escape hatch for call sites that cannot
// afford va_arg's emulated-array cost, and the place a future spatial-audio
// pass hooks into. Maps 1:1 onto sound7, so it is capped at 7 args forever.
void Sound_Emit(entity e, float chan, string smp, float fvol, float attn, float pitch, float flags)
{
	sound7(e, chan, smp, fvol, attn, pitch, flags);
}

// Pass one sample to play it, or several to pick one at random.
void Sound_Play(entity e, float chan, float fvol, float attn, float pitch, ... snds)
{
	float rsnd = Math_RandomInt(0, snds - 1);
	Sound_Emit(e, chan, va_arg(rsnd, string), fvol, attn, pitch, 0);
}

void Sound_Stop(entity e, float chan)
{
	Sound_Emit(e, chan, "common/null.wav", 1, 0, PITCH_NORM, 0);
}

#ifdef SVQC
// Sounds that land partway through an animation instead of at its start, so a
// reload cue does not have to be driven by hijacking the caller's own .think.
// One entity per pending sound, played through Sound_Play like everything else.
// Cancelling is the CALLER's job: see Sound_CancelDelayed, and
// docs/guide/12-assets.md for why no condition is stored on the sound itself.
#define SOUND_DELAYED_CLASS "delayed_sound"

.string sound_wav;
.float  sound_chan;
.float  sound_vol;
.float  sound_attn;
.float  sound_pitch;

void Sound_DelayedFree()
{
	if (self.sound_wav) strunzone(self.sound_wav);
	self.sound_wav = "";
	remove(self);
}

void Sound_DelayedThink()
{
	// An owner that has gone away takes its pending sounds with it.
	if (self.owner)
		Sound_Play(self.owner, self.sound_chan, self.sound_vol, self.sound_attn,
		           self.sound_pitch, self.sound_wav);

	Sound_DelayedFree();
}

entity Sound_PlayDelayed(entity src, float delay, float chan, float fvol,
                         float attn, float pitch, string smp)
{
	if (!src || smp == "") return world;

	entity d = spawn();
	d.classname   = SOUND_DELAYED_CLASS;
	d.owner       = src;
	d.sound_wav   = strzone(smp);
	d.sound_chan  = chan;
	d.sound_vol   = fvol;
	d.sound_attn  = attn;
	d.sound_pitch = pitch;
	d.think       = Sound_DelayedThink;
	d.nextthink   = time + delay;
	return d;
}

// Drop every sound still pending for this source.
void Sound_CancelDelayed(entity src)
{
	entity saved = self;
	entity d = find(world, classname, SOUND_DELAYED_CLASS);
	while (d)
	{
		entity nxt = find(d, classname, SOUND_DELAYED_CLASS);
		if (d.owner == src)
		{
			self = d;
			Sound_DelayedFree();
		}
		d = nxt;
	}
	self = saved;
}
#endif

#ifdef CSQC
void Sound_Local(string smp)
{
	pointsound('0 0 0', smp, 1, 0);
}
#endif
