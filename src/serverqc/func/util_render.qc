
void Render_Apply(entity targ)
{
    float mode = targ.rendermode;
    float amt  = targ.renderamt;

    if (mode == 0)
    {
        targ.alpha = 1;
        if (targ.effects & EF_NODRAW)   targ.effects = targ.effects - EF_NODRAW;
        if (targ.effects & EF_ADDITIVE) targ.effects = targ.effects - EF_ADDITIVE;
    }
    else
    {
        targ.alpha = amt / 255;

        if (amt <= 0)
            targ.effects = targ.effects | EF_NODRAW;
        else if (targ.effects & EF_NODRAW)
            targ.effects = targ.effects - EF_NODRAW;

        if (mode == 3 || mode == 5)
            targ.effects = targ.effects | EF_ADDITIVE;
        else if (targ.effects & EF_ADDITIVE)
            targ.effects = targ.effects - EF_ADDITIVE;
    }

    if (targ.rendercolor != '0 0 0')
        targ.colormod = targ.rendercolor / 255;

    setorigin(targ, targ.origin);
}
