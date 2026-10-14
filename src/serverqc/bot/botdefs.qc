// Bot state, and the few things the bot code expects a game to provide.
//
// Ported from QUALKER (qualker/src/serverqc/bot). The navigation, movement and
// combat layers came over unchanged; the systems that game has and this one does
// not (teams, downed players, a shop, a stealth model) are stubbed at the bottom
// so the ported code keeps one shape across both games.

#define BOT_TICK            0.1    // brain cadence, seconds
#define BOT_PLAN            0.4    // seconds between decisions
#define BOT_WALK_SPEED      190
#define BOT_SPRINT_SPEED    320
#define BOT_CROUCH_MULT     0.33
#define BOT_AIM_MULT        0.55   // aim down sights: this game has no such state
#define BOT_IMPULSE_RELOAD  100    // weapons.qc ImpulseCommands
#define BOT_IMPULSE_HEAL    0      // no medkit item here
#define BOT_BNAV            "maps/bnav/"

// What a bot is doing. utility.qc scores them all and picks one per plan tick.
#define BSTATE_ROAM    0
#define BSTATE_COMBAT  1
#define BSTATE_HUNT    2
#define BSTATE_REVIVE  3
#define BSTATE_COVER   4
#define BSTATE_REARM   5
#define BSTATE_PEEK    6
#define BSTATE_FLANK   7
#define BSTATE_PUSH    8
#define BSTATE_HEAL    9

#define BOT_TEAM_NONE   0
#define BOT_TEAM_A      1
#define BOT_TEAM_B      2
#define BOT_TEAM_COUNT  3

// Read by the ported sense code. Nothing writes them here: this game has no
// noise or visibility model, so a bot sees and nothing else.
.float medkits;          // no carried medkit here, so the heal option never wins
.float bot_teamPending;  // no teams here
.float bot_pickupGiveUp;
.entity bot_pickupBad;     // item it could not reach
.float  bot_pickupBadUntil;
.float bot_isBot;        // set on every bot client
.float bot_noise;
.float bot_visibility;
.float bot_awareness;
.float bot_down;           // no downed state here
.float bot_team;           // no teams here
.float bot_aimState;       // no shouldered aim here
.float bot_stamBlocked;    // no stamina here
.float bot_itemId;         // QUALKER drop id, unused here
.float bot_armWid;

.entity bot_brainEnt;       // the companion think entity
.entity bot_owner;       // on the brain, points back at the player edict
.float  bot_skill;       // 0..1
.float  bot_aim;         // steady state error cone, radians
.float  bot_react;       // seconds between seeing and aiming
.float  bot_aggro;       // 0..1, rolled independently of skill
.float  bot_rangePref;   // multiplier on the weapon's preferred range
.float  bot_seed;        // per bot phase, staggers the planner
.float  bot_state;
.float  bot_nextPlan;
.entity bot_target;
.float  bot_sawTime;     // when the current target became visible
.float  bot_lostTime;    // when line of sight to it broke
.vector bot_lkp;         // last known position of the target
.float  bot_los;         // target visible at the last check
.float  bot_losAt;       // when that check is next due
.float  bot_backoff;     // planner is backing away from a too close target
.float  bot_reloadSince; // when .reload was first seen set
.vector bot_goal;
.float  bot_repathAt;
.float  bot_jumpAt;
.float  bot_strafeDir;
.float  bot_strafeUntil;
.vector bot_aimErr;      // current error offset, a slow random walk
.vector bot_aimVel;      // angular velocity, for the settle curve
.float  bot_aimNextErr;
.float  bot_hold;        // planner wants the bot to hold ground and strafe
.float  bot_atkFin;      // last seen .attack_finished, to detect a real shot
.float  bot_burstLeft;
.float  bot_burstPause;
.float  bot_nextSwitch;
.entity bot_anchor;      // teammate this bot loosely follows
.float  bot_anchorAt;
.float  bot_buyAt;
.float  bot_hurtAt;      // last time something damaged it, for the lull test
.entity bot_pickup;      // item it is walking to
.float  bot_pickupAt;    // next scan
.float  bot_useUntil;    // holding USE until this time
.float  bot_useAgainAt;  // and released until this one, see bot/pickup.qc
.float  bot_breakUntil;  // running away with nothing to fight back with
.vector bot_pathGoal;     // goal the current path was planned for
.float  bot_pathLen;      // nodes in this bot's path slot, 0 none
.float  bot_pathPos;      // index of the node being walked to
.float  bot_pathTotal;    // hops in the whole route, beyond the window
.entity bot_pathStart;    // node the route starts from
.entity bot_h0, bot_h1, bot_h2, bot_h3, bot_h4, bot_h5, bot_h6, bot_h7;
.float  bot_l0, bot_l1, bot_l2, bot_l3, bot_l4, bot_l5, bot_l6, bot_l7;
.float  bot_linkStart;    // when the current link was entered
.float  bot_linkBudget;   // seconds that link is allowed
.float  bot_jumped;       // the current jump link has already fired
.float  bot_pullAt;       // next string pulling pass
.entity bot_lastGood;     // node last reached cleanly
.float  bot_bl0, bot_bl1, bot_bl2, bot_bl3;       // blacklisted link + 1
.float  bot_blT0, bot_blT1, bot_blT2, bot_blT3;   // and when each expires
.float  bot_blNext;
.float  bot_crouchUntil;
.float  bot_progBest;     // closest flat distance to the progress target
.float  bot_progAt;       // when that last improved
.vector bot_progTarget;
.float  bot_stuckStage;
.float  bot_backUntil;
.vector bot_backDir;
.float  bot_yieldUntil;
.vector bot_yieldDir;
.vector bot_areaOrg;      // where the bot stood a few seconds ago
.float  bot_areaAt;
.float  bot_stuckEvents;  // for `cmd bot stuckstats`
.float  bot_stuckWorst;
.entity bot_coverNode;
.entity bot_peekNode;
.float  bot_coverAt;
.float  bot_peekUntil;
.float  bot_peekAt;
.float  bot_flankUntil;
.float  bot_searchLeft;
.vector bot_lkpDir;       // which way the target was heading when lost
.float  bot_tgtStillAt;   // since when the target has barely moved
.vector bot_tgtLastOrg;
.float  bot_wpShow;
.entity bot_wpFrom;
.entity bot_learnNode;
.float  bot_learnAir;
.float  bot_learnStartZ;
.float  bot_learnPeakZ;
.float  bot_learnCrouch;
.float  bot_learnLadder;     // ladder entity number + 1 seen on this hop
.float  bot_learnAt;
.vector bot_learnLastOrg;

// What the ported code calls into, and this game does not have.
float Bot_TeamsEnabled() { return FALSE; }
float Bot_TeamSmallest() { return BOT_TEAM_NONE; }
float Bot_TeamSize(float t) { return 0; }
float Bot_DownModeAllows() { return FALSE; }
entity Bot_FindCasualty(entity bot) { return world; }
void Bot_PickAnchor(entity bot) { bot.bot_anchor = world; }
void Bot_BuyPhase(entity bot) { }
void Bot_LullBuy(entity bot) { }
float Bot_ReviveStep(entity bot, entity casualty) { return FALSE; }
void Bot_NoiseEvent(float amount) { }
