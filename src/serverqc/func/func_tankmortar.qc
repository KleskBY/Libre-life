// Magnitude is stored on self.iMagnitude

void  FuncTank_Init();
void  FuncTank_BaseFireFX(vector barrelEnd);
vector FuncTank_TankTrace(vector vecStart, vector vecForward, vector vecSpread);
vector FuncTank_GetSpread(float idx);

void FuncTankMortar_Fire(vector barrelEnd, vector forward, entity attacker)
{
    if (self.tank_fireLast != 0)
    {
        float bulletCount = floor((time - self.tank_fireLast) * self.firerate);
        if (bulletCount > 0)
        {
            // Only ever create 1 explosion per fire tick
            makevectors(self.angles);
            vector hit = FuncTank_TankTrace(barrelEnd, forward, FuncTank_GetSpread(self.firespread));
            te_explosion(hit);
            if (self.iMagnitude > 0)
            {
                entity blast = spawn();
                setorigin(blast, hit);
                blast.classname = "tankmortar_blast";
                T_RadiusDamage(blast, self, self.iMagnitude, self.iMagnitude * 2.5, DMG_BLAST);
                remove(blast);
            }
            FuncTank_BaseFireFX(barrelEnd);
        }
    }
    else
    {
        FuncTank_BaseFireFX(barrelEnd);
    }
}

void func_tankmortar()
{
    self.tankFire = FuncTankMortar_Fire;
    FuncTank_Init();
}
