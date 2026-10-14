// SSQC-owned first-person weapon entity, replacing the engine viewent.

.entity viewmodel;      // per-client viewmodel entity
.string vm_model;       // last requested viewmodel, latched off self.weaponmodel
.float  vm_restart;     // an anim restart is queued for the next update

// SendWeaponAnim semantics: always restarts, even on the same group.
void Weapon_SetFrame(float grp)
{
	self.weaponframe = grp;     // stat kept for HUD/save/legacy compat
	self.vm_restart  = TRUE;
}

// Permanent hide: the weapon is gone, not merely unavailable this instant.
void Viewmodel_Hide(entity p)
{
	if (p.viewmodel && !wasfreed(p.viewmodel))
		setmodel(p.viewmodel, "");
	p.vm_model    = "";
	p.weaponmodel = "";
}

void Viewmodel_Remove(entity p)
{
	if (p.viewmodel && !wasfreed(p.viewmodel))
		remove(p.viewmodel);
	p.viewmodel = world;
}

void PlayerViewmodel_Update()
{
	if (self.viewmodel && wasfreed(self.viewmodel))
		self.viewmodel = world;

	if (!self.viewmodel)
	{
		entity nvm = spawn();
		nvm.classname          = "player_viewmodel";
		nvm.viewmodelforclient = self;
		nvm.owner              = self;
		nvm.movetype           = MOVETYPE_NONE;
		nvm.solid              = SOLID_NOT;
		nvm.effects            = EF_NOSHADOW;
		setsize(nvm, '0 0 0', '0 0 0');
		self.viewmodel = nvm;
	}
	entity vm = self.viewmodel;

	if (self.weaponmodel != "")   // adopt + clear: keeps the engine viewent empty
	{
		self.vm_model    = self.weaponmodel;
		self.weaponmodel = "";
	}

	if (!IsAlive(self) || gameover || intermission_running
	    || self.classname == "observer" || self.vm_model == "")
	{
		if (vm.modelindex) setmodel(vm, "");
		Viewsway_Reset(self);
		return;
	}

	if (vm.model != self.vm_model) setmodel(vm, self.vm_model);

	vm.frame = self.weaponframe;

	if (self.vm_restart)
	{
		self.vm_restart = FALSE;
		vm.effects += (EF_RESTARTANIM_BIT - 2 * (vm.effects & EF_RESTARTANIM_BIT));
	}

	// Core has no pose chain, so the sway is the whole of the viewmodel's motion.
	Viewsway_Step(self);
	vm.origin = self.sway_origin;
	vm.angles = self.sway_angles;
}
