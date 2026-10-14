
void  FuncTank_Init();
void  FuncTank_Think();
void  FuncTank_BaseFireFX(vector barrelEnd);
vector FuncTank_TankTrace(vector vecStart, vector vecForward, vector vecSpread);
vector FuncTank_GetSpread(float idx);
void  EnvLaser_TurnOn(entity laser);
void  EnvLaser_TurnOff(entity laser);
.entity laser_endSprite;   // mirrored from env_laser.qc (loaded later in serverqc.src)

void FuncTankLaser_Think()
{
    // Auto-shutoff once the laser's last-fired window expires
    if (self.tank_laser && time > self.tank_laserTime)
        EnvLaser_TurnOff(self.tank_laser);
    FuncTank_Think();
}

void FuncTankLaser_Fire(vector barrelEnd, vector forward, entity attacker)
{
    if (!self.tank_laser)
    {
        FuncTank_BaseFireFX(barrelEnd);
        return;
    }

    if (self.tank_fireLast != 0)
    {
        float bulletCount = floor((time - self.tank_fireLast) * self.firerate);
        if (bulletCount > 0)
        {
            makevectors(self.angles);
            float i;
            for (i = 0; i < bulletCount; i = i + 1)
            {
                setorigin(self.tank_laser, barrelEnd);
                vector hit = FuncTank_TankTrace(barrelEnd, forward, FuncTank_GetSpread(self.firespread));

                self.tank_laserTime = time;
                EnvLaser_TurnOn(self.tank_laser);
                self.tank_laser.dmgtime = time - 1.0;  // ensure next StrikeThink applies a full damage tick

                // Position the end sprite at the impact and force an immediate strike.
                if (self.tank_laser.laser_endSprite)
                    setorigin(self.tank_laser.laser_endSprite, hit);
                self.tank_laser.nextthink = 0;
            }
            FuncTank_BaseFireFX(barrelEnd);
        }
    }
    else
    {
        FuncTank_BaseFireFX(barrelEnd);
    }
}

void FuncTankLaser_Activate()
{
    if (!self.message || self.message == "") return;

    entity e = find(world, targetname, self.message);
    while (e)
    {
        if (e.classname == "env_laser")
        {
            self.tank_laser = e;
            EnvLaser_TurnOff(self.tank_laser);
            return;
        }
        e = find(e, targetname, self.message);
    }
    dprint("func_tanklaser: no env_laser with targetname '");
    dprint(self.message);
    dprint("'\n");
}

void FuncTankLaser_DelayedActivate()
{
    FuncTankLaser_Activate();
    self.think = FuncTankLaser_Think;
    self.nextthink = self.ltime + 0.1;
}

void func_tanklaser()
{
    self.tankFire = FuncTankLaser_Fire;
    FuncTank_Init();

    self.think = FuncTankLaser_DelayedActivate;
    self.nextthink = self.ltime + 0.5;
}
