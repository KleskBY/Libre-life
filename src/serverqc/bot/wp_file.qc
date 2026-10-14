// The per map waypoint cache, maps/bnav/<mapname>.bnav.
//
// Plain text, one record per line, so a bad link can be found and fixed by hand:
//
//   BOT_BNAV <version> <fingerprint> <nodes>
//   n <x> <y> <z> <flags>
//   l <from> <to> <type> <flags> <failures> <entity model or ->
//   end
//
// A file without the closing `end` was cut off mid save and is regenerated rather
// than trusted: the header alone says nothing about whether the rest arrived.
//
// FILE_WRITE lands under <gamedir>/data/, and FILE_READ looks there first.
//
// Link entities are stored by brush model name ("*12"), never by edict number:
// map entities are numbered after the client slots, so the number moves whenever
// maxclients does.
//
// The fingerprint is a crc16 over the map name, the world surface count and a
// stride of surface vertices. A recompiled map fails it and regenerates.

#define WP_FILE_VERSION   3
#define WP_KEEP_FLAGS     (WPN_EDITED | WPN_HUMAN | WPN_ISLAND | WPN_ORPHAN | WPN_SEED)

nosave entity wpf_byId[WP_MAX];   // only used while loading
float wpf_fingerprint;

string WP_FileName()
{
	return strcat("maps/bnav/", mapname, ".bnav");
}

float WP_Fingerprint()
{
	if (wpf_fingerprint) return wpf_fingerprint;

	float count = 0;
	float sum = 0;
	while (count < 200000)
	{
		if (getsurfacenumpoints(world, count) <= 0) break;
		if (count - floor(count / 97) * 97 == 0)
		{
			vector p = getsurfacepoint(world, count, 0);
			sum = sum + floor(p_x) + floor(p_y) * 3 + floor(p_z) * 7;
			sum = sum - floor(sum / 1000000) * 1000000;
		}
		count = count + 1;
	}

	wpf_fingerprint = crc16(FALSE, strcat(mapname, " ", ftos(count), " ", ftos(sum))) + 1;
	return wpf_fingerprint;
}

float WP_EntByModel(string mdl)
{
	for (entity e = nextent(world); e; e = nextent(e))
		if (e.model == mdl) return num_for_edict(e);
	return -1;
}

void WP_Save()
{
	float fh = fopen(WP_FileName(), FILE_WRITE);
	if (fh < 0)
	{
		dprint(strcat("waypoints: cannot write ", WP_FileName(), "\n"));
		return;
	}

	float live = 0;
	for (entity n = wp_first; n; n = n.wp_allNext)
	{
		if (n.wp_flags & WPN_DEAD) { n.wp_id = -1; continue; }
		n.wp_id = live;
		live = live + 1;
	}

	fputs(fh, strcat("BOT_BNAV ", ftos(WP_FILE_VERSION), " ", ftos(WP_Fingerprint()), " ", ftos(live), "\n"));

	// One pass in list order, which is id order: the loader numbers nodes by the
	// order it reads them, so the ids line up whatever order the list is in.
	// Searching for each id in turn instead is quadratic, and at a few thousand
	// nodes that alone hits the runaway limit.
	for (entity m = wp_first; m; m = m.wp_allNext)
	{
		if (m.wp_id < 0) continue;
		fputs(fh, strcat("n ", ftos(rint(m.origin_x)), " ", ftos(rint(m.origin_y)), " "));
		fputs(fh, strcat(ftos(rint(m.origin_z)), " ", ftos(m.wp_flags & WP_KEEP_FLAGS), "\n"));
	}

	float links = 0;
	for (entity a = wp_first; a; a = a.wp_allNext)
	{
		if (a.wp_id < 0) continue;
		for (float s = 0; s < WP_LINKS; s = s + 1)
		{
			entity b = WPL_Dest(a, s);
			if (!WP_Live(b)) continue;

			float c = WPL_Code(a, s);
			string mdl = "-";
			float en = WPC_Ent(c);
			if (en > 0)
			{
				entity e = edict_num(en);
				if (e.model != "") mdl = e.model;
			}

			fputs(fh, strcat("l ", ftos(a.wp_id), " ", ftos(b.wp_id), " "));
			fputs(fh, strcat(ftos(WPC_Type(c)), " ", ftos(WPC_Flags(c)), " "));
			fputs(fh, strcat(ftos(WPL_Fail(a, s)), " ", mdl, "\n"));
			links = links + 1;
		}
	}

	fputs(fh, "end\n");
	fclose(fh);
	wp_dirty = FALSE;
	dprint(strcat("waypoints: saved ", ftos(live), " nodes, ", ftos(links), " links\n"));
}

// TRUE when a cache matching this exact map was read.
float WP_Load()
{
	float fh = fopen(WP_FileName(), FILE_READ);
	if (fh < 0) return FALSE;

	string line = fgets(fh);
	tokenize(line);
	if (argv(0) != "BOT_BNAV" || stof(argv(1)) != WP_FILE_VERSION || stof(argv(2)) != WP_Fingerprint())
	{
		fclose(fh);
		dprint("waypoints: cache is for another build of this map, regenerating\n");
		return FALSE;
	}

	WP_Clear();
	float loaded = 0;
	float complete = FALSE;
	while (TRUE)
	{
		line = fgets(fh);
		if (!line) break;

		float argc = tokenize(line);
		string kind = argv(0);

		if (kind == "end") { complete = TRUE; break; }

		if (kind == "n" && argc >= 5)
		{
			entity n = WP_AddNode([stof(argv(1)), stof(argv(2)), stof(argv(3))], stof(argv(4)));
			if (!n) continue;
			n.wp_id = loaded;
			if (loaded < WP_MAX) wpf_byId[loaded] = n;
			loaded = loaded + 1;
		}
		else if (kind == "l" && argc >= 7)
		{
			float ia = stof(argv(1));
			float ib = stof(argv(2));
			if (ia < 0 || ia >= loaded || ia >= WP_MAX) continue;
			if (ib < 0 || ib >= loaded || ib >= WP_MAX) continue;

			float ent = 0;
			if (argv(6) != "-")
			{
				ent = WP_EntByModel(argv(6));
				if (ent < 0) continue;     // the brush entity is gone, so is the link
			}

			float id = WP_AddLink(wpf_byId[ia], wpf_byId[ib], stof(argv(3)), stof(argv(4)), ent);
			if (id >= 0) WPL_SetFail(WPL_IdNode(id), WPL_IdSlot(id), stof(argv(5)));
		}
	}

	fclose(fh);
	if (!complete)
	{
		WP_Clear();
		dprint("waypoints: cache was cut off mid save, regenerating\n");
		return FALSE;
	}
	wp_dirty = FALSE;
	dprint(strcat("waypoints: loaded ", ftos(wp_count), " nodes, ", ftos(wp_linkCount), " links\n"));
	return wp_count > 0;
}
