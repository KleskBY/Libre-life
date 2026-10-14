
#define SF_CONVEYOR_VISUAL		0x0001
#define SF_CONVEYOR_NOTSOLID	0x0002

//TODO
void Conveyor_UpdateSpeed(float speed)
{
}

void Conveyor_Use()
{
    self.speed = -self.speed;
    Conveyor_UpdateSpeed(self.speed);
}

void Conveyor_UseHL(entity pActivator, entity pCaller, float useTypeArg, float useValueArg)
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

    if (self.spawnflags & SF_CONVEYOR_NOTSOLID)
    {
        self.solid = SOLID_NOT;
        self.skin = 0;
    }
    if (self.speed == 0) self.speed = 100;
    Conveyor_UpdateSpeed(self.speed);
    self.use = Conveyor_Use;
    self.usehl = Conveyor_UseHL;
}