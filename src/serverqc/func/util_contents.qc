
float Content_IsLiquid(float c) //liquids we emulate on DP
{
    return (c == CONTENT_WATER || c == CONTENT_SLIME || c == CONTENT_LAVA);
}

// DP swim physics TODO FIX
void WaterBrush_Touch()
{
    if (other.movetype == MOVETYPE_NOCLIP) return;
    if (other.classname != "player") return;
    if (!IsAlive(other)) return;

    // Depth: the brush top (absmax_z) is the water surface.
    float top   = self.absmax_z;
    float eyeZ  = other.origin_z + other.view_ofs_z;
    float midZ  = other.origin_z;
    float feetZ = other.origin_z + other.mins_z;

    float lvl;
    if      (eyeZ  < top) lvl = 3;   // submerged
    else if (midZ  < top) lvl = 2;
    else if (feetZ < top) lvl = 1;
    else                  return;    // standing on top of the volume

    // Drives water systems (drown/drag/bubbles, swim-jump, weapon gating). Cleared by Player_Swim when touches stop.
    other.watertype          = self.skin;   // CONTENT_WATER / SLIME / LAVA
    other.waterlevel         = lvl;
    other.brushWaterMode     = TRUE;
    other.waterBrushTouchTime = time;

    if (lvl < 2)
        return;

    float sv_maxspeed   = cvar("sv_maxspeed");
    float sv_friction   = cvar("sv_friction");
    float sv_accelerate = cvar("sv_accelerate");
    float sv_gravity    = cvar("sv_gravity");

    other.movetype = MOVETYPE_FLY;   // no ground-stick; restored by ResetMovetypeAfterLadder

    // water drag
    other.velocity = other.velocity * (1 - frametime * sv_friction);

    // plus explicit up/down on movement_z (jump/crouch).
    makevectors(other.v_angle);
    vector wishvel = v_forward * other.movement_x
                   + v_right   * other.movement_y
                   + '0 0 1'   * other.movement_z;

    vector wishdir   = normalize(wishvel);
    float  wishspeed = vlen(wishvel);
    if (wishspeed > sv_maxspeed) wishspeed = sv_maxspeed;
    wishspeed = wishspeed * 0.8;	// Water movement factor

    if (time >= other.teleport_time)
    {
        float f = wishspeed - (other.velocity * wishdir);
        if (f > 0)
            other.velocity = other.velocity + wishdir * min(f, sv_accelerate * frametime * wishspeed);
    }

    other.velocity_z = other.velocity_z + sv_gravity * frametime * 0.9;
}

// Negative skins on a SOLID_BSP entity act as CONTENTS overrides, causing the player to pass through the brush. Only -3 and below are real overrides; -1/-2 are the defaults and must be cleared.
void Brush_SanitizeSkin(entity e)
{
    if (e.skin == CONTENT_EMPTY || e.skin == CONTENT_SOLID)
        e.skin = 0;
}

// One-shot sweep for brush entities whose spawn never calls Brush_ApplyContents.
void Brush_SanitizeAllSkins()
{
    for (entity e = nextent(world); e != world; e = nextent(e))
    {
        if (e.solid != SOLID_BSP) continue;
        Brush_SanitizeSkin(e);
    }
}

void Brush_ApplyContents(entity e)
{
    Brush_SanitizeSkin(e);

    if (e.skin >= CONTENT_SOLID)    // 0 / -1 (empty) / -2 (solid): nothing to do
        return;

    if (IsFTE())
    {
        e.solid = SOLID_BSP;
        setorigin(e, e.origin);
        return;
    }

    if (Content_IsLiquid(e.skin))
    {
        e.solid = SOLID_TRIGGER;
        e.touch = WaterBrush_Touch;
        setorigin(e, e.origin);
    }
}
