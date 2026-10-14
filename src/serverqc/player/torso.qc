// Handles the two-entity player body split.

.entity torso_ent;
.entity weapon_ent;       // held w_ world model attached to the hand bone
.float  weapon_ent_wid;   // cached weapon for change detection
.entity hitbox_ent;       // upper body collision proxy, two entity path only

void Player_HitboxSync(entity p);   // defined at the foot of this file
#define PLAYER_MODEL_FULL   "models/player.iqm"
#define PLAYER_MODEL_LEGS   "models/player_legs.iqm"
#define PLAYER_MODEL_TORSO  "models/player_torso.iqm"

float Player_UseSplitBody()
{
	return !IsFTE();
}

void Player_TorsoHide(entity p)
{
	if (p.torso_ent)
		p.torso_ent.effects = p.torso_ent.effects | EF_NODRAW;
}

// The engine skips owner against owned but not two entities with the same owner,
// so without a shared clipgroup a projectile spawned inside its shooter's own
// hitbox proxy hits it on the first move.
void Player_ProjectileClip(entity proj, entity creator)
{
	if (creator.hitbox_ent) proj.clipgroup = creator.hitbox_ent.clipgroup;
}

void Player_HitboxRemove(entity p)
{
	if (p.hitbox_ent)
	{
		remove(p.hitbox_ent);
		p.hitbox_ent = world;
	}
}

void Player_TorsoRemove(entity p)
{
	Player_HitboxRemove(p);
	if (p.torso_ent)
	{
		remove(p.torso_ent);
		p.torso_ent = world;
	}
	if (p.weapon_ent)
	{
		remove(p.weapon_ent);
		p.weapon_ent = world;
	}
}

string Weapon_WorldModel(float wid)
{
	if (wid == WID_CROWBAR)     return "models/w_crowbar.iqm";
	if (wid == WID_GLOCK)       return "models/w_9mmhandgun.iqm";
	if (wid == WID_PYTHON)      return "models/w_357.iqm";
	if (wid == WID_MP5)         return "models/w_9mmar.iqm";
	if (wid == WID_SHOTGUN)     return "models/w_shotgun.iqm";
	if (wid == WID_CROSSBOW)    return "models/w_crossbow.iqm";
	if (wid == WID_RPG)         return "models/w_rpg.iqm";
	if (wid == WID_GAUSS)       return "models/w_gauss.iqm";
	if (wid == WID_EGON)        return "models/w_egon.iqm";
	if (wid == WID_HORNETGUN)   return "models/w_hgun.iqm";
	if (wid == WID_SNARK)       return "models/w_squeak.iqm";
	if (wid == WID_HANDGRENADE) return "models/w_grenade.iqm";
	if (wid == WID_SATCHEL)     return "models/w_satchel.iqm";
	return "";
}

vector Weapon_GripOrigin(float wid)
{
	if (wid == WID_CROWBAR)     return '3 0.5 5';
	if (wid == WID_GLOCK)       return '6 1 1';
	if (wid == WID_PYTHON)      return '6 1.5 2.5';
	if (wid == WID_MP5)         return '8 0 4';
	if (wid == WID_SHOTGUN)     return '10 1.5 2.5';
	if (wid == WID_CROSSBOW)    return '8 0 0';
	if (wid == WID_HANDGRENADE) return '2 1.5 -3';
	if (wid == WID_RPG)         return '0 5 0';
	if (wid == WID_SATCHEL)     return '2 1.5 -3';
	if (wid == WID_TRIPMINE)    return '2 1.5 -3';
	if (wid == WID_GAUSS)       return '4 0 0';
	if (wid == WID_EGON)        return '-14 6 0';
	if (wid == WID_HORNETGUN)   return '-4 -1 -4';
	if (wid == WID_SNARK)       return '2 1.5 -3';
	return '6 1 0';
}
vector Weapon_GripAngles(float wid)
{
	if (wid == WID_CROWBAR)     return '90 0 -90';
	if (wid == WID_GLOCK)       return '0 180 -90';
	if (wid == WID_PYTHON)      return '0 180 -90';
	if (wid == WID_MP5)         return '-90 90 0';
	if (wid == WID_SHOTGUN)     return '0 180 -90';
	if (wid == WID_CROSSBOW)    return '0 180 0';
	if (wid == WID_HANDGRENADE) return '0 0 0';
	if (wid == WID_RPG)         return '0 0 0';
	if (wid == WID_SATCHEL)     return '0 0 0';
	if (wid == WID_TRIPMINE)    return '0 0 0';
	if (wid == WID_GAUSS)       return '0 180 0';
	if (wid == WID_EGON)        return '0 0 0';
	if (wid == WID_HORNETGUN)   return '0 180 0';
	if (wid == WID_SNARK)       return '0 0 0';
	return '0 180 -90';
}

void Player_WeaponModelPrecache()
{
	precache_model("models/w_crowbar.iqm");
	precache_model("models/w_9mmhandgun.iqm");
	precache_model("models/w_357.iqm");
	precache_model("models/w_9mmar.iqm");
	precache_model("models/w_shotgun.iqm");
	precache_model("models/w_crossbow.iqm");
	precache_model("models/w_rpg.iqm");
	precache_model("models/w_gauss.iqm");
	precache_model("models/w_egon.iqm");
	precache_model("models/w_hgun.iqm");
	precache_model("models/w_squeak.iqm");
	precache_model("models/w_grenade.iqm");
	precache_model("models/w_satchel.iqm");
}

void Player_WeaponModelSync(entity p)
{
	entity holder = Player_UseSplitBody() ? p.torso_ent : p;
	if (!holder) return;

	if (!p.weapon_ent)
	{
		entity nw = spawn();
		nw.classname = "player_weaponmodel";
		nw.owner     = p;
		nw.solid     = SOLID_NOT;
		nw.movetype  = MOVETYPE_NONE;
		nw.scale	 = 0.5;
		p.weapon_ent = nw;
		p.weapon_ent_wid = -1;
	}
	entity w = p.weapon_ent;

	// self.weapon is the WEAPON_* bitflag: convert to the WID the tables use.
	float wid = Weapon_IDFromBit(p.weapon);

	// Hide when dead/observer/corpse or the weapon has no world model.
	string mdl = Weapon_WorldModel(wid);
	float bodyOk = IsFTE() ? (p.deadflag == DEAD_NO) : (p.model == PLAYER_MODEL_LEGS);
	if (mdl == "" || !bodyOk)
	{
		w.effects = w.effects | EF_NODRAW;
		p.weapon_ent_wid = -2;   // force re-setup when the body/weapon returns
		return;
	}
	w.effects = w.effects - (w.effects & EF_NODRAW);

	if (wid != p.weapon_ent_wid || w.tag_entity != holder)
	{
		p.weapon_ent_wid = wid;
		setmodel(w, mdl);
		setattachment(w, holder, "Bip01 R Hand");
		w.origin = Weapon_GripOrigin(wid);
		w.angles = Weapon_GripAngles(wid);
	}
}

void Player_WeaponGripSet(entity p, vector org, vector ang)
{
	if (!p.weapon_ent) { sprint(p, "no weapon model\n"); return; }
	p.weapon_ent.origin = org;
	p.weapon_ent.angles = ang;
	float wid = Weapon_IDFromBit(p.weapon);
	sprint(p, strcat("wgrip wid=", ftos(wid), "  origin='", vtos(org),
	                 "'  angles='", vtos(ang), "'\n"));
}

void Player_TorsoEnsure(entity p)
{
	if (p.torso_ent && p.torso_ent.classname == "player_torso" && p.torso_ent.tag_entity == p)
		return;

	entity t = spawn();
	t.classname = "player_torso";
	t.owner     = p;
	t.solid     = SOLID_NOT;
	t.movetype  = MOVETYPE_NONE;
	// t.effects   = EF_NOSHADOW;        // the legs (player ent) cast the shadow
	setmodel(t, PLAYER_MODEL_TORSO);
	setsize(t, '0 0 0', '0 0 0');
	setattachment(t, p, "");
	p.torso_ent = t;
}

// Call AFTER both entities' frames are set for the tick (post PlayerAnim).
void Player_TorsoAlignSpine(entity p)
{
	if (!Player_UseSplitBody()) return;
	entity t = p.torso_ent;
	if (!t || p.model != PLAYER_MODEL_LEGS) return;

	float lt = gettagindex(p, "Bip01 Spine");
	float tt = gettagindex(t, "Bip01 Spine");
	if (lt <= 0 || tt <= 0) return;

	vector ls = gettaginfo(p, lt);   // legs spine, world (gait pose)
	vector ts = gettaginfo(t, tt);   // torso spine, world (aim pose @ current offset)
	// t.origin is a local offset in the parent's space, so a world-space delta that must be divided back out of the parent's scale (id1 maps shrink it).
	t.origin_z = t.origin_z + (ls_z - ts_z) / PLAYER_MODEL_SCALE;
}

void Player_TorsoSync(entity p)
{
	Player_HitboxSync(p);   // ahead of the gate: FTE must tear down, not just skip
	if (!Player_UseSplitBody()) return;

	if (p.model != PLAYER_MODEL_LEGS)
	{
		Player_TorsoHide(p);
		return;
	}

	Player_TorsoEnsure(p);
	entity t = p.torso_ent;

	t.skin     = p.skin;
	t.colormap = p.colormap;
	t.alpha    = p.alpha;
	t.colormod = p.colormod;
	t.angles   = '0 0 0';
	if (p.effects & EF_NODRAW)
		t.effects = t.effects | EF_NODRAW;
	else
		t.effects = (t.effects - (t.effects & EF_NODRAW)) /*| EF_NOSHADOW*/;
}

// Upper body collision proxy. See docs/guide/08-player.md, "The upper body
// hitbox", for why each property below is what it is.
#define PLAYER_HITBOX_WAIST 0.4   // fraction of hull height where the torso starts

void Player_HitboxSync(entity p)
{
	if (!Player_UseSplitBody())
	{
		if (p.hitbox_ent) Player_HitboxRemove(p);
		return;
	}

	if (p.deadflag != DEAD_NO || p.classname != "player")
	{
		if (p.hitbox_ent) p.hitbox_ent.solid = SOLID_NOT;   // the corpse is its own body
		return;
	}

	entity hb = p.hitbox_ent;
	if (!hb || wasfreed(hb))
	{
		hb = spawn();
		hb.classname  = "player_hitbox";
		hb.owner      = p;
		hb.movetype   = MOVETYPE_NONE;
		hb.modelindex = 0;          // no mesh, so MOVE_HITMODEL_4 falls back to the box
		p.hitbox_ent  = hb;
	}

	hb.solid = SOLID_CORPSE;        // skipped by SOLID_SLIDEBOX ignore ents, hit by SOLID_BBOX shooters
	hb.clipgroup = num_for_edict(p);   // shared with this player's projectiles, see Player_ProjectileClip

	// Inset one unit inside the hull on every face but the waist, so hull traces
	// always reach the player first and only the mesh trace reaches the proxy.
	float waist = p.mins_z + (p.maxs_z - p.mins_z) * PLAYER_HITBOX_WAIST;
	setsize(hb, [p.mins_x + 1, p.mins_y + 1, waist],
	            [p.maxs_x - 1, p.maxs_y - 1, p.maxs_z - 1]);
	setorigin(hb, p.origin);
}

// Call straight after any traceline meant to hit people. Leaves trace_endpos
// alone: it is the real impact point the hit group is measured from.
void Player_HitboxResolve()
{
	if (trace_ent.classname == "player_hitbox" && trace_ent.owner)
		trace_ent = trace_ent.owner;
}
