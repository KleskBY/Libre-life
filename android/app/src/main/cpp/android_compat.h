#ifndef OBJECTN_ANDROID_COMPAT_H
#define OBJECTN_ANDROID_COMPAT_H

/* Force-included into every engine translation unit on Android.
   The Steam bridge headers use Win32 spellings that have no meaning here. */

#ifndef __cdecl
#define __cdecl
#endif

#ifndef __int32
#define __int32 int
#endif

typedef void *HMODULE;

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#endif
