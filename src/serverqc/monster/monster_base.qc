
// shared monster constants, fields, and macros

float Monster_TakeDamage(entity inflictor, entity attacker, float damage, float dmgType);
void  AddMultiDamage(entity hit, float damage, float dmgType);
float Monster_PlayAnimByName(entity mon, string seqName);

#define YAW_HL(x) ((x) * 0.2)

#define SCRIPT_PLAYING          0
#define SCRIPT_WAIT             1
#define SCRIPT_CLEANUP          2
#define SCRIPT_WALK_TO_MARK     3
#define SCRIPT_RUN_TO_MARK      4

// Back-pointer to the possessing script. Declared here, ahead of ai.qc, so the
// shared AI can gate on it; scripted_sequence.qc owns the writes.
.entity monster_cine;

// Snapshot of the think th_die installed, taken by Combat_Killed. Lets
// Monster_YieldIfDead hand control back to a death-animation chain instead of
// cancelling it.
.void() monster_deathThink;
.float  monster_deathThinkTime;

// Death yield. Call FIRST in any th_* that re-arms its own think.
float Monster_YieldIfDead()
{
    if (self.health > 0 && self.deadflag == DEAD_NO) return FALSE;

    // Hand the schedule back to whatever th_die installed. Q1 monsters run their
    // death animation from a QC think chain (Army_DieThink) that also performs the
    // Monster_BecomeCorpse resize partway through - cancelling it outright would
    // leave a SOLID_SLIDEBOX blocker frozen on its first death frame.
    // park to SUB_Null/-1 there, so the same restore is correct for them too.
    if (self.monster_deathThink)
    {
        self.think     = self.monster_deathThink;
        self.nextthink = self.monster_deathThinkTime;
    }
    else
    {
        self.think     = SUB_Null;
        self.nextthink = -1;
    }
    return TRUE;
}

// Standard think-state yield. Call first in any th_* that writes self.frame:
// the FindTarget gate stops target acquisition, but a direct frame write lands
// before the AI_* call and stomps the scripted pose regardless.
float Monster_YieldToCine(void() resume)
{
    if (!self.monster_cine || self.monster_cine == world) return FALSE;
    self.think = resume;
    self.nextthink = time + 0.2;
    return TRUE;
}

#define MONSTERSTATE_NONE       0
#define MONSTERSTATE_IDLE       1
#define MONSTERSTATE_ALERT      2
#define MONSTERSTATE_COMBAT     3
#define MONSTERSTATE_SCRIPT     4
#define MONSTERSTATE_PLAYDEAD   5
#define MONSTERSTATE_DEAD       6

// Barnacle victim anim phases
#define BARNACLE_VICTIM_NONE    -1  // not (yet) barnacled this grab
#define BARNACLE_VICTIM_HIT      0	// just grabbed, one-shot
#define BARNACLE_VICTIM_PULL     1	// being reeled up, loop
#define BARNACLE_VICTIM_CHOMP    2	// positioned at mouth, one-shot
#define BARNACLE_VICTIM_CHEW     3	// held in mouth, loop

#define TASKSTATUS_NEW          0
#define TASKSTATUS_RUNNING      1
#define TASKSTATUS_COMPLETE     2
#define TASKSTATUS_FAILED       3

#define SCHED_NONE              0
#define SCHED_IDLE_STAND        1
#define SCHED_IDLE_WALK         2
#define SCHED_ALERT_STAND       3
#define SCHED_ALERT_WALK        4
#define SCHED_CHASE_ENEMY       5
#define SCHED_RANGE_ATTACK1     6
#define SCHED_RANGE_ATTACK2     7
#define SCHED_MELEE_ATTACK1     8
#define SCHED_MELEE_ATTACK2     9
#define SCHED_TAKE_COVER        10
#define SCHED_SMALL_FLINCH      11
#define SCHED_DIE               12
#define SCHED_PATROL            13

#define BITS_COND_TASK_FAILED       (1<<0)
#define BITS_COND_SCHEDULE_DONE     (1<<1)
#define BITS_COND_LIGHT_DAMAGE      (1<<3)
#define BITS_COND_HEAVY_DAMAGE      (1<<4)
#define BITS_COND_CAN_RANGE_ATTACK1 (1<<5)
#define BITS_COND_CAN_MELEE_ATTACK1 (1<<6)
#define BITS_COND_CAN_RANGE_ATTACK2 (1<<7)
#define BITS_COND_CAN_MELEE_ATTACK2 (1<<8)
#define BITS_COND_ENEMY_OCCLUDED    (1<<9)
#define BITS_COND_SMELL_FOOD        (1<<10)
#define BITS_COND_ENEMY_TOOFAR      (1<<11)
#define BITS_COND_NEW_ENEMY         (1<<12)
#define BITS_COND_SEE_ENEMY         (1<<13)
#define BITS_COND_SEE_FEAR          (1<<14)
#define BITS_COND_SEE_HATE          (1<<15)
#define BITS_COND_SEE_DISLIKE       (1<<16)
#define BITS_COND_HEAR_SOUND        (1<<17)
#define BITS_COND_ENEMY_FACING_ME   (1<<18)
#define BITS_COND_ENEMY_DEAD        (1<<19)
#define BITS_COND_NO_AMMO_LOADED    (1<<20)
#define BITS_COND_BLOCKED_BY_DOOR   (1<<21)

#define BITS_CAP_DUCK           (1<<0)
#define BITS_CAP_JUMP           (1<<1)
#define BITS_CAP_DOORS_GROUP    (1<<2)
#define BITS_CAP_TURN_HEAD      (1<<3)
#define BITS_CAP_RANGE_ATTACK1  (1<<4)
#define BITS_CAP_RANGE_ATTACK2  (1<<5)
#define BITS_CAP_MELEE_ATTACK1  (1<<6)
#define BITS_CAP_MELEE_ATTACK2  (1<<7)
#define BITS_CAP_FLY            (1<<8)
#define BITS_CAP_SWIM           (1<<9)
#define BITS_CAP_CLIMB          (1<<10)
#define BITS_CAP_USE            (1<<11)
#define BITS_CAP_HEAR           (1<<12)
#define BITS_CAP_AUTO_DOORS     (1<<13)
#define BITS_CAP_OPEN_DOORS     (1<<14)

#define BITS_MEMORY_PROVOKED    (1<<0)
#define BITS_MEMORY_INCOVER     (1<<1)
#define BITS_MEMORY_SUSPICIOUS  (1<<2)
#define BITS_MEMORY_KILLED      (1<<3)
#define BITS_MEMORY_CUSTOM1     (1<<4)
#define BITS_MEMORY_CUSTOM2     (1<<5)
#define BITS_MEMORY_CUSTOM3     (1<<6)
#define BITS_MEMORY_CUSTOM4     (1<<7)

#define MOVEGOAL_NONE           0
#define MOVEGOAL_TARGETENT      1
#define MOVEGOAL_ENEMY          2
#define MOVEGOAL_PATHCORNER     3
#define MOVEGOAL_LOCATION       4
#define MOVEGOAL_NODE           5

#define BLOOD_COLOR_RED         GIB_BLOOD_RED
#define BLOOD_COLOR_YELLOW      GIB_BLOOD_ALIEN
#define BLOOD_COLOR_GREEN       GIB_BLOOD_ALIEN
#define DONT_BLEED              -1

#define GIB_NORMAL              0
#define GIB_NEVER               1
#define GIB_ALWAYS              2


#define R_AL    -2  // Ally
#define R_FR    -1  // Fear
#define R_NO     0  // None / Neutral
#define R_DL     1  // Dislike
#define R_HT     2  // Hate
#define R_NM     3  // Nemesis

#define ACT_RESET               0
#define ACT_IDLE                1
#define ACT_GUARD               2
#define ACT_WALK                3
#define ACT_RUN                 4
#define ACT_FLY                 5
#define ACT_SWIM                6
#define ACT_HOP                 7
#define ACT_LEAP                8
#define ACT_FALL                9
#define ACT_LAND                10
#define ACT_STRAFE_LEFT         11
#define ACT_STRAFE_RIGHT        12
#define ACT_ROLL_LEFT           13
#define ACT_ROLL_RIGHT          14
#define ACT_TURN_LEFT           15
#define ACT_TURN_RIGHT          16
#define ACT_CROUCH              17
#define ACT_CROUCHIDLE          18
#define ACT_STAND               19
#define ACT_USE                 20
#define ACT_SIGNAL1             21
#define ACT_SIGNAL2             22
#define ACT_SIGNAL3             23
#define ACT_TWITCH              24
#define ACT_COWER               25
#define ACT_SMALL_FLINCH        26
#define ACT_BIG_FLINCH          27
#define ACT_RANGE_ATTACK1       28
#define ACT_RANGE_ATTACK2       29
#define ACT_MELEE_ATTACK1       30
#define ACT_MELEE_ATTACK2       31
#define ACT_RELOAD              32
#define ACT_ARM                 33
#define ACT_DISARM              34
#define ACT_EAT                 35
#define ACT_DIESIMPLE           36
#define ACT_DIEBACKWARD         37
#define ACT_DIEFORWARD          38
#define ACT_DIEVIOLENT          39
#define ACT_BARNACLE_HIT        40
#define ACT_BARNACLE_PULL       41
#define ACT_BARNACLE_CHOMP      42
#define ACT_BARNACLE_CHEW       43
#define ACT_SLEEP               44
#define ACT_INSPECT_FLOOR       45
#define ACT_INSPECT_WALL        46
#define ACT_IDLE_ANGRY          47
#define ACT_WALK_HURT           48
#define ACT_RUN_HURT            49
#define ACT_HOVER               50
#define ACT_GLIDE               51
#define ACT_FLY_LEFT            52
#define ACT_FLY_RIGHT           53
#define ACT_DETECT_SCENT        54
#define ACT_SNIFF               55
#define ACT_BITE                56
#define ACT_THREAT_DISPLAY      57
#define ACT_FEAR_DISPLAY        58
#define ACT_EXCITED             59
#define ACT_SPECIAL_ATTACK1     60
#define ACT_SPECIAL_ATTACK2     61
#define ACT_COMBAT_IDLE         62
#define ACT_WALK_SCARED         63
#define ACT_RUN_SCARED          64
#define ACT_VICTORY_DANCE       65
#define ACT_DIE_HEADSHOT        66
#define ACT_DIE_CHESTSHOT       67
#define ACT_DIE_GUT             68
#define ACT_DIE_BACKSHOT        69
#define ACT_FLINCH_HEAD         70
#define ACT_FLINCH_CHEST        71
#define ACT_FLINCH_STOMACH      72
#define ACT_FLINCH_LEFTARM      73
#define ACT_FLINCH_RIGHTARM     74
#define ACT_FLINCH_LEFTLEG      75
#define ACT_FLINCH_RIGHTLEG     76

#define HITGROUP_GENERIC        0
#define HITGROUP_HEAD           1
#define HITGROUP_CHEST          2
#define HITGROUP_STOMACH        3
#define HITGROUP_LEFTARM        4
#define HITGROUP_RIGHTARM       5
#define HITGROUP_LEFTLEG        6
#define HITGROUP_RIGHTLEG       7

#define SF_MONSTER_WAIT_TILL_SEEN       1
#define SF_MONSTER_GAG                  2
#define SF_MONSTER_HITMONSTERCLIP       4
#define SF_MONSTER_PRISONER             16
#define SF_MONSTER_WAIT_FOR_SCRIPT      128
#define SF_MONSTER_PREDISASTER          256
#define SF_MONSTER_FADECORPSE           512
#define SF_MONSTER_FALL_TO_GROUND       0x80000000

#define DEAD_NO                 0
#define DEAD_DYING              1
#define DEAD_DEAD               2
#define DEAD_RESPAWNABLE        3
#define DEAD_DISCARDBODY        4

// AI state
.float monster_state;
.float monster_idealState;
.float m_Activity;
.float m_IdealActivity;
.float monster_taskStatus;
.float m_iScheduleIndex;
.float m_iScheduleType;
.float m_failSchedule;

// Combat
.float monster_conditions;
.float monster_memory;
.float monster_capability;
.float m_bitsDamageType;
.float m_lastDamageAmount;
// m_flNextAttack is declared in gamedefs.qc, which compiles first.
.float m_flNextFlinch;
.float m_LastHitGroup;
.float m_cAmmoLoaded;
.float m_iMaxHealth;

// Perception
.float monster_fieldOfView;
.float m_flDistTooFar;
.float monster_distLook;

// Navigation
.vector m_vecMoveGoal;
.vector m_vecLastPosition;
.vector m_vecEnemyLKP;
.float  monster_movementGoal;
.float  m_movementActivity;
.float  m_iHintNode;
.float  m_flWaitFinished;
.float  m_flMoveWaitFinished;

// Misc
.float m_flHungryTime;
.float monster_scriptState;

.entity monster_barnacleEnt;         // barnacle holding us, world if none
.float  monster_barnacleLifting;   // mirrors the barnacle's own barnacle_lifting
.float  monster_barnaclePhase;	// phase last (or currently) played
.float  monster_barnacleAnimEnd;   // time the current one-shot phase (HIT/CHOMP) finishes

// Trigger target for scripted AI
.string TriggerTarget;
.float  TriggerCondition;

// AI trigger conditions
#define AITRIGGER_NONE                      0
#define AITRIGGER_SEEPLAYER_ANGRY_AT_PLAYER 1
#define AITRIGGER_TAKEDAMAGE                2
#define AITRIGGER_HALFHEALTH                3
#define AITRIGGER_DEATH                     4
#define AITRIGGER_SQUADMEMBERDIE            5
#define AITRIGGER_SQUADLEADERDIE            6
#define AITRIGGER_HEARWORLD                 7
#define AITRIGGER_HEARPLAYER                8
#define AITRIGGER_HEARCOMBAT                9
#define AITRIGGER_SEEPLAYER_UNCONDITIONAL   10
#define AITRIGGER_SEEPLAYER_NOT_IN_COMBAT   11

.float monster_isAsleep;

.float monster_numMonsters;
.float monster_liveChildren;
.float m_imaxlivechildren;
.float monstercount;

// Inline helper macros

#define Monster_Remember(mem)       (self.monster_memory |= (mem))
#define Monster_Forget(mem)         (self.monster_memory &= ~(mem))
#define Monster_HasMemory(mem)      (self.monster_memory & (mem))

#define Monster_SetConditions(c)    (self.monster_conditions |= (c))
#define Monster_ClearConditions(c)  (self.monster_conditions &= ~(c))
#define Monster_HasConditions(c)    (self.monster_conditions & (c))
#define Monster_HasAllConditions(c) ((self.monster_conditions & (c)) == (c))

#define Monster_TaskComplete()      (self.monster_taskStatus = TASKSTATUS_COMPLETE)
#define Monster_TaskFail()          Monster_SetConditions(BITS_COND_TASK_FAILED)
#define Monster_TaskBegin()         (self.monster_taskStatus = TASKSTATUS_RUNNING)
#define Monster_TaskIsRunning()     (self.monster_taskStatus == TASKSTATUS_RUNNING)
#define Monster_TaskIsComplete()    (self.monster_taskStatus == TASKSTATUS_COMPLETE)
#define Monster_IsMoving()          (self.monster_movementGoal != MOVEGOAL_NONE)
#define Monster_StopAnimation()     (self.framerate = 0)

#define Monster_IsBarnacled()       (self.monster_barnacleEnt && self.monster_barnacleEnt != world)


// Monster_InitTakeDamage
float Monster_DefaultBloodColor()
{
	if (self.classname == "monster_miniturret") return 0;
	if (self.classname == "monster_headcrab") return BLOOD_COLOR_YELLOW;
	if (self.classname == "monster_houndeye") return BLOOD_COLOR_YELLOW;
	if (self.classname == "monster_barnacle") return BLOOD_COLOR_YELLOW;
	if (self.classname == "monster_alien_slave") return BLOOD_COLOR_YELLOW;
	if (self.classname == "monster_bullchicken") return BLOOD_COLOR_YELLOW;
	if (self.classname == "monster_cockroach") return BLOOD_COLOR_YELLOW;
	return BLOOD_COLOR_RED;
}

void Monster_TraceAttack(entity attacker, float flDamage, vector vecDir, float bitsDamageType)
{
	float bloodColor = Blood_ColorFor(self);
	vector bloodOrg = trace_endpos - vecDir * 4;
	if (bloodColor)
	{
		Blood_SpawnImpact(bloodOrg, vecDir, bloodColor, flDamage);
		Blood_TraceBleed(self, trace_endpos, vecDir, flDamage, bitsDamageType);
	}
	AddMultiDamage(self, flDamage, bitsDamageType);
}

void Monster_InitTakeDamage()
{
	if (GlobalState_RemoveIfDead(self))
		return;

	if (!self.max_health) self.max_health = self.health;
	if (!self.monster_bloodColor) self.monster_bloodColor = Monster_DefaultBloodColor();
	self.takedamage = DAMAGE_AIM;
	self.takeDmgFn  = Monster_TakeDamage;
	self.traceAttack = Monster_TraceAttack;
	if (self.spawnflags & SF_MONSTER_HITMONSTERCLIP)
		self.flags = self.flags | FL_MONSTERCLIP;
}

// Turn the dying monster into a corpse: still trace-solid, so it
// takes blood decals, crowbar hits and crush-gibs, but no longer a monster and
// no longer blocking the player.
void Monster_BecomeCorpse(vector cmins, vector cmaxs)
{
	self.solid      = SOLID_CORPSE;
	self.movetype   = MOVETYPE_TOSS;
	setsize(self, cmins, cmaxs);
	self.deadflag   = DEAD_DEAD;
	self.takedamage = DAMAGE_NO;
	self.flags      = self.flags - (self.flags & FL_MONSTER);
	self.enemy      = world;
	self.oldenemy   = world;
	self.goalentity = world;
	self.movetarget = world;
}

float Monster_IsFearedByFriendlies(entity e)
{
	if (!(e.flags & FL_MONSTER)) return FALSE;
	if (e.health <= 0) return FALSE;

	// Friendly / neutral / prop classes a passive NPC must never fear.
	if (e.classname == "monster_scientist")          return FALSE;
	if (e.classname == "monster_sitting_scientist")  return FALSE;
	if (e.classname == "monster_scientist_dead")     return FALSE;
	if (e.classname == "monster_barney")             return FALSE;
	if (e.classname == "monster_barney_dead")        return FALSE;
	if (e.classname == "monster_gman")               return FALSE;  // CLASS_NONE
	if (e.classname == "monster_generic")            return FALSE;  // scripted prop
	if (e.classname == "monster_furniture")          return FALSE;  // scripted prop

	if (e.classname == "monster_cockroach")          return FALSE;
	if (e.classname == "monster_leech")              return FALSE;

	// Static hazards/machines: passive NPCs don't fear them. Tripmines
	// never; turrets/sentries only while deployed (.cnt = charger_on).
	if (e.classname == "monster_tripmine")           return FALSE;
	if ((e.classname == "monster_sentry"
		|| e.classname == "monster_turret"
		|| e.classname == "monster_miniturret") && !e.cnt)
		return FALSE;

	return TRUE;
}

// Monster_CheckAITriggerDeath
void Monster_CheckAITriggerDeath()
{
	if (self.TriggerCondition != AITRIGGER_DEATH) return;
	SUB_FireTargets(self.TriggerTarget, self, self, USE_TOGGLE, 0);
	self.TriggerCondition = AITRIGGER_NONE;
}

// Barnacle victim handling
#define BARNACLE_VICTIM_THINK_RATE 0.1

void Monster_BarnacleGrab(entity victim, entity bnac)
{
	victim.monster_barnacleEnt       = bnac;
	victim.monster_barnacleLifting = TRUE;
	victim.monster_barnaclePhase   = BARNACLE_VICTIM_NONE;
	victim.monster_barnacleAnimEnd = 0;
}

void Monster_BarnacleRelease(entity victim)
{
	victim.monster_barnacleEnt     = world;
	victim.monster_barnaclePhase = BARNACLE_VICTIM_NONE;
}

float Monster_PlayBarnacledAnim(float phase)
{
	self.monster_barnaclePhase = phase;

	string primary  = "barnacled1";
	string fallback = "barnaclehit";
	if (phase == BARNACLE_VICTIM_PULL)       { primary = "barnacled2"; fallback = "barnaclepull";   }
	else if (phase == BARNACLE_VICTIM_CHOMP) { primary = "barnacled3"; fallback = "barnaclecrunch"; }
	else if (phase == BARNACLE_VICTIM_CHEW)  { primary = "barnacled4"; fallback = "barnaclechew";   }

	float dur = Monster_PlayAnimByName(self, primary);
	if (!dur) dur = Monster_PlayAnimByName(self, fallback);
	if (!dur) dur = 0.5;
	return dur;
}

void Monster_BarnacledThink()
{
	self.velocity = '0 0 0';

	if (!self.monster_barnacleEnt || self.monster_barnacleEnt == world) return;

	if (self.monster_barnacleLifting)
	{
		if (self.monster_barnaclePhase == BARNACLE_VICTIM_NONE)
			self.monster_barnacleAnimEnd = time + Monster_PlayBarnacledAnim(BARNACLE_VICTIM_HIT);
		else if (self.monster_barnaclePhase == BARNACLE_VICTIM_HIT && time >= self.monster_barnacleAnimEnd)
			Monster_PlayBarnacledAnim(BARNACLE_VICTIM_PULL);
	}
	else
	{
		if (self.monster_barnaclePhase != BARNACLE_VICTIM_CHOMP && self.monster_barnaclePhase != BARNACLE_VICTIM_CHEW)
			self.monster_barnacleAnimEnd = time + Monster_PlayBarnacledAnim(BARNACLE_VICTIM_CHOMP);
		else if (self.monster_barnaclePhase == BARNACLE_VICTIM_CHOMP && time >= self.monster_barnacleAnimEnd)
			Monster_PlayBarnacledAnim(BARNACLE_VICTIM_CHEW);
	}
}
