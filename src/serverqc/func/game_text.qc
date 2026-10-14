// Keys:
//   message     text to display (\n allowed for line breaks)
// x, y screen fraction position (-1 = centered on axis, 0..1 fraction)
// effect 0=fade in/out, 1=credits, 2=scan out (1/2 NYI, fall through to 0)
//   color       "r g b a" primary color (ints 0..255)
//   color2      "r g b a" secondary color (effect 1/2)
//   fadein, fadeout, holdtime, fxtime  timings (seconds)
//   master      master gate
#define SF_ENVTEXT_ALLPLAYERS   0x0001

.float  gt_channel;
.float  gt_x;
.float  gt_y;
.float  gt_effect;
.float  gt_fadein;
.float  gt_fadeout;
.float  gt_holdtime;
.float  gt_fxtime;
.vector gt_rgb1;
.float  gt_a1;
.vector gt_rgb2;
.float  gt_a2;

void GameText_ParseColor(string s, .vector rgbField, .float aField)
{
	if (!s || s == "")
	{
		self.rgbField = '100 100 100';
		self.aField   = 255;
		return;
	}
	float ntok = tokenize(s);
	float r = (ntok > 0) ? stof(argv(0)) : 100;
	float g = (ntok > 1) ? stof(argv(1)) : 100;
	float b = (ntok > 2) ? stof(argv(2)) : 100;
	float a = (ntok > 3) ? stof(argv(3)) : 255;
	self.rgbField = [r, g, b];
	self.aField   = a;
}

float GameText_MessageToAll() { return self.spawnflags & SF_ENVTEXT_ALLPLAYERS; }

void GameText_SendOne(entity dest)
{
	if (!dest || dest.classname != "player") return;

	string part1 = sprintf("hudmsg %d %f %f %d",
		(float)self.gt_channel,
		self.gt_x, self.gt_y,
		(float)self.gt_effect);
	string part2a = sprintf(" %d %d %d %d",
		(float)self.gt_rgb1_x, (float)self.gt_rgb1_y, (float)self.gt_rgb1_z, (float)self.gt_a1);
	string part2b = sprintf(" %d %d %d %d",
		(float)self.gt_rgb2_x, (float)self.gt_rgb2_y, (float)self.gt_rgb2_z, (float)self.gt_a2);
	string part2 = strcat(part2a, part2b);
	string body = strreplace("\\n", "|", self.message);
	string part3 = sprintf(" %f %f %f %f \"%s\"\n",
		self.gt_fadein, self.gt_fadeout, self.gt_holdtime, self.gt_fxtime,
		body);

	stuffcmd(dest, strcat(part1, part2, part3));
}

void GameText_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
{
	if (!Master_IsTriggered(self.master, pActivator)) return;

	if (GameText_MessageToAll())
	{
		entity p = find(world, classname, "player");
		while (p)
		{
			GameText_SendOne(p);
			p = find(p, classname, "player");
		}
	}
	else
	{
		GameText_SendOne(pActivator);
	}
}

void GameText_Use()
{
	GameText_UseHL(activator, self, useType, 0);
}

void game_text()
{
	self.solid    = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;
	self.effects  = EF_NODRAW;

	string colorStr  = "";
	string color2Str = "";

	for (float i = 1; i < (tokenize(__fullspawndata) - 1); i += 2)
	{
		string key = argv(i);
		string val = argv(i + 1);

		if      (key == "channel")  self.gt_channel  = stof(val);
		else if (key == "x")        self.gt_x        = stof(val);
		else if (key == "y")        self.gt_y        = stof(val);
		else if (key == "effect")   self.gt_effect   = stof(val);
		else if (key == "fadein")   self.gt_fadein   = stof(val);
		else if (key == "fadeout")  self.gt_fadeout  = stof(val);
		else if (key == "holdtime") self.gt_holdtime = stof(val);
		else if (key == "fxtime")   self.gt_fxtime   = stof(val);
		else if (key == "color")    colorStr  = val;
		else if (key == "color2")   color2Str = val;
	}

	if (self.gt_holdtime <= 0) self.gt_holdtime = 3.5;
	if (self.gt_fadein   <  0) self.gt_fadein   = 0;
	if (self.gt_fadeout  <  0) self.gt_fadeout  = 0;

	GameText_ParseColor(colorStr,  gt_rgb1, gt_a1);
	GameText_ParseColor(color2Str, gt_rgb2, gt_a2);

	self.use   = GameText_Use;
	self.usehl = GameText_UseHL;
}
