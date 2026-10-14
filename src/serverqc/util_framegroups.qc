// 111 core models ship a .framegroups sidecar, before counting a single
// downstream game's own (QUALKER alone adds 43 more for its weapons). This
// table is filled lazily, one slot per DISTINCT model actually requested
// this session, not preloaded, so exhaustion only shows up once a session
// has touched that many different models, weapon switches, monster variety,
// which is exactly what crashed FG_FrameDuration via FG_ModelSlot returning
// -1 once the old cap of 16 ran out.
#define MAX_FG_MODELS   256
#define MAX_FG_GROUPS   1536

string fgm_model[MAX_FG_MODELS];    // "models/scientist.iqm"
float  fgm_first[MAX_FG_MODELS];    // index into fg_* pools
float  fgm_count[MAX_FG_MODELS];    // groups parsed (0 = no/empty sidecar)
float  fgm_num;

string fg_name[MAX_FG_GROUPS];      // group name (5th column), "" if absent
float  fg_dur[MAX_FG_GROUPS];       // length / fps, seconds
float  fg_num;

// Line format: "groupname time_seconds event_code options" ('-' = no options).
#define MAX_FG_EVENTS   768

float  fge_group[MAX_FG_EVENTS];    // framegroup index within its model
float  fge_time[MAX_FG_EVENTS];     // seconds from sequence start
float  fge_code[MAX_FG_EVENTS];     // event id
string fge_opts[MAX_FG_EVENTS];     // options token, "" if '-'
float  fge_num;

float  fgm_evfirst[MAX_FG_MODELS];  // per-model slice into fge_* pools
float  fgm_evcount[MAX_FG_MODELS];

float FG_ModelSlot(string mdl)
{
    if (mdl == "") return -1;

    for (float i = 0; i < fgm_num; i = i + 1)
        if (fgm_model[i] == mdl) return i;

    if (fgm_num >= MAX_FG_MODELS)
    {
        dprint("FG_ModelSlot: MAX_FG_MODELS exceeded\n");
        return -1;
    }

    float slot = fgm_num;
    fgm_num = fgm_num + 1;
    fgm_model[slot] = strzone(mdl);
    fgm_first[slot] = fg_num;
    fgm_count[slot] = 0;

    float fh = fopen(strcat(mdl, ".framegroups"), FILE_READ);
    if (fh < 0) return slot;    // cached as "no sidecar"

    string line;
    while ((line = fgets(fh)))
    {
        float n = tokenize(line);
        if (n < 3) continue;    // need at least start/length/fps

        if (fg_num >= MAX_FG_GROUPS)
        {
            dprint("FG_ModelSlot: MAX_FG_GROUPS exceeded parsing ");
            dprint(mdl);
            dprint("\n");
            break;
        }

        float len = stof(argv(1));
        float fps = stof(argv(2));
        fg_dur[fg_num]  = (fps > 0) ? (len / fps) : 0;
        fg_name[fg_num] = (n >= 5) ? strzone(argv(4)) : "";
        fg_num = fg_num + 1;
        fgm_count[slot] = fgm_count[slot] + 1;
    }
    fclose(fh);

    fgm_evfirst[slot] = fge_num;
    fgm_evcount[slot] = 0;
    fh = fopen(strcat(mdl, ".events"), FILE_READ);
    if (fh >= 0)
    {
        while ((line = fgets(fh)))
        {
            float en = tokenize(line);
            if (en < 4) continue;

            if (fge_num >= MAX_FG_EVENTS)
            {
                dprint("FG_ModelSlot: MAX_FG_EVENTS exceeded parsing ");
                dprint(mdl);
                dprint("\n");
                break;
            }

            // Resolve group name inside this model's slice.
            string gname = argv(0);
            float gidx = -1;
            for (float gi = 0; gi < fgm_count[slot]; gi = gi + 1)
                if (fg_name[fgm_first[slot] + gi] == gname) { gidx = gi; break; }
            if (gidx < 0) continue;

            fge_group[fge_num] = gidx;
            fge_time[fge_num]  = stof(argv(1));
            fge_code[fge_num]  = stof(argv(2));
            string opts = argv(3);
            fge_opts[fge_num]  = (opts == "-") ? "" : strzone(opts);
            fge_num = fge_num + 1;
            fgm_evcount[slot] = fgm_evcount[slot] + 1;
        }
        fclose(fh);
    }
    return slot;
}

float FG_FrameForName(string mdl, string name)
{
    float slot = FG_ModelSlot(mdl);
    if (slot < 0 || name == "") return -1;

    float first = fgm_first[slot];
    float cnt   = fgm_count[slot];
    for (float i = 0; i < cnt; i = i + 1)
        if (fg_name[first + i] == name) return i;
    return -1;
}

float FG_FrameDuration(string mdl, float f)
{
    float slot = FG_ModelSlot(mdl);
    // Two statements, not one `||` chain: QuakeC's && and || do not
    // short-circuit here (fteqcc.ini's "lo" optimisation, which would add
    // that, is off), so `slot < 0 || f >= fgm_count[slot]` still evaluates
    // fgm_count[slot] even when slot is -1, and bounds-checked arrays treat
    // an out-of-range index as fatal rather than returning garbage. This is
    // exactly what MAX_FG_MODELS running out crashed on: FG_ModelSlot
    // returning -1 was not enough to stop the second operand from running.
    if (slot < 0) return 0;
    if (f < 0 || f >= fgm_count[slot]) return 0;
    return fg_dur[fgm_first[slot] + f];
}

float FG_EventFirst(string mdl)
{
    float slot = FG_ModelSlot(mdl);
    return (slot < 0) ? 0 : fgm_evfirst[slot];
}

float FG_EventCount(string mdl)
{
    float slot = FG_ModelSlot(mdl);
    return (slot < 0) ? 0 : fgm_evcount[slot];
}
