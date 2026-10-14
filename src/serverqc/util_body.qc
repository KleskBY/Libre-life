
.float body;
.float skinFamily;

#define MAX_BODYINFO_MODELS 32
#define MAX_BODYINFO_GROUPS 128

string bodyinfo_model[MAX_BODYINFO_MODELS];
float  bodyinfo_families[MAX_BODYINFO_MODELS];   // -1 = checked, no sidecar
float  bodyinfo_firstgroup[MAX_BODYINFO_MODELS];
float  bodyinfo_numgroups[MAX_BODYINFO_MODELS];
float  bodyinfo_splitbone[MAX_BODYINFO_MODELS];  // 0-based first TORSO bone, -1 = none
float  bodyinfo_count;

string bodygroup_name[MAX_BODYINFO_GROUPS];
float  bodygroup_submodels[MAX_BODYINFO_GROUPS];
float  bodygroup_base[MAX_BODYINFO_GROUPS];
float  bodygroup_cursor;

float Body_Mod(float a, float b)
{
	if (b <= 0) return 0;
	return a - floor(a / b) * b;
}

float BodyInfo_Load(string mdl)
{
	if (mdl == "") return -1;

	float i;
	for (i = 0; i < bodyinfo_count; i = i + 1)
		if (bodyinfo_model[i] == mdl)
			return (bodyinfo_families[i] < 0) ? -1 : i;

	if (bodyinfo_count >= MAX_BODYINFO_MODELS)
	{
		dprint("BodyInfo_Load: table full, ignoring "); dprint(mdl); dprint("\n");
		return -1;
	}

	float idx = bodyinfo_count;
	bodyinfo_count = bodyinfo_count + 1;
	bodyinfo_model[idx]      = strzone(mdl);
	bodyinfo_families[idx]   = -1;
	bodyinfo_firstgroup[idx] = bodygroup_cursor;
	bodyinfo_numgroups[idx]  = 0;
	bodyinfo_splitbone[idx]  = -1;

	float fh = fopen(strcat(mdl, ".bodyinfo"), FILE_READ);
	if (fh < 0) return -1;

	string line;
	while ((line = fgets(fh)))
	{
		float n = tokenize(line);
		if (n < 2) continue;
		string kw = argv(0);
		if (kw == "families")
		{
			bodyinfo_families[idx] = stof(argv(1));
		}
		else if (kw == "group" && n >= 4)
		{
			if (bodygroup_cursor >= MAX_BODYINFO_GROUPS)
			{
				dprint("BodyInfo_Load: group table full\n");
				continue;
			}
			bodygroup_name[bodygroup_cursor]      = strzone(argv(1));
			bodygroup_submodels[bodygroup_cursor] = stof(argv(2));
			bodygroup_base[bodygroup_cursor]      = stof(argv(3));
			bodygroup_cursor = bodygroup_cursor + 1;
			bodyinfo_numgroups[idx] = bodyinfo_numgroups[idx] + 1;
		}
		else if (kw == "splitbone")
		{
			bodyinfo_splitbone[idx] = stof(argv(1));
		}
	}
	fclose(fh);

	if (bodyinfo_families[idx] < 1) bodyinfo_families[idx] = 1;
	return idx;
}

float Body_SplitBone(string mdl)
{
	float mi = BodyInfo_Load(mdl);
	if (mi < 0) return -1;
	return bodyinfo_splitbone[mi];
}

// Global group-table index for a named group, -1 if not found.
float Body_FindGroup(float mi, string gname)
{
	if (mi < 0) return -1;
	float g;
	for (g = 0; g < bodyinfo_numgroups[mi]; g = g + 1)
	{
		float gi = bodyinfo_firstgroup[mi] + g;
		if (bodygroup_name[gi] == gname) return gi;
	}
	return -1;
}

void Body_Apply(entity e)
{
	float mi = BodyInfo_Load(e.model);
	if (mi < 0) return;
	e.skin = e.body * bodyinfo_families[mi] + e.skinFamily;
}

float Body_GroupCount(entity e, string gname)
{
	float gi = Body_FindGroup(BodyInfo_Load(e.model), gname);
	if (gi < 0) return 0;
	return bodygroup_submodels[gi];
}

// GetBodygroup: current submodel index within a named group.
float Body_GetGroup(entity e, string gname)
{
	float gi = Body_FindGroup(BodyInfo_Load(e.model), gname);
	if (gi < 0) return 0;
	return Body_Mod(floor(e.body / bodygroup_base[gi]), bodygroup_submodels[gi]);
}

void Body_SetGroup(entity e, string gname, float val)
{
	float mi = BodyInfo_Load(e.model);
	float gi = Body_FindGroup(mi, gname);
	if (gi < 0)
	{
		dprint("Body_SetGroup: no group '"); dprint(gname);
		dprint("' on "); dprint(e.model); dprint("\n");
		return;
	}
	if (val < 0) val = 0;
	if (val >= bodygroup_submodels[gi]) val = bodygroup_submodels[gi] - 1;

	float cur = Body_Mod(floor(e.body / bodygroup_base[gi]), bodygroup_submodels[gi]);
	e.body = e.body + (val - cur) * bodygroup_base[gi];
	Body_Apply(e);
}

void Body_SetFamily(entity e, float fam)
{
	float mi = BodyInfo_Load(e.model);
	if (mi < 0)
	{
		e.skin = fam;	// no bodyinfo: behave like plain .skin
		return;
	}
	if (fam < 0) fam = 0;
	if (fam >= bodyinfo_families[mi]) fam = bodyinfo_families[mi] - 1;
	e.skinFamily = fam;
	Body_Apply(e);
}
