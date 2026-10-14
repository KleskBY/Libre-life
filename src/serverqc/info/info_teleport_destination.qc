
void info_teleport_destination()
{
    self.solid    = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
    self.effects  = self.effects | EF_NODRAW;
}
