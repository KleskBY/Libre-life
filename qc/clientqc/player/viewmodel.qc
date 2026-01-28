
entity playerViewmodel;
void Viewmodel_Create()
{
	if(playerViewmodel) return;
	playerViewmodel = spawn();
	playerViewmodel.drawmask = MASK_ENGINEVIEWMODELS;
	playerViewmodel.renderflags = RF_VIEWMODEL;
	precache_model("models/weapons/v_ak74.md3");
	setmodel(playerViewmodel, "models/weapons/v_ak74.md3");
}