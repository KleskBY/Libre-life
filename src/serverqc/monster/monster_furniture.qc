
void Furniture_Die()
{
    self.think     = SUB_Remove;
    self.nextthink = time;
}

void monster_furniture()
{
    if (Monster_RemoveIfSpent()) return;
    if (self.model == "")
    {
        dprint("monster_furniture at ");
        dprint(vtos(self.origin));
        dprint(" has no model; removing\n");
        remove(self);
        return;
    }

    precache_model(self.model);
    setmodel(self, self.model);

    self.movetype   = MOVETYPE_NONE;
    self.solid      = SOLID_BBOX;
    self.health     = 80000;
    self.max_health = self.health;
    self.takedamage = DAMAGE_AIM;
    self.effects    = 0;
    self.yaw_speed  = 0;
    self.frame      = 0;
    self.flags      = self.flags | FL_MONSTER;

    // No state machine, no AI. Only scripted_sequence drives anim.
    self.th_die = Furniture_Die;

}
