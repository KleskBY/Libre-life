
#define SF_SENTENCE_ONCE        1
#define SF_SENTENCE_FOLLOWERS   2   // only speak if NPC is following a player
#define SF_SENTENCE_INTERRUPT   4   // override CanPlaySentence gate
#define SF_SENTENCE_CONCURRENT  8

.string sent_sentence;          // sentence group name (e.g. "SC_HELLO")
.string m_iszEntity;            // (already shared with scripted_sequence)
.float  sent_duration;
.float  sent_attenuation;
.float  sent_volume;
.string sent_listener;          // optional: who the speaker should look at
.float  sent_active;               // gates Use re-entry while sentence in flight

// Per-NPC callback. Speakable monsters install this.
// Returns TRUE if the sentence was actually played.
.float(string sentence, float duration, float volume, float attn,
       float concurrent, entity listener) playScriptedSentence;

.float sent_sentenceBusyUntil;

.entity m_followTarget;

void ScriptedSent_FindThink();
void ScriptedSent_DelayThink();

float ScriptedSent_Acceptable(entity speaker)
{
    if (!speaker || speaker == world) return FALSE;
    if (speaker.health <= 0) return FALSE;

    if (speaker.flags & FL_MONSTER)
    {
        if (self.spawnflags & SF_SENTENCE_FOLLOWERS)
        {
            // Scientist stores its follow target in m_followTarget.
            entity hold = speaker.m_followTarget;
            if (!hold || hold == world) hold = speaker.monster_targetEnt;
            if (!hold || hold == world) return FALSE;
            if (hold.classname != "player") return FALSE;
        }

        if (!(self.spawnflags & SF_SENTENCE_INTERRUPT))
        {
            if (speaker.sent_sentenceBusyUntil > time) return FALSE;
        }
        return TRUE;
    }

    // Non-monster targets: only accept if they expose a play callback.
    if (speaker.playScriptedSentence) return TRUE;
    return FALSE;
}

// FindEntity: searches by targetname, then by classname within radius.
entity ScriptedSent_FindEntity()
{
    if (self.m_iszEntity == "") return world;

    entity e = find(world, targetname, self.m_iszEntity);
    while (e)
    {
        if (ScriptedSent_Acceptable(e)) return e;
        e = find(e, targetname, self.m_iszEntity);
    }

    if (self.m_flRadius > 0)
    {
        e = findradius(self.origin, self.m_flRadius);
        while (e)
        {
            if (e.classname == self.m_iszEntity
                && (e.flags & FL_MONSTER)
                && ScriptedSent_Acceptable(e))
                return e;
            e = e.chain;
        }
    }
    return world;
}

entity ScriptedSent_FindListener(entity speaker)
{
    if (self.sent_listener == "") return world;

    if (self.sent_listener == "player")
        return find(world, classname, "player");

    // Targetname lookup.
    entity e = find(world, targetname, self.sent_listener);
    if (e) return e;

    // Classname-in-radius fallback.
    float r = (self.m_flRadius > 0) ? self.m_flRadius : 4096;
    e = findradius(speaker.origin, r);
    while (e)
    {
        if (e.classname == self.sent_listener) return e;
        e = e.chain;
    }
    return world;
}

// StartSentence: asks the NPC to speak. Fires self.target on success.
float ScriptedSent_Start(entity speaker)
{
    if (!speaker || speaker == world) return FALSE;
    if (!speaker.playScriptedSentence)
    {
        dprint("scripted_sentence: ");
        dprint(speaker.classname);
        dprint(" has no playScriptedSentence callback\n");
        return FALSE;
    }

    float concurrent = !((self.spawnflags & SF_SENTENCE_CONCURRENT) != 0);
    entity listener  = ScriptedSent_FindListener(speaker);

    // Mark NPC busy so other concurrent sentences back off.
    speaker.sent_sentenceBusyUntil = time + self.sent_duration;

    entity stemp = self;
    self = speaker;
    float ok = speaker.playScriptedSentence(
        stemp.sent_sentence, stemp.sent_duration, stemp.sent_volume,
        stemp.sent_attenuation, concurrent, listener);
    self = stemp;

    if (!ok) return FALSE;

    dprint("scripted_sentence: '");
    dprint(self.sent_sentence);
    dprint("' played by ");
    dprint(speaker.classname);
    dprint("\n");

    SUB_UseTargetsHL(speaker, USE_TOGGLE, 0);    // unconditional: killtarget-only sentences exist

    return TRUE;
}

// Think loop
void ScriptedSent_FindThink()
{
    entity speaker = ScriptedSent_FindEntity();
    if (speaker != world)
    {
        ScriptedSent_Start(speaker);
        if (self.spawnflags & SF_SENTENCE_ONCE)
        {
            remove(self);
            return;
        }
        self.sent_active = FALSE;
        self.think    = ScriptedSent_DelayThink;
        self.nextthink = time + self.sent_duration + self.m_flRepeat;
    }
    else
    {
        // No speaker yet: retry later.
        self.nextthink = time + self.m_flRepeat + 0.5;
    }
}

void ScriptedSent_DelayThink()
{
    self.sent_active = TRUE;
    self.think    = ScriptedSent_FindThink;
    if (self.targetname == "")
        self.nextthink = time + 0.1;
    // (else: wait for next Use)
}

// Use callbacks.
void ScriptedSent_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (!self.sent_active) return;
    self.think     = ScriptedSent_FindThink;
    self.nextthink = time;
}

void ScriptedSent_UseLegacy()
{
    ScriptedSent_UseHL(activator, world, USE_TOGGLE, 0);
}

// Spawn entry point
void scripted_sentence()
{
    self.solid    = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.sent_active = TRUE;

    // Defaults.
    if (self.m_flRadius <= 0) self.m_flRadius = 512;
    if (self.sent_volume <= 0) self.sent_volume = 1.0;
    if (self.sent_duration <= 0) self.sent_duration = 3.0;

    string key, val;
    float n = tokenize(__fullspawndata);
    for (float i = 1; i < n - 1; i = i + 2)
    {
        key = argv(i);
        val = argv(i+1);

        if      (key == "sentence")     self.sent_sentence = strzone(val);
        else if (key == "entity")       self.m_iszEntity   = strzone(val);
        else if (key == "duration")     self.sent_duration  = stof(val);
        else if (key == "radius")       self.m_flRadius    = stof(val);
        else if (key == "refire")       self.m_flRepeat    = stof(val);
        else if (key == "attenuation")  self.impulse       = stof(val);
        else if (key == "volume")       self.sent_volume    = stof(val) * 0.1;
        else if (key == "listener")     self.sent_listener = strzone(val);
    }

    if      (self.impulse == 1) self.sent_attenuation = ATTN_STATIC;
    else if (self.impulse == 2) self.sent_attenuation = ATTN_NORM;
    else if (self.impulse == 3) self.sent_attenuation = ATTN_NONE;
    else                         self.sent_attenuation = ATTN_IDLE;
    self.impulse = 0;

    self.use   = ScriptedSent_UseLegacy;
    self.usehl = ScriptedSent_UseHL;

    // Auto-start if no targetname.
    if (self.targetname == "")
    {
        self.think     = ScriptedSent_FindThink;
        self.nextthink = time + 1.0;
    }
}
