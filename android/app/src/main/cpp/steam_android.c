/* Android replacement for the engine's steam.c and steam_net.c.
   Steam is Windows-only here; achievements and relay networking are inert. */

#include "darkplaces.h"
#include "steam.h"
#include "steam_net.h"

#include <SDL.h>

bool g_steamNetInitialized = false;

cvar_t steam_fakeip = { CF_SERVER | CF_READONLY | CF_NOTIFY, "steam_fakeip", "", "Unused on Android." };
cvar_t steam_steamid = { CF_CLIENT | CF_SERVER | CF_READONLY | CF_NOTIFY, "steam_steamid", "", "Unused on Android." };
cvar_t steam_networking = { CF_CLIENT | CF_SERVER, "steam_networking", "0", "Unused on Android." };

bool Steam_Init(void) { return false; }
void Steam_Frame(void) {}
void Steam_Shutdown(void) {}

int Steam_Achivment_Unlock(const char *name) { (void)name; return 0; }
int Steam_Achivment_Lock(const char *name) { (void)name; return 0; }

void Steam_OpenUrl(const char *url)
{
	if (url && url[0])
		SDL_OpenURL(url);
}

void SteamNet_RegisterCvars(void)
{
	Cvar_RegisterVariable(&steam_fakeip);
	Cvar_RegisterVariable(&steam_steamid);
	Cvar_RegisterVariable(&steam_networking);
}

int SteamNet_Init(void) { return 0; }
void SteamNet_Shutdown(void) {}
void SteamNet_ServerStop(void) {}
int SteamNet_ServerStart(void) { return 0; }
void SteamNet_ClientDisconnect(void) {}
int SteamNet_ClientConnectFakeIP(const lhnetaddress_t *server_addr) { (void)server_addr; return 0; }
void SteamNet_Frame(void) {}
bool SteamNet_IsFakeIPAddr(const lhnetaddress_t *a) { (void)a; return false; }
void Steam_InviteFriend_f(cmd_state_t *cmd) { (void)cmd; }

int SteamNet_Read(lhnetsocket_t *s, void *content, int maxcontentlength, lhnetaddress_t *vaddress)
{
	(void)s; (void)content; (void)maxcontentlength; (void)vaddress;
	return -1;
}

int SteamNet_Write(lhnetsocket_t *s, const void *content, int contentlength, const lhnetaddress_t *vaddress)
{
	(void)s; (void)content; (void)contentlength; (void)vaddress;
	return -1;
}

/* Beta 164 guards the definition with STEAM_NETWORKING but calls it unconditionally
   from the net_dropsteamconnection console command. */
void NetConn_DropSteamConnection(uint32_t hConn, const char *reason)
{
	(void)hConn; (void)reason;
}
