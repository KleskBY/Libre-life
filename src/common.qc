

float FTE;
float IsFTE()
{
	if(FTE) return TRUE;
	if(cvar_string("qws_name") == "FTE") 
	{
		FTE = TRUE;
		return TRUE;
	}
	return FALSE;
}

float StringContains(string str, string needle)
{
	if(str == "") return FALSE;
	if(strstrofs(str, needle, 0) >= 0) return TRUE;
	return FALSE;
}

float FStrEq(string str1, string str2)
{
	return (str1 == str2);
}

float FClassnameIs(entity ent, string str)
{
	return (ent.classname == str);
}

float Map_IsId1BSP()
{
	return (cvar("halflifebsp") == 0);
}

float IsVisible(entity targ)
{
	vector spot1 = self.origin + self.view_ofs;
	vector spot2 = targ.origin + targ.view_ofs;
	traceline(spot1, spot2, TRUE, self); // Trace line, ignore monsters
	if (trace_inopen && trace_inwater) return FALSE; // Do not see an object in the water if you are on land
	if (trace_fraction == 1) return TRUE;
	return FALSE;
};

float IsAlive(entity e)
{
	if(e.health > 0 && !e.deadflag) return TRUE;
	return FALSE;
};

entity FindNearestPlayer(vector src)
{
	entity e, nearest;
	for (e = findchain(classname, "player"); e; e = e.chain) 
	{
		if(e != self && IsAlive(e))
		{
			if (!nearest || !IsVisible(nearest)) nearest = e;
			if(IsVisible(e))
			{
				if (!nearest) nearest = e;
				else if(vlen(e.origin - src) < vlen(nearest.origin - src)) nearest = e;
			}
			else if (!nearest) nearest = e;
		}
	}
	return nearest;
};

entity FindNearest(string class, vector src)
{
	entity e, nearest;
	for (e = findchain(classname, class); e; e = e.chain) 
	{
		if(e != self && IsAlive(e))
		{
			if (!nearest || !IsVisible(nearest)) nearest = e;
			if(IsVisible(e))
			{
				if (!nearest) nearest = e;
				else if(vlen(e.origin - src) < vlen(nearest.origin - src)) nearest = e;
			}
			else if (!nearest) nearest = e;
		}
	}
	return nearest;
};
