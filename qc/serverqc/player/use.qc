
#define USE_DISTANCE 80
.float used_once;

void Player_Use()
{
	if(self.classname != "player") return;
	if(!self.buttonuse)
	{
		self.used_once = FALSE;
		return;
	}

	makevectors(self.v_angle);
	vector src = self.origin + self.view_ofs; 
	traceline(src, src + v_forward * USE_DISTANCE, FALSE, self);
	if (trace_fraction != 1.0 && trace_ent.classname != "worldspawn")
	{
		print(trace_ent.classname, " ", etos(trace_ent), " ", ftos(trace_ent.object_caps), "\n");
		// if(trace_ent.classname == "button" || trace_ent.classname == "func_door" || trace_ent.classname == "func_door_rotating")
		// if(trace_ent.usable == 1 || (trace_ent.usable == 2 && self.used_once == 0))
		if(trace_ent.object_caps & FCAP_CONTINUOUS_USE || ((trace_ent.object_caps & FCAP_ONOFF_USE || trace_ent.object_caps & FCAP_IMPULSE_USE) && self.used_once == 0))
		{
			if(trace_ent.use)
			{
				sound(self, CHAN_ITEM, "common/wpn_select.wav", 0.4, ATTN_NORM);
				self.used_once = TRUE;
				activator = self;
				self = trace_ent;
				trace_ent.use();
				self = activator;
				return;
			}
		}
	}

	if(!self.used_once )
	{
		sound(self, CHAN_ITEM, "common/wpn_denyselect.wav", 0.4, ATTN_NORM);
		self.used_once = TRUE;
	}
}