
float Skill_Level()
{
	float s = cvar("skill");
	if (s < 1) return 1;
	if (s < 2) return 2;
	return 3;
}

float Skill_GetValue(string base, float defaultVal)
{
	string v = cvar_string(strcat(base, ftos(Skill_Level())));
	if (v == "") return defaultVal;
	return stof(v);
}
