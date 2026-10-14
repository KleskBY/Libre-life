
#define PLAYER_USE_DISTANCE 80
#define PLAYER_SEARCH_RADIUS 64
#define VIEW_FIELD_NARROW 0.7
#define FCAP_USE_MASK (FCAP_IMPULSE_USE | FCAP_ONOFF_USE | FCAP_CONTINUOUS_USE)
.float used_once;

vector Use_ClampVectorToBox(vector input, vector half)
{
	if (input.x >  half.x) input.x = input.x - half.x;
	else if (input.x < -half.x) input.x = input.x + half.x;
	else input.x = 0;

	if (input.y >  half.y) input.y = input.y - half.y;
	else if (input.y < -half.y) input.y = input.y + half.y;
	else input.y = 0;

	if (input.z >  half.z) input.z = input.z - half.z;
	else if (input.z < -half.z) input.z = input.z + half.z;
	else input.z = 0;

	return input;
}

float Use_IsUsable(entity e)
{
	if (e.object_caps & FCAP_CONTINUOUS_USE)
		return TRUE;
	if ((e.object_caps & FCAP_ONOFF_USE || e.object_caps & FCAP_IMPULSE_USE) && self.used_once == 0)
		return TRUE;
	return FALSE;
}

// The two halves of "what would USE hit right now", split out so a HUD can ask
// the same question the key press asks. Anything that picks its own target
// drifts from this one and ends up highlighting a thing that will not fire.
//
// `caps` is the mask Player_Use builds from used_once, and testing it is exactly
// Use_IsUsable's condition: with the key held, only FCAP_CONTINUOUS_USE is still
// live. Passing FCAP_USE_MASK asks what a FRESH press would find, which is what
// a highlight wants while the key is down.
entity Use_TraceTarget(float caps)
{
	makevectors(self.v_angle);
	vector src = self.origin + self.view_ofs;
	traceline(src, src + v_forward * PLAYER_USE_DISTANCE, FALSE, self);
	if (trace_fraction == 1.0) return world;
	if (trace_ent.classname == "worldspawn") return world;
	if (!(trace_ent.object_caps & caps)) return world;
	return trace_ent;
}

// findchainflags runs the edict walk in C and hands back only entities that
// advertise a use type, so the QC loop is a handful of iterations instead of
// every edict on the map.
entity Use_NearbyTarget(float caps)
{
	makevectors(self.v_angle);
	vector src = self.origin + self.view_ofs;

	entity pClosest = world;
	float flMaxDot = VIEW_FIELD_NARROW;
	float flDot;
	float radiusSq = PLAYER_SEARCH_RADIUS * PLAYER_SEARCH_RADIUS;
	vector center, half, vecLOS;

	for (entity pObject = findchainflags(object_caps, caps); pObject; pObject = pObject.chain)
	{
		if (pObject == self) continue;

		center = (pObject.absmin + pObject.absmax) * 0.5;
		half   = (pObject.absmax - pObject.absmin) * 0.5;
		// Distance gate: closest point of bbox to player origin
		vecLOS = Use_ClampVectorToBox(center - self.origin, half);
		if (vecLOS * vecLOS > radiusSq) continue;

		// View cone gate: same clamp but from eye position
		vecLOS = Use_ClampVectorToBox(center - src, half);
		vecLOS = normalize(vecLOS);
		flDot = vecLOS * v_forward;
		if (flDot > flMaxDot)
		{
			flMaxDot = flDot;
			pClosest = pObject;
		}
	}
	return pClosest;
}

float Use_Dispatch(entity pUsed)
{
	entity pActivator = self;
	if (pUsed.usehl)
	{
		// handler expects self to be the entity used
		if (!self.used_once)
			Sound_Play(self, CHAN_ITEM, 0.4, ATTN_NORM, PITCH_NORM, "common/wpn_select.wav");
		self.used_once = TRUE;
		self = pUsed;
		pUsed.usehl(pActivator, pActivator, USE_SET, 1);
		self = pActivator;
		return TRUE;
	}
	if (pUsed.use)
	{
		// Legacy fallback: activator global + self swap
		if (!self.used_once)
			Sound_Play(self, CHAN_ITEM, 0.4, ATTN_NORM, PITCH_NORM, "common/wpn_select.wav");
		self.used_once = TRUE;
		activator = pActivator;
		self = pUsed;
		pUsed.use();
		self = pActivator;
		return TRUE;
	}
	return FALSE;
}

void Player_Use()
{
	if(self.classname != "player") return;

	if(IsFTE())
	{
		if(!self.button5)
		{
			self.used_once = FALSE;
			return;
		}
	}
	else
	{
		if(!self.buttonuse)
		{
			self.used_once = FALSE;
			return;
		}
	}

	float caps = FCAP_CONTINUOUS_USE;
	if (!self.used_once) caps = FCAP_USE_MASK;

	// fast, solid objects only
	entity pTraced = Use_TraceTarget(caps);
	if (pTraced != world && Use_Dispatch(pTraced))
		return;

	// For non-solid entities
	entity pClosest = Use_NearbyTarget(caps);
	if (pClosest != world && Use_Dispatch(pClosest))
		return;

	if (!self.used_once)
	{
		Sound_Play(self, CHAN_ITEM, 0.4, ATTN_NORM, PITCH_NORM, "common/wpn_denyselect.wav");
		self.used_once = TRUE;
	}
}
