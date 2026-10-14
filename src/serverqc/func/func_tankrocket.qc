
void Rocket_Create(entity creator, vector src, vector ang);   // weapons/rpg.qc
void FuncTank_Init();
void FuncTank_BaseFireFX(vector barrelEnd);

void FuncTankRocket_Fire(vector barrelEnd, vector forward, entity attacker)
{
    if (self.tank_fireLast != 0)
    {
        float bulletCount = floor((time - self.tank_fireLast) * self.firerate);
        if (bulletCount > 0)
        {
            float i;
            for (i = 0; i < bulletCount; i = i + 1)
                Rocket_Create(self, barrelEnd, self.angles);
            FuncTank_BaseFireFX(barrelEnd);
        }
    }
    else
    {
        FuncTank_BaseFireFX(barrelEnd);
    }
}

void func_tankrocket()
{
    precache_model("models/rpgrocket.iqm");
    precache_sound("weapons/rocketfire1.wav");
    precache_sound("weapons/rocket1.wav");
    precache_sound("weapons/explode3.wav");

    self.tankFire = FuncTankRocket_Fire;
    FuncTank_Init();
}
