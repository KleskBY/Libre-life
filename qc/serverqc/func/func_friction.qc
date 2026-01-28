
void Trigger_ChangeFriction()
{
	//cvar_set("sv_friction", 
	other.velocity = other.velocity * (1 - frametime * cvar("sv_friction"));
};

void func_friction()
{
	self.solid = SOLID_TRIGGER;
	setmodel(self, self.model);
	self.movetype = MOVETYPE_NONE;
	self.touch = Trigger_ChangeFriction;
}
