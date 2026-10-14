// Ejected casings, and the shared resolver for where a held weapon really is.
//
// Every effect a weapon spawns exists twice: a first person copy placed off the
// viewmodel and drawn only to the shooter, and a third person copy placed off the
// world weapon in the hand and drawn to everyone else. See docs/guide/07-weapons.md,
// "Third person weapon effects".

vector g_fxMuzzle;   // filled by Weapon_WorldMuzzle
vector g_fxEject;
vector g_fxFwd;
vector g_fxRight;
vector g_fxUp;

.float fx_silent;    // first person casing: the third person copy makes the sound

float Effect_OnlyToOwner()  { return other == self.owner; }
float Effect_HideFromOwner() { return other != self.owner; }

// World space barrel end and ejection port of the weapon p is visibly holding.
// FALSE when there is no drawn world weapon to anchor to.
float Weapon_WorldMuzzle(entity p)
{
	entity w = p.weapon_ent;
	if (!w) return FALSE;
	if (wasfreed(w)) return FALSE;
	if (w.effects & EF_NODRAW) return FALSE;
	if (w.model == "") return FALSE;

	vector grip = gettaginfo(w, 0);   // the attachment point is the grip

	makevectors(p.v_angle);           // a held barrel points where its holder aims
	g_fxFwd   = v_forward;
	g_fxRight = v_right;
	g_fxUp    = v_up;

	float sc = w.scale;
	if (!sc) sc = 1;
	float psc = p.scale;
	if (!psc) psc = 1;

	// World models disagree on their long axis, so take the longest extent.
	float len = w.maxs_x;
	if (0 - w.mins_x > len) len = 0 - w.mins_x;
	if (w.maxs_y > len) len = w.maxs_y;
	if (0 - w.mins_y > len) len = 0 - w.mins_y;
	if (len < 4) len = 20;
	len = len * sc * psc;

	g_fxMuzzle = grip + g_fxFwd * len;

	// The suppressor mount sits at the barrel end wherever the model has one.
	float tag = gettagindex(w, "wpn_silencer");
	if (tag > 0)
	{
		vector t = gettaginfo(w, tag);
		float d = vlen(t - grip);
		if (d > 2 && d < len * 1.5 + 8) g_fxMuzzle = t;
	}

	g_fxEject = grip + g_fxFwd * (len * 0.3) + g_fxRight * (3 * psc) + g_fxUp * (3 * psc);
	return TRUE;
}

void Shell_Touch()
{
	if (other.classname == "func_door" || other.classname == "func_door_rotating")
	{
		remove(self);
		return;
	}
	if (self.fx_silent) return;

	if (self.owner.weapon == WEAPON_SHOTGUN) Sound_Play(self, CHAN_WEAPON, 0.5, ATTN_NORM, PITCH_NORM, "weapons/sshell3.wav");
	else Sound_Play(self, CHAN_WEAPON, 0.5, ATTN_NORM, PITCH_NORM, "weapons/sshell1.wav");
}

entity Shell_Spawn(entity shooter, string mdl, vector org, vector vel)
{
	entity s = spawn();
	s.owner = shooter;
	s.classname = "shell";
	s.movetype = MOVETYPE_BOUNCE;
	if (random() < 0.5) s.solid = SOLID_BBOX;
	else s.solid = SOLID_NOT;
	s.angles = g_fxFwd * (random() + 1);
	setmodel(s, mdl);
	setsize(s, VEC_ORIGIN, VEC_ORIGIN);
	setorigin(s, org);
	s.avelocity_x = random(4000, 9000);
	s.avelocity_y = random(4000, 9000);
	s.velocity = vel;
	s.touch = Shell_Touch;
	s.think = SUB_Remove;
	s.nextthink = time + 1.5;
	return s;
}

// Called by the weapon, self = the shooter; offset is in view space.
void Shell_Eject(string mdl, vector offset)
{
	makevectors(self.v_angle);
	g_fxFwd = v_forward;
	vector org = self.origin + self.view_ofs + v_forward * offset_x + v_right * offset_y + v_up * offset_z;
	vector vel = v_forward * random(10, 20) + v_right * random(60, 120) + v_up * random(70, 110);

	entity own = Shell_Spawn(self, mdl, org, vel);
	own.customizeentityforclient = Effect_OnlyToOwner;
	own.fx_silent = TRUE;

	if (!Weapon_WorldMuzzle(self)) return;

	vel = g_fxFwd * random(0, 15) + g_fxRight * random(60, 110) + g_fxUp * random(60, 100);
	vel = vel + [self.velocity_x, self.velocity_y, 0] * 0.8;   // keep up with a moving shooter
	entity world3p = Shell_Spawn(self, mdl, g_fxEject, vel);
	world3p.customizeentityforclient = Effect_HideFromOwner;
}
