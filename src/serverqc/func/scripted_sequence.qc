
#define SF_SCRIPT_WAITTILLSEEN      1   // hold the play until a player has seen the NPC
#define SF_SCRIPT_EXITAGITATED      2   // release the NPC in ALERT instead of IDLE
#define SF_SCRIPT_REPEATABLE        4
#define SF_SCRIPT_LEAVECORPSE       8
#define SF_SCRIPT_NOINTERRUPT       32
#define SF_SCRIPT_OVERRIDESTATE     64
#define SF_SCRIPT_NOSCRIPTMOVEMENT  128

// MoveTo modes (m_fMoveTo keyvalue).
#define SCRIPT_MOVETO_NONE          0
#define SCRIPT_MOVETO_WALK          1
#define SCRIPT_MOVETO_RUN           2
#define SCRIPT_MOVETO_TELEPORT      4

#define SCRIPT_FINISHSCHED_DEFAULT  0
#define SCRIPT_FINISHSCHED_AMBUSH   1

#define SCRIPTEDSEQ_INTERRUPT_IDLE           0
#define SCRIPTEDSEQ_INTERRUPT_BY_NAME        1
#define SCRIPTEDSEQ_INTERRUPT_AI             2

#define EF_NOINTERP EF_TELEPORT_BIT


// Per-script entity (CCineMonster).
.string m_iszIdle;          // optional pre-roll anim played at possess time
.string m_iszPlay;          // main anim, fired from play_think
.string m_iszEntity;        // NPC targetname OR classname
.float  m_fMoveTo;          // SCRIPT_MOVETO_*
.float  m_flRadius;         // classname-search radius (default 256)
.float  m_flRepeat;         // re-arm delay when SF_SCRIPT_REPEATABLE
.float  m_iFinishSchedule;  // SCRIPT_FINISHSCHED_*
.float  seq_delay;           // group-sync barrier (DelayStart)
.float  seq_interruptable;    // mirror of !SF_SCRIPT_NOINTERRUPT, for future use
.float  seq_startTime;        // gate; sequence proceeds only when time >= this
.entity monster_targetEnt;       // currently possessed NPC
.float  ss_isAI;            // TRUE for aiscripted_sequence (CCineAI parity)
.float  ss_warnedMissing;   // de-dupe the "can't find" dprint while retrying
.float  ss_seen;            // SF_SCRIPT_WAITTILLSEEN latch: player has seen the NPC
.float  ss_delayCounted;    // this script currently holds a +1 on the group barrier

// Saved NPC state, restored on done/cancel.
.float  ss_saved_movetype;
.float  ss_saved_solid;
.float  ss_saved_effects;
.vector ss_saved_origin;          // for SF_SCRIPT_NOSCRIPTMOVEMENT restore

// Move-to-mark progress tracking (ScriptedSeq_StepTowardMark).
.float  ss_lastMarkDist;          // best (smallest) distance to mark so far
.float  ss_markDone;	// move phase finished (arrived or gave up), latched
.float  ss_routeTriggerTime;
.float  ss_giveUpTime;            // when to release if truly unreachable

// Root-motion catch-up (ScriptedSeq_CatchUpToRoot).
.vector ss_rootStart;             // root-bone world pos at the first play frame
.float  ss_rootTracked;           // ss_rootStart holds a live sample

.float seq_leaveCorpse;

// Per-monster back-pointer `monster_cine` is declared in monster_base.qc.

.float(string name) frameByName;
// Monster-specific anim event hook. Fired for event
// codes < 1000 during scripted playback (barney gun draw=2 / holster=4, ...).
.void(float code, string opts) handleAnimEvent;

// Forward decls
void ScriptedSeq_Think();
void ScriptedSeq_PlayThink();
void ScriptedSeq_DoneThink();
void ScriptedSeq_CancelScript();

// True if `e` is either flavor of scripted sequence entity.
float ScriptedSeq_IsEnt(entity e)
{
    if (e.classname == "scripted_sequence")   return TRUE;
    if (e.classname == "aiscripted_sequence") return TRUE;
    return FALSE;
}

// Silent name -> framegroup resolve; -1 on miss. Split out so callers can probe
// alternate spellings without tripping the not-found dprint.
float Monster_FrameForName(entity mon, string seqName)
{
    if (!seqName) return -1;
    if (seqName == "") return -1;
    if (!mon.modelindex) return -1;

    if (IsFTE())
        return frameforname(mon.modelindex, seqName);

    float f = FG_FrameForName(mon.model, seqName);
    if (f >= 0) return f;

    if (mon.frameByName)
    {
        // Swap self so the dispatcher can be a method-style function.
        entity stemp = self;
        self = mon;
        f = mon.frameByName(seqName);
        self = stemp;
    }
    return f;
}

float Monster_PlayAnimByName(entity mon, string seqName)
{
    float f = Monster_FrameForName(mon, seqName);

    if (f < 0)
    {
        dprint("Monster_PlayAnimByName: '");
        dprint(seqName);
        dprint("' not found on ");
        dprint(mon.classname);
        dprint("\n");
        return 0;
    }

    float dur;
    if (IsFTE()) dur = frameduration(mon.modelindex, f);
    else         dur = FG_FrameDuration(mon.model, f);

    mon.frame      = f;
    mon.frame1time = time;    // restart the cycle from now
    mon.framerate  = 1;

    if (dur <= 0) dur = 0.5;
    return dur;
}

// Script locomotion is driven by activity (ACT_WALK / ACT_RUN). We resolve by
// name instead, and sequence names are not consistent between models
// barney/scientist/hassassin/bullsquid use "walk"/"run", hgrunt "walk1"/"run",
// islave "walk1"/"run1". Probe the numbered spelling before reporting a miss.
float ScriptedSeq_PlayMoveAnim(entity mon, string base)
{
    if (Monster_FrameForName(mon, base) >= 0)
        return Monster_PlayAnimByName(mon, base);

    return Monster_PlayAnimByName(mon, strcat(base, "1"));
}

#define SCRIPT_EVENT_DEAD           1000
#define SCRIPT_EVENT_NOINTERRUPT    1001
#define SCRIPT_EVENT_CANINTERRUPT   1002
#define SCRIPT_EVENT_FIREEVENT      1003
#define SCRIPT_EVENT_SOUND          1004
#define SCRIPT_EVENT_SENTENCE       1005
#define SCRIPT_EVENT_SOUND_VOICE    1008
#define SCRIPT_EVENT_SENTENCE_RND1  1009
#define SCRIPT_EVENT_NOT_DEAD       1010

.float ep_group;    // framegroup index being played
.float ep_prev;     // elapsed seconds already processed
.float ep_dur;      // total play duration

// streamed wavs are prefixed with '*'; it is not part of the file path.
string ScriptEvent_SoundPath(string opts)
{
    if (str2chr(opts, 0) == 42 /* '*' */)
        opts = substring(opts, 1, strlen(opts) - 1);
    return strtolower(opts);
}

void ScriptEvent_Apply(entity mon, float code, string opts)
{
    if (code == SCRIPT_EVENT_DEAD)
    {
        if (mon.monster_cine && mon.monster_cine != world)
        {
            mon.deadflag = DEAD_DYING;
            mon.health   = 0;
        }
    }
    else if (code == SCRIPT_EVENT_NOT_DEAD)
    {
        if (mon.monster_cine && mon.monster_cine != world)
        {
            mon.deadflag = DEAD_NO;
            mon.health   = mon.max_health;
        }
    }
    else if (code == SCRIPT_EVENT_SOUND)
        Sound_Play(mon, CHAN_BODY, 1.0, ATTN_IDLE, PITCH_NORM, ScriptEvent_SoundPath(opts));
    else if (code == SCRIPT_EVENT_SOUND_VOICE)
    {
        Sentences_Stop(mon, CHAN_VOICE);
        Sound_Play(mon, CHAN_VOICE, 1.0, ATTN_IDLE, PITCH_NORM, ScriptEvent_SoundPath(opts));
    }
    else if (code == SCRIPT_EVENT_SENTENCE)
        Sentences_Play(mon, CHAN_VOICE, opts, 1.0, ATTN_IDLE, 100);
    else if (code == SCRIPT_EVENT_SENTENCE_RND1)
    {
        if (random() > 0.33)
            Sentences_Play(mon, CHAN_VOICE, opts, 1.0, ATTN_IDLE, 100);
    }
    else if (code == SCRIPT_EVENT_FIREEVENT)
        SUB_FireTargets(opts, mon, mon, USE_TOGGLE, 0);
    else if (code > 0 && code < 1000 && mon.handleAnimEvent)
    {
        // Monster-specific anim event (barney draw=2 / holster=4, etc.)
        // e.g. toggling the gun bodygroup mid-cutscene. Run on the monster
        // with self swapped.
        entity s = self;
        self = mon;
        mon.handleAnimEvent(code, opts);
        self = s;
    }
    // NOINTERRUPT/CANINTERRUPT: interruption policy not enforced here.
}

void ScriptEventPlayer_Think()
{
    entity mon = self.owner;
    if (!mon || mon == world || wasfreed(mon))
    {
        remove(self);
        return;
    }

    float elapsed = self.ep_prev + 0.05;
    float first = FG_EventFirst(mon.model);
    float cnt   = FG_EventCount(mon.model);
    for (float i = first; i < first + cnt; i = i + 1)
    {
        if (fge_group[i] != self.ep_group) continue;
        if (fge_time[i] > self.ep_prev && fge_time[i] <= elapsed)
            ScriptEvent_Apply(mon, fge_code[i], fge_opts[i]);
    }
    self.ep_prev = elapsed;

    if (elapsed >= self.ep_dur)
    {
        remove(self);
        return;
    }
    self.think = ScriptEventPlayer_Think;
    self.nextthink = time + 0.05;
}

// Kill any event player already attached to this monster (sequence replaced).
void ScriptEvents_Stop(entity mon)
{
    entity e = find(world, classname, "script_event_player");
    while (e)
    {
        entity nxt = find(e, classname, "script_event_player");
        if (e.owner == mon) remove(e);
        e = nxt;
    }
}

// Start firing the events of framegroup `gidx` on `mon` over `dur` seconds.
void ScriptEvents_Start(entity mon, float gidx, float dur)
{
    ScriptEvents_Stop(mon);
    if (gidx < 0) return;
    if (FG_EventCount(mon.model) <= 0) return;

    entity e = spawn();
    e.classname = "script_event_player";
    e.owner     = mon;
    e.ep_group  = gidx;
    e.ep_prev   = -0.001;   // window test is strict '>': catch t=0.000 events
    e.ep_dur    = dur;
    e.think     = ScriptEventPlayer_Think;
    e.nextthink = time + 0.05;
}

// Predicates
float ScriptedSeq_IsMonster(entity e)
{
    if (!e || e == world) return FALSE;
    if (!(e.flags & FL_MONSTER)) return FALSE;
    if (e.health <= 0) return FALSE;
    return TRUE;
}

float ScriptedSeq_CanOverrideState()
{
    // CCineAI always overrides state regardless of spawnflag.
    if (self.ss_isAI) return TRUE;
    return (self.spawnflags & SF_SCRIPT_OVERRIDESTATE) != 0;
}

float ScriptedSeq_CanPlay(entity mon, float overrideState, float interruptType)
{
    if (!ScriptedSeq_IsMonster(mon)) return FALSE;

    // CBaseMonster::CanPlaySequence bails on monster_cine unconditionally, an
    // NPC already owned by another script is off limits, whatever state it is
    // in and whatever spawnflags the asking script carries. Letting a second
    // script steal a mid-walk NPC makes the two ping-pong: each steal re-runs
    // ScriptedSeq_PossessEntity, which restarts the walk anim and bumps seq_delay, so
    // neither ever clears its group barrier and the NPC walks in place forever.
    // (c0a0e: barnwalk2's long walk vs the player-tripped barnwalk3.)
    if (mon.monster_cine && mon.monster_cine != world && mon.monster_cine != self)
        return FALSE;

    return TRUE;
}

float ScriptedSeq_FindEntity()
{
    self.monster_targetEnt = world;
    if (self.m_iszEntity == "") return FALSE;

    entity e = find(world, targetname, self.m_iszEntity);
    while (e)
    {
        if (ScriptedSeq_IsMonster(e) && ScriptedSeq_CanPlay(e, ScriptedSeq_CanOverrideState(), SCRIPTEDSEQ_INTERRUPT_BY_NAME))
        {
            self.monster_targetEnt = e;
            return TRUE;
        }
        e = find(e, targetname, self.m_iszEntity);
    }

    if (self.m_flRadius > 0)
    {
        e = findradius(self.origin, self.m_flRadius);
        while (e)
        {
            if (e.classname == self.m_iszEntity
                && ScriptedSeq_IsMonster(e)
                && ScriptedSeq_CanPlay(e, ScriptedSeq_CanOverrideState(), SCRIPTEDSEQ_INTERRUPT_IDLE))
            {
                self.monster_targetEnt = e;
                return TRUE;
            }
            e = e.chain;
        }
    }

    return FALSE;
}

float ScriptedSeq_TargetSeenByPlayer(entity mon)
{
    if (!mon || mon == world) return FALSE;

    entity p = find(world, classname, "player");
    while (p)
    {
        if (p.health > 0)
        {
            makevectors(p.v_angle);
            if (normalize(mon.origin - p.origin) * v_forward > 0)
            {
                traceline(p.origin + p.view_ofs, mon.origin + '0 0 16', TRUE, p);
                if (trace_fraction == 1 || trace_ent == mon)
                    return TRUE;
            }
        }
        p = find(p, classname, "player");
    }
    return FALSE;
}

void ScriptedSeq_DelayStart(float state)
{
    if (self.targetname == "") return;

    entity e = find(world, targetname, self.targetname);
    while (e)
    {
        if (ScriptedSeq_IsEnt(e))
        {
            if (state)
            {
                e.seq_delay = e.seq_delay + 1;
            }
            else
            {
                e.seq_delay = e.seq_delay - 1;
                if (e.seq_delay <= 0)
                    e.seq_startTime = time + 0.05;
            }
        }
        e = find(e, targetname, self.targetname);
    }
}

void ScriptedSeq_PossessEntity()
{
    entity mon = self.monster_targetEnt;
    if (!mon || mon == world) return;

    self.ss_saved_movetype = mon.movetype;
    self.ss_saved_solid    = mon.solid;
    self.ss_saved_effects  = mon.effects;
    self.ss_saved_origin   = mon.origin;

    mon.monster_cine = self;
    mon.enemy   = world;
    mon.effects = mon.effects | self.effects;
    if (!mon.yaw_speed) mon.yaw_speed = 8;   // ChangeYaw is a no-op at 0: strafing NPC

    // Reset the move-to-mark progress tracker for this (fresh) move.
    self.ss_lastMarkDist = 0;
    self.ss_markDone     = FALSE;
    mon.monster_movementGoal = MOVEGOAL_NONE;

    if (self.m_fMoveTo == SCRIPT_MOVETO_WALK)
    {
        mon.monster_scriptState = SCRIPT_WALK_TO_MARK;
        if (!self.ss_delayCounted) { self.ss_delayCounted = TRUE; ScriptedSeq_DelayStart(1); }
        ScriptedSeq_PlayMoveAnim(mon, "walk");
    }
    else if (self.m_fMoveTo == SCRIPT_MOVETO_RUN)
    {
        mon.monster_scriptState = SCRIPT_RUN_TO_MARK;
        if (!self.ss_delayCounted) { self.ss_delayCounted = TRUE; ScriptedSeq_DelayStart(1); }
        ScriptedSeq_PlayMoveAnim(mon, "run");
    }
    else if (self.m_fMoveTo == SCRIPT_MOVETO_TELEPORT)
    {
        setorigin(mon, self.origin);
        mon.angles_y  = self.angles_y;
        mon.ideal_yaw = self.angles_y;
        mon.velocity  = '0 0 0';
        mon.avelocity = '0 0 0';
        mon.effects   = mon.effects | EF_NOINTERP;
        mon.monster_scriptState = SCRIPT_WAIT;
        // Set startTime high so play_think waits for an external Use event.
        self.seq_startTime = time + 1000000;
    }
    else
    {
        mon.monster_scriptState = SCRIPT_WAIT;
    }

    mon.monster_idealState = MONSTERSTATE_SCRIPT;

    if (self.m_iszIdle != "")
    {
        Monster_PlayAnimByName(mon, self.m_iszIdle);
        if (self.m_iszIdle == self.m_iszPlay)
            mon.framerate = 0;
    }
}

#define SCRIPTEDSEQ_TICK         0.1
#define SCRIPTEDSEQ_WALK_SPEED   80
#define SCRIPTEDSEQ_RUN_SPEED    200
#define SCRIPTEDSEQ_ARRIVE_DIST  8
#define SCRIPTEDSEQ_PLANT_DIST   64      // max snap distance on the give-up path
#define SCRIPTEDSEQ_ROUTE_DELAY  1.0     // sec of no progress before detouring via nodes
#define SCRIPTEDSEQ_GIVEUP_TIME  8.0     // sec of no net progress before releasing

vector g_placeDest;         // out-param for ScriptedSeq_FindFreeZ

// Free spot for mon's hull at dest's x/y, starting at dest's z and stepping up.
// A landing anim ends with the root inside the floor as often as above it.
float ScriptedSeq_FindFreeZ(entity mon, vector dest)
{
    for (float z = 0; z <= 64; z = z + 8)
    {
        vector p = [dest_x, dest_y, dest_z + z];
        tracebox(p + '0 0 1', mon.mins, mon.maxs, p, TRUE, mon);
        if (!trace_startsolid && !trace_allsolid)
        {
            g_placeDest = trace_endpos;     // p itself may sit up to 1u inside the floor
            return TRUE;
        }
    }
    return FALSE;
}

// Put `mon` at `dest`. Validates the DESTINATION, not the path to it: the
// mesh has already visibly travelled there, and a swept trace refuses exactly
// the moves worth making (the c1a1b houndeye jumps *through* a window, so the
// straight hull path is solid the whole way).
float ScriptedSeq_PlaceMonster(entity mon, vector dest)
{
    if (!ScriptedSeq_FindFreeZ(mon, dest))
    {
        vector alt = [dest_x, dest_y, mon.origin_z];    // anim z unusable
        if (!ScriptedSeq_FindFreeZ(mon, alt))
            return FALSE;
    }

    setorigin(mon, g_placeDest);
    mon.effects = mon.effects | EF_NOINTERP;
    return TRUE;
}

void ScriptedSeq_SettleOnFloor(entity mon)
{
    if (mon.movetype != MOVETYPE_STEP) return;
    entity s = self;
    self = mon;
    if (!droptofloor() && ScriptedSeq_PlaceMonster(mon, mon.origin))
        droptofloor();                  // started embedded: lift clear, then drop
    self = s;
}

// Called when planting on a script entity.
void ScriptedSeq_PlantOnMark(entity mon)
{
    vector mark = self.origin;                      // read-once (fteqcc arg-deref)
    if (ScriptedSeq_PlaceMonster(mon, mark))
        ScriptedSeq_SettleOnFloor(mon);
}

// Root-bone world position for the pose the monster is showing right now.
// Tag index 1 == joint 0, which is the parentless root ("Bip01") on every
// mdl2iqm-converted model. Models with no skeleton return a constant, so the
// start/end samples cancel and the catch-up is a no-op.
#define SCRIPT_ROOT_TAG 1

// mdl2iqm only strips baked root motion from locomotion sequences, so a
// scripted anim travels the MESH while the entity stands still. Move the
// entity by the distance the root covered, so collision lines back up with
// what the player sees.
void ScriptedSeq_CatchUpToRoot(entity mon)
{
    if (!self.ss_rootTracked) return;
    self.ss_rootTracked = FALSE;

    vector delta = gettaginfo(mon, SCRIPT_ROOT_TAG) - self.ss_rootStart;
    float d = vlen(delta);
    if (d < 1) return;                  // in-place anim: nothing to catch up to
    if (d > 512)
    {
        dprint(strcat("ScriptedSeq_CatchUpToRoot: ", strcat(self.targetname,
               strcat(" root delta ", strcat(vtos(delta), " rejected\n")))));
        return;
    }

    if (!ScriptedSeq_PlaceMonster(mon, mon.origin + delta))
        dprint(strcat("ScriptedSeq_CatchUpToRoot: ", strcat(self.targetname,
               strcat(" no free spot for root delta ", strcat(vtos(delta), "\n")))));
}

// Deterministic escape fan around `yaw`, widening outward. Never a turnaround,
// so we can never give back ground already covered.
float ScriptedSeq_ProbeStep(float yaw, float step, float sgn)
{
    if (walkmove(yaw + 30 * sgn, step)) return TRUE;
    if (walkmove(yaw - 30 * sgn, step)) return TRUE;
    if (walkmove(yaw + 60 * sgn, step)) return TRUE;
    if (walkmove(yaw - 60 * sgn, step)) return TRUE;
    if (walkmove(yaw + 90 * sgn, step)) return TRUE;   // pure sidestep: peels off a hugged wall
    if (walkmove(yaw - 90 * sgn, step)) return TRUE;
    return FALSE;
}

float ScriptedSeq_StepTowardMark()
{
    entity mon = self.monster_targetEnt;
    if (!mon || mon == world || wasfreed(mon)) return FALSE;
    if (self.m_fMoveTo != SCRIPT_MOVETO_WALK && self.m_fMoveTo != SCRIPT_MOVETO_RUN)
        return FALSE;

    // Move phase is over: never step (or steer) again. Without this latch the
    // walk code keeps running every tick after we give up on the mark, and its
    // ChangeYaw() toward the mark cancels the play-phase ChangeYaw() toward the
    // script's own angles; two 30 deg/tick pulls in opposite directions leave
    // the NPC frozen mid-turn, so the `d > 8` align gate never clears and the
    // sequence never starts.
    if (self.ss_markDone) return FALSE;

    vector mark = self.origin;
    vector flat = mark - mon.origin;
    flat_z = 0;
    float dist = vlen(flat);

    if (dist <= SCRIPTEDSEQ_ARRIVE_DIST)
    {
        ScriptedSeq_PlantOnMark(mon);
        self.ss_markDone = TRUE;
        mon.velocity_x = 0;
        mon.velocity_y = 0;
        mon.monster_movementGoal = MOVEGOAL_NONE;     // clear any node route
        mon.goalentity = world;                 // drop the mark goal
        return FALSE;
    }

    float spd = (self.m_fMoveTo == SCRIPT_MOVETO_RUN) ? SCRIPTEDSEQ_RUN_SPEED : SCRIPTEDSEQ_WALK_SPEED;
    float step = spd * SCRIPTEDSEQ_TICK;
    if (step > dist) step = dist;

    entity stemp = self;
    self = mon;
    if (mon.monster_movementGoal == MOVEGOAL_NODE)
    {
        self.goalentity = world;
        Monster_AdvanceRoute(step);
    }
    else if (Monster_ProactiveRoute(mark))
    {
        self.goalentity = world;
        Monster_AdvanceRoute(step);
    }
    else
    {
        // Turn and step by hand. movetogoal() is the engine's enemy-chase bump
        // AI: it quantizes headings to 8 compass dirs, re-picks a direction
        // (turnaround included) on ~1 tick in 4, and SV_StepDirection restores
        // the pre-step origin whenever the yaw error is still > 45 deg. On a
        // scripted walk that reads as the NPC being snapped back onto its node
        // while it fights to rotate.
        self.goalentity = world;

        float markYaw = vectoyaw(flat);
        self.ideal_yaw = markYaw;
        ChangeYaw();                        // yaw_speed deg/tick, independent of the step

        float yawErr = Math_AngleMod(markYaw - self.angles_y);
        if (yawErr > 180) yawErr = 360 - yawErr;

        if (yawErr <= 90 && !walkmove(markYaw, step))
        {
            float sgn = self.lefty ? -1 : 1;
            if (!ScriptedSeq_ProbeStep(markYaw, step, sgn))
            {
                self.lefty = 1 - self.lefty;
                stemp.ss_routeTriggerTime = 0;   // boxed in: detour via nodes now
            }
        }
        // yawErr > 90: spend the tick turning only, so we never walk backwards.
    }
    self = stemp;

    if (self.ss_lastMarkDist <= 0 || dist < self.ss_lastMarkDist - 4)
    {
        self.ss_lastMarkDist     = dist;                 // new best
        self.ss_routeTriggerTime = time + SCRIPTEDSEQ_ROUTE_DELAY;
        self.ss_giveUpTime       = time + SCRIPTEDSEQ_GIVEUP_TIME;
        return TRUE;
    }

    if (time > self.ss_giveUpTime)
    {
        dprint("scripted_sequence: ");
        dprint(self.targetname);
        dprint(" mark unreachable, playing from here\n");
        if (dist <= SCRIPTEDSEQ_PLANT_DIST)
            ScriptedSeq_PlantOnMark(mon);                // walkmove-stuck, not walled off
        self.ss_markDone   = TRUE;                       // latch: stop walking/steering
        mon.monster_movementGoal = MOVEGOAL_NONE;
        mon.goalentity     = world;
        mon.velocity_x     = 0;
        mon.velocity_y     = 0;
        return FALSE;                                    // fall through to the play phase
    }

    if (mon.monster_movementGoal != MOVEGOAL_NODE && time > self.ss_routeTriggerTime)
    {
        entity s2 = self;
        self = mon;
        Monster_RouteTo(mark);
        self = s2;
        self.ss_routeTriggerTime = time + SCRIPTEDSEQ_ROUTE_DELAY * 2;  // give the route time
    }
    return TRUE;
}

void ScriptedSeq_ReleaseMonster()
{
    // Cancelled before reaching the mark: hand back our group-barrier count,
    // otherwise the other members of the group wait on us forever.
    if (self.ss_delayCounted)
    {
        self.ss_delayCounted = FALSE;
        ScriptedSeq_DelayStart(0);
    }

    entity mon = self.monster_targetEnt;
    if (mon && mon != world && !wasfreed(mon) && mon.monster_cine == self)
    {
        mon.movetype = self.ss_saved_movetype;
        mon.solid    = self.ss_saved_solid;
        mon.effects  = self.ss_saved_effects;
        mon.framerate = 1;
        mon.monster_cine  = world;
        mon.monster_scriptState = SCRIPT_CLEANUP;
        mon.monster_isAsleep = FALSE;
        mon.spawnflags = mon.spawnflags & ~SF_MONSTER_WAIT_FOR_SCRIPT;
        ScriptEvents_Stop(mon);

        if (mon.deadflag == DEAD_DYING)
        {
            mon.health     = 0;
            mon.framerate  = 0;         // freeze pose ("Monster_StopAnimation")
            mon.solid      = SOLID_NOT;
            mon.movetype   = MOVETYPE_NONE;
            mon.takedamage = DAMAGE_NO;
            mon.deadflag   = DEAD_DEAD;
            mon.monster_state      = MONSTERSTATE_DEAD;
            mon.monster_idealState = MONSTERSTATE_DEAD;
            setsize(mon, mon.mins, [mon.maxs_x, mon.maxs_y, mon.mins_z + 2]);
            mon.effects = mon.effects | EF_NOINTERP;

            mon.use   = SUB_Null;
            mon.usehl = __NULL__;
            mon.touch = SUB_Null;
            if (self.spawnflags & SF_SCRIPT_LEAVECORPSE)
            {
                mon.think = SUB_Null;
                mon.nextthink = -1;
            }
            else
            {
                mon.think = SUB_Remove;
                mon.nextthink = time + 10;
            }

            dprint("ScriptedSeq_ReleaseMonster: ");
            dprint(mon.classname);
            dprint(" died in script ");
            dprint(self.targetname);
            dprint(" (SCRIPT_EVENT_DEAD)\n");

            self.monster_targetEnt = world;
            return;
        }

        if (self.spawnflags & SF_SCRIPT_NOSCRIPTMOVEMENT)
        {
            setorigin(mon, self.ss_saved_origin);
            mon.effects = mon.effects | EF_NOINTERP;
        }
        else if (mon.health > 0 && mon.movetype == MOVETYPE_STEP)
        {
            ScriptedSeq_CatchUpToRoot(mon);
            ScriptedSeq_SettleOnFloor(mon);
        }

        if (self.spawnflags & SF_SCRIPT_LEAVECORPSE)
            mon.seq_leaveCorpse = TRUE;

        if (mon.health > 0)
        {
            // EXITAGITATED: come out of the script wary instead of relaxed.
            if (self.spawnflags & SF_SCRIPT_EXITAGITATED)
            {
                mon.monster_idealState = MONSTERSTATE_ALERT;
                mon.monster_state = MONSTERSTATE_ALERT;
            }
            else
                mon.monster_idealState = MONSTERSTATE_IDLE;
        }
        else
            mon.monster_idealState = MONSTERSTATE_DEAD;

        dprint("ScriptedSeq_ReleaseMonster: ");
        dprint(mon.classname);
        dprint(" released by ");
        dprint(self.targetname);
        dprint("\n");

        // MonsterThink never stops, so AI owns the pose in the same frame
        // CineCleanup runs. Ours yields by rescheduling (0.2s in th_*, 0.5s in
        // the deferred *_StartGo), and even a next-frame think leaves one frame
        // where the finished framegroup wraps to its first pose. Run the think
        // here instead of scheduling it.
        if (mon.health > 0 && mon.deadflag == DEAD_NO && mon.think)
        {
            float playFrame = mon.frame;
            mon.nextthink = time + 0.05;        // fallback if the think reschedules oddly
            entity mtemp = self;
            self = mon;
            mon.think();
            self = mtemp;

            // Think declined to pose us (scientist holds its anim while a sentence plays). Hold the last scripted frame rather than let the finished group wrap; any later *_PlayAnim restores framerate.
            if (mon.frame == playFrame)
                mon.framerate = 0;
        }
    }
    self.monster_targetEnt = world;
}

float Monster_ExitScriptedSequence()
{
    if (self.deadflag == DEAD_DYING)
    {
        self.monster_idealState = MONSTERSTATE_DEAD;
        return FALSE;
    }
    if (self.monster_cine && self.monster_cine != world)
    {
        entity c = self.monster_cine;
        entity stemp = self;
        self = c;
        ScriptedSeq_CancelScript();
        self = stemp;
    }
    return TRUE;
}

void ScriptedSeq_CancelScript()
{
    if (self.targetname == "")
    {
        ScriptedSeq_ReleaseMonster();
        return;
    }

    entity me = self;
    entity e = find(world, targetname, me.targetname);
    while (e)
    {
        if (ScriptedSeq_IsEnt(e))
        {
            self = e;
            ScriptedSeq_ReleaseMonster();
        }
        e = find(e, targetname, me.targetname);
    }
    self = me;
}

// SequenceDone: fire targets, release monster, repeat or remove.
void ScriptedSeq_Done()
{
    ScriptedSeq_ReleaseMonster();

    SUB_UseTargetsHL(world, USE_TOGGLE, 0);    // unconditional: a script may carry only a killtarget

    if (self.spawnflags & SF_SCRIPT_REPEATABLE)
    {
        self.ss_seen = FALSE;               // WAITTILLSEEN re-arms with the script
        self.think = ScriptedSeq_Think;
        self.nextthink = time + ((self.m_flRepeat > 0) ? self.m_flRepeat : 0.1);
        // Wait to be Used again unless we auto-start (no targetname or has idle).
        if (self.targetname != "" && self.m_iszIdle == "")
            self.seq_startTime = time + 1000000;
        else
            self.seq_startTime = time;
        dprint("scripted_sequence: ");
        dprint(self.targetname);
        dprint(" re-armed (REPEATABLE)\n");
        return;
    }

    self.think = SUB_Remove;
    self.nextthink = time + 0.1;
}

// Think loop
void ScriptedSeq_Think()
{
    if (self.monster_targetEnt && self.monster_targetEnt != world && wasfreed(self.monster_targetEnt))
    {
        if (!self.ss_warnedMissing)
        {
            self.ss_warnedMissing = TRUE;
            dprint("scripted_sequence: ");
            dprint(self.targetname);
            dprint(" lost possessed NPC ");
            dprint(self.m_iszEntity);
            dprint(" (removed mid-sequence), aborting move\n");
        }
        self.monster_targetEnt = world;
    }

    if (!self.monster_targetEnt || self.monster_targetEnt == world || self.monster_targetEnt.monster_cine != self)
    {
        if (!ScriptedSeq_FindEntity())
        {
            if (!self.ss_warnedMissing)
            {
                self.ss_warnedMissing = TRUE;
                dprint("scripted_sequence: can't find ");
                dprint(self.m_iszEntity);
                dprint("\n");
            }
            self.nextthink = time + 1.0;
            return;
        }
        self.ss_warnedMissing = FALSE;	// found it; re-arm the warning
        ScriptedSeq_PossessEntity();
    }

    if (self.seq_startTime > time)
    {
        self.nextthink = time + 0.2;
        return;
    }

    if ((self.spawnflags & SF_SCRIPT_WAITTILLSEEN) && !self.ss_seen)
    {
        if (!ScriptedSeq_TargetSeenByPlayer(self.monster_targetEnt))
        {
            self.nextthink = time + 0.2;
            return;
        }
        self.ss_seen = TRUE;
    }

    if (ScriptedSeq_StepTowardMark())
    {
        self.nextthink = time + 0.1;
        return;
    }

    // Release our +1 exactly once, mirroring the possess-time increment.
    if (self.ss_delayCounted)
    {
        self.ss_delayCounted = FALSE;
        ScriptedSeq_DelayStart(0);
    }

    if (self.seq_delay > 0)
    {
        // Still waiting on other group members.
        self.nextthink = time + 0.1;
        return;
    }

    if (self.m_fMoveTo == SCRIPT_MOVETO_WALK || self.m_fMoveTo == SCRIPT_MOVETO_RUN)
    {
        entity mon = self.monster_targetEnt;
        if (mon && mon != world && !wasfreed(mon) && mon.monster_cine == self)
        {
            if (!mon.yaw_speed) mon.yaw_speed = 8;
            mon.ideal_yaw = self.angles_y;
            entity s = self;
            self = mon;
            ChangeYaw();
            self = s;
            float d = Math_AngleMod(mon.angles_y - self.angles_y);
            if (d > 180) d = 360 - d;        // absolute angular distance
            if (d > 8)
            {
                self.nextthink = time + 0.05;
                return;
            }
            mon.angles_y = self.angles_y;    // snap the last few degrees
        }
    }

    self.think = ScriptedSeq_PlayThink;
    self.nextthink = time + 0.05;
}

void ScriptedSeq_PlayThink()
{
    entity mon = self.monster_targetEnt;
    if (!mon || mon == world || wasfreed(mon) || mon.monster_cine != self)
    {
        // Lost the monster; restart find loop.
        self.think = ScriptedSeq_Think;
        self.nextthink = time + 1.0;
        return;
    }

    mon.monster_scriptState = SCRIPT_PLAYING;

    float dur = 0;
    if (self.m_iszPlay != "")
        dur = Monster_PlayAnimByName(mon, self.m_iszPlay);
    if (dur <= 0) dur = 0.2;

    if (self.m_iszPlay != "")
        ScriptEvents_Start(mon, FG_FrameForName(mon.model, self.m_iszPlay), dur);

    // frame1time is `time`, so this samples the pose at frame 0 of the play.
    // No play anim: the root only moves between idle poses, which is not travel.
    self.ss_rootStart   = gettaginfo(mon, SCRIPT_ROOT_TAG);
    self.ss_rootTracked = (self.m_iszPlay != "");

    self.think = ScriptedSeq_DoneThink;
    self.nextthink = time + dur;
}

void ScriptedSeq_DoneThink()
{
    ScriptedSeq_Done();
}

// Use callbacks. The handler is canonical; legacy fallback delegates.
void ScriptedSeq_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    // If we already own a target and it's actively playing; ignores.
    if (self.monster_targetEnt && self.monster_targetEnt != world)
    {
        if (self.monster_targetEnt.monster_scriptState == SCRIPT_PLAYING)
            return;
        // Already possessed and waiting (e.g. teleport mode parked); nudge.
        self.seq_startTime = time + 0.05;
        if (self.nextthink > time + 0.5)
            self.nextthink = time + 0.1;
        return;
    }

    // Not possessed; start the find loop now.
    self.seq_startTime = time;
    self.think = ScriptedSeq_Think;
    self.nextthink = time;
}

void ScriptedSeq_UseLegacy()
{
    ScriptedSeq_UseHL(activator, world, USE_TOGGLE, 0);
}

void scripted_sequence()
{
    self.solid    = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;

    if (self.m_flRadius <= 0) self.m_flRadius = 256;
    self.seq_interruptable = ((self.spawnflags & SF_SCRIPT_NOINTERRUPT) == 0);

    string key, val;
    float n = tokenize(__fullspawndata);
    for (float i = 1; i < n - 1; i = i + 2)
    {
        key = argv(i);
        val = argv(i+1);

        if (key == "m_iszIdle" || key == "idle")
            self.m_iszIdle = strzone(val);
        else if (key == "m_iszPlay" || key == "play")
            self.m_iszPlay = strzone(val);
        else if (key == "m_iszEntity")
            self.m_iszEntity = strzone(val);
        else if (key == "m_fMoveTo" || key == "moveto")
            self.m_fMoveTo = stof(val);
        else if (key == "m_flRadius" || key == "radius" || key == "range")
            self.m_flRadius = stof(val);
        else if (key == "m_flRepeat")
            self.m_flRepeat = stof(val);
        else if (key == "m_iFinishSchedule")
            self.m_iFinishSchedule = stof(val);
    }

    self.use   = ScriptedSeq_UseLegacy;
    self.usehl = ScriptedSeq_UseHL;

    // Spawn(): autostart if no targetname OR if an idle anim was set.
    if (self.targetname == "" || self.m_iszIdle != "")
    {
        self.think = ScriptedSeq_Think;
        float startDelay = 1.0;
        if (self.m_fMoveTo == SCRIPT_MOVETO_TELEPORT && self.m_iszIdle != "")
            startDelay = 0.1;
        self.nextthink = time + startDelay;
        if (self.targetname != "")
            self.seq_startTime = time + 1000000;
        else
            self.seq_startTime = time;               // immediate
    }
    else
    {
        // Has targetname, no idle; wait for Use to wake us up.
        self.seq_startTime = time + 1000000;
    }
}

void aiscripted_sequence()
{
    scripted_sequence();    // shared spawn body
    self.ss_isAI = TRUE;
}
