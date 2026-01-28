float sv_accelerate;
float sv_airaccelerate; // optional, or reuse sv_accelerate
float sv_maxairspeed;
float sv_friction;
float sv_maxspeed;
float sv_stopspeed;
float sv_gravity;

// prediction state
float pm_onground;          // 1 = on ground, 0 = in air
vector pm_groundnormal;

// you already have these in CSQC
.float ladder_time;
.entity ladder_entity;
.float gravity; // per-entity gravity if you want
void PM_CategorizePosition()
{
    vector start, end;

    start = player.origin;
    end   = start + '0 0 -1'; // trace 1 unit down

    tracebox(start, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, end, MOVE_NETWORK_ENTITIES_BAKER_4096, player);
    if (trace_fraction < 1 && trace_plane_normal_z >= 0.7) // not too steep
    {
        pm_onground    = TRUE;
        pm_groundnormal = trace_plane_normal;
    }
    else
    {
        pm_onground = FALSE;
    }
}

void PM_Friction()
{
    vector vel;
    float speed, drop, control, newspeed;

    vel = player.velocity;

    // Full 3D speed like in Quake
    speed = vlen(vel);
    if (speed < 1)
    {
        // snap to stop
        player.velocity_x = 0;
        player.velocity_y = 0;
        // leave Z to gravity
        return;
    }

    drop = 0;

    // Only apply ground friction (no water etc)
    if (pm_onground)
    {
        if (speed < sv_stopspeed)
            control = sv_stopspeed;
        else
            control = speed;

        drop += control * sv_friction * frametime;
    }

    newspeed = speed - drop;
    if (newspeed < 0)
        newspeed = 0;

    newspeed /= speed;

    player.velocity_x *= newspeed;
    player.velocity_y *= newspeed;
    // Z is handled by gravity
}

void PM_Accelerate(vector wishdir, float wishspeed, float accel)
{
    float currentspeed, addspeed, accelspeed;

    currentspeed = vdot(player.velocity, wishdir);
    addspeed = wishspeed - currentspeed;
    if (addspeed <= 0)
        return;

    accelspeed = accel * frametime * wishspeed;
    if (accelspeed > addspeed)
        accelspeed = addspeed;

    player.velocity += wishdir * accelspeed;
}

void PM_AirAccelerate(vector wishdir, float wishspeed, float accel)
{
    float wishspd, currentspeed, addspeed, accelspeed;

    // Quake caps air wishspeed at 30 by default
    wishspd = wishspeed;
    if (wishspd > sv_maxairspeed) // set sv_maxairspeed = 30 for classic
        wishspd = sv_maxairspeed;

    currentspeed = vdot(player.velocity, wishdir);
    addspeed = wishspd - currentspeed;
    if (addspeed <= 0)
        return;

    accelspeed = accel * wishspd * frametime;
    if (accelspeed > addspeed)
        accelspeed = addspeed;

    player.velocity += wishdir * accelspeed;
}

vector PM_ClipVelocity(vector in, vector normal, float overbounce)
{
    float backoff;
    vector out;

    backoff = vdot(in, normal) * overbounce;
    out = in - normal * backoff;

    // STOP_EPSILON-ish
    if (out_x > -0.1 && out_x < 0.1) out_x = 0;
    if (out_y > -0.1 && out_y < 0.1) out_y = 0;
    if (out_z > -0.1 && out_z < 0.1) out_z = 0;

    return out;
}

void PM_FlyMove()
{
    float time_left;
    float bump;
    float numbumps = 4;
    vector primal_velocity;

    time_left = frametime;
    primal_velocity = player.velocity;

    for (bump = 0; bump < numbumps && time_left > 0; bump++)
    {
        vector end;

        end = player.origin + player.velocity * time_left;

        tracebox(player.origin, PLAYER_STAND_SIZE_MIN, PLAYER_STAND_SIZE_MAX, end, MOVE_NETWORK_ENTITIES_BAKER_4096, player);

        if (trace_startsolid || trace_allsolid)
        {
            // stuck in solid
            player.velocity = '0 0 0';
            return;
        }

        // move as far as we can
        if (trace_fraction > 0)
        {
            setorigin(player, trace_endpos);
        }

        if (trace_fraction == 1)
            break; // moved full distance

        // reduce remaining time along this path
        time_left -= time_left * trace_fraction;

        // clip velocity to the impact plane
        player.velocity = PM_ClipVelocity(player.velocity, trace_plane_normal, 1);

        // like Quake: if we’re going against original vel, stop to avoid tiny oscillations
        if (vdot(player.velocity, primal_velocity) <= 0)
        {
            player.velocity = '0 0 0';
            break;
        }
    }
}

void PM_GroundMove()
{
    // When grounded, no vertical movement from velocity
    player.velocity_z = 0;

    if (!player.velocity_x && !player.velocity_y)
        return;

    PM_FlyMove();
}

void() PlayerJump =
{	
    if (!isJumping) return;
    if (player.lastTouch + 1 > time) return;
    if (!pm_onground) return;

	pm_onground = false;
    player.lastTouch = time;
    player.velocity_z = player.velocity_z + 270;
};


void Player_Movement()
{
    // --- read server movevars (cvars) ---
    sv_maxairspeed   = cvar("sv_maxairspeed");  // set this to 30 to match Quake air accel cap
    sv_maxspeed      = cvar("sv_maxspeed");
    sv_friction      = cvar("sv_friction");
    sv_accelerate    = cvar("sv_accelerate");
    sv_airaccelerate = cvar("sv_airaccelerate"); // or reuse sv_accelerate
    sv_stopspeed     = cvar("sv_stopspeed");
    sv_gravity       = cvar("sv_gravity");

    // --- construct wish direction from input & view yaw ---
    // input_angles_y is yaw in DarkPlaces CSQC
    makevectors(input_angles_y * '0 1 0');

    vector wishvel;
    wishvel = v_forward * input_movevalues_x + v_right   * input_movevalues_y;
    wishvel_z = 0;

    vector wishdir = '0 0 0';
    float  wishspeed = vlen(wishvel);

    if (wishspeed > 0)
    {
        wishdir = wishvel / wishspeed;
        // clamp to sv_maxspeed like Quake
        if (wishspeed > sv_maxspeed) wishspeed = sv_maxspeed;
    }

    // --- figure out if we’re on ground ---
    PM_CategorizePosition();

    // --- apply friction first (like Quake) ---
    PM_Friction();
	PlayerJump();
    // --- apply acceleration ---
    if (wishspeed > 0)
    {
        if (pm_onground) PM_Accelerate(wishdir, wishspeed, sv_accelerate);
        else PM_AirAccelerate(wishdir, wishspeed, sv_airaccelerate);
    }

    // --- gravity ---
    if (!pm_onground) player.velocity_z -= sv_gravity * frametime;
    else player.velocity_z = 0;

    // --- move with collisions ---
    if (pm_onground) PM_GroundMove();
    else PM_FlyMove();

    // --- recalc ground for final position ---
    PM_CategorizePosition();
	
	string pstr = "cmd p ";
	pstr = strcat(pstr, ftos(player.origin_x));
	pstr = strcat(pstr, " ");
	pstr = strcat(pstr, ftos(player.origin_y));
	pstr = strcat(pstr, " ");
	pstr = strcat(pstr, ftos(player.origin_z));
	pstr = strcat(pstr, "\n");
	localcmd(pstr);
	setproperty(VF_ORIGIN, player.origin + [0, 0, playerHeight]);
}

