
#define OLD_FR_OLD1       0
#define OLD_FR_OLD46      45
#define OLD_FR_SHAKE1     46
#define OLD_FR_SHAKE12    57
#define OLD_FR_SHAKE15    61
#define OLD_FR_SHAKE16    62
#define OLD_FR_SHAKE20    66

#define OLD_MODEL         "progs/oldone.mdl"

#define OLD_HERO_MDL      PLAYER_MODEL_FULL
#define OLD_HERO_ANIM     "look_idle"
#define OLD_HERO_Z_OFS    -20
#define OLD_FINALE_MENU_DELAY   20
#define OLD_FINALE_SKIP_DELAY   3

#define OLD_SND_DEATH     "boss2/death.wav"
#define OLD_SND_SIGHT     "boss2/sight.wav"
#define OLD_SND_POP       "boss2/pop2.wav"
#define OLD_SND_TELE      "misc/r_tele1.wav"

#define OLD_THINK_RATE    0.1

// intermission_running / intermission_exittime are declared in gamedefs.qc.

entity shub;

void OldOne_Idle();
void OldOne_Thrash();
void OldOne_Finale_1();
void OldOne_Finale_2();
void OldOne_Finale_3();
void OldOne_Finale_4();
void OldOne_FinaleExit();

void OldOne_FinaleExit()
{
    float skip = FALSE;
    if (time >= self.pain_finished)
    {
        entity pl = find(world, classname, "player");
        while (pl != world)
        {
            if (pl.button0 || pl.button1 || pl.button2)
                skip = TRUE;
            pl = find(pl, classname, "player");
        }
    }

    if (skip || time >= self.delay)
    {
        localcmd("disconnect\ntogglemenu 1\n");
        remove(self);
        return;
    }

    self.think     = OldOne_FinaleExit;
    self.nextthink = time + OLD_THINK_RATE;
}

void OldOne_Idle()
{
    self.frame = self.frame + 1;
    if (self.frame < OLD_FR_OLD1 || self.frame > OLD_FR_OLD46)
        self.frame = OLD_FR_OLD1;

    self.think     = OldOne_Idle;
    self.nextthink = time + OLD_THINK_RATE;
}

void OldOne_Thrash()
{
    if (self.frame < OLD_FR_SHAKE1 - 1 || self.frame > OLD_FR_SHAKE20)
        self.frame = OLD_FR_SHAKE1;
    else
        self.frame = self.frame + 1;

    float fi = self.frame - OLD_FR_SHAKE1;
    if      (fi == 0)  lightstyle(0, "m");
    else if (fi <= 7)  lightstyle(0, "kkigeca");     // dim down
    else if (fi <= 14) lightstyle(0, "cegikm");      // back up

    if (self.frame == OLD_FR_SHAKE15)
    {
        self.cnt = self.cnt + 1;
        if (self.cnt < 3)
        {
            self.frame     = OLD_FR_SHAKE1 - 1;
            self.think     = OldOne_Thrash;
            self.nextthink = time + OLD_THINK_RATE;
            return;
        }
    }

    if (self.frame >= OLD_FR_SHAKE20)
    {
        self.think     = OldOne_Finale_4;	// let shake20 render for one tick
        self.nextthink = time + OLD_THINK_RATE;
        return;
    }

    self.think     = OldOne_Thrash;
    self.nextthink = time + OLD_THINK_RATE;
}

void OldOne_Finale_1()
{
    intermission_exittime = time + 10000000;
    intermission_running  = 1;
    // PlayerPostThink only skips Weapon_Frame when gameover is set
    // intermission_running alone stops PreThink but leaves the player able to fire
    gameover              = 1;

    entity pos = find(world, classname, "info_intermission");
    if (!pos)
    {
        dprint("monster_oldone: no info_intermission\n");
        return;
    }

    entity tt = find(world, classname, "misc_teleporttrain");
    if (tt) remove(tt);

    WriteByte(MSG_ALL, SVC_FINALE);
    WriteString(MSG_ALL, "");

    entity pl = find(world, classname, "player");
    while (pl != world)
    {
        pl.view_ofs    = '0 0 0';
        pl.angles      = pos.mangle;
        pl.v_angle     = pos.mangle;
        pl.fixangle    = TRUE;
        pl.nextthink   = time + 0.5;
        pl.takedamage  = DAMAGE_NO;
        pl.solid       = SOLID_NOT;
        pl.movetype    = MOVETYPE_NONE;
        // Clearing .model as well as modelindex matters on the DP split-body
        // path: Player_TorsoSync runs ahead of the gameover gate in
        // PlayerPostThink and re-creates the torso child for as long as the
        // player still wears the legs model.
        setmodel(pl, "");
        pl.modelindex  = 0;
        setorigin(pl, pos.origin);

        // Nothing left to shoot at, and this map has no next level to carry an
        // Since the body hide doesn't hide the held world model, we must drop weapons and models.
        Player_StripWeapons(pl);
        Player_TorsoRemove(pl);

        pl = find(pl, classname, "player");
    }

    entity timer = spawn();
    timer.nextthink = time + 1;
    timer.think     = OldOne_Finale_2;
}


void OldOne_Finale_2()
{
    if (!shub)
    {
        remove(self);
        return;
    }

    vector o = shub.origin - '0 100 0';
    te_teleport(o);
    Sound_Play(shub, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OLD_SND_TELE);

    self.nextthink = time + 2;
    self.think     = OldOne_Finale_3;
}

void OldOne_Finale_3()
{
    if (shub)
    {
        shub.frame     = OLD_FR_SHAKE1 - 1;	// first think steps onto SHAKE1
        shub.cnt       = 0;
        shub.think     = OldOne_Thrash;
        shub.nextthink = time + 0.1;
        Sound_Play(shub, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OLD_SND_DEATH);
    }

    lightstyle(0, "abcdefghijklmlkjihgfedcb");
    remove(self);
}

void OldOne_Finale_4()
{
    Sound_Play(self, CHAN_VOICE, 1, ATTN_NORM, PITCH_NORM, OLD_SND_POP);
    vector oldo = self.origin;
    float z = 16;
    while (z <= 144)
    {
        float x = -64;
        while (x <= 64)
        {
            float y = -64;
            while (y <= 64)
            {
                vector org = oldo + [x, y, z];

                float r = random();
                string gib = "progs/gib3.mdl";
                if      (r < 0.3) gib = "progs/gib1.mdl";
                else if (r < 0.6) gib = "progs/gib2.mdl";

                Gib_SpawnPiece(gib, org, Gib_RandomVelocity(-999), GIB_BLOOD_RED);

                y = y + 32;
            }
            x = x + 32;
        }
        z = z + 96;
    }

    WriteByte(MSG_ALL, SVC_FINALE);
    WriteString(MSG_ALL,
        "Congratulations and well done! You have\n"
        "beaten the hideous Shub-Niggurath, and\n"
        "her hundreds of ugly changelings and\n"
        "monsters. You have proven that your\n"
        "skill and your cunning are greater than\n"
        "all the powers of Quake. You are the\n"
        "master now. Id Software salutes you.");

    entity n = spawn();
    n.classname = "oldone_finale_hero";
    n.solid     = SOLID_NOT;
    n.movetype  = MOVETYPE_NONE;
    setmodel(n, OLD_HERO_MDL);
    Body_Apply(n);
    // Authored to a 72-unit hull, and drawn at the map family's player scale
    // scale so the hull matches, or droptofloor lands the box on the
    // ground with the shrunk mesh floating above it.
    n.scale = PLAYER_MODEL_SCALE;
    setsize(n, HL_PLAYER_STAND_SIZE_MIN * PLAYER_MODEL_SCALE, HL_PLAYER_STAND_SIZE_MAX * PLAYER_MODEL_SCALE);
    setorigin(n, oldo - '32 264 0');
    n.angles = '0 290 0';

    float hf = Player_AnimResolve(n, OLD_HERO_ANIM);
    if (hf >= 0)
    {
        n.frame      = hf;
        n.frame1time = time;
    }

    entity oself = self;
    self = n;
    if (!droptofloor())
        dprint("monster_oldone: finale hero has no floor under it\n");
    self = oself;
    setorigin(n, n.origin + [0, 0, OLD_HERO_Z_OFS]);

    // Crowbar
    entity hw = spawn();
    hw.classname = "oldone_finale_hero_weapon";
    hw.owner     = n;
    hw.solid     = SOLID_NOT;
    hw.movetype  = MOVETYPE_NONE;
    hw.scale     = 0.5;
    setmodel(hw, Weapon_WorldModel(WID_CROWBAR));
    setattachment(hw, n, "Bip01 R Hand");
    hw.origin    = Weapon_GripOrigin(WID_CROWBAR);
    hw.angles    = Weapon_GripAngles(WID_CROWBAR);

    entity ex = spawn();
    ex.classname = "oldone_finale_exit";
    ex.delay     = time + OLD_FINALE_MENU_DELAY;
    ex.pain_finished = time + OLD_FINALE_SKIP_DELAY;
    ex.think     = OldOne_FinaleExit;
    ex.nextthink = time + OLD_THINK_RATE;

    WriteByte(MSG_ALL, SVC_CDTRACK);
    WriteByte(MSG_ALL, 3);
    WriteByte(MSG_ALL, 3);
    lightstyle(0, "m");

    killed_monsters = killed_monsters + 1;
    WriteByte(MSG_ALL, SVC_KILLEDMONSTER);
    monster_death_use();

    shub = world;
    remove(self);
}

void OldOne_Touch()
{
    if (other.classname != "player") return;
    if (!IsAlive(other)) return;
    OldOne_Finale_1();
}

void OldOne_Precache()
{
    precache_model(OLD_MODEL);
    precache_model(OLD_HERO_MDL);
    precache_model(Weapon_WorldModel(WID_CROWBAR));
    precache_model("progs/gib1.mdl");
    precache_model("progs/gib2.mdl");
    precache_model("progs/gib3.mdl");

    precache_sound(OLD_SND_DEATH);
    precache_sound(OLD_SND_SIGHT);
    precache_sound(OLD_SND_POP);
    precache_sound(OLD_SND_TELE);
}

void monster_oldone()
{
    self.q1_monster = TRUE;
	if(RemoveInDeathmatch()) return;

    OldOne_Precache();

    self.solid      = SOLID_BBOX;
    self.movetype   = MOVETYPE_NONE;
    self.health     = 40000;
    self.max_health = self.health;
    self.takedamage = DAMAGE_NO;
    self.flags      = self.flags | FL_MONSTER;

    setmodel(self, OLD_MODEL);
    setsize(self, '-160 -128 -24', '160 128 256');

    self.touch      = OldOne_Touch;
    self.th_die     = OldOne_Finale_1;
    self.frame      = OLD_FR_OLD1;
    self.think      = OldOne_Idle;
    self.nextthink  = time + 0.1;

    shub = self;
    total_monsters  = total_monsters + 1;
}
