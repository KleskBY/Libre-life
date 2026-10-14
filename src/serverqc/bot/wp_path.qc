// A* over the bot waypoint graph.
//
// The open set is a bucket queue threaded through node fields, doubly linked so
// a node whose cost improves can leave its bucket in O(1). Buckets are
// WPQ_WIDTH units of estimated cost wide, which makes the result optimal to
// within one bucket; for a bot that is indistinguishable from exact, and there is
// no heap array to pay the ArrayGet cost on.
//
// Search state is stamped rather than cleared: a node belongs to the current
// search only while its stamp matches.
//
// The route is read back by walking parents from the goal, keeping the eight
// hops nearest the start in a sliding window. Those land on the bot's own
// bot_h* / bot_l* fields, so no bot's route can be overwritten by another
// bot's query. A longer route simply repaths when the window runs out.

#define WPQ_BUCKETS      512
#define WPQ_WIDTH        48
#define WPA_PER_FRAME    2       // searches allowed per server frame
#define WPA_EXPAND_MAX   6000    // node expansions per search, well under the runaway limit
#define WPA_VIS_BUDGET   192     // exposure traces allowed per search
#define WPA_EXPOSED_COST 384     // extra cost for a node the threat can see
#define WP_HOPS          8

.float  wpa_g;
.float  wpa_open;
.float  wpa_closed;
.entity wpa_parent;
.float  wpa_parentSlot;
.entity wpa_qNext;
.entity wpa_qPrev;
.float  wpa_bucket;
.float  wpa_visStamp;
.float  wpa_visVal;

nosave entity wpq_bucket[WPQ_BUCKETS];
float wpq_min;
float wpq_max;
float wpa_stamp;
float wpa_frameTime;
float wpa_frameCount;

float  wpa_threatActive;   // set around a flanking search
vector wpa_threatEye;
float  wpa_visId;
vector wpa_visEye;
float  wpa_visUsed;

void WPQ_Reset()
{
	for (float b = 0; b <= wpq_max; b = b + 1)
		wpq_bucket[b] = world;
	wpq_min = 0;
	wpq_max = 0;
}

void WPQ_Insert(entity n, float f)
{
	float b = floor(f / WPQ_WIDTH);
	if (b < wpq_min) b = wpq_min;
	if (b >= WPQ_BUCKETS) b = WPQ_BUCKETS - 1;
	if (b > wpq_max) wpq_max = b;

	n.wpa_bucket = b;
	n.wpa_qPrev = world;
	n.wpa_qNext = wpq_bucket[b];
	if (n.wpa_qNext) n.wpa_qNext.wpa_qPrev = n;
	wpq_bucket[b] = n;
}

void WPQ_Remove(entity n)
{
	if (n.wpa_qPrev) n.wpa_qPrev.wpa_qNext = n.wpa_qNext;
	else             wpq_bucket[n.wpa_bucket] = n.wpa_qNext;
	if (n.wpa_qNext) n.wpa_qNext.wpa_qPrev = n.wpa_qPrev;
	n.wpa_qNext = world;
	n.wpa_qPrev = world;
}

entity WPQ_Pop()
{
	while (wpq_min <= wpq_max)
	{
		entity n = wpq_bucket[wpq_min];
		if (n)
		{
			WPQ_Remove(n);
			return n;
		}
		wpq_min = wpq_min + 1;
	}
	return world;
}

float WP_Blacklisted(entity bot, float id)
{
	if (!bot) return FALSE;
	float k = id + 1;
	if (bot.bot_bl0 == k) if (time < bot.bot_blT0) return TRUE;
	if (bot.bot_bl1 == k) if (time < bot.bot_blT1) return TRUE;
	if (bot.bot_bl2 == k) if (time < bot.bot_blT2) return TRUE;
	if (bot.bot_bl3 == k) if (time < bot.bot_blT3) return TRUE;
	return FALSE;
}

void WP_Blacklist(entity bot, float id, float secs)
{
	if (id < 0) return;
	float k = id + 1;
	float slot = bot.bot_blNext;
	bot.bot_blNext = slot + 1;
	if (bot.bot_blNext > 3) bot.bot_blNext = 0;

	if (slot == 0)      { bot.bot_bl0 = k; bot.bot_blT0 = time + secs; }
	else if (slot == 1) { bot.bot_bl1 = k; bot.bot_blT1 = time + secs; }
	else if (slot == 2) { bot.bot_bl2 = k; bot.bot_blT2 = time + secs; }
	else                { bot.bot_bl3 = k; bot.bot_blT3 = time + secs; }
}

float WP_BlacklistSize(entity bot)
{
	float n = 0;
	if (bot.bot_bl0) if (time < bot.bot_blT0) n = n + 1;
	if (bot.bot_bl1) if (time < bot.bot_blT1) n = n + 1;
	if (bot.bot_bl2) if (time < bot.bot_blT2) n = n + 1;
	if (bot.bot_bl3) if (time < bot.bot_blT3) n = n + 1;
	return n;
}

// Can the flanking threat see this node? Cached per node for as long as the
// threat stays roughly where it is, and capped per search.
float WPA_Exposed(entity n)
{
	if (n.wpa_visStamp == wpa_visId) return n.wpa_visVal;
	if (wpa_visUsed >= WPA_VIS_BUDGET) return 0;
	wpa_visUsed = wpa_visUsed + 1;

	traceline(wpa_threatEye, n.origin + '0 0 24', WP_NOMON, world);
	float v = (trace_fraction == 1) ? 1 : 0;
	n.wpa_visStamp = wpa_visId;
	n.wpa_visVal = v;
	return v;
}

void WP_SetThreat(float active, vector eye)
{
	wpa_threatActive = active;
	if (!active) return;
	wpa_threatEye = eye;
	if (!wpa_visId || vlen(eye - wpa_visEye) > 64)
	{
		wpa_visEye = eye;
		wpa_visId = wpa_visId + 1;
	}
}

float WP_PathBudget()
{
	if (wpa_frameTime != time)
	{
		wpa_frameTime = time;
		wpa_frameCount = 0;
	}
	if (wpa_frameCount >= WPA_PER_FRAME) return FALSE;
	wpa_frameCount = wpa_frameCount + 1;
	return TRUE;
}

entity WP_HopNode(entity bot, float i)
{
	if (i == 0) return bot.bot_h0;
	if (i == 1) return bot.bot_h1;
	if (i == 2) return bot.bot_h2;
	if (i == 3) return bot.bot_h3;
	if (i == 4) return bot.bot_h4;
	if (i == 5) return bot.bot_h5;
	if (i == 6) return bot.bot_h6;
	if (i == 7) return bot.bot_h7;
	return world;
}

// Link id + 1 used to arrive at hop i.
float WP_HopLink(entity bot, float i)
{
	if (i == 0) return bot.bot_l0;
	if (i == 1) return bot.bot_l1;
	if (i == 2) return bot.bot_l2;
	if (i == 3) return bot.bot_l3;
	if (i == 4) return bot.bot_l4;
	if (i == 5) return bot.bot_l5;
	if (i == 6) return bot.bot_l6;
	if (i == 7) return bot.bot_l7;
	return 0;
}

// Route from start to goal for `bot`. Fills the bot's hop window and returns the
// full hop count (0 when unreachable). Hop 0 is the first node after `start`.
float WP_FindPath(entity bot, entity start, entity goal)
{
	if (!WP_Live(start) || !WP_Live(goal)) return 0;

	wpa_stamp = wpa_stamp + 1;
	wpa_visUsed = 0;
	WPQ_Reset();

	start.wpa_g = 0;
	start.wpa_parent = world;
	start.wpa_open = wpa_stamp;
	WPQ_Insert(start, vlen(goal.origin - start.origin));

	float found = FALSE;
	float expanded = 0;
	while (TRUE)
	{
		entity cur = WPQ_Pop();
		if (!cur) break;
		if (cur == goal) { found = TRUE; break; }
		cur.wpa_closed = wpa_stamp;

		expanded = expanded + 1;
		if (expanded > WPA_EXPAND_MAX) break;

		for (float s = 0; s < WP_LINKS; s = s + 1)
		{
			entity d = WPL_Dest(cur, s);
			if (!d) continue;
			if (d.wp_flags & WPN_DEAD) continue;
			float c = WPL_Code(cur, s);
			if (WPC_Flags(c) & WPLF_DISABLED) continue;
			if (d.wpa_closed == wpa_stamp) continue;

			float id = WPL_Id(cur, s);
			if (WP_Blacklisted(bot, id)) continue;

			float g = cur.wpa_g + WP_TypeCost(WPC_Type(c), vlen(d.origin - cur.origin))
			          + WPL_Fail(cur, s) * 48;
			if (wpa_threatActive) g = g + WPA_Exposed(d) * WPA_EXPOSED_COST;

			if (d.wpa_open == wpa_stamp)
			{
				if (g >= d.wpa_g) continue;
				WPQ_Remove(d);
			}

			d.wpa_g = g;
			d.wpa_parent = cur;
			d.wpa_parentSlot = s;
			d.wpa_open = wpa_stamp;
			WPQ_Insert(d, g + vlen(goal.origin - d.origin));
		}
	}
	if (!found) return 0;

	entity w0 = world, w1 = world, w2 = world, w3 = world, w4 = world, w5 = world, w6 = world, w7 = world;
	float  k0 = 0, k1 = 0, k2 = 0, k3 = 0, k4 = 0, k5 = 0, k6 = 0, k7 = 0;
	float count = 0;

	for (entity n = goal; n && n != start; n = n.wpa_parent)
	{
		w7 = w6; w6 = w5; w5 = w4; w4 = w3; w3 = w2; w2 = w1; w1 = w0;
		k7 = k6; k6 = k5; k5 = k4; k4 = k3; k3 = k2; k2 = k1; k1 = k0;
		w0 = n;
		k0 = WPL_Id(n.wpa_parent, n.wpa_parentSlot) + 1;
		count = count + 1;
		if (count > WP_MAX) return 0;
	}

	bot.bot_h0 = w0; bot.bot_h1 = w1; bot.bot_h2 = w2; bot.bot_h3 = w3;
	bot.bot_h4 = w4; bot.bot_h5 = w5; bot.bot_h6 = w6; bot.bot_h7 = w7;
	bot.bot_l0 = k0; bot.bot_l1 = k1; bot.bot_l2 = k2; bot.bot_l3 = k3;
	bot.bot_l4 = k4; bot.bot_l5 = k5; bot.bot_l6 = k6; bot.bot_l7 = k7;
	return count;
}
