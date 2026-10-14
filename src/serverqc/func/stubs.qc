
void infodecal() { remove(self); }
void env_sound() { remove(self); }
void trigger_transition() { remove(self); }
void light_environment() { remove(self); }

void env_spark();
void env_debris() { env_spark(); }
void env_smoker() { remove(self); }

// system; not ported
void func_mortar_field() { remove(self); }

// Ambient critters without models
void monster_rat()     { remove(self); }
void monster_bloater() { remove(self); }

// scripted_sequence instead; stub the legacy classnames.
void monster_cine_scientist()   { remove(self); }
void monster_cine_panther()     { remove(self); }
void monster_cine_barney()      { remove(self); }
void monster_cine2_scientist()  { remove(self); }
void monster_cine2_hvyweapons() { remove(self); }
void monster_cine2_slave()      { remove(self); }
void monster_cine3_scientist()  { remove(self); }
void monster_cine3_barney()     { remove(self); }

