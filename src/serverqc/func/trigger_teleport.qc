//                      1  SF_TRIGGER_ALLOWMONSTERS  monsters may use it
//                      2  SF_TRIGGER_NOCLIENTS      players blocked
//                      4  SF_TRIGGER_PUSHABLES      func_pushable triggers
//                    Default (flags=0) = players only.
//
// Triggers are use-only, handling telefrag, fog visuals, sounds, and velocity kick.
//                      1  PLAYER_ONLY
//                      2  SILENT


#define SF_TRIGGER_ALLOWMONSTERS  1
#define SF_TRIGGER_NOCLIENTS      2

// Q1 spawnflag values (only honored on id1 BSPs).
#define TELE_Q1_PLAYER_ONLY  1
#define TELE_Q1_SILENT       2

#define TELE_AMBIENT      "ambience/hum1.wav"
#define TELE_SND_BASE     "misc/r_tele"

void Trigger_TeleportTouchHL();
void Trigger_TeleportTouch_Q1();
void Trigger_TFog_Play();
void Trigger_SpawnTFog(vector org);
void Trigger_TDeathTouch();
void Trigger_SpawnTDeath(vector org, entity victim);

// Path for non-Q1 builds
void Trigger_TeleportTouchHL()
{
    if (!(other.flags & (FL_CLIENT | FL_MONSTER))) return;

    if (!Master_IsTriggered(self.master, other)) return;

    if (!(self.spawnflags & SF_TRIGGER_ALLOWMONSTERS))
    {
        if (other.flags & FL_MONSTER) return;
    }

    if (self.spawnflags & SF_TRIGGER_NOCLIENTS)
    {
        if (other.classname == "player") return;
    }

    entity dest = find(world, targetname, self.target);
    if (!dest) return;

    vector tmp = dest.origin;

    // Adjust Z so feet (mins.z) land on dest.origin, not center.
    if (other.classname == "player")
        tmp_z -= other.mins_z;
    tmp_z = tmp_z + 1;

    if (other.flags & FL_ONGROUND)
        other.flags = other.flags - FL_ONGROUND;

    setorigin(other, tmp);

    other.angles = dest.angles;
    if (other.classname == "player")
        other.v_angle = dest.angles;

    other.fixangle = TRUE;
    other.velocity = '0 0 0';
}

// Q1 path (visuals + telefrag + use-only gate + velocity kick)
void Trigger_TFog_Play()
{
    float v = random() * 5;
    string snd;
    if      (v < 1) snd = strcat(TELE_SND_BASE, "1.wav");
    else if (v < 2) snd = strcat(TELE_SND_BASE, "2.wav");
    else if (v < 3) snd = strcat(TELE_SND_BASE, "3.wav");
    else if (v < 4) snd = strcat(TELE_SND_BASE, "4.wav");
    else            snd = strcat(TELE_SND_BASE, "5.wav");
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, snd);
    remove(self);
}

void Trigger_SpawnTFog(vector org)
{
    entity s = spawn();
    setorigin(s, org);
    s.nextthink = time + 0.2;
    s.think     = Trigger_TFog_Play;
	te_teleport(org);
}

void Trigger_TDeathTouch()
{
    if (other == self.owner) return;

    if (other.classname == "player")
    {
        if (self.owner.classname != "player")
        {
            T_Damage(self.owner, self, self, 50000, DMG_GENERIC);
            return;
        }
    }

    if (other.health)
        T_Damage(other, self, self, 50000, DMG_GENERIC);
}

void Trigger_SpawnTDeath(vector org, entity victim)
{
    entity death = spawn();
    death.classname = "teledeath";
    death.movetype  = MOVETYPE_NONE;
    death.solid     = SOLID_TRIGGER;
    death.angles    = '0 0 0';
    setsize(death, victim.mins - '1 1 1', victim.maxs + '1 1 1');
    setorigin(death, org);
    death.touch     = Trigger_TDeathTouch;
    death.nextthink = time + 0.2;
    death.think     = SUB_Remove;
    death.owner     = victim;

    force_retouch = 2;
}

void Trigger_TeleportTouch_Q1()
{
    // Targetname'd Q1 teleports are use-only; .use opens a 0.2s window.
    if (self.targetname && self.nextthink < time)
        return;

    if (!Master_IsTriggered(self.master, other)) return;

    if (self.spawnflags & TELE_Q1_PLAYER_ONLY)
    {
        if (other.classname != "player") return;
    }

    if (other.health <= 0) return;
    if (other.solid != SOLID_SLIDEBOX) return;

    SUB_UseTargets();
    Trigger_SpawnTFog(other.origin);

    entity dest = find(world, targetname, self.target);
    if (!dest)
    {
        dprint("trigger_teleport: missing destination ");
        dprint(self.target ? self.target : "(none)");
        dprint("\n");
        return;
    }

    makevectors(dest.mangle != '0 0 0' ? dest.mangle : dest.angles);
    vector front = dest.origin + 32 * v_forward;
    Trigger_SpawnTFog(front);
    Trigger_SpawnTDeath(dest.origin, other);

    setorigin(other, dest.origin);
    other.angles = (dest.mangle != '0 0 0') ? dest.mangle : dest.angles;

    if (other.classname == "player")
    {
        other.fixangle      = TRUE;
        other.v_angle       = other.angles;
        other.teleport_time = time + 0.7;
        if (other.flags & FL_ONGROUND)
            other.flags = other.flags - FL_ONGROUND;
        other.velocity = v_forward * 300;
    }
    else
    {
        if (other.flags & FL_ONGROUND)
            other.flags = other.flags - FL_ONGROUND;
        other.velocity = v_forward * 100;
    }
}

void Trigger_TeleportUse()
{
    self.nextthink = time + 0.2;
    self.think     = SUB_Null;
    force_retouch  = 2;
}

void Trigger_TeleportUseHL(entity pActivator, entity pCaller, float utype, float uvalue)
{
    Trigger_TeleportUse();
}

void trigger_teleport()
{
    InitTrigger();

    if (!self.target)
    {
        dprint("trigger_teleport: no target\n");
        return;
    }

    if (Map_IsId1BSP())
    {
        self.touch = Trigger_TeleportTouch_Q1;
        self.use   = Trigger_TeleportUse;
        self.usehl = Trigger_TeleportUseHL;

        precache_sound("misc/r_tele1.wav");
        precache_sound("misc/r_tele2.wav");
        precache_sound("misc/r_tele3.wav");
        precache_sound("misc/r_tele4.wav");
        precache_sound("misc/r_tele5.wav");

        if (!(self.spawnflags & TELE_Q1_SILENT))
        {
            precache_sound(TELE_AMBIENT);
            vector o = (self.mins + self.maxs) * 0.5;
            ambientsound(o, TELE_AMBIENT, 0.5, ATTN_STATIC);
        }
        return;
    }

    self.touch = Trigger_TeleportTouchHL;
}

