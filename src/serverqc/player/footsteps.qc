
float FOOTSTEPS_CHECK_SURFACE = 1;
float FOOTSTEPS_VOLUME = 0.9;
float FOOTSTEPS_INTERVAL = 0.4;
float FOOTSTEPS_INTERVAL_RUN = 0.7;

#define STEP_CONCRETE	0
#define STEP_METAL		1		// metal floor
#define STEP_DIRT		2
#define STEP_VENT		3		// ventillation duct
#define STEP_GRATE		4		// metal grating
#define STEP_TILE		5		// floor tiles
#define STEP_SLOSH		6
#define STEP_WADE		7
#define STEP_LADDER		8		// climbing ladder

float m_iStepLeft;
float iSkipStep;

// Picks smps[idx] deliberately (alternating left/right) so tools can harvest them.
void Player_StepSample(float idx, float fvol, ... smps)
{
	if (idx < 0 || idx >= smps) idx = 0;
	Sound_Play(self, CHAN_BODY, fvol, ATTN_NORM, PITCH_NORM, va_arg(idx, string));
}

void Player_PlayStepSound(float step, float fvol)
{
	float irand = Math_RandomInt(0, 1) + (m_iStepLeft * 2);

	m_iStepLeft = !m_iStepLeft;

	// Sample order is 1,3,2,4 to ensure consecutive steps never reuse a sample (right takes 1/3, left takes 2/4). STEP_WADE is an exception (1,2,3,4).
	switch (step)
	{
	default:
	case STEP_CONCRETE:
		Player_StepSample(irand, fvol, "player/pl_step1.wav", "player/pl_step3.wav",
			"player/pl_step2.wav", "player/pl_step4.wav");
		break;
	case STEP_METAL:
		Player_StepSample(irand, fvol, "player/pl_metal1.wav", "player/pl_metal3.wav",
			"player/pl_metal2.wav", "player/pl_metal4.wav");
		break;
	case STEP_DIRT:
		Player_StepSample(irand, fvol, "player/pl_dirt1.wav", "player/pl_dirt3.wav",
			"player/pl_dirt2.wav", "player/pl_dirt4.wav");
		break;
	case STEP_VENT:
		Player_StepSample(irand, fvol, "player/pl_duct1.wav", "player/pl_duct3.wav",
			"player/pl_duct2.wav", "player/pl_duct4.wav");
		break;
	case STEP_GRATE:
		Player_StepSample(irand, fvol, "player/pl_grate1.wav", "player/pl_grate3.wav",
			"player/pl_grate2.wav", "player/pl_grate4.wav");
		break;
	case STEP_TILE:
		if (!Math_RandomInt(0,4))
			irand = 4;
		Player_StepSample(irand, fvol, "player/pl_tile1.wav", "player/pl_tile3.wav",
			"player/pl_tile2.wav", "player/pl_tile4.wav", "player/pl_tile5.wav");
		break;
	case STEP_SLOSH:
		Player_StepSample(irand, fvol, "player/pl_slosh1.wav", "player/pl_slosh3.wav",
			"player/pl_slosh2.wav", "player/pl_slosh4.wav");
		break;
	case STEP_WADE:
		if ( iSkipStep == 0 )
		{
			iSkipStep++;
			break;
		}

		if ( iSkipStep++ == 3 )
		{
			iSkipStep = 0;
		}

		Player_StepSample(irand, fvol, "player/pl_wade1.wav", "player/pl_wade2.wav",
			"player/pl_wade3.wav", "player/pl_wade4.wav");
		break;
	case STEP_LADDER:
		Player_StepSample(irand, fvol, "player/pl_ladder1.wav", "player/pl_ladder3.wav",
			"player/pl_ladder2.wav", "player/pl_ladder4.wav");
		break;
	}
}	


void Player_Footsteps()
{
	if(vlen(self.velocity) < 60) return;
	if(!(self.flags & FL_ONGROUND)) return;
	if(self.crouching) return;
	if(self.movetype != MOVETYPE_WALK) return;
	if(time + random(0, 0.1) < self.footstep_finished) return;
	
	float r = random();
	if(!FOOTSTEPS_CHECK_SURFACE) // || clienttype(self) != CLIENTTYPE_REAL
	{
		Player_PlayStepSound(STEP_CONCRETE, 1);
	}
	else
	{
		traceline(self.origin, self.origin - '0 0 64', TRUE, self);
		if (self.flags & FL_INWATER && self.waterlevel > 0)
		{
			Sound_Play(self, CHAN_BODY, 1, Sound_Radius(550), PITCH_NORM, "misc/h2ohit1.wav");
		}
		else if(StringContains(trace_dphittexturename, "metal"))
		{
			Player_PlayStepSound(STEP_METAL, 1);
		}
		else if(StringContains(trace_dphittexturename, "dirt"))
		{
			Player_PlayStepSound(STEP_DIRT, 1);
		}
		else
		{
			Player_PlayStepSound(STEP_CONCRETE, 1);
		}
	}
	self.footstep_finished = time + FOOTSTEPS_INTERVAL;
	if(self.button4) self.footstep_finished = time + FOOTSTEPS_INTERVAL_RUN;
}