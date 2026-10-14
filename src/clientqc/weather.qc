
#define WEATHER_EMIT_INTERVAL	0.1

float weatherNextEmit;

float Weather_CvarOrDefault(string name, float fallback)
{
	float value = cvar(name);
	if (!value)
		return fallback;
	return value;
}

vector Weather_Velocity(string name, vector fallback)
{
	string value = str_cvar(name);
	if (value == "")
		return fallback;
	return stov(value);
}

void Weather_Emit(float snow)
{
	vector viewOrg = getpropertyvec(VF_ORIGIN);
	makevectors(input_angles);

	vector center = viewOrg + v_forward * 384;
	vector mins = center + '-640 -640 -384';
	vector maxs = center + '640 640 512';

	if (snow)
	{
		te_particlesnow(
			mins,
			maxs,
			Weather_Velocity("cl_weather_snow_velocity", '0 0 -300'),
			Weather_CvarOrDefault("cl_weather_snow_count", 10),
			Weather_CvarOrDefault("cl_weather_snow_cnt", 11));
	}
	else
	{
		te_particlerain(
			mins,
			maxs,
			Weather_Velocity("cl_weather_rain_velocity", '0 0 -700'),
			Weather_CvarOrDefault("cl_weather_rain_count", 4),
			Weather_CvarOrDefault("cl_weather_rain_cnt", 2));
	}
}

void Weather_Update()
{
	if (!cvar("cl_weather"))
		return;

	if (time < weatherNextEmit)
		return;
	weatherNextEmit = time + WEATHER_EMIT_INTERVAL;

	if (cvar("cl_weather_rain"))
		Weather_Emit(FALSE);
	if (cvar("cl_weather_snow"))
		Weather_Emit(TRUE);
}
