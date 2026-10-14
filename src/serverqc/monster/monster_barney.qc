#define BARNEY_MODEL                "models/barney.iqm"

#define BA_HEALTH                   Skill_GetValue("sk_barney_health", 35)
#define BA_FOV                      0.2

#define BA_FOLLOW_KEEP_DIST         96
#define BA_FOLLOW_LOSE_DIST         2048
#define BA_FOLLOW_SPEED             120

#define BA_HOSTILE_RADIUS           1024
#define BA_ATTACK_RANGE             1024
#define BA_ATTACK_COOLDOWN          1.0
#define BA_BULLET_DAMAGE            Skill_GetValue("sk_9mm_bullet", 8)
#define BA_BULLET_SPREAD            0.0349	// ~2 degrees (VECTOR_CONE_2DEGREES)

#define BA_TALK_INTERVAL_MIN        6
#define BA_TALK_INTERVAL_MAX        12
#define BA_TALK_RANGE               1024
#define BA_PAIN_DEBOUNCE            0.6

#define BA_PAIN_SOUND1              "barney/ba_pain1.wav"
#define BA_PAIN_SOUND2              "barney/ba_pain2.wav"
#define BA_PAIN_SOUND3              "barney/ba_pain3.wav"
#define BA_DIE_SOUND1               "barney/ba_die1.wav"
#define BA_DIE_SOUND2               "barney/ba_die2.wav"
#define BA_DIE_SOUND3               "barney/ba_die3.wav"
#define BA_FIRE_SOUND               "barney/ba_attack2.wav"

#define BA_ANIM_IDLE                "idle1"
#define BA_ANIM_WALK                "walk"
#define BA_ANIM_RUN                 "run"
#define BA_ANIM_FLINCH              "smlflinch"
#define BA_ANIM_DRAW                "draw"
#define BA_ANIM_SHOOT               "shootgun"
#define BA_ANIM_HOLSTER             "disarm"
#define BA_ANIM_DIE                 "diesimple"

#define BARNEY_BODY_GUNHOLSTERED    0
#define BARNEY_BODY_GUNDRAWN        1
#define BARNEY_BODY_GUNGONE         2

.entity m_followTarget;
.float  m_nextTalk;
.float  m_saidHello;
.float  barney_gunDrawn;
.float  barney_nextAttack;

void Barney_Stand();
void Barney_Walk();
void Barney_Combat();
void Barney_Follow();
void Barney_Speak(string label);
void Barney_HandleAnimEvent(float code, string opts);

// DarkPlaces fallback; keep this in framegroup order.
float Barney_FrameByName(string name)
{
    if (name == "idle1")             return 0;
    if (name == "idle2")             return 1;
    if (name == "idle3")             return 2;
    if (name == "idle4")             return 3;
    if (name == "walk")              return 4;
    if (name == "run")               return 5;
    if (name == "shootgun")          return 6;
    if (name == "shootgun2")         return 7;
    if (name == "draw")              return 8;
    if (name == "disarm")            return 9;
    if (name == "reload")            return 10;
    if (name == "turnleft")          return 11;
    if (name == "turnright")         return 12;
    if (name == "laflinch")          return 13;
    if (name == "raflinch")          return 14;
    if (name == "llflinch")          return 15;
    if (name == "rlflinch")          return 16;
    if (name == "smlflinch")         return 17;
    if (name == "cower_stand")       return 18;
    if (name == "locked_door")       return 19;
    if (name == "fall_loop")         return 20;
    if (name == "barn_wave")         return 21;
    if (name == "beat_grunt")        return 22;
    if (name == "beat_gruntidle")    return 23;
    if (name == "flashlight")        return 24;
    if (name == "diesimple")         return 25;
    if (name == "dieviolent")        return 26;
    if (name == "diegutshot")        return 27;
    if (name == "dieforward")        return 28;
    if (name == "diebackward")       return 29;
    if (name == "diecrump")          return 30;
    if (name == "barnaclehit")       return 31;
    if (name == "barnaclepull")      return 32;
    if (name == "barnaclecrunch")    return 33;
    if (name == "barnaclechew")      return 34;
    if (name == "lying_on_back")     return 35;
    if (name == "lying_on_side")     return 36;
    if (name == "lying_on_stomach")  return 37;
    if (name == "stuffed_in_vent")   return 38;
    if (name == "standing_idle")     return 39;
    if (name == "cprbarney")         return 40;
    if (name == "cprbarneyrevive")   return 41;
    if (name == "barney_dragvent")   return 42;
    if (name == "dying_barney")      return 43;
    if (name == "dying_barneyidle")  return 44;
    if (name == "dying_friend")      return 45;
    if (name == "dying_friendidle")  return 46;
    if (name == "c1a3_bidle")        return 47;
    if (name == "c1a3_ventb")        return 48;
    if (name == "c1a3_emergeidle")   return 49;
    if (name == "c1a3_emerge")       return 50;
    if (name == "haulbarney")        return 51;
    if (name == "intropush")         return 52;
    if (name == "fence")             return 53;
    if (name == "sit1")              return 54;
    if (name == "sit2")              return 54;
    if (name == "sit3")              return 54;
    if (name == "almostidle")        return 55;
    if (name == "almost")            return 56;
    if (name == "laseridle")         return 57;
    if (name == "laser_top")         return 58;
    if (name == "laser_bottom")      return 59;
    if (name == "barneyfallidle")    return 60;
    if (name == "barneyfall")        return 61;
    if (name == "c3a2_draw")         return 62;
    if (name == "unlatch")           return 63;
    if (name == "retina")            return 64;
    if (name == "relaxstand")        return 65;
    if (name == "assassinated")      return 66;
    if (name == "trackswitch")       return 67;
    if (name == "pepsiswing")        return 68;
    if (name == "pepsipush")         return 69;
    if (name == "buttonpush")        return 70;
    return -1;
}

void Barney_PlayAnim(string name)
{
    if (!self.modelindex) return;
    float f;
    if (IsFTE()) f = frameforname(self.modelindex, name);
    else         f = Barney_FrameByName(name);
    if (f < 0) return;
    self.framerate = 1;             // a script may have parked us at 0
    if (self.frame == f) return;
    self.frame      = f;
    self.frame1time = time;
}

float Barney_AnimIndex(string name)
{
    if (!self.modelindex) return -1;
    if (IsFTE()) return frameforname(self.modelindex, name);
    return Barney_FrameByName(name);
}

float Barney_OnMoveAnim()
{
    return (self.frame == Barney_AnimIndex(BA_ANIM_WALK))
        || (self.frame == Barney_AnimIndex(BA_ANIM_RUN));
}

float Barney_PlayAnimForce(string name)
{
    return Monster_PlayAnimByName(self, name);
}

void Barney_Speak(string label)
{
    float dur = Sentences_Play(self, CHAN_VOICE, label, 1.0, ATTN_NORM, 100);
    if (dur <= 0)
    {
        // Missing sentence groups fall back to a pain sound.
        Sound_Play(self, CHAN_VOICE, 0.6, ATTN_NORM, PITCH_NORM, BA_PAIN_SOUND1);
        dur = 1.5;
    }

    if (time + dur > self.sent_sentenceBusyUntil)
        self.sent_sentenceBusyUntil = time + dur;
    if (time + dur + 2.0 > g_talkWaitTime)
        g_talkWaitTime = time + dur + 2.0;
}

float Barney_OkToSpeak()
{
    if (self.health <= 0) return FALSE;
    if (self.spawnflags & SF_MONSTER_GAG) return FALSE;
    if (self.monster_cine && self.monster_cine != world) return FALSE;
    if (self.m_nextTalk > time) return FALSE;
    if (self.sent_sentenceBusyUntil > time) return FALSE;
    if (time <= g_talkWaitTime) return FALSE;
    return TRUE;
}

float Barney_PlayScriptedSentence(string sentence, float duration, float volume,
    float attn, float concurrent, entity listener)
{
    if (!concurrent)
        self.m_followTarget = world;

    if (listener && listener != world)
    {
        vector to = listener.origin - self.origin;
        to_z = 0;
        if (vlen(to) > 1)
            self.ideal_yaw = vectoyaw(normalize(to));
    }

    float dur = Sentences_Play(self, CHAN_VOICE, sentence, volume, attn, 100);
    if (dur <= 0) dur = 1.5;

    if (time + dur > self.sent_sentenceBusyUntil)
        self.sent_sentenceBusyUntil = time + dur;
    if (self.sent_sentenceBusyUntil > self.m_nextTalk)
        self.m_nextTalk = self.sent_sentenceBusyUntil;

    if (self.sent_sentenceBusyUntil + 2.0 > g_talkWaitTime)
        g_talkWaitTime = self.sent_sentenceBusyUntil + 2.0;
    return TRUE;
}

void Barney_ResetTalkTimer()
{
    self.m_nextTalk = time + BA_TALK_INTERVAL_MIN
        + random() * (BA_TALK_INTERVAL_MAX - BA_TALK_INTERVAL_MIN);
}

entity Barney_FindNearestPlayer()
{
    entity best = world;
    float  best_d = 1000000000;
    entity p = find(world, classname, "player");
    while (p)
    {
        if (p.health > 0)
        {
            float d = vlen(p.origin - self.origin);
            if (d < best_d) { best_d = d; best = p; }
        }
        p = find(p, classname, "player");
    }
    return best;
}

float Barney_CanSee(entity tgt)
{
    if (!tgt || tgt == world) return FALSE;
    traceline(self.origin + self.view_ofs, tgt.origin + tgt.view_ofs, TRUE, self);
    return (trace_ent == tgt) || (trace_fraction == 1.0);
}

float Barney_IsHostile(entity e)
{
    if (e == self) return FALSE;
    return Monster_IsFearedByFriendlies(e);
}

entity Barney_FindHostile()
{
    entity best = world;
    float  best_d = BA_HOSTILE_RADIUS;
    entity e = findradius(self.origin, BA_HOSTILE_RADIUS);
    while (e)
    {
        if (Barney_IsHostile(e) && Barney_CanSee(e))
        {
            float d = vlen(e.origin - self.origin);
            if (d < best_d) { best_d = d; best = e; }
        }
        e = e.chain;
    }
    return best;
}

void Barney_TriggerCombat(entity threat)
{
    self.enemy    = threat;
    self.m_followTarget = world;
    if (!self.barney_gunDrawn)
    {
        self.barney_gunDrawn = TRUE;
        Barney_PlayAnimForce(BA_ANIM_DRAW);
        Body_SetGroup(self, "gun", BARNEY_BODY_GUNDRAWN);
    }
    Barney_Speak("BA_ATTACK");
    self.think     = Barney_Combat;
    self.nextthink = time + 0.1;
}

#define BA_GUN_LENGTH   9                     // right hand to muzzle, the pistol is part of the mesh
#define BA_SHELL_MODEL  "models/shell.iqm"

void Barney_FirePistol()
{
    if (!self.enemy || self.enemy == world) return;

    vector shootOrigin = self.origin + '0 0 50';
    vector aim = self.enemy.origin + self.enemy.view_ofs - shootOrigin;
    aim = normalize(aim);

    makevectors(vectoangles(aim));
    aim = aim
        + v_right * ((random() * 2 - 1) * BA_BULLET_SPREAD)
        + v_up    * ((random() * 2 - 1) * BA_BULLET_SPREAD);
    aim = normalize(aim);

    traceline(shootOrigin, shootOrigin + aim * 4096, FALSE, self);
    if (trace_fraction < 1.0 && trace_ent && trace_ent != world)
    {
        if (trace_ent.takedamage != DAMAGE_NO)
            T_Damage(trace_ent, self, self, BA_BULLET_DAMAGE, DMG_BULLET);
    }

    float pitch = 100 + floor(random() * 20) - 5;
    Sound_Play(self, CHAN_WEAPON, 1, ATTN_NORM, pitch, BA_FIRE_SOUND);

    self.effects = self.effects | EF_MUZZLEFLASH;
    Monster_MuzzleEffects(self, aim, BA_GUN_LENGTH, BA_SHELL_MODEL);
}

// Scripted draw and holster animations rely on these events to update the gun.
void Barney_HandleAnimEvent(float code, string opts)
{
    if (code == 2)	// BARNEY_AE_DRAW: gun into hand
    {
        self.barney_gunDrawn = TRUE;
        Body_SetGroup(self, "gun", BARNEY_BODY_GUNDRAWN);
    }
    else if (code == 4)	// holster: gun away
    {
        self.barney_gunDrawn = FALSE;
        Body_SetGroup(self, "gun", BARNEY_BODY_GUNHOLSTERED);
    }
}

void Barney_Combat()
{
    if (Monster_YieldIfDead()) return;
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Barney_Combat;
        self.nextthink = time + 0.2;
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Barney_Combat;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    if (!self.enemy || self.enemy == world || self.enemy.health <= 0)
    {
        self.enemy = world;
        if (Barney_OkToSpeak()) Barney_Speak("BA_KILL");
        self.think = Barney_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    vector to = self.enemy.origin - self.origin;
    to_z = 0;
    if (vlen(to) > 1)
    {
        self.ideal_yaw = vectoyaw(normalize(to));
        ChangeYaw();
    }

    float canSee = Barney_CanSee(self.enemy);
    float dist   = vlen(self.enemy.origin - self.origin);

    Barney_PlayAnim(BA_ANIM_IDLE);
    self.monster_state = MONSTERSTATE_COMBAT;

    if (canSee && dist < BA_ATTACK_RANGE && time > self.barney_nextAttack)
    {
        Barney_PlayAnimForce(BA_ANIM_SHOOT);
        Barney_FirePistol();
        self.barney_nextAttack = time + BA_ATTACK_COOLDOWN;
    }

    self.think = Barney_Combat;
    self.nextthink = time + 0.1;
}

void Barney_Stand()
{
    if (Monster_YieldIfDead()) return;

        self.think     = Barney_Stand;
        self.nextthink = time + 0.2;
    if (self.monster_cine && self.monster_cine != world)
    {
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Barney_Stand;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    if (self.sent_sentenceBusyUntil <= time || Barney_OnMoveAnim())
        Barney_PlayAnim(BA_ANIM_IDLE);
    self.monster_state = MONSTERSTATE_IDLE;

    entity threat = Barney_FindHostile();
    if (threat != world)
    {
        Barney_TriggerCombat(threat);
        return;
    }

    entity p = Barney_FindNearestPlayer();
    if (self.spawnflags & SF_MONSTER_PREDISASTER) p = world;
    if (Barney_OkToSpeak() && p && !self.m_saidHello && Barney_CanSee(p)
        && vlen(p.origin - self.origin) <= BA_TALK_RANGE)
    {
        self.m_saidHello = TRUE;
        Barney_Speak("BA_HELLO");
        Barney_ResetTalkTimer();
    }
    else if (Barney_OkToSpeak() && p && vlen(p.origin - self.origin) <= BA_TALK_RANGE)
    {
        Barney_Speak("BA_IDLE");
        Barney_ResetTalkTimer();
    }

    if (self.movetarget && time > self.pausetime && self.th_walk)
    {
        self.th_walk();
        return;
    }

}

void Barney_Walk()
{
    if (Monster_YieldIfDead()) return;
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Barney_Walk;
        self.nextthink = time + 0.2;
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Barney_Walk;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    Barney_PlayAnim(BA_ANIM_WALK);
    self.monster_state = MONSTERSTATE_ALERT;

    entity threat = Barney_FindHostile();
    if (threat != world)
    {
        Barney_TriggerCombat(threat);
        return;
    }

    if (!self.goalentity || self.goalentity == world)
    {
        self.think = Barney_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    movedist = 8;
    Monster_MoveToward(self.goalentity, 8);

    self.think = Barney_Walk;
    self.nextthink = time + 0.1;
}

void Barney_Follow()
{
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Barney_Follow;
        self.nextthink = time + 0.2;
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Barney_Follow;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    entity tgt = self.m_followTarget;
    if (!tgt || tgt == world || tgt.health <= 0)
    {
        self.m_followTarget = world;
        self.think = Barney_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    entity threat = Barney_FindHostile();
    if (threat != world)
    {
        Barney_TriggerCombat(threat);
        return;
    }

    float dist = vlen(tgt.origin - self.origin);
    if (dist > BA_FOLLOW_LOSE_DIST)
    {
        self.m_followTarget = world;
        self.think = Barney_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    self.monster_state = MONSTERSTATE_ALERT;
    if (dist <= BA_FOLLOW_KEEP_DIST)
    {
        Barney_PlayAnim(BA_ANIM_IDLE);
        vector to = tgt.origin - self.origin;
        to_z = 0;
        if (vlen(to) > 1) self.ideal_yaw = vectoyaw(normalize(to));
        ChangeYaw();
    }
    else
    {
        Barney_PlayAnim(BA_ANIM_WALK);
        movedist = BA_FOLLOW_SPEED * 0.1 / 12;
        Monster_MoveToward(tgt, 10);
    }

    self.think = Barney_Follow;
    self.nextthink = time + 0.1;
}

void Barney_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    dprint("Barney_UseHL: entered\n");

    if (!pActivator || !(pActivator.flags & FL_CLIENT))
    {
        dprint("  blocked: activator not a client\n");
        return;
    }
    if (self.health <= 0)
    {
        dprint("  blocked: dead\n");
        return;
    }
    if (self.monster_cine && self.monster_cine != world)
    {
        dprint("  blocked: scripted_sequence active\n");
        return;
    }
    if (self.enemy && self.enemy != world)
    {
        dprint("  blocked: in combat (enemy=");
        dprint(self.enemy.classname);
        dprint(")\n");
        return;
    }

    if (self.spawnflags & SF_MONSTER_PREDISASTER)
    {
        Barney_Speak("BA_POK");
        Barney_ResetTalkTimer();
        return;
    }

    if (self.m_followTarget == pActivator)
    {
        self.m_followTarget = world;
        Barney_Speak("BA_WAIT");
        self.think = Barney_Stand;
        self.nextthink = time + 0.1;
    }
    else
    {
        self.m_followTarget = pActivator;
        Barney_Speak("BA_OK");
        self.think = Barney_Follow;
        self.nextthink = time + 0.1;
    }
    Barney_ResetTalkTimer();
}

void Barney_PainSound()
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + BA_PAIN_DEBOUNCE;
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
        BA_PAIN_SOUND1, BA_PAIN_SOUND2, BA_PAIN_SOUND3);
}

void Barney_Pain(entity attacker, float damage)
{
    Barney_PainSound();

    if (self.monster_cine && self.monster_cine != world) return;

    Barney_PlayAnimForce(BA_ANIM_FLINCH);

    if (attacker.flags & FL_CLIENT)
    {
        if (self.enemy && self.enemy != world)
        {
            return;
        }

        makevectors(attacker.v_angle);
        vector toMe = self.origin - attacker.origin;
        toMe_z = 0;
        if (vlen(toMe) > 1) toMe = normalize(toMe);
        float facing = toMe * v_forward;

        if ((self.monster_memory & BITS_MEMORY_SUSPICIOUS) || facing > 0.96)
        {
            Barney_Speak("BA_MAD");
            self.monster_memory = self.monster_memory | BITS_MEMORY_PROVOKED;
            self.m_followTarget = world;
            Barney_TriggerCombat(attacker);
        }
        else
        {
            Barney_Speak("BA_SHOT");
            self.monster_memory = self.monster_memory | BITS_MEMORY_SUSPICIOUS;
        }
    }
    else if (Barney_IsHostile(attacker))
    {
        Barney_TriggerCombat(attacker);
    }
    else
    {
        Barney_Speak("BA_SHOT");
    }
}

void Barney_Die()
{
    Monster_ExitScriptedSequence();

    Sentences_Stop(self, CHAN_VOICE);

    if (Gib_ShouldGib())
    {
        Gib();
        return;
    }

    float pick = floor(random() * 3);
    string snd = BA_DIE_SOUND1;
    if      (pick == 1) snd = BA_DIE_SOUND2;
    else if (pick == 2) snd = BA_DIE_SOUND3;
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, snd);

    Barney_PlayAnimForce(BA_ANIM_DIE);

    Body_SetGroup(self, "gun", BARNEY_BODY_GUNGONE);
    entity gun = spawn();
    setorigin(gun, self.origin + '0 0 32');
    makevectors([0, self.angles_y, 0]);
    // Item_Place settles the dropped gun on the next tick
    gun.movetype = MOVETYPE_TOSS;
    gun.velocity = v_forward * 60 + v_right * random(-30, 30) + '0 0 120';
    entity stemp = self;
    self = gun;
    weapon_9mmhandgun();
    self = stemp;

    self.solid     = SOLID_CORPSE;
    self.movetype  = MOVETYPE_TOSS;
    setsize(self, '-16 -16 0', '16 16 16');
    self.deadflag  = DEAD_DEAD;
    self.flags     = self.flags - (self.flags & FL_MONSTER);
    self.takedamage = DAMAGE_NO;
    self.m_followTarget = world;
    self.enemy          = world;

    if (self.seq_leaveCorpse)
    {
        self.think = SUB_Null;
        self.nextthink = -1;
    }
    else
    {
        self.think = SUB_Remove;
        self.nextthink = time + 120;
    }
}

void Barney_Precache()
{
    precache_model(BA_SHELL_MODEL);
    precache_model(BARNEY_MODEL);
    precache_sound(BA_PAIN_SOUND1);
    precache_sound(BA_PAIN_SOUND2);
    precache_sound(BA_PAIN_SOUND3);
    precache_sound(BA_DIE_SOUND1);
    precache_sound(BA_DIE_SOUND2);
    precache_sound(BA_DIE_SOUND3);
    precache_sound(BA_FIRE_SOUND);
}

void Barney_StartGo()
{
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Barney_StartGo;
        self.nextthink = time + 0.5;
        return;
    }

    if (self.health <= 0 || self.deadflag != DEAD_NO)
        return;

    self.origin_z = self.origin_z + 1;
    droptofloor();
    if (!walkmove(0, 0))
    {
        dprint("monster_barney in wall at: ");
        dprint(vtos(self.origin));
        dprint("\n");
    }

    self.takedamage = DAMAGE_AIM;
    self.ideal_yaw  = self.angles * '0 1 0';
    if (!self.yaw_speed) self.yaw_speed = YAW_HL(90);
    self.view_ofs   = '0 0 50';
    self.flags      = self.flags | FL_MONSTER;

    self.use         = SUB_Null;
    self.usehl       = Barney_UseHL;
    self.object_caps = FCAP_IMPULSE_USE;

    if (self.target)
    {
        self.goalentity = self.movetarget = find(world, targetname, self.target);
        if (self.movetarget)
            self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
        if (self.movetarget && self.movetarget.classname == "path_corner")
        {
            if (self.th_walk) { self.th_walk(); return; }
        }
        else
        {
            self.pausetime = 99999999;
        }
    }
    else
    {
        self.pausetime = 99999999;
    }

    if (self.th_stand) self.th_stand();
    self.nextthink = self.nextthink + random() * 0.5;
}

void monster_barney()
{
    if (Monster_RemoveIfSpent()) return;
    if (RemoveInDeathmatch()) return;

    Barney_Precache();

    setmodel(self, BARNEY_MODEL);
    setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

    self.solid     = SOLID_SLIDEBOX;
    self.movetype  = MOVETYPE_STEP;
    self.health    = BA_HEALTH;
    self.yaw_speed = YAW_HL(90);

    self.flags = self.flags | FL_MONSTER;

    self.monster_state      = MONSTERSTATE_IDLE;
    self.monster_idealState = MONSTERSTATE_IDLE;
    self.monster_bloodColor        = BLOOD_COLOR_RED;
    self.monster_fieldOfView     = BA_FOV;
    self.skin = 0;
    self.body = 0;
    self.skinFamily = 0;
    Body_Apply(self);

    self.m_followTarget = world;
    self.m_saidHello    = FALSE;
    self.m_nextTalk     = time + 2 + random() * 4;
    self.barney_gunDrawn    = FALSE;
    self.barney_nextAttack   = 0;

    self.monster_capability = BITS_CAP_HEAR | BITS_CAP_TURN_HEAD
        | BITS_CAP_DOORS_GROUP;

    self.th_stand = Barney_Stand;
    self.th_walk  = Barney_Walk;
    self.th_run   = Barney_Combat;
    self.th_pain  = Barney_Pain;
    self.th_die   = Barney_Die;

    self.frameByName = Barney_FrameByName;
    self.playScriptedSentence = Barney_PlayScriptedSentence;
    self.handleAnimEvent = Barney_HandleAnimEvent;

    self.use         = SUB_Null;
    self.usehl       = Barney_UseHL;
    self.object_caps = FCAP_IMPULSE_USE;

    Monster_InitTakeDamage();

    self.think     = Barney_StartGo;
    self.nextthink = time + 0.1 + random() * 0.5;
    total_monsters = total_monsters + 1;

    Barney_PlayAnim(BA_ANIM_IDLE);
}


.float pose;

void monster_barney_dead()
{
    precache_model(BARNEY_MODEL);
    setmodel(self, BARNEY_MODEL);
    setsize(self, '-16 -16 0', '16 16 16');

    Body_Apply(self);

    self.solid     = SOLID_NOT;
    self.movetype  = MOVETYPE_NONE;
    self.effects   = 0;
    self.health    = 8;
    self.monster_bloodColor = BLOOD_COLOR_RED;


    string poseName = "lying_on_back";
    if      (self.pose == 1) poseName = "lying_on_side";
    else if (self.pose == 2) poseName = "lying_on_stomach";

    Monster_PlayAnimByName(self, poseName);
    self.framerate = 0;
	self.frame = 37 + self.pose;
	
	if(self.pose == 1) self.effects = EF_NODRAW;	// temp fix
}
