void SV_ChangeTeam(float pcolor)
{

}

void Nametag_SendTo(entity dest);   // nametag.qc

void Bot_Command();                // bot/cmd.qc
void WP_Command();                 // bot/wp_edit.qc

string(entity e, string key) infokey = #0:infokey;	// FTE only; Zircon's #80 is a different builtin

// The player at the server's own keyboard. Remote clients on a listen or
// dedicated server never qualify, so host-only commands cannot be driven by them.
float SV_IsHostClient(entity e)
{
	if (!(e.flags & FL_CLIENT)) return FALSE;
	if (!IsMultiplayer()) return TRUE;
	string addr;
	if (IsFTE()) addr = infokey(e, "ip");
	else addr = e.netaddress;	// "local" for the loopback client
	if (addr == "loopback") return TRUE;
	return substring(addr, 0, 5) == "local";
}

float SV_RequireHost(string what)
{
	if (SV_IsHostClient(self)) return TRUE;
	sprint(self, strcat(what, ": host only\n"));
	return FALSE;
}

float SV_RequireCheats(string what)
{
	if (cvar("sv_cheats")) return TRUE;
	sprint(self, strcat(what, ": requires sv_cheats\n"));
	return FALSE;
}

// Save slot names reach fopen, so only plain file names get through.
float SV_SafeSlotName(string s)
{
	float n = strlen(s);
	if (n < 1 || n > 64) return FALSE;
	if (str2chr(s, 0) == 46) return FALSE;	// leading '.'
	for (float i = 0; i < n; i = i + 1)
	{
		float c = str2chr(s, i);
		if (c >= 48 && c <= 57) continue;
		if (c >= 65 && c <= 90) continue;
		if (c >= 97 && c <= 122) continue;
		if (c == 95 || c == 45 || c == 46) continue;	// _ - .
		return FALSE;
	}
	return strstrofs(s, "..", 0) < 0;
}

void SV_ParseClientCommand(string s)
{
	float argc = tokenize(s);
	string cmd = argv(0); // /say
	string arg1 = argv(1);
	string arg2 = argv(2);
	string arg3 = argv(3); 
	string arg4 = argv(4); 
	if(s == "flashlight")
	{
		Flashlight_Toggle();
		return;
	}
	if(cmd == "bot" || cmd == "bot_add" || cmd == "bot_kick")
	{
		if (!SV_RequireHost(cmd)) return;
		Bot_Command();
		return;
	}
	if(cmd == "wp")
	{
		if (!SV_RequireHost("wp")) return;
		WP_Command();
		return;
	}
	if(cmd == "gs_writesave")
	{
		if (!SV_IsHostClient(self) || !SV_SafeSlotName(arg1)) return;
		GlobalState_WriteCfg(arg1);
		return;
	}
	if(cmd == "gs_restore")
	{
		if (!SV_IsHostClient(self) || !SV_SafeSlotName(arg1)) return;
		GlobalState_RestoreCfg(arg1);
		TriggerAuto_RearmAll();
		return;
	}
	if(cmd == "sbsync")
	{
		if (IsMultiplayer())
		{
			Scoreboard_SendAllTo(self);
			Nametag_SendTo(self);
			if (!(self.flags & FL_CLIENT)) Scoreboard_SendRowTo(self, self);	// not in the client chain until PutClientInServer
		}
		return;
	}
	if(cmd == "p")
	{
		if (!SV_RequireCheats("p")) return;
		setorigin(self, [stof(arg1), stof(arg2), stof(arg3)]);
		return;
	}
	if(cmd == "wgrip")
	{
		if (!SV_RequireCheats("wgrip")) return;
		Player_WeaponGripSet(self, [stof(arg1), stof(arg2), stof(arg3)],
		                           [stof(arg4), stof(argv(5)), stof(argv(6))]);
		return;
	}
	clientcommand(self, s);
};
