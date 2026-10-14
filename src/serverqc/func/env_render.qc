
#define SF_RENDER_MASKFX     1
#define SF_RENDER_MASKAMT    2
#define SF_RENDER_MASKMODE   4
#define SF_RENDER_MASKCOLOR  8

void EnvRender_DoTarget(entity src, entity targ)
{
    if (!(src.spawnflags & SF_RENDER_MASKFX))    targ.renderfx    = src.renderfx;
    if (!(src.spawnflags & SF_RENDER_MASKAMT))   targ.renderamt   = src.renderamt;
    if (!(src.spawnflags & SF_RENDER_MASKMODE))  targ.rendermode  = src.rendermode;
    if (!(src.spawnflags & SF_RENDER_MASKCOLOR)) targ.rendercolor = src.rendercolor;

    entity stemp = self;
    self = targ;
    Render_Apply(targ);
    self = stemp;
}

void EnvRender_Fire(entity src)
{
    if (src.target == "") return;

    entity t = world;
    do {
        t = find(t, targetname, src.target);
        if (t != world) EnvRender_DoTarget(src, t);
    } while (t != world);
}

void EnvRender_Use()
{
    EnvRender_Fire(self);
}

void EnvRender_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    EnvRender_Fire(self);
}

void env_render()
{
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.use = EnvRender_Use;
    self.usehl = EnvRender_UseHL;
}
