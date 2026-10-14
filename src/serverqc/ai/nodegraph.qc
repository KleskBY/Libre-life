

#define NODE_MAX            512
#define NODE_LINK_MAX       4096
#define NODE_INIT_LINKS     64
#define NODE_HEIGHT         8
#define HULL_STEP_SIZE      16
#define NODE_DROP_DIST      384
#define NODE_GRAPH_VERSION  3           // Bump when the graph or cache format changes.

#define NODE_BIG            1000000000  // fteqcc does not accept 1e9.

#define NODE_REALM_LAND     1
#define NODE_REALM_AIR      2
#define NODE_REALM_WATER    4

#define LINK_SMALL          1
#define LINK_HUMAN          2
#define LINK_LARGE          4
#define LINK_FLY            8

#define HULL_SMALL          0
#define HULL_HUMAN          1
#define HULL_LARGE          2
#define HULL_FLY            3

#define NODE_CAP_DOORS  (BITS_CAP_DOORS_GROUP | BITS_CAP_OPEN_DOORS | BITS_CAP_AUTO_DOORS | BITS_CAP_USE)

// These values match the node definitions.
#define HINT_NONE               0
#define HINT_WORLD_DOOR         1
#define HINT_WORLD_WINDOW       2
#define HINT_WORLD_BUTTON       3
#define HINT_WORLD_MACHINERY    4
#define HINT_WORLD_LEDGE        5
#define HINT_WORLD_LIGHT_SOURCE 6
#define HINT_WORLD_HEAT_SOURCE  7
#define HINT_WORLD_BLINKING_LIGHT 8
#define HINT_WORLD_BRIGHT_COLORS  9
#define HINT_WORLD_HUMAN_BLOOD    10
#define HINT_WORLD_ALIEN_BLOOD    11
#define HINT_TACTICAL_EXIT      100
#define HINT_TACTICAL_VANTAGE   101
#define HINT_TACTICAL_AMBUSH    102

vector node_origin[NODE_MAX];
float  node_realm[NODE_MAX];
float  node_hinttype[NODE_MAX];
float  node_hintact[NODE_MAX];
float  node_hintyaw[NODE_MAX];
float  node_firstlink[NODE_MAX];
float  node_numlinks[NODE_MAX];
float  node_count;

float  link_dest[NODE_LINK_MAX];
float  link_bits[NODE_LINK_MAX];
float  link_weight[NODE_LINK_MAX];
string link_door[NODE_LINK_MAX];
float  link_count;

// Dijkstra workspace.
float  node_dist[NODE_MAX];
float  node_prev[NODE_MAX];
float  node_done[NODE_MAX];
float  node_path[NODE_MAX];

// Keep the map placements around in case the cache has to be rebuilt.
vector placed_origin[NODE_MAX];
float  placed_realm[NODE_MAX];
float  placed_hinttype[NODE_MAX];
float  placed_hintact[NODE_MAX];
float  placed_hintyaw[NODE_MAX];
float  placed_count;

float  node_graph_present;
float  node_built;
float  node_cache_checksum;

float  dbg_cand;
float  dbg_hull;
float  dbg_startsolid;

// Builder and route-following state.
.float  node_savedsolid;
.float  m_iGoalNode;
.float  m_iRouteNode;
.vector m_lastStuckOrg;
.float  m_stuckTime;
.float  m_stuckDist;
.entity m_nodeMarker;
.entity m_routeRealGoal;
.float  m_reachCheckTime;
.float  m_slideYaw;
.float  m_slideUntil;
.float  m_slideGoalDist;
.float  m_slideCool;
.vector m_dbgLastOrg;
.float  m_dbgStall;

// Candidate links for the node currently being built.
float  scratch_dest[NODE_INIT_LINKS];
string scratch_door[NODE_INIT_LINKS];
float  scratch_bits[NODE_INIT_LINKS];
float  scratch_weight[NODE_INIT_LINKS];
float  scratch_n;

void NodeGraph_Save(string map);
float NodeGraph_PlacedChecksum();
float Monster_DirectStep(vector goalorg, float dist);

float Node_HullBit(float hull)
{
    if (hull == HULL_SMALL) return LINK_SMALL;
    if (hull == HULL_HUMAN) return LINK_HUMAN;
    if (hull == HULL_LARGE) return LINK_LARGE;
    return LINK_FLY;
}

vector Node_HullMins(float hull)
{
    if (hull == HULL_SMALL) return '-12 -12 0';
    if (hull == HULL_LARGE) return '-32 -32 0';
    if (hull == HULL_FLY)   return '-32 -32 0';
    return '-16 -16 0';
}

vector Node_HullMaxs(float hull)
{
    if (hull == HULL_SMALL) return '12 12 24';
    if (hull == HULL_LARGE) return '32 32 64';
    if (hull == HULL_FLY)   return '32 32 64';
    return '16 16 72';
}

float Monster_HullIndex(entity e)
{
    if (e.monster_capability & BITS_CAP_FLY) return HULL_FLY;
    if (e.maxs_x <= 12) return HULL_SMALL;
    if (e.maxs_x <= 16) return HULL_HUMAN;
    return HULL_LARGE;
}

// Every probe below used to trace a fixed 32x32x54 human. A narrower monster
// then read "blocked" where it fits, and a shorter one read "blocked" under
// every low ceiling. Trace the body that is actually moving; the raised floor
// is the step height, so a kerb is not an obstacle.
#define MONSTER_PROBE_STEP  18

vector Monster_ProbeMins()
{
    if (self.maxs_z <= 0) return '-16 -16 18';
    return [self.mins_x, self.mins_y, self.mins_z + MONSTER_PROBE_STEP];
}

vector Monster_ProbeMaxs()
{
    if (self.maxs_z <= 0) return '16 16 72';
    return self.maxs;
}

// `set sv_monsterdebug <entnum>` in the console traces that monster's
// locomotion to the developer log. Sampled once a second rather than per
// think: this sits in every monster's move path.
float g_monsterDebugEnt;
float g_monsterDebugNext;

// track is FALSE for a report that is not the think's final word (a rejected
// probe), so the stall counter measures thinks rather than reports.
void Monster_MoveDebug(string branch, float ok, float track)
{
    if (time >= g_monsterDebugNext)
    {
        g_monsterDebugNext = time + 1;
        g_monsterDebugEnt  = cvar("sv_monsterdebug");
    }
    if (!g_monsterDebugEnt) return;
    if (g_monsterDebugEnt != num_for_edict(self)) return;

    float moved = vlen(self.origin - self.m_dbgLastOrg);
    if (moved < 0.5) moved = 0;
    if (track)
    {
        self.m_dbgLastOrg = self.origin;
        if (moved < 2) self.m_dbgStall = self.m_dbgStall + 1;
        else self.m_dbgStall = 0;
    }

    float dgoal = 0;
    if (self.goalentity && self.goalentity != world)
        dgoal = vlen(self.origin - self.goalentity.origin);

    string line = strcat(branch, ok ? " ok" : " BLOCKED",
                         " moved ", ftos(rint(moved)),
                         " goal ", ftos(rint(dgoal)));
    line = strcat(line, " yaw ", ftos(rint(self.angles_y)),
                  "/", ftos(rint(self.ideal_yaw)),
                  " stall ", ftos(self.m_dbgStall), "\n");
    dprint(line);
}

float Monster_NodeType(entity e)
{
    if (e.monster_capability & BITS_CAP_FLY)  return NODE_REALM_AIR;
    if (e.monster_capability & BITS_CAP_SWIM) return NODE_REALM_WATER;
    return NODE_REALM_LAND;
}

float Node_Dist2D(vector a, vector b)
{
    vector d = a - b;
    d_z = 0;
    return vlen(d);
}
vector Node_Dir2D(vector a, vector b)
{
    vector d = a - b;
    d_z = 0;
    return normalize(d);
}

#define NODE_LINK_HEIGHT 32
string g_node_door;
float Node_TestVisible(vector a, vector b, entity ignore)
{
    g_node_door = "";

    vector ah = a + [0, 0, NODE_LINK_HEIGHT];
    vector bh = b + [0, 0, NODE_LINK_HEIGHT];

    traceline(ah, bh, MOVE_WORLDONLY_3, ignore);
    if (trace_fraction < 1.0)
        return FALSE;

    // The world-only trace skips doors, so trace again and remember any door on the link.
    traceline(ah, bh, TRUE, ignore);
    if (trace_fraction < 1.0 && trace_ent != world)
    {
        if (trace_ent.classname == "func_door" ||
            trace_ent.classname == "func_door_rotating")
            g_node_door = trace_ent.targetname;
    }
    return TRUE;
}

#define NODE_DOOR_USE_ONLY 256  // SF_DOOR_USE_ONLY; func_door.qc compiles after this file

// A door on a link is passable while it stands open, or when it is use-only and
// the monster can work it. A closed door that only a trigger moves is a wall:
// nothing in the locomotion code can open it, so routing through it strands the
// monster against it (hldemo1's CPU banks are func_door_rotating).
float Node_DoorLinkOpen(string doorName, float capmask)
{
    entity d = find(world, targetname, doorName);
    while (d)
    {
        if (d.classname == "func_door" || d.classname == "func_door_rotating")
        {
            if (d.state != STATE_TOP && d.solid != SOLID_NOT)
            {
                if (!(d.spawnflags & NODE_DOOR_USE_ONLY)) return FALSE;
                if (!(capmask & BITS_CAP_OPEN_DOORS))     return FALSE;
            }
        }
        d = find(d, targetname, doorName);
    }
    return TRUE;    // open, workable, or gone
}

float Node_TestWalk(vector a, vector b)
{
    setsize(self, '-16 -16 0', '16 16 72');
    setorigin(self, a);
    if (!droptofloor())
        return FALSE;

    float dist = Node_Dist2D(b, a);
    float guard = floor(dist / 16) + 8;
    while (Node_Dist2D(self.origin, b) > 24)
    {
        float yaw = vectoyaw(b - self.origin);
        if (!walkmove(yaw, 16))
            return FALSE;
        guard = guard - 1;
        if (guard <= 0)
            return FALSE;
    }
    return TRUE;
}

void NodeGraph_Build()
{
    float i, j, k;

    if (node_count <= 0)
    {
        dprint("NodeGraph_Build: no info_node entities in map.\n");
        return;
    }

    entity stemp = self;

    entity builder = spawn();
    builder.classname = "node_builder";
    builder.movetype  = MOVETYPE_STEP;
    builder.solid     = SOLID_SLIDEBOX;
    self = builder;

    entity e;
    for (e = nextent(world); e != world; e = nextent(e))
    {
        if (e == builder)
            continue;
        if (e.solid == SOLID_TRIGGER || e.solid == SOLID_BBOX ||
            e.solid == SOLID_SLIDEBOX)
        {
            e.node_savedsolid = e.solid;
            e.solid = SOLID_NOT;
        }
    }

    // Keep vector arrays in locals around builtins; fteqcc can scramble direct array arguments.
    for (i = 0; i < node_count; i = i + 1)
    {
        vector o = node_origin[i];

        if (node_realm[i] & NODE_REALM_AIR)
            continue;

        if (pointcontents(o) == CONTENT_WATER)
        {
            node_realm[i] = NODE_REALM_WATER;
            continue;
        }

        node_realm[i] = NODE_REALM_LAND;
        traceline(o, o - [0, 0, NODE_DROP_DIST], TRUE, builder);
        o = trace_endpos;
        o_z = o_z + NODE_HEIGHT;
        node_origin[i] = o;
    }
    dprint(strcat("  node[0] after classify = ", strcat(vtos(node_origin[0]), "\n")));

    link_count = 0;
    dbg_cand = 0;
    dbg_hull = 0;
    dbg_startsolid = 0;
    for (i = 0; i < node_count; i = i + 1)
    {
        scratch_n = 0;

        vector oi = node_origin[i];

        for (j = 0; j < node_count; j = j + 1)
        {
            if (j == i)
                continue;
            if (node_realm[i] != node_realm[j])
                continue;
            if (scratch_n >= NODE_INIT_LINKS)
                break;

            vector oj = node_origin[j];

            if (!Node_TestVisible(oi, oj, builder))
                continue;
            string door = g_node_door;
            dbg_cand = dbg_cand + 1;

            if (door == "")
            {
                if (!Node_TestWalk(oi, oj))
                    continue;
            }

            scratch_dest[scratch_n]   = j;
            scratch_door[scratch_n]   = (door != "") ? strzone(door) : "";
            scratch_weight[scratch_n] = Node_Dist2D(oj, oi);
            scratch_bits[scratch_n]   = LINK_SMALL | LINK_HUMAN | LINK_LARGE | LINK_FLY;
            scratch_n = scratch_n + 1;
            dbg_hull = dbg_hull + 1;
        }

        // When two links point the same way, keep the nearer one.
        for (j = 0; j < scratch_n; j = j + 1)
        {
            if (scratch_bits[j] < 0)
                continue;
            vector oj = node_origin[scratch_dest[j]];
            vector dirj = Node_Dir2D(oj, oi);
            for (k = 0; k < scratch_n; k = k + 1)
            {
                if (k == j || scratch_bits[k] < 0)
                    continue;
                vector ok = node_origin[scratch_dest[k]];
                vector dirk = Node_Dir2D(ok, oi);
                if ((dirj * dirk) >= 0.998 && scratch_weight[k] < scratch_weight[j])
                {
                    scratch_bits[j] = -1;
                    break;
                }
            }
        }

        node_firstlink[i] = link_count;
        float n = 0;
        for (j = 0; j < scratch_n; j = j + 1)
        {
            if (scratch_bits[j] < 0)
                continue;
            if (link_count >= NODE_LINK_MAX)
                break;
            link_dest[link_count]   = scratch_dest[j];
            link_bits[link_count]   = scratch_bits[j];
            link_weight[link_count] = scratch_weight[j];
            link_door[link_count]   = scratch_door[j];
            link_count = link_count + 1;
            n = n + 1;
        }
        node_numlinks[i] = n;
    }

    for (i = 0; i < node_count; i = i + 1)
    {
        if (node_realm[i] & NODE_REALM_LAND)
        {
            vector o = node_origin[i];
            o_z = o_z - NODE_HEIGHT;
            node_origin[i] = o;
        }
    }

    for (e = nextent(world); e != world; e = nextent(e))
    {
        if (e.node_savedsolid)
        {
            e.solid = e.node_savedsolid;
            e.node_savedsolid = 0;
        }
    }

    remove(builder);
    self = stemp;

    node_graph_present = TRUE;

    dprint("NodeGraph: built ");
    dprint(ftos(node_count));
    dprint(" nodes, ");
    dprint(ftos(dbg_cand));
    dprint(" LOS candidates, ");
    dprint(ftos(dbg_hull));
    dprint(" passed hull, ");
    dprint(ftos(link_count));
    dprint(" links.\n");

    NodeGraph_Save(mapname);
}

float NodeGraph_NearestNode(vector org, float realm)
{
    if (!node_graph_present)
        return -1;

    float best = -1;
    float bestd = NODE_BIG;
    float fallback = -1;
    float fbd = NODE_BIG;
    float i;
    for (i = 0; i < node_count; i = i + 1)
    {
        if (realm && node_realm[i] != realm)
            continue;
        vector no = node_origin[i];
        float d = vlen(org - no);
        if (d < fbd) { fbd = d; fallback = i; }
        if (d >= bestd)
            continue;
        traceline(org + '0 0 32', no + '0 0 32', TRUE, world);
        if (trace_fraction >= 1.0)
        {
            best = i;
            bestd = d;
        }
    }
    if (best >= 0)
        return best;
    if (fallback >= 0 && fbd < 512)
        return fallback;
    return -1;
}

float NodeGraph_FindPath(float start, float dest, float hull, float capmask)
{
    if (!node_graph_present)
        return 0;
    if (start < 0 || dest < 0 || start >= node_count || dest >= node_count)
        return 0;

    if (start == dest)
    {
        node_path[0] = start;
        return 1;
    }

    float hullbit = Node_HullBit(hull);
    float candoors = (capmask & NODE_CAP_DOORS);
    float i;

    for (i = 0; i < node_count; i = i + 1)
    {
        node_dist[i] = NODE_BIG;
        node_prev[i] = -1;
        node_done[i] = 0;
    }
    node_dist[start] = 0;

    while (TRUE)
    {
        float cur = -1;
        float curd = NODE_BIG;
        for (i = 0; i < node_count; i = i + 1)
        {
            if (!node_done[i] && node_dist[i] < curd)
            {
                curd = node_dist[i];
                cur = i;
            }
        }
        if (cur < 0 || curd >= NODE_BIG)
            break;
        if (cur == dest)
            break;

        node_done[cur] = 1;

        float li = node_firstlink[cur];
        float ln = node_numlinks[cur];
        float e;
        for (e = 0; e < ln; e = e + 1)
        {
            float idx = li + e;
            float to  = link_dest[idx];

            if ((link_bits[idx] & hullbit) != hullbit)
                continue;
            if (link_door[idx] != "")
            {
                if (!candoors) continue;
                if (!Node_DoorLinkOpen(link_door[idx], capmask)) continue;
            }

            float nd = node_dist[cur] + link_weight[idx];
            if (nd < node_dist[to])
            {
                node_dist[to] = nd;
                node_prev[to] = cur;
            }
        }
    }

    if (node_dist[dest] >= NODE_BIG)
        return 0;

    float count = 1;
    float c = dest;
    while (c != start)
    {
        count = count + 1;
        c = node_prev[c];
        if (c < 0)
            return 0;
    }

    c = dest;
    for (i = count - 1; i >= 0; i = i - 1)
    {
        node_path[i] = c;
        c = node_prev[c];
    }
    return count;
}

void NodeGraph_TreeFrom(float src, float hull, float capmask)
{
    if (!node_graph_present || src < 0 || src >= node_count)
        return;

    float hullbit  = Node_HullBit(hull);
    float candoors = (capmask & NODE_CAP_DOORS);
    float i;
    for (i = 0; i < node_count; i = i + 1)
    {
        node_dist[i] = NODE_BIG;
        node_prev[i] = -1;
        node_done[i] = 0;
    }
    node_dist[src] = 0;

    while (TRUE)
    {
        float cur = -1;
        float curd = NODE_BIG;
        for (i = 0; i < node_count; i = i + 1)
            if (!node_done[i] && node_dist[i] < curd) { curd = node_dist[i]; cur = i; }
        if (cur < 0 || curd >= NODE_BIG)
            break;

        node_done[cur] = 1;
        float li = node_firstlink[cur];
        float ln = node_numlinks[cur];
        float e;
        for (e = 0; e < ln; e = e + 1)
        {
            float idx = li + e;
            float to  = link_dest[idx];
            if ((link_bits[idx] & hullbit) != hullbit)
                continue;
            if (link_door[idx] != "")
            {
                if (!candoors) continue;
                if (!Node_DoorLinkOpen(link_door[idx], capmask)) continue;
            }
            float nd = node_dist[cur] + link_weight[idx];
            if (nd < node_dist[to])
            {
                node_dist[to] = nd;
                node_prev[to] = cur;
            }
        }
    }
}

float NodeGraph_FindCover(vector threatOrg, vector fromOrg, float maxdist, float realm)
{
    if (!node_graph_present)
        return -1;

    float best = -1;
    float bestscore = -NODE_BIG;
    float i;
    for (i = 0; i < node_count; i = i + 1)
    {
        if (realm && node_realm[i] != realm)
            continue;
        vector no = node_origin[i];
        float d = vlen(fromOrg - no);
        if (d > maxdist)
            continue;

        traceline(threatOrg, no + [0, 0, NODE_HEIGHT], TRUE, world);
        if (trace_fraction >= 1.0)
            continue;

        float score = maxdist - d;
        if (node_hinttype[i] == HINT_TACTICAL_EXIT ||
            node_hinttype[i] == HINT_TACTICAL_VANTAGE ||
            node_hinttype[i] == HINT_TACTICAL_AMBUSH)
            score = score + maxdist;

        if (score > bestscore)
        {
            bestscore = score;
            best = i;
        }
    }
    return best;
}

string NodeGraph_Filename(string map)
{
    return strcat("maps/graphs/", strcat(map, ".llnod"));
}

void NodeGraph_Save(string map)
{
    if (link_count <= 0)
    {
        dprint("NodeGraph_Save: 0 links, not caching.\n");
        return;
    }

    float fh = fopen(NodeGraph_Filename(map), FILE_WRITE);
    if (fh < 0)
    {
        dprint("NodeGraph_Save: cannot open file (graph kept in memory).\n");
        return;
    }

    // magic version nodecount linkcount checksum
    fputs(fh, strcat("LL_NODEGRAPH ", strcat(ftos(NODE_GRAPH_VERSION),
          strcat(" ", strcat(ftos(node_count),
          strcat(" ", strcat(ftos(link_count),
          strcat(" ", strcat(ftos(NodeGraph_PlacedChecksum()), "\n")))))))));

    float i;
    for (i = 0; i < node_count; i = i + 1)
    {
        vector o = node_origin[i];
        string ln = "N ";
        ln = strcat(ln, strcat(ftos(o_x), " "));
        ln = strcat(ln, strcat(ftos(o_y), " "));
        ln = strcat(ln, strcat(ftos(o_z), " "));
        ln = strcat(ln, strcat(ftos(node_realm[i]), " "));
        ln = strcat(ln, strcat(ftos(node_hinttype[i]), " "));
        ln = strcat(ln, strcat(ftos(node_hintact[i]), " "));
        ln = strcat(ln, strcat(ftos(node_hintyaw[i]), " "));
        ln = strcat(ln, strcat(ftos(node_firstlink[i]), " "));
        ln = strcat(ln, strcat(ftos(node_numlinks[i]), "\n"));
        fputs(fh, ln);
    }

    for (i = 0; i < link_count; i = i + 1)
    {
        string door = link_door[i];
        if (door == "")
            door = "-";
        string ln = "L ";
        ln = strcat(ln, strcat(ftos(link_dest[i]), " "));
        ln = strcat(ln, strcat(ftos(link_bits[i]), " "));
        ln = strcat(ln, strcat(ftos(link_weight[i]), " "));
        ln = strcat(ln, strcat(door, "\n"));
        fputs(fh, ln);
    }

    fclose(fh);
    dprint("NodeGraph: saved ");
    dprint(NodeGraph_Filename(map));
    dprint("\n");
}

float NodeGraph_Load(string map)
{
    float fh = fopen(NodeGraph_Filename(map), FILE_READ);
    if (fh < 0)
        return FALSE;

    string line = fgets(fh);
    float n = tokenize(line);
    if (n < 5 || argv(0) != "LL_NODEGRAPH" || stof(argv(1)) != NODE_GRAPH_VERSION)
    {
        fclose(fh);
        return FALSE;
    }

    node_count = stof(argv(2));
    link_count = stof(argv(3));
    node_cache_checksum = stof(argv(4));

    if (link_count <= 0)
    {
        fclose(fh);
        node_count = 0;
        return FALSE;
    }

    float ni = 0, lj = 0;
    while ((line = fgets(fh)))
    {
        if (line == "")
            continue;
        n = tokenize(line);
        if (n < 1)
            continue;

        if (argv(0) == "N" && n >= 10 && ni < NODE_MAX)
        {
            node_origin[ni]   = [stof(argv(1)), stof(argv(2)), stof(argv(3))];
            node_realm[ni]    = stof(argv(4));
            node_hinttype[ni] = stof(argv(5));
            node_hintact[ni]  = stof(argv(6));
            node_hintyaw[ni]  = stof(argv(7));
            node_firstlink[ni]= stof(argv(8));
            node_numlinks[ni] = stof(argv(9));
            ni = ni + 1;
        }
        else if (argv(0) == "L" && n >= 5 && lj < NODE_LINK_MAX)
        {
            link_dest[lj]   = stof(argv(1));
            link_bits[lj]   = stof(argv(2));
            link_weight[lj] = stof(argv(3));
            link_door[lj]   = (argv(4) == "-") ? "" : strzone(argv(4));
            lj = lj + 1;
        }
    }
    fclose(fh);

    node_graph_present = TRUE;
    dprint("NodeGraph: loaded ");
    dprint(ftos(node_count));
    dprint(" nodes, ");
    dprint(ftos(link_count));
    dprint(" links from cache.\n");
    return TRUE;
}


float Monster_RouteTo(vector dest)
{
    if (!node_graph_present)
        return FALSE;

    float realm  = Monster_NodeType(self);
    float startn = NodeGraph_NearestNode(self.origin, realm);
    float goaln  = NodeGraph_NearestNode(dest, realm);
    if (startn < 0 || goaln < 0)
    {
        dprint("NodeRoute: no nearby node (place info_node ents in the map)\n");
        return FALSE;
    }

    if (startn == goaln)
    {
        dprint("NodeRoute: goal shares our nearest node -- local movement only\n");
        return FALSE;
    }

    float cnt = NodeGraph_FindPath(startn, goaln,
                                   Monster_HullIndex(self), self.monster_capability);
    if (cnt < 2)
    {
        dprint("NodeRoute: no path between nodes\n");
        return FALSE;
    }

    self.m_iGoalNode    = goaln;
    self.m_iRouteNode   = node_path[1];
    self.monster_movementGoal = MOVEGOAL_NODE;
    self.m_slideUntil   = 0;
    self.m_lastStuckOrg = self.origin;
    self.m_stuckTime    = time + 0.6;
    if (self.goalentity && self.goalentity != self.m_nodeMarker)
        self.m_routeRealGoal = self.goalentity;
    dprint(strcat("NodeRoute: routing ", strcat(ftos(cnt), " hops\n")));
    return TRUE;
}

void Monster_AdvanceRoute(float dist)
{
    if (self.goalentity == self.m_nodeMarker)
    {
        if (self.m_routeRealGoal && !wasfreed(self.m_routeRealGoal))
            self.goalentity = self.m_routeRealGoal;
        else
            self.goalentity = world;
    }

    if (!node_graph_present ||
        self.m_iRouteNode < 0 || self.m_iRouteNode >= node_count)
    {
        self.monster_movementGoal = MOVEGOAL_NONE;
        return;
    }

    if (self.goalentity && self.goalentity != world)
    {
        tracebox(self.origin, Monster_ProbeMins(), Monster_ProbeMaxs(),
                 self.goalentity.origin, TRUE, self);
        if (trace_fraction >= 1.0)
        {
            self.monster_movementGoal = MOVEGOAL_NONE;
            vector gorg = self.goalentity.origin;
            if (!Monster_DirectStep(gorg, dist))
                movetogoal(dist);
            return;
        }
    }

    vector ntarget = node_origin[self.m_iRouteNode];

    if (Node_Dist2D(self.origin, ntarget) <= 32)
    {
        if (self.m_iRouteNode == self.m_iGoalNode)
        {
            self.monster_movementGoal = MOVEGOAL_NONE;
            return;
        }
        float cnt = NodeGraph_FindPath(self.m_iRouteNode, self.m_iGoalNode,
                                       Monster_HullIndex(self), self.monster_capability);
        if (cnt < 2)
        {
            self.monster_movementGoal = MOVEGOAL_NONE;
            return;
        }
        self.m_iRouteNode = node_path[1];
        ntarget = node_origin[self.m_iRouteNode];
    }

    if (time >= self.m_stuckTime)
    {
        self.m_stuckTime = time + 0.5;
        if (vlen(self.origin - self.m_lastStuckOrg) < 8)
        {
            float nn = NodeGraph_NearestNode(self.origin, Monster_NodeType(self));
            if (nn >= 0 && nn != self.m_iGoalNode)
            {
                float rc = NodeGraph_FindPath(nn, self.m_iGoalNode,
                                              Monster_HullIndex(self), self.monster_capability);
                if (rc >= 2)
                {
                    self.m_iRouteNode = node_path[1];
                    ntarget = node_origin[self.m_iRouteNode];
                }
                else { self.monster_movementGoal = MOVEGOAL_NONE; return; }
            }
            else { self.monster_movementGoal = MOVEGOAL_NONE; return; }
        }
        self.m_lastStuckOrg = self.origin;
    }

    if (!self.m_nodeMarker)
    {
        entity mk = spawn();
        mk.classname = "node_goalmarker";
        mk.solid     = SOLID_NOT;
        mk.movetype  = MOVETYPE_NONE;
        mk.owner     = self;
        self.m_nodeMarker = mk;
    }
    setorigin(self.m_nodeMarker, ntarget);
    self.goalentity = self.m_nodeMarker;
    // movetogoal backs out while the yaw error is over 45 degrees.
    if (!Monster_DirectStep(ntarget, dist))
        movetogoal(dist);
}

float Monster_TakeCover(entity threat)
{
    if (!node_graph_present || !threat || threat == world)
        return FALSE;
    float realm = Monster_NodeType(self);
    float ci = NodeGraph_FindCover(threat.origin, self.origin, 1024, realm);
    if (ci < 0)
        return FALSE;
    vector co = node_origin[ci];
    return Monster_RouteTo(co);
}

// Sliding changes movement direction, but monsters should still face their enemy.
void Monster_SlideFace(float slideYaw)
{
    if (self.enemy && self.enemy != world && self.enemy.health > 0)
        self.ideal_yaw = vectoyaw(self.enemy.origin - self.origin);
    else
        self.ideal_yaw = slideYaw;
    ChangeYaw();
}


// The slide is a nudge that peels a monster off a wall, not a movement mode.
// Left to run it travels 128 units sideways, loses ground it had already made,
// and re-arms on the first good movetogoal tick after it, which is an orbit,
// not a chase. Three bounds hold it: a short window, an abort once it is
// losing ground, and a cooldown before another can start.
#define MONSTER_SLIDE_TIME   0.4
#define MONSTER_SLIDE_DRIFT  32
#define MONSTER_SLIDE_COOL   0.5

// A slide leaves the stuck sampler holding an origin and a goal distance from
// before it started, so the first ordinary tick after one would compare across
// the whole slide and re-trigger immediately. Rearm the window instead.
void Monster_SlideEnd()
{
    self.m_slideUntil   = 0;
    self.m_slideCool    = time + MONSTER_SLIDE_COOL;
    self.m_lastStuckOrg = self.origin;
    self.m_stuckDist    = 0;
    self.m_stuckTime    = time + 0.3;
}

float Monster_WallSlide(vector goal, float dist)
{
    vector dir = goal - self.origin;
    dir_z = 0;
    if (vlen(dir) < 1)
        return FALSE;
    dir = normalize(dir);

    tracebox(self.origin, Monster_ProbeMins(), Monster_ProbeMaxs(),
             self.origin + dir * 48, TRUE, self);
    if (trace_fraction >= 1.0)
        return FALSE;
    vector n = trace_plane_normal;
    n_z = 0;
    if (vlen(n) < 0.5)
        return FALSE;
    n = normalize(n);

    vector slide = dir - n * (dir * n);
    if (vlen(slide) < 0.2)
    {
        slide = [0 - n_y, n_x, 0];
        if (self.lefty)
            slide = slide * -1;
    }
    slide = normalize(slide);

    float yaw = vectoyaw(slide);
    if (!walkmove(yaw, dist))
    {
        yaw = yaw + 180;
        self.lefty = 1 - self.lefty;
        if (!walkmove(yaw, dist))
            return FALSE;
    }

    self.m_slideYaw      = yaw;
    self.m_slideUntil    = time + MONSTER_SLIDE_TIME;
    self.m_slideGoalDist = vlen(self.origin - goal);
    self.m_lastStuckOrg  = self.origin;
    self.m_stuckDist     = 0;
    self.m_stuckTime     = time + 0.3;
    Monster_SlideFace(yaw);
    return TRUE;
}

float Monster_SlideStep(float dist)
{
    if (!self.m_slideUntil)
        return FALSE;
    if (time >= self.m_slideUntil)
    {
        Monster_SlideEnd();
        return FALSE;
    }

    if (self.goalentity && self.goalentity != world)
    {
        float dgoal = vlen(self.origin - self.goalentity.origin);
        if (dgoal > self.m_slideGoalDist + MONSTER_SLIDE_DRIFT)
        {
            Monster_SlideEnd();
            return FALSE;
        }
        if (dgoal < self.m_slideGoalDist)
            self.m_slideGoalDist = dgoal;

        tracebox(self.origin, Monster_ProbeMins(), Monster_ProbeMaxs(),
                 self.goalentity.origin, TRUE, self);
        if (trace_fraction >= 1.0)
        {
            Monster_SlideEnd();
            return FALSE;
        }
    }

    if (!walkmove(self.m_slideYaw, dist))
    {
        self.m_slideUntil = 0;
        if (self.goalentity && self.goalentity != world)
            return Monster_WallSlide(self.goalentity.origin, dist);
        Monster_SlideEnd();
        return FALSE;
    }
    Monster_SlideFace(self.m_slideYaw);
    return TRUE;
}

// The straight-line step, for open ground only. It exists because movetogoal
// backs out while the yaw error is over 45 degrees, which reads as hesitation
// in the open.
//
// It must NOT be taken toward a blocked heading. ideal_yaw is the state
// SV_NewChaseDir uses to remember the detour it picked, so writing it every
// tick makes the engine re-decide from scratch at every corner and the monster
// oscillates instead of rounding it. A blocked probe therefore returns FALSE
// with ideal_yaw untouched and lets the caller fall through to movetogoal.
float Monster_DirectStep(vector goalorg, float dist)
{
    vector dir = goalorg - self.origin;
    dir_z = 0;
    if (vlen(dir) < 1)
        return TRUE;
    dir = normalize(dir);

    float reach = dist * 4;
    if (reach < 32) reach = 32;
    tracebox(self.origin, Monster_ProbeMins(), Monster_ProbeMaxs(),
             self.origin + dir * reach, TRUE, self);
    if (trace_fraction < 1.0)
    {
        Monster_MoveDebug("DIRECT", FALSE, FALSE);
        return FALSE;
    }

    float yaw = vectoyaw(dir);
    self.ideal_yaw = yaw;
    ChangeYaw();
    float ok = walkmove(yaw, dist);
    Monster_MoveDebug("DIRECT", ok, TRUE);
    return ok;
}

// The wall slide half of this works without a graph, and a graphless map is
// exactly where a monster has no other recovery at all.
void Monster_StuckCheck(float dist)
{
    if (!self.goalentity || self.goalentity == world)
        return;
    if (time < self.m_stuckTime)
        return;
    self.m_stuckTime = time + 0.3;

    float dgoal = vlen(self.origin - self.goalentity.origin);

    if (dgoal < 80)
    {
        self.m_stuckDist = 0;
        self.m_lastStuckOrg = self.origin;
        return;
    }

    float moved = vlen(self.origin - self.m_lastStuckOrg);
    self.m_lastStuckOrg = self.origin;
    float prevd = self.m_stuckDist;
    self.m_stuckDist = dgoal;
    if (prevd <= 0)
        return;

    float approached = prevd - dgoal;
    if (moved < 12 || approached < moved * 0.5)
    {
        Monster_MoveDebug("STUCK", FALSE, FALSE);
        if (node_graph_present)
        {
            if (Monster_RouteTo(self.goalentity.origin))
                return;
        }
        if (time < self.m_slideCool)
            return;
        Monster_WallSlide(self.goalentity.origin, dist);
    }
}

float Monster_ProactiveRoute(vector dest)
{
    if (!node_graph_present)
        return FALSE;
    if (time < self.m_reachCheckTime)
        return FALSE;
    self.m_reachCheckTime = time + 0.4;
    if (vlen(self.origin - dest) <= 96)
        return FALSE;
    tracebox(self.origin, Monster_ProbeMins(), Monster_ProbeMaxs(), dest, TRUE, self);
    if (trace_fraction >= 1.0)
        return FALSE;
    return Monster_RouteTo(dest);
}

void Monster_MoveToward(entity goal, float dist)
{
    self.goalentity = goal;
    if (self.monster_movementGoal == MOVEGOAL_NODE)
    {
        Monster_AdvanceRoute(dist);
        return;
    }
    if (Monster_SlideStep(dist))
        return;
    if (goal && goal != world && Monster_ProactiveRoute(goal.origin))
    {
        Monster_AdvanceRoute(dist);
        return;
    }
    if (goal && goal != world && Monster_DirectStep(goal.origin, dist))
        return;
    movetogoal(dist);
    Monster_StuckCheck(dist);
}

float NodeGraph_PlacedChecksum()
{
    float s = placed_count * 100000;
    float i;
    for (i = 0; i < placed_count; i = i + 1)
    {
        vector o = placed_origin[i];
        s = s + floor(o_x) * 3 + floor(o_y) * 5 + floor(o_z) * 7
              + placed_realm[i];
    }
    return s;
}

void NodeGraph_RebuildFromPlaced()
{
    dprint(strcat("NodeGraph: rebuild from ", strcat(ftos(placed_count),
           " placed nodes\n")));
    if (placed_count > 0)
        dprint(strcat("  placed[0] = ", strcat(vtos(placed_origin[0]), "\n")));
    if (placed_count > 1)
        dprint(strcat("  placed[1] = ", strcat(vtos(placed_origin[1]), "\n")));

    node_graph_present = FALSE;
    node_count = placed_count;
    float i;
    for (i = 0; i < placed_count; i = i + 1)
    {
        node_origin[i]   = placed_origin[i];
        node_realm[i]    = placed_realm[i];
        node_hinttype[i] = placed_hinttype[i];
        node_hintact[i]  = placed_hintact[i];
        node_hintyaw[i]  = placed_hintyaw[i];
    }
    if (node_count > 0)
        dprint(strcat("  node[0] after copy = ", strcat(vtos(node_origin[0]), "\n")));
    NodeGraph_Build();
}

void NodeGraph_FrameCheck()
{
    if (node_built)
        return;

    if (node_graph_present)
    {
        node_built = TRUE;
        dprint(strcat("NodeGraph: using loaded graph (", strcat(ftos(node_count),
               strcat(" nodes, ", strcat(ftos(link_count), " links).\n")))));
        return;
    }

    if (placed_count <= 0)
        return;
    node_built = TRUE;
    NodeGraph_RebuildFromPlaced();
}

void NodeGraph_Init()
{
    node_count = 0;
    link_count = 0;
    placed_count = 0;
    node_graph_present = FALSE;
    node_built = FALSE;
    node_cache_checksum = 0;
    NodeGraph_Load(mapname);
}
