// Original Q1 shows pre-written
// SVC_FINALE strings on episode-end maps and on campaign completion.
// Uses Q1 flow for id1 BSPs, not HL-style changelevel
// Only for id1 BSPs (Map_IsId1BSP() == 1). Other maps keep instant transitions.
//
// State machine (mirrors Q1 ExitIntermission):
//   intermission_running == 0  : normal play
//   2 : episode-end finale text (or skip to changelevel for non-boss maps)
//   3 : final all-runes text if (serverflags & 15) == 15 (halts campaign),
//       else changelevel.

// intermission_running / intermission_exittime declared in gamedefs.qc.
// nextmap declared in serverqc/func/trigger_changelevel.qc.

void Q1Intermission_Exit();

entity Q1Intermission_FindSpot()
{
    entity pos = find(world, classname, "info_intermission");
    if (pos) return pos;
    pos = find(world, classname, "info_player_start");
    return pos;
}

void Q1Intermission_FreezePlayers(entity pos)
{
    entity pl = find(world, classname, "player");
    while (pl != world)
    {
        pl.view_ofs    = '0 0 0';
        pl.angles      = pos.mangle;
        pl.v_angle     = pos.mangle;
        pl.fixangle    = TRUE;
        pl.think       = SUB_Null;
        pl.nextthink   = time + 0.5;
        pl.takedamage  = DAMAGE_NO;
        pl.solid       = SOLID_NOT;
        pl.movetype    = MOVETYPE_NONE;
        pl.modelindex  = 0;
        setorigin(pl, pos.origin);
        // Strip powerup screen tint bits so the intermission camera is clean.
        pl.items = pl.items & ~(IT_INVULNERABILITY | IT_INVISIBILITY | IT_QUAD | IT_SUIT);
        pl.invincible_finished = 0; pl.invincible_time = 0;
        pl.invisible_finished  = 0; pl.invisible_time  = 0;
        pl.super_damage_finished = 0; pl.super_time     = 0;
        pl.radsuit_finished    = 0; pl.rad_time        = 0;
        pl = find(pl, classname, "player");
    }
}

float Q1Intermission_SendEpisodeText()
{
    if (mapname == "e1m7")
    {
        WriteByte(MSG_ALL, SVC_CDTRACK);
        WriteByte(MSG_ALL, 2);
        WriteByte(MSG_ALL, 3);
        WriteByte(MSG_ALL, SVC_FINALE);
        WriteString(MSG_ALL, "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!");
        return 1;
    }
    if (mapname == "e2m6")
    {
        WriteByte(MSG_ALL, SVC_CDTRACK);
        WriteByte(MSG_ALL, 2);
        WriteByte(MSG_ALL, 3);
        WriteByte(MSG_ALL, SVC_FINALE);
        WriteString(MSG_ALL, "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral.");
        return 1;
    }
    if (mapname == "e3m6")
    {
        WriteByte(MSG_ALL, SVC_CDTRACK);
        WriteByte(MSG_ALL, 2);
        WriteByte(MSG_ALL, 3);
        WriteByte(MSG_ALL, SVC_FINALE);
        WriteString(MSG_ALL, "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth.");
        return 1;
    }
    if (mapname == "e4m7")
    {
        WriteByte(MSG_ALL, SVC_CDTRACK);
        WriteByte(MSG_ALL, 2);
        WriteByte(MSG_ALL, 3);
        WriteByte(MSG_ALL, SVC_FINALE);
        WriteString(MSG_ALL, "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person.");
        return 1;
    }
    return 0;
}

float Q1Intermission_SendFinalText()
{
    if ((serverflags & 15) == 15)
    {
        WriteByte(MSG_ALL, SVC_FINALE);
        WriteString(MSG_ALL, "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born.");
        return 1;
    }
    return 0;
}

void Q1Intermission_GotoNextMap()
{
    changelevel(nextmap);
}

void Q1Intermission_Begin(entity pActivator, string mapTo)
{
    nextmap               = mapTo;
    intermission_running  = 1;
    intermission_exittime = time + 2;
    gameover              = 1;

    WriteByte(MSG_ALL, SVC_CDTRACK);
    WriteByte(MSG_ALL, 3);
    WriteByte(MSG_ALL, 3);

    entity pos = Q1Intermission_FindSpot();
    if (!pos)
    {
        dprint("q1_intermission: no info_intermission, skipping\n");
        intermission_running = 0;
        gameover = 0;
        changelevel(mapTo);
        return;
    }

    Q1Intermission_FreezePlayers(pos);
    WriteByte(MSG_ALL, SVC_INTERMISSION);
}

void Q1Intermission_Exit()
{
    intermission_exittime = time + 1;
    intermission_running  = intermission_running + 1;

    if (intermission_running == 2)
    {
        if (!Q1Intermission_SendEpisodeText())
            Q1Intermission_GotoNextMap();
        return;
    }

    if (intermission_running == 3)
    {
        if (!Q1Intermission_SendFinalText())
            Q1Intermission_GotoNextMap();
        return;
    }
}

void Q1Intermission_Think(entity pl)
{
    if (time < intermission_exittime) return;
    if (!pl.button0 && !pl.button1 && !pl.button2) return;
    Q1Intermission_Exit();
}
