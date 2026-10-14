
#define SF_GENERICMONSTER_NOTSOLID  4

#define RENDERFX_HOLOGRAM   16

.string generic_idleAnim;
.vector generic_holoJitter;
.float  generic_holoGlitchTime;

void MonsterGeneric_Think();
void MonsterGeneric_StartGo();

float Generic_HoloFrameByName(string name)
{
    if (name == "walk")             return 0;
    if (name == "longjump")         return 1;
    if (name == "troom_talkidle_1") return 2;
    if (name == "troom_quadjump")   return 3;
    if (name == "troom_intro")      return 4;
    if (name == "quadtalk")         return 5;
    if (name == "troom_talkidle_2") return 6;
    if (name == "cjump_hole")       return 7;
    if (name == "scharge")          return 8;
    if (name == "crouch_hole")      return 9;
    if (name == "jump_module")      return 10;
    if (name == "longjumptalk")     return 11;
    if (name == "healthkit")        return 12;
    if (name == "completed")        return 13;
    if (name == "target")           return 14;
    if (name == "kickup")           return 15;
    if (name == "treadwater")       return 16;
    if (name == "dive")             return 17;
    if (name == "divetalk_1")       return 18;
    if (name == "aqua_exit")        return 19;
    if (name == "divetalk_2")       return 20;
    if (name == "train")            return 21;
    if (name == "crate")            return 22;
    if (name == "pull_box")         return 23;
    if (name == "crate_exit")       return 24;
    if (name == "bust_wall")        return 25;
    if (name == "ladder")           return 26;
    return -1;
}

float Generic_FrameByName(string name)
{
    if (self.model == "models/holo.iqm")
        return Generic_HoloFrameByName(name);
    return -1;
}

float Generic_PlayScriptedSentence(string sentence, float duration, float volume,
    float attn, float concurrent, entity listener)
{
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

    return TRUE;
}

void MonsterGeneric_Die()
{
    // Generic is a prop, not a real NPC.
    self.solid = SOLID_NOT;
    self.takedamage = DAMAGE_NO;
    self.flags = self.flags - (self.flags & FL_MONSTER);
    self.think = SUB_Remove;
    self.nextthink = time + 30;
}

void Generic_HologramFX()
{
    // Nearest player is the viewer (SP: the only one).
    entity viewer = world;
    float best = 999999;
    entity e = find(world, classname, "player");
    while (e)
    {
        float d = vlen(e.origin - self.origin);
        if (d < best) { best = d; viewer = e; }
        e = find(e, classname, "player");
    }

    float blend = 180;
    if (viewer != world)
    {
        makevectors(viewer.v_angle);
        vector rel = self.origin - (viewer.origin + viewer.view_ofs);
        float dist = rel * v_forward;
        if (dist <= 0)
            blend = 0;
        else
        {
            if (dist > 100)
                blend = (1 - (dist - 100) * 0.0025) * 180;
            blend = blend + Math_RandomInt(-32, 31);
        }
        if (blend < 0) blend = 0;
        if (blend > 255) blend = 255;
    }
    self.alpha = (blend < 5) ? 0.02 : blend / 255;

    if (self.generic_holoJitter != '0 0 0')
    {
        self.effects += (EF_TELEPORT_BIT - 2 * (self.effects & EF_TELEPORT_BIT));
        setorigin(self, self.origin - self.generic_holoJitter);
        self.generic_holoJitter = '0 0 0';
    }
    else if (time > self.generic_holoGlitchTime)
    {
        // Glitch: 1.5 to 4u shift, random sign per axis, occasional vertical.
        vector j;
        j_x = ((random() < 0.5) ? -1 : 1) * random(1.5, 4);
        j_y = ((random() < 0.5) ? -1 : 1) * random(1.5, 4);
        j_z = (random() < 0.4) ? ((random() < 0.5) ? -1 : 1) * random(1, 3) : 0;
        self.effects += (EF_TELEPORT_BIT - 2 * (self.effects & EF_TELEPORT_BIT));
        setorigin(self, self.origin + j);
        self.generic_holoJitter = j;
        self.generic_holoGlitchTime = time + random(0.4, 1.6);
    }
}

// Idle think: yields to scripted_sequence, otherwise loops the idle anim.
void MonsterGeneric_Think()
{
    float rate = (self.renderfx == RENDERFX_HOLOGRAM) ? 0.1 : 0.2;
    if (self.renderfx == RENDERFX_HOLOGRAM)
        Generic_HologramFX();

    if (self.monster_cine && self.monster_cine != world)
    {
        // Script owns body movement. FX above still runs.
        self.nextthink = time + rate;
        self.think = MonsterGeneric_Think;
        return;
    }

    // Emulates idle activity: (re)enters the loop anim if needed
    if (self.generic_idleAnim != "")
    {
        float f = -1;
        if (IsFTE())
            f = frameforname(self.modelindex, self.generic_idleAnim);
        else if (self.frameByName)
            f = self.frameByName(self.generic_idleAnim);
        if (f >= 0 && self.frame != f)
            Monster_PlayAnimByName(self, self.generic_idleAnim);
    }

    self.nextthink = time + ((self.renderfx == RENDERFX_HOLOGRAM) ? 0.1 : 0.5);
    self.think = MonsterGeneric_Think;
}

void MonsterGeneric_StartGo()
{
    self.origin_z = self.origin_z + 1;
    droptofloor();
    if (!walkmove(0, 0))
    {
        dprint("monster_generic in wall at: ");
        dprint(vtos(self.origin));
        dprint("\n");
    }

    self.flags = self.flags | FL_MONSTER;

    if (self.target)
    {
        self.goalentity = self.movetarget = find(world, targetname, self.target);
        if (self.movetarget)
            self.ideal_yaw = vectoyaw(self.goalentity.origin - self.origin);
    }

    self.think     = MonsterGeneric_Think;
    self.nextthink = time + 0.5 + random() * 0.5;
}

void monster_generic()
{
    if (Monster_RemoveIfSpent()) return;
    if (RemoveInDeathmatch()) return;

    if (self.model != "")
        self.model = strireplace(".mdl", ".iqm", self.model);

    if (self.model == "")
    {
        dprint("monster_generic at ");
        dprint(vtos(self.origin));
        dprint(" has no model; removing\n");
        remove(self);
        return;
    }

    precache_model(self.model);
    setmodel(self, self.model);

    if (self.model == "models/player.iqm" || self.model == "models/holo.iqm")
        setsize(self, HL_PLAYER_STAND_SIZE_MIN, HL_PLAYER_STAND_SIZE_MAX);
    else
        setsize(self, VEC_HUMAN_HULL_MIN, VEC_HUMAN_HULL_MAX);

    self.solid       = SOLID_SLIDEBOX;
    self.movetype    = MOVETYPE_STEP;
    self.health      = 8;
    self.max_health  = self.health;
    self.yaw_speed   = YAW_HL(90);	// Sets the default yaw speed
    self.takedamage  = DAMAGE_AIM;
    self.view_ofs    = '0 0 50';
    self.monster_bloodColor        = BLOOD_COLOR_RED;
    self.monster_fieldOfView     = 0.5;
    self.monster_state      = MONSTERSTATE_IDLE;
    self.monster_idealState = MONSTERSTATE_IDLE;

    self.frameByName = Generic_FrameByName;
    self.playScriptedSentence = Generic_PlayScriptedSentence;

    // ACT_IDLE stand-in (see generic_idleAnim comment)
    if (self.model == "models/holo.iqm")
        self.generic_idleAnim = "troom_talkidle_1";

    self.th_die = MonsterGeneric_Die;

    Render_Apply(self);

    Monster_InitTakeDamage();

    // Hologram path: SOLID_NOT + DAMAGE_NO. Players walk through.
    if (self.spawnflags & SF_GENERICMONSTER_NOTSOLID)
    {
        self.solid      = SOLID_NOT;
        self.takedamage = DAMAGE_NO;
    }

    self.think     = MonsterGeneric_StartGo;
    self.nextthink = time + 0.1 + random() * 0.5;
    total_monsters = total_monsters + 1;
}
