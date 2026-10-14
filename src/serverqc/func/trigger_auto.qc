
#define SF_AUTO_FIREONCE 1

.float triggerstate;
.float auto_useType;

void Trigger_TriggerAutoThink()
{
	if (self.globalstate && self.globalstate != ""
	    && GlobalState_Get(self.globalstate) != GLOBAL_ON)
		return;

	SUB_UseTargetsHL(self, self.auto_useType, 0);
	if (self.spawnflags & SF_AUTO_FIREONCE)
	{
		Spent_Mark(self);
		remove(self);
	}
}

void trigger_auto()
{
	Spent_Capture(self);
	if (Spent_IsSpent(self)) { remove(self); return; }

	switch ((float)self.triggerstate)
	{
	case 0:  self.auto_useType = USE_OFF;    break;
	case 2:  self.auto_useType = USE_TOGGLE; break;
	default: self.auto_useType = USE_ON;     break;
	}

	self.nextthink = time + 0.1;
	self.think = Trigger_TriggerAutoThink;
}

// Run after a level is restored (hub revisit, savegame load). The snapshot holds
// the think already spent, so a trigger_auto gated on a globalstate set on
// another map (hldemo3's dish) would never look again. Ungated ones fired at
// first spawn and are left alone: refiring them doubles looping effects.
void TriggerAuto_RearmAll()
{
	for (entity e = find(world, classname, "trigger_auto"); e; e = find(e, classname, "trigger_auto"))
	{
		if (e.globalstate == "") continue;
		e.think = Trigger_TriggerAutoThink;
		e.nextthink = time + 0.1;
	}
}