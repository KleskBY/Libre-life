
#define PLAYER_FATAL_FALL_SPEED		1024
#define PLAYER_MAX_SAFE_FALL_SPEED	580
#define DAMAGE_FOR_FALL_SPEED		(float) 100 / ( PLAYER_FATAL_FALL_SPEED - PLAYER_MAX_SAFE_FALL_SPEED )
#define PLAYER_MIN_BOUNCE_SPEED		200
#define PLAYER_FALL_PUNCH_THRESHHOLD (float)350


void Q1Intermission_Think(entity pl); //serverqc/func/q1_intermission.qc 

void PlayerAnim()
{
	self.angles_x = 0;
	self.angles_z = 0;
	Player_AnimUpdate(self);
}

float Combat_PlayerFallDamage()
{
	return (fabs(self.jump_flag) - PLAYER_MAX_SAFE_FALL_SPEED) * DAMAGE_FOR_FALL_SPEED;
}

void PlayerPostThink()
{
	Player_TorsoSync(self);
	PlayerViewmodel_Update();   // before the early-outs: dead players must reach the hide branch

	if (gameover)
		goto pt_end;

	if (!IsAlive(self))
		goto pt_end;

	PlayerAnim();
	Player_TorsoAlignSpine(self);   // DP: pin torso waist to the legs' spine (post-frame)
	Player_WeaponModelSync(self);   // held w_ model on the hand bone
	Weapon_Frame();
	Player_UpdateGeiger();

	// Damage-icon latch decay (gamedefs.qc dmg_shownhud_bits).
	if (self.dmg_shownhud_bits && time > self.dmg_shownhud_time)
		self.dmg_shownhud_bits = 0;
// Fall triggers: half max safe distance triggers bootscrape (no damage); max safe distance triggers fallpain (damage)

	if(self.jump_flag < -150 && self.flags & FL_ONGROUND && self.health > 0) //Landing
	{
		if (self.watertype == CONTENT_WATER)
		{
			// no landing sound in water
		}
		else if (self.jump_flag < -PLAYER_MAX_SAFE_FALL_SPEED)
		{
			float flFallDamage = Combat_PlayerFallDamage();
			// CheckFalling: any damaging fall grunts
			Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, "player/pl_fallpain3.wav");
			if (flFallDamage > self.health) //splat
			{
				Sound_Play(self, CHAN_ITEM, 1, ATTN_NORM, PITCH_NORM, "common/bodysplat.wav");
			}
			if (Map_IsId1BSP() && flFallDamage > 5)
			{
				flFallDamage = 5;
			}
			if (flFallDamage > 0)
			{
				Combat_TakeDamage(self, world, world, flFallDamage, DMG_FALL); 
				self.punchangle.x = 0;
			}
		}

    }

	if (FBitSet(flags, FL_ONGROUND))
	{
		self.jump_flag = 0;
	}

pt_end:
}


void SetNewParms()
{

}

void SetChangeParms()
{

}

void Player_Think()
{
	self.weaponframe = 0;
	self.reload = FALSE;
	self.think = Player_Think;
	self.nextthink = time + 0.1;
}

void Player_Pain(entity attacker, float damage)
{
	if (self.health < 0) return;
	if (self.pain_finished > time) return;
	self.pain_finished = time + 0.1;
	
	Sound_Play(self, CHAN_VOICE, 1, Sound_Radius(800), PITCH_NORM,
		"player/pl_pain5.wav", "player/pl_pain6.wav", "player/pl_pain7.wav");
};


void Bot_PerFrame(entity bot);     // bot/think.qc
void WP_EnsureManager();           // bot/wp_manager.qc
void WP_LearnFrame(entity p);      // bot/wp_learn.qc

// Called every frame before physics
void PlayerPreThink()
{
	self.player_viewZoom255 = floor(self.viewzoom * 255 + 0.5);	// ahead of the early-outs below: the zoom still has to reach the client while dead or at intermission
	self.player_punch10x = floor(self.punchangle_x * 10 + 0.5);	// rint is CSQC-only here
	self.player_punch10y = floor(self.punchangle_y * 10 + 0.5);

	if (intermission_running)
	{
		Q1Intermission_Think(self);
		return;
	}
	if(gameover) return;
	if(self.deadflag == DEAD_DYING)
	{
		// Guard: restores Player_Dead think if overwritten by weapon code
		if (self.think != Player_Dead)
		{
			self.think     = Player_Dead;
			self.nextthink = time + 0.1;
		}
		return;
	}
	if(self.flags & FL_ONGROUND) self.flags = self.flags - (self.flags & FL_LADDERJUMP);

	if (self.deadflag >= DEAD_DYING)
	{
		Player_DeathThink();
		return;
	}
	
	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	Player_Swim();
	Player_FrictionTick();
	float trainUseConsumed = Player_TrainControls();
	Player_Jump();
	if (!trainUseConsumed)
		Player_Use();
	Player_TankFrame();
	// A bot has no usercmd, so its movement is written here, before physics
	// consumes it. A human instead teaches the waypoint graph where it walked.
	WP_EnsureManager();
	if (self.bot_isBot) Bot_PerFrame(self);
	else                WP_LearnFrame(self);

	Player_Footsteps();
	Player_Stance();
	Player_FixMovement();
	Flashlight_Tick();
	PowerUp_Tick();

	if (time < self.pausetime) self.velocity = '0 0 0'; // teleporters can force a non-moving pause time
};


void Player_TraceAttack(vector org, vector vel, float damage)
{
	if(!self.takedamage) return;
	self.last_hitgroup = Player_AnimHitGroupFromZ(self, org);
}

