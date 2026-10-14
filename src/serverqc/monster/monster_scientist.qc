#define SCIENTIST_MODEL             "models/scientist.iqm"
#define SCI_HEAD_GLASSES            0
#define SCI_HEAD_EINSTEIN           1
#define SCI_HEAD_LUTHER             2
#define SCI_HEAD_SLICK              3
#define SCI_NUM_HEADS               4

void Scientist_ApplyBody()
{
    if (self.body == -1)
    {
        self.body = 0;
        Body_SetGroup(self, "heads", floor(random() * SCI_NUM_HEADS));
    }
    self.skinFamily = 0;
    if (Body_GetGroup(self, "heads") == SCI_HEAD_LUTHER)
        self.skinFamily = 1;
    Body_Apply(self);
}

#define SCI_HEALTH                  Skill_GetValue("sk_scientist_health", 20)
#define SCI_FOV                     0.2

#define SCI_WALK_DIST               8
#define SCI_FOLLOW_DIST             10
#define SCI_FLEE_DIST               14

#define SCI_FOLLOW_KEEP_DIST        96
#define SCI_FOLLOW_LOSE_DIST        2048

#define SCI_HEAL_AMOUNT             Skill_GetValue("sk_scientist_heal", 25)
#define SCI_HEAL_RANGE              90
#define SCI_HEAL_COOLDOWN           60
#define SCI_HEAL_ANIM_TIME          1.2

#define SCI_TALK_INTERVAL_MIN       6
#define SCI_TALK_INTERVAL_MAX       12
#define SCI_TALK_RANGE              1024
#define SCI_PAIN_DEBOUNCE           0.8

#define SCI_HOSTILE_RADIUS          200
#define SCI_FLEE_DURATION           5
#define SCI_FLEE_GOAL_DIST          384
#define SCI_FLEE_GOAL_REFRESH       0.7
#define SCI_FLEE_GOAL_REACHED       64
#define SCI_SCREAM_INTERVAL         1.5

#define SCIENTIST_PAIN_SOUND1       "scientist/sci_pain1.wav"
#define SCIENTIST_PAIN_SOUND2       "scientist/sci_pain2.wav"
#define SCIENTIST_PAIN_SOUND3       "scientist/sci_pain3.wav"
#define SCIENTIST_PAIN_SOUND4       "scientist/sci_pain4.wav"
#define SCIENTIST_PAIN_SOUND5       "scientist/sci_pain5.wav"

// Animation names are resolved differently on FTE and DarkPlaces.
#define SCI_ANIM_IDLE               "idle1"
#define SCI_ANIM_WALK               "walk"
#define SCI_ANIM_WALK_SCARED        "walk_scared"
#define SCI_ANIM_RUN                "run"
#define SCI_ANIM_FLINCH             "flinch"
#define SCI_ANIM_HEAL               "give_shot"
#define SCI_ANIM_DIE                "diesimple"
#define SCI_ANIM_PANIC              "panic"
#define SCI_ANIM_FEAR               "fear1"

// g_talkWaitTime is declared in serverqc/func/speaker.qc, which compiles first.

.entity m_followTarget;
.float  scientist_healTime;
.float  scientist_fearTime;
.float  scientist_fleeUntil;
.float  scientist_nextFleeGoal;
.float  scientist_nextScream;
.float  m_nextTalk;
.float  m_saidHello;
.float  scientist_saidWoundLight;
.float  scientist_saidWoundHeavy;
.float  scientist_healAnimEnd;
.entity scientist_fleeGoal;
.float  scientist_fleeStuck;
.vector scientist_fleeLastOrg;
.float  scientist_cowerAnimEnd;

void Scientist_Stand();
void Scientist_Walk();
void Scientist_Flee();
void Scientist_Follow();
void Scientist_HealApply();
void Scientist_Speak(string label);

string Scientist_GetModel()
{
    string ovr = cvar_string("_sv_override_scientist_mdl");
    if (ovr && strlen(ovr) > 5) return ovr;
    return SCIENTIST_MODEL;
}

float Scientist_FrameByName(string name)
{
    if (name == "walk")                    return 0;
    if (name == "walk_scared")             return 1;
    if (name == "run")                     return 2;
    if (name == "run1")                    return 3;
    if (name == "run2")                    return 4;
    if (name == "180_Left")                return 5;
    if (name == "180_Right")                return 6;
    if (name == "flinch")                  return 7;
    if (name == "flinch1")                 return 8;
    if (name == "laflinch")                return 9;
    if (name == "raflinch")                return 10;
    if (name == "llflinch")                return 11;
    if (name == "rlflinch")                return 12;
    if (name == "idle1")                   return 13;
    if (name == "idle3")                   return 14;
    if (name == "idle4")                   return 15;
    if (name == "idle5")                   return 16;
    if (name == "idle6")                   return 17;
    if (name == "idle7")                   return 18;
    if (name == "crouchstand")             return 19;
    if (name == "crouch_idle")             return 20;
    if (name == "crouch_idle2")            return 21;
    if (name == "crouch_idle3_1")          return 22;
    if (name == "crouch_idle3_2")          return 23;
    if (name == "panic")                   return 24;
    if (name == "fear1")                   return 25;
    if (name == "fear2")                   return 26;
    if (name == "eye_wipe")                return 27;
    if (name == "pull_needle")             return 28;
    if (name == "return_needle")           return 29;
    if (name == "give_shot")               return 30;
    if (name == "diesimple")               return 31;
    if (name == "dieforward")              return 32;
    if (name == "dieforward1")             return 33;
    if (name == "diebackward")             return 34;
    if (name == "headshot")                return 35;
    if (name == "gutshot")                 return 36;
    if (name == "lying_on_back")           return 37;
    if (name == "lying_on_stomach")        return 38;
    if (name == "dead_sitting")            return 39;
    if (name == "dead_table1")             return 40;
    if (name == "dead_table2")             return 41;
    if (name == "dead_table3")             return 42;
    if (name == "barnacled1")              return 43;
    if (name == "barnacled2")              return 44;
    if (name == "barnacled3")              return 45;
    if (name == "barnacled4")              return 46;
    if (name == "console")                 return 47;
    if (name == "checktie")                return 48;
    if (name == "dryhands")                return 49;
    if (name == "tieshoe")                 return 50;
    if (name == "writeboard")              return 51;
    if (name == "studycart")               return 52;
    if (name == "lean")                    return 53;
    if (name == "pondering")               return 54;
    if (name == "pondering2")              return 55;
    if (name == "pondering3")              return 56;
    if (name == "buysoda")                 return 57;
    if (name == "pause")                   return 58;
    if (name == "yes")                     return 59;
    if (name == "no")                      return 60;
    if (name == "push_button")             return 61;
    if (name == "converse1")               return 62;
    if (name == "converse2")               return 63;
    if (name == "retina")                  return 64;
    if (name == "talkleft")                return 65;
    if (name == "talkright")               return 66;
    if (name == "deskidle")                return 67;
    if (name == "coffee")                  return 68;
    if (name == "franticbutton")           return 69;
    if (name == "startle")                 return 70;
    if (name == "sitlookleft")             return 71;
    if (name == "sitlookright")            return 72;
    if (name == "sitscared")               return 73;
    if (name == "sitting2")                return 74;
    if (name == "sitting3")                return 75;
    if (name == "cprscientist")            return 76;
    if (name == "cprscientistrevive")      return 77;
    if (name == "cowering_in_corner")      return 78;
    if (name == "sstruggleidle")           return 79;
    if (name == "sstruggle")               return 80;
    if (name == "headcrabbed")             return 81;
    if (name == "c1a0_catwalkidle")        return 82;
    if (name == "c1a0_catwalk")            return 83;
    if (name == "ceiling_dangle")          return 84;
    if (name == "ventpull1")               return 85;
    if (name == "ventpull2")               return 86;
    if (name == "ventpullidle1")           return 87;
    if (name == "ventpullidle2")           return 88;
    if (name == "sitidle")                 return 89;
    if (name == "sitstand")                return 90;
    if (name == "keypad")                  return 91;
    if (name == "panic1")                  return 92;
    if (name == "lookwindow")              return 93;
    if (name == "wave")                    return 94;
    if (name == "pulldoor")                return 95;
    if (name == "beatdoor")                return 96;
    if (name == "fallingloop")             return 97;
    if (name == "crawlwindow")             return 98;
    if (name == "divewindow")              return 99;
    if (name == "locked_door")             return 100;
    if (name == "push_button2")            return 101;
    if (name == "unlock_door")             return 102;
    if (name == "quicklook")               return 103;
    if (name == "handrailidle")            return 104;
    if (name == "handrail")                return 105;
    if (name == "hanging_idle")            return 106;
    if (name == "fall")                    return 107;
    if (name == "scientist_get_pulled")    return 108;
    if (name == "hanging_idle2")           return 109;
    if (name == "fall_elevator")           return 110;
    if (name == "scientist_idlewall")      return 111;
    if (name == "ickyjump_sci")            return 112;
    if (name == "haulscientist")           return 113;
    if (name == "c1a4_wounded_idle")       return 114;
    if (name == "c1a4_dying_speech")       return 115;
    if (name == "tentacle_grab")           return 116;
    if (name == "helicack")                return 117;
    if (name == "windive")                 return 118;
    if (name == "scicrashidle")            return 119;
    if (name == "scicrash")                return 120;
    if (name == "onguard")                 return 121;
    if (name == "seeya")                   return 122;
    if (name == "rocketcrawl")             return 123;
    if (name == "portal")                  return 124;
    if (name == "gluonshow")               return 125;
    if (name == "crouch")                  return 126;
    if (name == "kneel")                   return 127;
    return -1;
}

void Scientist_PlayAnim(string name)
{
    if (!self.modelindex) return;
    float f;
    if (IsFTE()) f = frameforname(self.modelindex, name);
    else         f = Scientist_FrameByName(name);
    if (f < 0) return;
    self.framerate = 1;	// script might set framerate to 0
    if (self.frame == f) return;
    self.frame      = f;
    self.frame1time = time;
}

float Scientist_PlayAnimForce(string name)
{
    return Monster_PlayAnimByName(self, name);
}

float Scientist_AnimIndex(string name)
{
    if (!self.modelindex) return -1;
    if (IsFTE()) return frameforname(self.modelindex, name);
    return Scientist_FrameByName(name);
}

float Scientist_OnMoveAnim()
{
    return (self.frame == Scientist_AnimIndex(SCI_ANIM_WALK))
        || (self.frame == Scientist_AnimIndex(SCI_ANIM_WALK_SCARED))
        || (self.frame == Scientist_AnimIndex(SCI_ANIM_RUN))
        || (self.frame == Scientist_AnimIndex("run1"))
        || (self.frame == Scientist_AnimIndex("run2"));
}

float Scientist_PlayScriptedSentence(string sentence, float duration,
                                     float volume, float attn,
                                     float concurrent, entity listener)
{
    if (self.health <= 0) return FALSE;

    float scripted = (self.monster_cine && self.monster_cine != world);

    if (!scripted && listener && listener != world)
    {
        vector to = listener.origin - self.origin;
        to_z = 0;
        if (vlen(to) > 1)
        {
            float yaw = vectoyaw(normalize(to));
            self.ideal_yaw = yaw;
            self.angles_y  = yaw;
        }

        // Hold the idle gate for the full talk gesture, not only the audio.
        makevectors(self.angles);
        vector rel = listener.origin - self.origin;
        float animDur;
        if ((rel * v_right) < 0) animDur = Scientist_PlayAnimForce("talkleft");
        else                     animDur = Scientist_PlayAnimForce("talkright");
        if (time + animDur > self.sent_sentenceBusyUntil)
            self.sent_sentenceBusyUntil = time + animDur;
    }

    if (time + duration > self.sent_sentenceBusyUntil)
        self.sent_sentenceBusyUntil = time + duration;

    Scientist_Speak(sentence);

    if (self.sent_sentenceBusyUntil > self.m_nextTalk)
        self.m_nextTalk = self.sent_sentenceBusyUntil;

    if (self.sent_sentenceBusyUntil + 2.0 > g_talkWaitTime)
        g_talkWaitTime = self.sent_sentenceBusyUntil + 2.0;
    return TRUE;
}

void Scientist_Speak(string label)
{
    float dur = Sentences_Play(self, CHAN_VOICE, label, 1.0, ATTN_NORM, 100);
    if (dur <= 0)
    {
        Sound_Play(self, CHAN_VOICE, 0.6, ATTN_NORM, 100,
            SCIENTIST_PAIN_SOUND1,
            SCIENTIST_PAIN_SOUND2,
            SCIENTIST_PAIN_SOUND3);
        dur = 1.5;
    }

    if (time + dur > self.sent_sentenceBusyUntil)
        self.sent_sentenceBusyUntil = time + dur;

    // Leave a short gap before another talk monster speaks.
    if (time + dur + 2.0 > g_talkWaitTime)
        g_talkWaitTime = time + dur + 2.0;
}

float Scientist_OkToSpeak()
{
    if (self.health <= 0) return FALSE;
    if (self.spawnflags & SF_MONSTER_GAG) return FALSE;
    if (self.monster_cine && self.monster_cine != world) return FALSE;
    if (self.m_nextTalk > time) return FALSE;
    if (self.sent_sentenceBusyUntil > time) return FALSE;
    if (time <= g_talkWaitTime) return FALSE;
    if (self.scientist_fleeUntil > time) return FALSE;
    return TRUE;
}

void Scientist_ResetTalkTimer()
{
    self.m_nextTalk = time + SCI_TALK_INTERVAL_MIN
        + random() * (SCI_TALK_INTERVAL_MAX - SCI_TALK_INTERVAL_MIN);
}

entity Scientist_FindNearestPlayer()
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

float Scientist_CanSee(entity tgt)
{
    if (!tgt || tgt == world) return FALSE;
    traceline(self.origin + self.view_ofs, tgt.origin + tgt.view_ofs, TRUE, self);
    return (trace_ent == tgt) || (trace_fraction == 1.0);
}

float Scientist_IsHostile(entity e)
{
    if (e == self) return FALSE;
    return Monster_IsFearedByFriendlies(e);
}

// Returns world if no hostile in radius + LOS.
entity Scientist_FindHostile()
{
    entity best = world;
    float  best_d = SCI_HOSTILE_RADIUS;
    entity e = findradius(self.origin, SCI_HOSTILE_RADIUS);
    while (e)
    {
        if (Scientist_IsHostile(e) && Scientist_CanSee(e))
        {
            float d = vlen(e.origin - self.origin);
            if (d < best_d) { best_d = d; best = e; }
        }
        e = e.chain;
    }
    return best;
}

void Scientist_RemoveFleeGoal()
{
    if (self.scientist_fleeGoal && self.scientist_fleeGoal != world)
    {
        if (self.goalentity == self.scientist_fleeGoal)
            self.goalentity = world;
        remove(self.scientist_fleeGoal);
        self.scientist_fleeGoal = world;
    }
}

entity Scientist_EnsureFleeGoal()
{
    if (!self.scientist_fleeGoal || self.scientist_fleeGoal == world)
    {
        self.scientist_fleeGoal = spawn();
        self.scientist_fleeGoal.classname = "scientist_flee_goal";
        self.scientist_fleeGoal.owner = self;
        self.scientist_fleeGoal.solid = SOLID_NOT;
        self.scientist_fleeGoal.movetype = MOVETYPE_NONE;
        setsize(self.scientist_fleeGoal, '-8 -8 -8', '8 8 8');
    }
    return self.scientist_fleeGoal;
}

void Scientist_UpdateFleeGoal()
{
    if (!self.enemy || self.enemy == world) return;
    if (time < self.scientist_nextFleeGoal && self.goalentity && self.goalentity != world)
        return;

    vector away = self.origin - self.enemy.origin;
    away_z = 0;
    if (vlen(away) < 1) away = '1 0 0';
    away = normalize(away);

    makevectors([0, vectoyaw(away), 0]);
    float side = (random() < 0.5) ? -1 : 1;
    vector goal = self.origin + away * SCI_FLEE_GOAL_DIST
        + v_right * side * (64 + random() * 96);

    traceline(self.origin + '0 0 32', goal + '0 0 32', TRUE, self);
    if (trace_fraction < 1)
        goal = trace_endpos - away * 32;
    goal_z = self.origin_z;

    entity fleeGoal = Scientist_EnsureFleeGoal();
    setorigin(fleeGoal, goal);
    self.goalentity = fleeGoal;
    self.ideal_yaw = vectoyaw(fleeGoal.origin - self.origin);
    self.scientist_nextFleeGoal = time + SCI_FLEE_GOAL_REFRESH;
}

void Scientist_TriggerFlee(entity threat)
{
    if (self.monster_cine && self.monster_cine != world) return;

    self.enemy        = threat;
    self.scientist_fearTime   = time;
    self.scientist_fleeUntil  = time + SCI_FLEE_DURATION;
    self.search_time  = self.scientist_fleeUntil;
    self.scientist_nextFleeGoal = 0;
    Scientist_UpdateFleeGoal();
    self.think        = Scientist_Flee;
    self.nextthink    = time + 0.05;
    Scientist_Speak("SC_FEAR");
}

float Scientist_CanHeal(entity tgt)
{
    if (self.scientist_healTime > time) return FALSE;
    if (!tgt || tgt == world) return FALSE;
    if (tgt.health <= 0) return FALSE;
    if (tgt.max_health <= 0) return FALSE;
    if (tgt.health > tgt.max_health * 0.5) return FALSE;
    return TRUE;
}

void Scientist_HealApply()
{
    entity tgt = self.m_followTarget;
    self.scientist_healAnimEnd = 0;
    Body_SetGroup(self, "needle", 0);

    if (Scientist_CanHeal(tgt) && vlen(tgt.origin - self.origin) <= SCI_HEAL_RANGE)
    {
        T_Heal(tgt, SCI_HEAL_AMOUNT, FALSE);
        self.scientist_healTime = time + SCI_HEAL_COOLDOWN;
        Scientist_Speak("SC_OK");
    }

    self.think = Scientist_Follow;
    self.nextthink = time + 0.1;
}

void Scientist_HealStart(entity tgt)
{
    if (Scientist_OkToSpeak())
        Scientist_Speak("SC_HEAL");

    vector to = tgt.origin - self.origin;
    to_z = 0;
    self.angles_y  = vectoyaw(normalize(to));
    self.ideal_yaw = self.angles_y;

    float dur = Scientist_PlayAnimForce(SCI_ANIM_HEAL);
    if (dur <= 0) dur = SCI_HEAL_ANIM_TIME;
    self.scientist_healAnimEnd = time + dur;

    Body_SetGroup(self, "needle", 1);

    self.think = Scientist_HealApply;
    self.nextthink = time + dur;
}

void Scientist_Stand()
{
    if (Monster_YieldIfDead()) return;
    // Schedule FIRST: if the body kills us, th_die installs the death chain afterwards and wins
    self.think     = Scientist_Stand;
    self.nextthink = time + 0.2;

    if (self.monster_cine && self.monster_cine != world)
    {
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Scientist_Stand;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    if (self.sent_sentenceBusyUntil <= time || Scientist_OnMoveAnim())
        Scientist_PlayAnim(SCI_ANIM_IDLE);
    Scientist_RemoveFleeGoal();
    self.monster_state = MONSTERSTATE_IDLE;

    entity threat = Scientist_FindHostile();
    if (threat != world)
    {
        Scientist_TriggerFlee(threat);
        return;
    }

    if (Scientist_OkToSpeak())
    {
        if (!self.scientist_saidWoundHeavy && self.health <= self.max_health * 0.5)
        {
            self.scientist_saidWoundHeavy = TRUE;
            Scientist_Speak("SC_MORTAL");
            Scientist_ResetTalkTimer();
        }
        else if (!self.scientist_saidWoundLight && self.health <= self.max_health * 0.75)
        {
            self.scientist_saidWoundLight = TRUE;
            Scientist_Speak("SC_WOUND");
            Scientist_ResetTalkTimer();
        }
    }

    float isPre = (self.spawnflags & SF_MONSTER_PREDISASTER);
    string helloGroup = isPre ? "SC_PHELLO" : "SC_HELLO";
    string idleGroup  = isPre ? "SC_PIDLE"  : "SC_IDLE";
    string speakGroup = idleGroup;
    if (isPre && (random() < 0.5)) speakGroup = "SC_PQUEST";

    entity p = Scientist_FindNearestPlayer();

    if (Scientist_OkToSpeak() && p && !self.m_saidHello && Scientist_CanSee(p)
        && vlen(p.origin - self.origin) <= SCI_TALK_RANGE)
    {
        self.m_saidHello = TRUE;
        Scientist_Speak(helloGroup);
        Scientist_ResetTalkTimer();
    }
    else if (Scientist_OkToSpeak() && p && vlen(p.origin - self.origin) <= SCI_TALK_RANGE)
    {
        Scientist_Speak(speakGroup);
        Scientist_ResetTalkTimer();
    }

    if (self.movetarget && time > self.pausetime && self.th_walk)
    {
        self.th_walk();
        return;
    }

}

void Scientist_Walk()
{
    if (Monster_YieldIfDead()) return;
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Scientist_Walk;
        self.nextthink = time + 0.2;
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Scientist_Walk;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    Scientist_PlayAnim(SCI_ANIM_WALK);
    self.monster_state = MONSTERSTATE_ALERT;

    entity threat = Scientist_FindHostile();
    if (threat != world)
    {
        Scientist_TriggerFlee(threat);
        return;
    }

    if (!self.goalentity || self.goalentity == world)
    {
        self.think = Scientist_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    movedist = SCI_WALK_DIST;
    Monster_MoveToward(self.goalentity, SCI_WALK_DIST);

    self.think = Scientist_Walk;
    self.nextthink = time + 0.1;
}

void Scientist_Cower()
{
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Scientist_Cower;
        self.nextthink = time + 0.2;
        return;
    }

    self.think = Scientist_Cower;
    self.nextthink = time + 0.2;

    if (time < self.scientist_cowerAnimEnd) return;
    Scientist_PlayAnim("crouch_idle");

    entity threat = Scientist_FindHostile();
    if (threat != world)
    {
        self.enemy = threat;
        self.scientist_fleeUntil = time + 2;
    }
    if (time <= self.scientist_fleeUntil) return;

    self.enemy = world;
    self.scientist_fleeStuck = 0;
    Scientist_RemoveFleeGoal();
    Scientist_PlayAnim(SCI_ANIM_IDLE);
    if (self.m_followTarget && self.m_followTarget != world)
        self.think = Scientist_Follow;
    else
        self.think = Scientist_Stand;
    self.nextthink = time + 0.1;
}

void Scientist_CowerStart()
{
    self.scientist_fleeStuck = 0;

    if (self.enemy && self.enemy != world)
    {
        self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
        self.angles_y  = self.ideal_yaw;
    }
    if (random() < 0.3)
        Scientist_Speak("SC_SCREAM");

    float dur = Scientist_PlayAnimForce(SCI_ANIM_PANIC);
    if (dur <= 0) dur = 0.5;
    self.scientist_cowerAnimEnd = time + dur;

    self.think = Scientist_Cower;
    self.nextthink = time + 0.1;
}

void Scientist_Flee()
{
    if (Monster_YieldIfDead()) return;
    // Schedule FIRST so a mid-think death lets th_die win the think
    self.think     = Scientist_Flee;
    self.nextthink = time + 0.1;

    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Scientist_Flee;
        self.nextthink = time + 0.2;
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Scientist_Flee;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    if (time > self.scientist_fleeUntil
        || !self.enemy
        || self.enemy == world
        || self.enemy.health <= 0)
    {
        self.enemy = world;
        Scientist_RemoveFleeGoal();
        if (self.m_followTarget && self.m_followTarget != world)
            self.think = Scientist_Follow;
        else
            self.think = Scientist_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    Scientist_PlayAnim(SCI_ANIM_RUN);
    self.monster_state = MONSTERSTATE_COMBAT;

    Scientist_UpdateFleeGoal();
    if (self.goalentity && self.goalentity != world)
    {
        self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);

        if (vlen(self.goalentity.origin - self.origin) <= SCI_FLEE_GOAL_REACHED)
            self.scientist_nextFleeGoal = 0;
    }

    AI_Run(SCI_FLEE_DIST);

    if (vlen(self.origin - self.scientist_fleeLastOrg) < 2)
    {
        self.scientist_fleeStuck = self.scientist_fleeStuck + 0.1;
        if (self.scientist_fleeStuck >= 0.8)
        {
            Scientist_CowerStart();
            return;
        }
    }
    else
        self.scientist_fleeStuck = 0;
    self.scientist_fleeLastOrg = self.origin;

    if (time > self.scientist_nextScream)
    {
        self.scientist_nextScream = time + SCI_SCREAM_INTERVAL;
        Scientist_Speak("SC_SCREAM");
    }

}

void Scientist_Follow()
{
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Scientist_Follow;
        self.nextthink = time + 0.2;
        return;
    }
    if (Monster_IsBarnacled())
    {
        self.think = Scientist_Follow;
        self.nextthink = time + BARNACLE_VICTIM_THINK_RATE;
        Monster_BarnacledThink();
        return;
    }

    entity tgt = self.m_followTarget;
    if (!tgt || tgt == world || tgt.health <= 0)
    {
        self.m_followTarget = world;
        self.think = Scientist_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    Scientist_RemoveFleeGoal();

    entity threat = Scientist_FindHostile();
    if (threat != world)
    {
        Scientist_TriggerFlee(threat);
        return;
    }

    float dist = vlen(tgt.origin - self.origin);

    if (dist > SCI_FOLLOW_LOSE_DIST)
    {
        self.m_followTarget = world;
        self.think = Scientist_Stand;
        self.nextthink = time + 0.1;
        return;
    }

    if (dist <= SCI_FOLLOW_KEEP_DIST && Scientist_CanHeal(tgt))
    {
        Scientist_HealStart(tgt);
        return;
    }

    self.monster_state = MONSTERSTATE_ALERT;

    if (dist <= SCI_FOLLOW_KEEP_DIST)
    {
        Scientist_PlayAnim(SCI_ANIM_IDLE);
        vector to = tgt.origin - self.origin;
        to_z = 0;
        if (vlen(to) > 1) self.ideal_yaw = vectoyaw(normalize(to));
        ChangeYaw();
    }
    else
    {
        Scientist_PlayAnim(SCI_ANIM_WALK);
        movedist = SCI_FOLLOW_DIST;
        Monster_MoveToward(tgt, SCI_FOLLOW_DIST);
    }

    self.think = Scientist_Follow;
    self.nextthink = time + 0.1;
}

void Scientist_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (!pActivator || !(pActivator.flags & FL_CLIENT)) return;
    if (self.health <= 0) return;
    if (self.monster_cine && self.monster_cine != world) return;
    if (self.scientist_fleeUntil > time) return;

    if (self.spawnflags & SF_MONSTER_PREDISASTER)
    {
        Scientist_Speak("SC_POK");
        Scientist_ResetTalkTimer();
        return;
    }

    if (self.m_followTarget == pActivator)
    {
        self.m_followTarget = world;
        Scientist_Speak("SC_WAIT");
        self.think = Scientist_Stand;
        self.nextthink = time + 0.1;
    }
    else
    {
        self.m_followTarget = pActivator;
        Scientist_Speak("SC_OK");
        self.think = Scientist_Follow;
        self.nextthink = time + 0.1;
    }
    Scientist_ResetTalkTimer();
}

void Scientist_PainSound()
{
    if (self.pain_finished > time) return;
    self.pain_finished = time + SCI_PAIN_DEBOUNCE;
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
        SCIENTIST_PAIN_SOUND1,
        SCIENTIST_PAIN_SOUND2,
        SCIENTIST_PAIN_SOUND3);
}

void Scientist_Pain(entity attacker, float damage)
{
    Scientist_PainSound();

    if (self.monster_cine && self.monster_cine != world)
        return;

    Scientist_PlayAnimForce(SCI_ANIM_FLINCH);

    if (self.scientist_healAnimEnd > 0)
    {
        self.scientist_healAnimEnd = 0;
        Body_SetGroup(self, "needle", 0);
        self.think = Scientist_Follow;
        self.nextthink = time + 0.1;
    }

    if (attacker.flags & FL_CLIENT)
    {
        Scientist_Speak("SC_PLFEAR");
        if (self.m_followTarget == attacker)
            self.m_followTarget = world;
        Scientist_TriggerFlee(attacker);
    }
    else if (Scientist_IsHostile(attacker))
    {
        Scientist_TriggerFlee(attacker);
    }
    else
    {
        Scientist_Speak("SC_FEAR");
    }
}

void Scientist_Die()
{
    Monster_ExitScriptedSequence();

    Sentences_Stop(self, CHAN_VOICE);

    if (Gib_ShouldGib())
    {
        Gib();
        return;
    }

    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, 100,
        SCIENTIST_PAIN_SOUND1,
        SCIENTIST_PAIN_SOUND4,
        SCIENTIST_PAIN_SOUND5);
    Scientist_Speak("SC_SCREAM");
    Scientist_PlayAnimForce(SCI_ANIM_DIE);

    self.solid = SOLID_CORPSE;
    self.movetype = MOVETYPE_TOSS;
    setsize(self, '-16 -16 0', '16 16 16');
    self.deadflag = DEAD_DEAD;
    self.flags = self.flags - (self.flags & FL_MONSTER);
    self.takedamage = DAMAGE_NO;
    self.m_followTarget = world;
    self.enemy          = world;
    Scientist_RemoveFleeGoal();

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

void Scientist_Precache()
{
    precache_model(Scientist_GetModel());
    precache_sound(SCIENTIST_PAIN_SOUND1);
    precache_sound(SCIENTIST_PAIN_SOUND2);
    precache_sound(SCIENTIST_PAIN_SOUND3);
    precache_sound(SCIENTIST_PAIN_SOUND4);
    precache_sound(SCIENTIST_PAIN_SOUND5);
}

void Scientist_StartGo()
{
    // Retry after script release, ensuring droptofloor origin is stable.
    if (self.monster_cine && self.monster_cine != world)
    {
        self.think = Scientist_StartGo;
        self.nextthink = time + 0.5;
        return;
    }

    if (self.health <= 0 || self.deadflag != DEAD_NO)
        return;

    self.origin_z = self.origin_z + 1;
    droptofloor();
    if (!walkmove(0, 0))
    {
        dprint("monster_scientist in wall at: ");
        dprint(vtos(self.origin));
        dprint("\n");
    }

    self.takedamage = DAMAGE_AIM;
    self.ideal_yaw  = self.angles * '0 1 0';
    if (!self.yaw_speed) self.yaw_speed = YAW_HL(150);
    self.view_ofs   = '0 0 50';
    self.flags      = self.flags | FL_MONSTER;

    self.use         = SUB_Null;
    self.usehl       = Scientist_UseHL;
    self.object_caps = FCAP_IMPULSE_USE;

    if (self.target)
    {
        self.goalentity = self.movetarget = find(world, targetname, self.target);
        if (!self.movetarget)
        {
            dprint("scientist can't find target at ");
            dprint(vtos(self.origin));
            dprint("\n");
        }
        else
        {
            self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
        }
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

void monster_scientist()
{
    if (Monster_RemoveIfSpent()) return;
    if (RemoveInDeathmatch()) return;

    Scientist_Precache();

    setmodel(self, Scientist_GetModel());
    setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.health      = SCI_HEALTH;
    self.yaw_speed   = YAW_HL(150);

    // Scripts must find the scientist before deferred StartGo runs.
    self.flags = self.flags | FL_MONSTER;

    self.monster_state      = MONSTERSTATE_IDLE;
    self.monster_idealState = MONSTERSTATE_IDLE;
    self.monster_bloodColor        = BLOOD_COLOR_RED;
    self.monster_fieldOfView     = SCI_FOV;
    Scientist_ApplyBody();

    self.m_followTarget  = world;
    self.m_saidHello     = FALSE;
    self.scientist_saidWoundLight = FALSE;
    self.scientist_saidWoundHeavy = FALSE;
    self.m_nextTalk      = time + 2 + random() * 4;
    self.scientist_healTime      = 0;
    self.scientist_fearTime      = 0;
    self.scientist_fleeUntil     = 0;
    self.scientist_nextFleeGoal  = 0;
    self.scientist_fleeGoal      = world;

    self.monster_capability = BITS_CAP_HEAR | BITS_CAP_TURN_HEAD
        | BITS_CAP_OPEN_DOORS | BITS_CAP_AUTO_DOORS | BITS_CAP_USE;

    self.th_stand = Scientist_Stand;
    self.th_walk  = Scientist_Walk;
    self.th_run   = Scientist_Flee;
    self.th_pain  = Scientist_Pain;
    self.th_die   = Scientist_Die;

    self.frameByName = Scientist_FrameByName;

    self.playScriptedSentence = Scientist_PlayScriptedSentence;

    Monster_InitTakeDamage();

    // Wait until the rest of the map has spawned.
    self.think     = Scientist_StartGo;
    self.nextthink = time + 0.1 + random() * 0.5;
    total_monsters = total_monsters + 1;

    Scientist_PlayAnim(SCI_ANIM_IDLE);
}
