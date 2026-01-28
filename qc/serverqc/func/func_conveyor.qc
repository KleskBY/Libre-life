
#define SF_CONVEYOR_VISUAL		0x0001
#define SF_CONVEYOR_NOTSOLID	0x0002

// .vector rendercolor;
void Conveyor_UpdateSpeed(float speed)
{
    // float speedCode = floor(fabs(speed) * 16);
    // if (speed < 0) self.rendercolor_x = 1;
    // else self.rendercolor_x = 0;
    // self.rendercolor_y = floor(speedCode / 256);
    // self.rendercolor_z = speedCode - (self.rendercolor_y * 256);
}

void Conveyor_Use()
{
    self.speed = -self.speed;
    Conveyor_UpdateSpeed(self.speed);
}

void func_conveyor()
{
    SetMovedir();
    self.angles = '0 0 0';
    self.movetype = MOVETYPE_PUSH;
    self.solid = SOLID_BSP;
    setmodel(self, self.model);
    // self.flags = self.flags | FL_WORLDBRUSH;
    // if (!(self.spawnflags & SF_CONVEYOR_VISUAL))
        // self.flags = self.flags | FL_CONVEYOR;
    if (self.spawnflags & SF_CONVEYOR_NOTSOLID)
    {
        self.solid = SOLID_NOT;
        self.skin = 0;
    }
    if (self.speed == 0) self.speed = 100;
    Conveyor_UpdateSpeed(self.speed);
    self.use = Conveyor_Use;
}