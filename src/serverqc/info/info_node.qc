
.float hinttype;
.float activity;

void Node_Record(float realm)
{
    self.movetype = MOVETYPE_NONE;
    self.solid    = SOLID_NOT;

    if (placed_count >= NODE_MAX) { remove(self); return; }


    placed_origin[placed_count]   = self.origin;
    placed_realm[placed_count]    = realm;
    placed_hintyaw[placed_count]  = self.angles_y;
    placed_hinttype[placed_count] = self.hinttype;
    placed_hintact[placed_count]  = self.activity;
    placed_count = placed_count + 1;

    remove(self);
}

void info_node()     { Node_Record(NODE_REALM_LAND); }
void info_node_air() { Node_Record(NODE_REALM_AIR); }
