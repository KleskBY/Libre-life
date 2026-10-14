
.float modifier;

float g_frictionSaved;
float g_normalFriction;

void Friction_Touch()
{
    if (other.classname != "player")
        return;

    if (!g_frictionSaved)
    {
        g_normalFriction = cvar("sv_friction");
        g_frictionSaved = TRUE;
    }

    cvar_set("sv_friction", ftos(g_normalFriction * self.modifier / 100));
    other.inFrictionVol = TRUE;
    other.frictionTouchTime = time;
}

void Player_FrictionTick()
{
    if (!self.inFrictionVol)
        return;
    if (self.frictionTouchTime >= time - frametime * 2)
        return;

    cvar_set("sv_friction", ftos(g_normalFriction));
    self.inFrictionVol = 0;
}

void Player_FrictionRelease()
{
    if (!self.inFrictionVol)
        return;
    if (g_frictionSaved)
        cvar_set("sv_friction", ftos(g_normalFriction));
    self.inFrictionVol = 0;
    self.frictionTouchTime = 0;
}

void func_friction()
{
    self.solid = SOLID_TRIGGER;
    setmodel(self, self.model);
    self.movetype = MOVETYPE_NONE;
    self.touch = Friction_Touch;
}
