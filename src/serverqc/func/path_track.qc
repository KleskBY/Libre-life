#define SF_PATH_DISABLED		0x00000001
#define SF_PATH_FIREONCE		0x00000002
#define SF_PATH_ALTREVERSE		0x00000004
#define SF_PATH_DISABLE_TRAIN	0x00000008
#define SF_PATH_ALTERNATE		0x00008000

#define SF_CORNER_WAITFORTRIG	0x001
#define SF_CORNER_TELEPORT		0x002
#define SF_CORNER_FIREONCE		0x004

#define SF_TRACKTRAIN_NOPITCH		0x0001
#define SF_TRACKTRAIN_NOCONTROL		0x0002
#define SF_TRACKTRAIN_FORWARDONLY	0x0004
#define SF_TRACKTRAIN_PASSABLE		0x0008

.entity pathtrack_next;
.entity pathtrack_prev;
.entity pathtrack_altPath;
.string altpath;	// alternative path name

// Cached length, computed on demand
.float pathtrack_length;

// result "out parameter" for LookAhead/Project
vector pathtrack_lookahead_origin;


entity PathTrack_Instance(entity pent)
{ 
	if (pent.classname ==  "path_track")
	{
		return pent;
	}
	return world;
}

entity(entity ppath, float testFlag) PathTrack_ValidPath =
{
    if (!ppath) 
		return world;

    if (testFlag && (ppath.spawnflags & SF_PATH_DISABLED))
        return world;

    return ppath;
};

entity PathTrack_GetNext(entity p)
{
    if (p.pathtrack_altPath && (p.spawnflags & SF_PATH_ALTERNATE) && !(p.spawnflags & SF_PATH_ALTREVERSE))
        return p.pathtrack_altPath;

    return p.pathtrack_next;
}

entity PathTrack_GetPrevious(entity p)
{
    if (p.pathtrack_altPath && (p.spawnflags & SF_PATH_ALTERNATE) && (p.spawnflags & SF_PATH_ALTREVERSE))
        return p.pathtrack_altPath;

    return p.pathtrack_prev;
}

void PathTrack_SetPrevious(entity p, entity pprev)
{
	if (pprev && !(pprev.targetname == p.altpath))
		p.pathtrack_prev = pprev;
};

// Projects past end point by remaining distance (when move==0)
void PathTrack_Project(entity pstart, entity pend, float dist)
{
    if (pstart && pend)
	{
		vector dir = normalize(pend.origin - pstart.origin);
		pathtrack_lookahead_origin = pend.origin + dir * dist;
	}
};


void() PathTrack_Link =
{
	entity pentTarget;
	if (self.target)
	{
		pentTarget = find(world, targetname, self.target);
		if(pentTarget)
		{
			self.pathtrack_next = PathTrack_Instance(pentTarget);
			if (self.pathtrack_next)
			{
				PathTrack_SetPrevious(self.pathtrack_next, self);
			}
		}
		else 
		{
			dprint("Dead end link ");
			dprint(self.target);
			dprint("\n");
		}
	}

	if (self.altpath)
	{
		pentTarget =  find(world, targetname, self.altpath);
		if (pentTarget)
		{
			self.pathtrack_altPath = PathTrack_Instance(pentTarget);
			if (self.pathtrack_altPath)
			{
				PathTrack_SetPrevious(self.pathtrack_altPath, self);
			}
		}
	}

	/*
    entity t;

    // clear
    self.pathtrack_next = world;
    self.pathtrack_prev = world;
    self.pathtrack_altPath = world;

    // link next via "target"
    if (self.target != "")
    {
        t = find(world, targetname, self.target);
        if (t != world && t.classname == "path_track")
        {
            self.pathtrack_next = t;
            // back-link
            PathTrack_SetPrevious(t, self);
        }
        else
        {
            // dead end (optional debug)
            // dprint("path_track dead end link: ", self.target, "\n");
        }
    }

    // link alternate via "altpath"
    if (self.altpath != "")
    {
        t = find(world, targetname, self.altpath);
        if (t != world && t.classname == "path_track")
        {
            self.pathtrack_altPath = t;
            PathTrack_SetPrevious(t, oldself);
        }
    }
	*/
};

void() PathTrack_LinkThink =
{
    // Only link named nodes
    if (self.targetname)
        PathTrack_Link();

    self.think = SUB_Null;
    self.nextthink = -1;
};

// Resolve all named node links immediately
// per-node LinkThink. A level-transition train restore needs the path graph
// before the first frame runs; Link() is pure assignment from find(), so
// running it early - or twice - changes nothing.
void() PathTrack_LinkAll =
{
    entity oself = self;
    for (entity p = find(world, classname, "path_track"); p; p = find(p, classname, "path_track"))
    {
        if (p.targetname)
        {
            self = p;
            PathTrack_Link();
            self.think = SUB_Null;
            self.nextthink = -1;
        }
    }
    self = oself;
};

void() PathTrack_Use =
{
    float on;

    // if there is an alternate path, USE toggles alternate routing.
    if (self.pathtrack_altPath != world)
    {
        on = !(self.spawnflags & SF_PATH_ALTERNATE);
        if (on) self.spawnflags |= SF_PATH_ALTERNATE;
        else    self.spawnflags &= ~SF_PATH_ALTERNATE;
        return;
    }

    on = !(self.spawnflags & SF_PATH_DISABLED);

    if (on) self.spawnflags |= SF_PATH_DISABLED;
    else    self.spawnflags &= ~SF_PATH_DISABLED;
};

void PathTrack_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
    float on;

    if (self.pathtrack_altPath != world)
    {
        on = !(self.spawnflags & SF_PATH_ALTERNATE);
        if (on) self.spawnflags |= SF_PATH_ALTERNATE;
        else    self.spawnflags &= ~SF_PATH_ALTERNATE;
        return;
    }

    on = !(self.spawnflags & SF_PATH_DISABLED);
    if (on) self.spawnflags |= SF_PATH_DISABLED;
    else    self.spawnflags &= ~SF_PATH_DISABLED;
}


/*
entity PathTrack_LookAhead3(entity this, vector org, float dist, float move)
{
	entity pcurrent;
	float originalDist = dist;
	
	pcurrent = this;
	vector currentPos = org;
	pathtrack_lookahead_origin = org;

	if (dist < 0)		// Travelling backwards through path
	{
		dist = -dist;
		while (dist > 0)
		{
			vector dir = pcurrent.origin - currentPos;
			float length = vlen(dir);
			if (!length)
			{
				if (!PathTrack_ValidPath(PathTrack_GetPrevious(pcurrent), move))	// If no previous node or it's disabled, return now
				{
					if (!move)
						PathTrack_Project(PathTrack_GetNext(pcurrent), pcurrent, dist);
					return world;
				}
				pcurrent = PathTrack_GetPrevious(pcurrent);
			}
			else if (length > dist)	// enough left in this path to move
			{
				pathtrack_lookahead_origin = currentPos + (dir * (dist / length));
				return pcurrent;
			}
			else
			{
				dist -= length;
				currentPos = pcurrent.origin;
				pathtrack_lookahead_origin = currentPos;
				if (!PathTrack_ValidPath(PathTrack_GetPrevious(pcurrent), move))	// If no previous node or it's disabled, return now
					return world;

				pcurrent = PathTrack_GetPrevious(pcurrent);
			}
		}
		pathtrack_lookahead_origin = currentPos;
		return pcurrent;
	}
	else 
	{
		while (dist > 0)
		{
			if (!PathTrack_ValidPath(PathTrack_GetNext(pcurrent), move))	// If no next node or it's disabled, return now
			{
				if (!move)
					PathTrack_Project(PathTrack_GetPrevious(pcurrent), pcurrent, dist);
				return world;
			}
			vector dir = PathTrack_GetNext(pcurrent).origin - currentPos;
			float length = vlen(dir);
			
			if (!length && !PathTrack_ValidPath(PathTrack_GetNext(PathTrack_GetNext(pcurrent)), move))
			{
				if (dist == originalDist)	// Check for dead end
					return world;
				return pcurrent;
			}
			if (length > dist)	// enough left in this path to move
			{
				pathtrack_lookahead_origin = currentPos + (dir * (dist / length));
				return pcurrent;
			}
			else
			{
				dist -= length;
				currentPos = PathTrack_GetNext(pcurrent).origin;
				pcurrent = PathTrack_GetNext(pcurrent);
				pathtrack_lookahead_origin = currentPos;
			}
		}
		pathtrack_lookahead_origin = currentPos;
	}

	return pcurrent;
}
*/

entity PathTrack_LookAhead(entity pcurrent, vector org, float dist, float move)
{
    float originalDist = dist;
	vector currentPos = org;
	vector dir;
	float len;

    pathtrack_lookahead_origin = org;

    if (dist < 0)
    {
        dist = -dist;
        while (dist > 0)
        {
            dir = pcurrent.origin - currentPos;
            len = vlen(dir);
            if (!len)
            {
                if (!PathTrack_ValidPath(PathTrack_GetPrevious(pcurrent), move))
                {
                    if (!move) PathTrack_Project(PathTrack_GetNext(pcurrent), pcurrent, dist);
                    return world;
                }
                pcurrent = PathTrack_GetPrevious(pcurrent);
                continue;
            }
            else if (len > dist)
            {
                pathtrack_lookahead_origin = currentPos + dir * (dist / len);
                return pcurrent;
            }
			else
			{
				dist -= len;
				currentPos = pcurrent.origin;
				pathtrack_lookahead_origin = currentPos;

				if(!PathTrack_ValidPath(PathTrack_GetPrevious(pcurrent), move))
					return world;
				
				pcurrent = PathTrack_GetPrevious(pcurrent);
			}
        }
        pathtrack_lookahead_origin = currentPos;
        return pcurrent;
    }
	else
	{
		while (dist > 0) // forwards
		{
			if(!PathTrack_ValidPath(PathTrack_GetNext(pcurrent), move))
			{
				if(!move) PathTrack_Project(PathTrack_GetPrevious(pcurrent), pcurrent, dist);
				return world;
			}
			

			dir = PathTrack_GetNext(pcurrent).origin - currentPos;
			len = vlen(dir);
			// special dead-end handling
			if (!len && !PathTrack_ValidPath(PathTrack_GetNext(PathTrack_GetNext(pcurrent)), move))
			{
				if (dist == originalDist)
					return world; // up against dead end
				return pcurrent;
			}
			if (len > dist)
			{
				pathtrack_lookahead_origin = currentPos + dir * (dist / len);
				return pcurrent;
			}
			else
			{
				dist -= len;
				currentPos = PathTrack_GetNext(pcurrent).origin;
				pcurrent = PathTrack_GetNext(pcurrent);
				pathtrack_lookahead_origin = currentPos;
			}
		}
		pathtrack_lookahead_origin = currentPos;
	}

    return pcurrent;
};

entity PathTrack_Nearest(entity p, vector org)
{
	float dist;	
	vector delta = org - p.origin;
	delta_z = 0;
	float minDist = vlen(delta);
	entity pnearest = p;
	entity ppath = PathTrack_GetNext(p);
	
	float deadCount = 0;
	while (ppath && ppath != p)
	{
		deadCount++;
		if (deadCount > 9999)
		{
			dprint("Bad sequence of path_tracks from ");
			dprint(p.targetname);
			dprint("\n");
			return world;
		}
		delta = org - ppath.origin;
		delta_z = 0;
		dist = vlen(delta);
		if(dist < minDist)
		{
			minDist = dist;
			pnearest = ppath;
		}
		ppath = PathTrack_GetNext(ppath);
	}
	return pnearest;
	

};


void() path_track =
{
    self.solid = SOLID_TRIGGER;
    self.movetype = MOVETYPE_NONE;
    setsize(self, '-8 -8 -8', '8 8 8');

    self.pathtrack_next = world;
    self.pathtrack_prev = world;
    self.pathtrack_altPath = world;

    self.use = PathTrack_Use;
    self.usehl = PathTrack_UseHL;

    // Delay linking until after spawn so target nodes exist.
    self.think = PathTrack_LinkThink;
    self.nextthink = time + 0.1;
};
