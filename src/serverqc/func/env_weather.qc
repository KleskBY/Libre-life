
#define ENV_WEATHER_RAIN	1
#define ENV_WEATHER_SNOW	2

#define SF_ENVFOG_START_OFF	1

.float weatherType;
.string fogString;

string EnvWeather_VectorString(vector v)
{
	return sprintf("%g %g %g", v_x, v_y, v_z);
}

void EnvWeather_Send(entity p)
{
	if (!p || p.classname != "player")
		return;

	if (self.weatherType == ENV_WEATHER_SNOW)
	{
		stuffcmd(p, "set cl_weather_snow 1\n");
		stuffcmd(p, strcat("set cl_weather_snow_velocity \"", EnvWeather_VectorString(self.dest), "\"\n"));
		stuffcmd(p, strcat("set cl_weather_snow_count ", ftos(self.count), "\n"));
		stuffcmd(p, strcat("set cl_weather_snow_cnt ", ftos(self.cnt), "\n"));
	}
	else
	{
		stuffcmd(p, "set cl_weather_rain 1\n");
		stuffcmd(p, strcat("set cl_weather_rain_velocity \"", EnvWeather_VectorString(self.dest), "\"\n"));
		stuffcmd(p, strcat("set cl_weather_rain_count ", ftos(self.count), "\n"));
		stuffcmd(p, strcat("set cl_weather_rain_cnt ", ftos(self.cnt), "\n"));
	}
}

void EnvWeather_Apply()
{
	entity p = find(world, classname, "player");
	while (p)
	{
		EnvWeather_Send(p);
		p = find(p, classname, "player");
	}
}

void EnvWeather_Think()
{
	EnvWeather_Apply();
}

void EnvWeather_Spawn(float kind)
{
	self.weatherType = kind;
	self.dest = self.velocity;
	self.velocity = '0 0 0';

	if (!self.dest)
	{
		if (kind == ENV_WEATHER_SNOW) self.dest = '0 0 -300';
		else                         self.dest = '0 0 -700';
	}

	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.effects = EF_NODRAW;

	if (!self.cnt)
	{
		if (kind == ENV_WEATHER_SNOW) self.cnt = 11;
		else                         self.cnt = 2;
	}

	if (!self.count)
	{
		if (kind == ENV_WEATHER_SNOW) self.count = 10;
		else                         self.count = 4;
	}

	if (self.count < 1)
	{
		remove(self);
		return;
	}

	self.think = EnvWeather_Think;
	self.nextthink = time + 0.5;
}

void env_rain() { EnvWeather_Spawn(ENV_WEATHER_RAIN); }
void func_rain() { env_rain(); }

void env_snow() { EnvWeather_Spawn(ENV_WEATHER_SNOW); }
void func_snow() { env_snow(); }

float EnvFog_ColorComponent(float c)
{
	if (c > 1) return c / 255;
	return c;
}

float EnvFog_Alpha()
{
	if (!self.renderamt) return 1;
	if (self.renderamt > 1) return self.renderamt / 255;
	return self.renderamt;
}

string EnvFog_BuildString()
{
	if (self.message && self.message != "")
		return self.message;
	if (self.fogString && self.fogString != "")
		return self.fogString;

	float densityValue = self.density;
	if (!densityValue) densityValue = 0.001;

	vector col = self.rendercolor;
	if (col == '0 0 0')
		col = '128 128 128';

	string first = sprintf("%g %g %g %g",
		densityValue,
		EnvFog_ColorComponent(col_x),
		EnvFog_ColorComponent(col_y),
		EnvFog_ColorComponent(col_z));
	string second = sprintf(" %g %g %g %g %g",
		EnvFog_Alpha(),
		self.waitmin,
		self.waitmax,
		self.height,
		self.distance);
	return strcat(first, second);
}

void EnvFog_Send(entity p)
{
	if (!p || p.classname != "player")
		return;

	if (!self.state)
		stuffcmd(p, "fog 0\n");
	else
		stuffcmd(p, strcat("fog ", EnvFog_BuildString(), "\n"));
}

void EnvFog_Apply()
{
	entity p = find(world, classname, "player");
	while (p)
	{
		EnvFog_Send(p);
		p = find(p, classname, "player");
	}
}

void EnvFog_Think()
{
	EnvFog_Apply();
	self.nextthink = time + 2;
}

void EnvFog_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	useType = useTypeArg;
	if (ShouldToggle(self.state))
		self.state = !self.state;

	EnvFog_Apply();
}

void EnvFog_Use()
{
	EnvFog_UseHL(activator, self, useType, 0);
}

void env_fog()
{
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects = EF_NODRAW;

	self.state = !(self.spawnflags & SF_ENVFOG_START_OFF);
	self.use = EnvFog_Use;
	self.usehl = EnvFog_UseHL;

	self.think = EnvFog_Think;
	self.nextthink = time + 0.5;
}
