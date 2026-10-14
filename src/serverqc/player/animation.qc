float PLAYER_DEEP_IDLE_DELAY = 10;
float PLAYER_RUN_SPEED       = 210;	// PM_UpdateStepSound velrun

#define PLAYER_AIR_GRACE  0.15      // longer than a slope step, shorter than a fall
#define PLAYER_JUMP_RISE  32        // climbing this fast is a jump, not a slope
#define PLAYER_WATER_GRACE 0.25     // longer than the two frame waterlevel clear

#define FTE_BASEBONE_DELTA 1

string Player_AnimWeaponExt(float wbit)
{
	float wid = Weapon_IDFromBit(wbit);
	if (wid <= WID_NONE || wid >= WID_COUNT) return "";
	return weapon_animExt[wid];
}

float Player_AnimIsTwoHanded(float wbit)
{
	float wid = Weapon_IDFromBit(wbit);
	if (wid <= WID_NONE || wid >= WID_COUNT) return FALSE;
	return weapon_twoHanded[wid];
}

// If the pelvis/root moves too far for a static torso aim pose, play the gait on the whole body instead
float Player_LegsFullBody(string legs)
{
	return (legs == "jump" || legs == "long_jump"
	     || legs == "swim" || legs == "treadwater");
}

float Player_AnimIDFromName(string name)
{
	if (name == "look_idle")               return 0;
	if (name == "idle")                    return 1;
	if (name == "deep_idle")               return 2;
	if (name == "run2")                    return 3;
	if (name == "walk2handed")             return 4;
	if (name == "2handshoot")              return 5;
	if (name == "crawl")                   return 6;
	if (name == "crouch_idle")             return 7;
	if (name == "jump")                    return 8;
	if (name == "long_jump")               return 9;
	if (name == "swim")                    return 10;
	if (name == "treadwater")              return 11;
	if (name == "run")                     return 12;
	if (name == "walk")                    return 13;
	if (name == "aim_2")                   return 14;
	if (name == "shoot_2")                 return 15;
	if (name == "aim_1")                   return 16;
	if (name == "shoot_1")                 return 17;
	if (name == "die_simple")              return 18;
	if (name == "die_backwards1")          return 19;
	if (name == "die_backwards")           return 20;
	if (name == "die_forwards")            return 21;
	if (name == "headshot")                return 22;
	if (name == "die_spin")                return 23;
	if (name == "gutshot")                 return 24;
	if (name == "ref_aim_crowbar")         return 25;
	if (name == "ref_shoot_crowbar")       return 26;
	if (name == "crouch_aim_crowbar")      return 27;
	if (name == "crouch_shoot_crowbar")    return 28;
	if (name == "ref_aim_trip")            return 29;
	if (name == "ref_shoot_trip")          return 30;
	if (name == "crouch_aim_trip")         return 31;
	if (name == "crouch_shoot_trip")       return 32;
	if (name == "ref_aim_onehanded")       return 33;
	if (name == "ref_shoot_onehanded")     return 34;
	if (name == "crouch_aim_onehanded")    return 35;
	if (name == "crouch_shoot_onehanded")  return 36;
	if (name == "ref_aim_python")          return 37;
	if (name == "ref_shoot_python")        return 38;
	if (name == "crouch_aim_python")       return 39;
	if (name == "crouch_shoot_python")     return 40;
	if (name == "ref_aim_shotgun")         return 41;
	if (name == "ref_shoot_shotgun")       return 42;
	if (name == "crouch_aim_shotgun")      return 43;
	if (name == "crouch_shoot_shotgun")    return 44;
	if (name == "ref_aim_gauss")           return 45;
	if (name == "ref_shoot_gauss")         return 46;
	if (name == "crouch_aim_gauss")        return 47;
	if (name == "crouch_shoot_gauss")      return 48;
	if (name == "ref_aim_mp5")             return 49;
	if (name == "ref_shoot_mp5")           return 50;
	if (name == "crouch_aim_mp5")          return 51;
	if (name == "crouch_shoot_mp5")        return 52;
	if (name == "ref_aim_rpg")             return 53;
	if (name == "ref_shoot_rpg")           return 54;
	if (name == "crouch_aim_rpg")          return 55;
	if (name == "crouch_shoot_rpg")        return 56;
	if (name == "ref_aim_egon")            return 57;
	if (name == "ref_shoot_egon")          return 58;
	if (name == "crouch_aim_egon")         return 59;
	if (name == "crouch_shoot_egon")       return 60;
	if (name == "ref_aim_squeak")          return 61;
	if (name == "ref_shoot_squeak")        return 62;
	if (name == "crouch_aim_squeak")       return 63;
	if (name == "crouch_shoot_squeak")     return 64;
	if (name == "ref_aim_hive")            return 65;
	if (name == "ref_shoot_hive")          return 66;
	if (name == "crouch_aim_hive")         return 67;
	if (name == "crouch_shoot_hive")       return 68;
	if (name == "ref_aim_bow")             return 69;
	if (name == "ref_shoot_bow")           return 70;
	if (name == "crouch_aim_bow")          return 71;
	if (name == "crouch_shoot_bow")        return 72;
	if (name == "deadback")                return 73;
	if (name == "deadsitting")             return 74;
	if (name == "deadstomach")             return 75;
	if (name == "deadtable")               return 76;
	return -1;
}

// Resolves a framegroup name against the playing entity. FTE handles this natively, while DP-class engines read the sidecar file; the hardcoded table is a fallback (indices match player.iqm.framegroups)
float Player_AnimResolve(entity p, string name)
{
	float f;
	if (IsFTE()) f = frameforname(p.modelindex, name);
	else         f = FG_FrameForName(p.model, name);
	if (f >= 0) return f;
	return Player_AnimIDFromName(name);
}

float Player_AnimDuration(entity p, float f)
{
	if (IsFTE()) return frameduration(p.modelindex, f);
	return FG_FrameDuration(p.model, f);
}

void Player_AnimSetLegs(entity p, string name)
{
	float f;

	if (Player_UseSplitBody())
	{
		// DP: the player entity wears the legs model; gait plays on .frame.
		f = Player_AnimResolve(p, name);
		if (f < 0) return;
		if (p.frame == f && p.anim_legs == name) return;
		p.frame      = f;
		p.frame1time = time;
		p.anim_legs  = name;
		return;
	}

	p.basebone = p.anim_basebone;

	f = Player_AnimResolve(p, name);
	if (f < 0) return;
	if (p.baseframe == f) return;

	p.baseframe      = f;
	p.baseframe2     = f;
	p.baseframe1time = time;
	p.baselerpfrac   = 0;
	p.anim_legs      = name;
}

void Player_AnimSetTorso(entity p, string name)
{
	// DP split: weapon/action anims play on the attached torso child.
	entity tgt = Player_UseSplitBody() ? p.torso_ent : p;
	if (!tgt) return;

	float f = Player_AnimResolve(tgt, name);
	if (f < 0) return;
	if (tgt.frame == f && p.anim_torso == name) return;

	tgt.frame      = f;
	tgt.frame2     = f;
	tgt.frame1time = time;
	tgt.lerpfrac   = 0;
	p.anim_torso   = name;
}

void Player_AnimClearLegsBlend(entity p)
{
	p.basebone  = 0;
	p.anim_legs = "";
}

void Player_AnimPickDeath(entity p)
{
	string name = "die_simple";

	if (p.last_hitgroup == HITGROUP_HEAD)          name = "headshot";
	else if (p.last_hitgroup == HITGROUP_STOMACH)  name = "gutshot";
	else
	{
		makevectors(p.angles);
		float dot = p.last_attacker_dir * v_forward;
		if (dot > 0.3)       name = "die_backwards";
		else if (dot < -0.3) name = "die_forwards";
		else                 name = "die_simple";
	}

	float f = Player_AnimResolve(p, name);
	if (f < 0) f = Player_AnimResolve(p, "die_simple");
	if (f < 0) return;

	p.anim_death_seq = f;
	p.frame          = f;
	p.frame1time     = time;
	p.basebone       = 0;
	p.anim_legs      = "";
	p.anim_torso     = name;
}

void Player_AnimOnFire(entity p)
{
	if (Player_LegsFullBody(p.anim_legs)) return;

	string ext = Player_AnimWeaponExt(p.weapon);
	if (ext == "") return;

	string anim;
	if (p.crouching) anim = strcat("crouch_shoot_", ext);
	else             anim = strcat("ref_shoot_", ext);

	entity tgt = Player_UseSplitBody() ? p.torso_ent : p;
	if (!tgt) return;

	float f = Player_AnimResolve(tgt, anim);
	if (f < 0) return;

	tgt.frame              = f;
	tgt.frame1time         = time;
	if (Player_UseSplitBody())
		tgt.effects = tgt.effects + (EF_RESTARTANIM_BIT - 2 * (tgt.effects & EF_RESTARTANIM_BIT));
	p.anim_torso           = anim;
	p.anim_torso_locked    = 1;

	float dur = Player_AnimDuration(tgt, f);
	if (dur <= 0) dur = 0.4;
	p.anim_torso_end_time  = time + dur;
}

void Player_AnimInit(entity p)
{
	float b = 0;
	float sb = Body_SplitBone(p.model);
	if (sb >= 0)
	{
		b = sb + FTE_BASEBONE_DELTA;
	}
	else if (IsFTE())
	{
		b = gettagindex(p, "Bip01 Spine");
		if (b <= 0) b = gettagindex(p, "Bip01_Spine");
		if (b <= 0) b = gettagindex(p, "Spine");
	}
	if (b <= 0) b = 14 + FTE_BASEBONE_DELTA;	// 50-joint rig last resort
	p.anim_basebone = b;

	p.anim_legs           = "";
	p.anim_torso          = "";
	p.anim_torso_locked   = 0;
	p.anim_torso_end_time = 0;
	p.anim_death_seq      = 0;
	p.anim_idle_since     = time;
	p.basebone            = b;
	p.baseframe           = 0;
	p.baseframe1time      = time;
	p.frame               = 0;
}

void Player_AnimUpdate(entity p)
{
	if (p.deadflag != DEAD_NO) return;

	float moving = (p.velocity_x != 0 || p.velocity_y != 0);
	if (moving || p.button0 || p.button2 || p.button3 || p.impulse)
		p.anim_idle_since = time;

	string legs = "idle";
	vector vxy = p.velocity;
	vxy_z = 0;
	float speed = vlen(vxy);
	float wantMove = (p.movement_x != 0 || p.movement_y != 0);

	if (p.flags & FL_ONGROUND)
		p.anim_groundTime = time;
	if (p.waterlevel >= 2)
		p.anim_waterTime = time;

	// Both states are latched, because both flicker. A slope drops FL_ONGROUND
	// for a frame at a time as the player steps off each facet, and at the water
	// surface waterlevel lapses whenever the touch that sets it misses. Rising
	// fast is a real jump and switches at once; otherwise the state has to have
	// been gone for the grace period before it counts.
	if (p.waterlevel >= 2 || time - p.anim_waterTime < PLAYER_WATER_GRACE)
	{
		legs = (speed > 16) ? "swim" : "treadwater";
	}
	// Out of the water entirely, or it is buoyancy rather than a leap: the water
	// brush pushes up hard enough to clear PLAYER_JUMP_RISE on its own.
	else if (!(p.flags & FL_ONGROUND) && p.waterlevel == 0
	         && (p.velocity_z > PLAYER_JUMP_RISE
	             || time - p.anim_groundTime > PLAYER_AIR_GRACE))
	{
		legs = "jump";
	}
	else if (p.crouching)
	{
		legs = (wantMove ? "crawl" : "crouch_idle");
	}
	else if (wantMove && speed > PLAYER_RUN_SPEED)
	{
		legs = (p.weapon == WID_NONE) ? "run2" : "run";
	}
	else if (wantMove)
	{
		legs = Player_AnimIsTwoHanded(p.weapon) ? "walk2handed" : "walk";
	}
	else
	{
		if (time - p.anim_idle_since > PLAYER_DEEP_IDLE_DELAY)
			legs = "deep_idle";
		else
			legs = "idle";
	}

	if (Player_LegsFullBody(legs))
	{
		p.anim_torso_locked = 0;
		if (Player_UseSplitBody())
		{
			Player_AnimSetTorso(p, legs);
			Player_AnimSetLegs(p, legs);
		}
		else
		{
			Player_AnimClearLegsBlend(p);
			Player_AnimSetTorso(p, legs);
		}
		return;
	}

	if (p.anim_torso_locked && time < p.anim_torso_end_time)
	{
	}
	else
	{
		p.anim_torso_locked = 0;

		string ext = Player_AnimWeaponExt(p.weapon);
		if (ext == "")
		{
			// Whole body plays the gait anim (no weapon stance).
			if (Player_UseSplitBody())
			{
				Player_AnimSetTorso(p, legs);
				Player_AnimSetLegs(p, legs);
			}
			else
			{
				// FTE: drop the basebone split so .frame owns every bone.
				Player_AnimClearLegsBlend(p);
				Player_AnimSetTorso(p, legs);
			}
			return;
		}

		string torso;
		if (p.crouching) torso = strcat("crouch_aim_", ext);
		else             torso = strcat("ref_aim_", ext);
		Player_AnimSetTorso(p, torso);
	}

	Player_AnimSetLegs(p, legs);
}

float Player_AnimHitGroupFromZ(entity p, vector hit)
{
	float relZ = hit.z - p.origin_z;
	if (relZ > 24) return HITGROUP_HEAD;
	if (relZ <  4) return HITGROUP_STOMACH;
	return HITGROUP_CHEST;
}

