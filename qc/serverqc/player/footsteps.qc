
float FOOTSTEPS_CHECK_SURFACE = 1;
float FOOTSTEPS_VOLUME = 0.9;
float FOOTSTEPS_INTERVAL = 0.4;
float FOOTSTEPS_INTERVAL_RUN = 0.3;

#define STEP_CONCRETE	0		// default step sound
#define STEP_METAL		1		// metal floor
#define STEP_DIRT		2		// dirt, sand, rock
#define STEP_VENT		3		// ventillation duct
#define STEP_GRATE		4		// metal grating
#define STEP_TILE		5		// floor tiles
#define STEP_SLOSH		6		// shallow liquid puddle
#define STEP_WADE		7		// wading in liquid
#define STEP_LADDER		8		// climbing ladder

float m_iStepLeft;
float iSkipStep;
// void CBasePlayer :: PlayStepSound(int step, float fvol)
void Player_PlayStepSound(float step, float fvol)
{
	// irand - 0,1 for right foot, 2,3 for left foot
	// used to alternate left and right foot
	float irand = RandomInt(0, 1) + (m_iStepLeft * 2);

	m_iStepLeft = !m_iStepLeft;

	switch (step)
	{
	default:
	case STEP_CONCRETE:
		switch (irand)
		{
		// right foot
		case 0: sound(self, CHAN_BODY, "player/pl_step1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_step3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_step2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_step4.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_METAL:
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_metal1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_metal3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_metal2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_metal4.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_DIRT:
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_dirt1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_dirt3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_dirt2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_dirt4.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_VENT:
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_duct1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_duct3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_duct2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_duct4.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_GRATE:
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_grate1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_grate3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_grate2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_grate4.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_TILE:
		if (!RandomInt(0,4))
			irand = 4;
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_tile1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_tile3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_tile2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_tile4.wav", fvol, ATTN_NORM);	break;
		case 4: sound(self, CHAN_BODY, "player/pl_tile5.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_SLOSH:
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_slosh1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_slosh3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_slosh2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_slosh4.wav", fvol, ATTN_NORM);	break;
		}
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

		switch (irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_wade1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_wade2.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_wade3.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_wade4.wav", fvol, ATTN_NORM);	break;
		}
		break;
	case STEP_LADDER:
		switch(irand)
		{
		// right foot
		case 0:	sound(self, CHAN_BODY, "player/pl_ladder1.wav", fvol, ATTN_NORM);	break;
		case 1:	sound(self, CHAN_BODY, "player/pl_ladder3.wav", fvol, ATTN_NORM);	break;
		// left foot
		case 2:	sound(self, CHAN_BODY, "player/pl_ladder2.wav", fvol, ATTN_NORM);	break;
		case 3:	sound(self, CHAN_BODY, "player/pl_ladder4.wav", fvol, ATTN_NORM);	break;
		}
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
		//PlayRandomFootstepSound("footsteps/footstep1.wav", "footsteps/footstep2.wav", "footsteps/footstep3.wav", "footsteps/footstep4.wav");
	}
	else
	{
		traceline(self.origin, self.origin - '0 0 64', TRUE, self);
		if (self.flags & FL_INWATER && self.waterlevel > 0)
		{
			sound(self, CHAN_BODY, "misc/h2ohit1.wav", 1, SoundRadius(550));
		}
		else if(StringContains(trace_dphittexturename, "metal"))
		{
			Player_PlayStepSound(STEP_METAL, 1);
			// PlayRandomFootstepSound("footsteps/metal1.wav", "footsteps/metal2.wav", "footsteps/metal3.wav", "footsteps/metal4.wav");
		}
		else if(StringContains(trace_dphittexturename, "dirt"))
		{
			Player_PlayStepSound(STEP_DIRT, 1);
			// PlayRandomFootstepSound("footsteps/gravel1.wav", "footsteps/gravel2.wav", "footsteps/gravel3.wav", "footsteps/gravel4.wav");
		}
		else
		{
			Player_PlayStepSound(STEP_CONCRETE, 1);
			// PlayRandomFootstepSound("footsteps/footstep1.wav", "footsteps/footstep2.wav", "footsteps/footstep3.wav", "footsteps/footstep4.wav");
		}
	}
	self.footstep_finished = time + FOOTSTEPS_INTERVAL;
	if(self.button4) self.footstep_finished = time + FOOTSTEPS_INTERVAL_RUN;
}