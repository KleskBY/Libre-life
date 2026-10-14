
void FuncTankControls_Find()
{
    entity t = find(world, targetname, self.target);
    while (t)
    {
        // Match any func_tank* classname (tank/tankrocket/tankmortar/tanklaser).
        if (strncmp(t.classname, "func_tank", 9) == 0 && t.classname != "func_tankcontrols")
        {
            self.tank_ent = t;
            return;
        }
        t = find(t, targetname, self.target);
    }
    dprint("func_tankcontrols: no tank with targetname '");
    dprint(self.target);
    dprint("'\n");
}

void FuncTankControls_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    if (!self.tank_ent) return;
    entity stemp = self;
    self = self.tank_ent;
    self.usehl(pActivator, pCaller, useTypeArg, useValueArg);
    self = stemp;
}

void FuncTankControls_Use()
{
    FuncTankControls_UseHL(activator, self, useType, 0);
}

void func_tankcontrols()
{
    self.solid    = SOLID_TRIGGER;
    self.movetype = MOVETYPE_NONE;
    self.effects  = self.effects | EF_NODRAW;
    setmodel(self, self.model);
    setsize(self, self.mins, self.maxs);
    setorigin(self, self.origin);

    self.use   = FuncTankControls_Use;
    self.usehl = FuncTankControls_UseHL;
    self.object_caps = FCAP_IMPULSE_USE;

    self.think = FuncTankControls_Find;
    self.nextthink = time + 0.3;
}
