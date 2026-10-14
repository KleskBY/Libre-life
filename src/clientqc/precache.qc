

void Precache()
{
	precache_cubemap("cubemaps/237");
	
	precache_sound("common/wpn_hudon.wav");
	precache_sound("common/wpn_hudoff.wav");
	precache_sound("common/wpn_moveselect.wav");
	precache_sound("common/wpn_select.wav");
	precache_sound("common/wpn_denyselect.wav");
	precache_sound("common/null.wav");
	
	precache_pic("gfx/background");
	precache_pic("gfx/cursor");
	
	// HUD
	precache_pic("gfx/hud_suit_empty");
	precache_pic("gfx/hud_suit_full");
	precache_pic("gfx/hud_cross");
	
	// Damage-type
	precache_pic("gfx/hud_dmg_poison");
	precache_pic("gfx/hud_dmg_chem");
	precache_pic("gfx/hud_dmg_cold");
	precache_pic("gfx/hud_dmg_drown");
	precache_pic("gfx/hud_dmg_heat");
	precache_pic("gfx/hud_dmg_gas");
	precache_pic("gfx/hud_dmg_rad");
	precache_pic("gfx/hud_dmg_shock");
	precache_pic("gfx/hud_flash_empty");
	precache_pic("gfx/hud_flash_full");
	precache_pic("gfx/hud_flash_beam");
	
	//Damage indicator
	precache_pic("gfx/pain_forward");
	precache_pic("gfx/pain_right");
	precache_pic("gfx/pain_back");
	precache_pic("gfx/pain_left");
	
	
	//Train
	precache_pic("gfx/hud_train_stop");
	precache_pic("gfx/hud_train_back");
	precache_pic("gfx/hud_train_forward1");
	precache_pic("gfx/hud_train_forward2");
	precache_pic("gfx/hud_train_forward3");
};
