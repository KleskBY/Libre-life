/* On-screen touch controls bridge.
   TouchOverlay.java runs on the Android UI thread and writes here through JNI;
   the engine thread drains it. Android_Touch_Frame runs from Sys_SendKeyEvents on
   every host frame (menus included); Android_Touch_Move runs from IN_Move, after
   CL_Input has reset the move command, and only matters in gameplay. Movement and
   look are analog; buttons become real key events so they follow the binds. */

#ifndef _GNU_SOURCE
#define _GNU_SOURCE // cpu_set_t / sched_setaffinity; normally supplied by CMake before the force-included compat header
#endif
#include <jni.h>
#include <SDL.h>
#include <android/log.h>
#include <dlfcn.h>
#include <sched.h>
#include <unistd.h>
#include <sys/syscall.h>
#include <time.h>

#include "quakedef.h"

#define TOUCH_QUEUE_SIZE 64
#define TOUCH_LOG(...) __android_log_print(ANDROID_LOG_INFO, "ObjectNTouch", __VA_ARGS__)

typedef struct touch_keyevent_s
{
	int key;
	qbool down;
} touch_keyevent_t;

#define TOUCH_POINTER_MOVE 0
#define TOUCH_POINTER_DOWN 1
#define TOUCH_POINTER_UP 2

typedef struct touch_pointerevent_s
{
	int phase;
	float x, y;
	qbool homed; // engine thread: press has already triggered a cursor resync
} touch_pointerevent_t;

double android_swap_accum, android_sleep_accum; // seconds spent in SDL_GL_SwapWindow / Host_Sleep since the last Android_Touch_Frame
double android_csqc_cursor_time; // last time CSQC drew its own mouse cursor (set in VM_drawpic)
qbool android_touch_cursor_ui; // game code owns the pointer: no sticks, no mouse look

static SDL_SpinLock touch_lock;
static float touch_move_x, touch_move_y;
static float touch_look_dx, touch_look_dy;
static touch_keyevent_t touch_keyqueue[TOUCH_QUEUE_SIZE];
static int touch_keyqueue_head, touch_keyqueue_tail;
static touch_pointerevent_t touch_pointerqueue[TOUCH_QUEUE_SIZE];
static int touch_pointerqueue_head, touch_pointerqueue_tail;

static volatile int touch_state; // bit 0 in game, bit 1 console open, bit 2 menu, bit 3 game cursor UI
static volatile int touch_keyboard_request; // player asked for the soft keyboard while the console is open

void VID_ShowKeyboard(qbool show);
qbool VID_ShowingKeyboard(void);

JNIEXPORT void JNICALL Java_by_quake_zircon_TouchOverlay_nativeRequestKeyboard(JNIEnv *env, jclass cls, jboolean show)
{
	(void)env; (void)cls;
	touch_keyboard_request = show ? 1 : 0;
}

// engine thread only
static touch_pointerevent_t touch_pointerpending[TOUCH_QUEUE_SIZE];
static int touch_numpointerpending;
static float touch_cursor_x, touch_cursor_y;
static qbool touch_cursor_valid, touch_cursor_applied;
static qbool touch_cvars_registered;
static int touch_laststate = -1;

cvar_t touch_look_sensitivity = {CF_CLIENT | CF_ARCHIVE, "touch_look_sensitivity", "0.3", "view rotation in degrees per dp of finger drag"};
cvar_t touch_look_invert = {CF_CLIENT | CF_ARCHIVE, "touch_look_invert", "0", "invert vertical touch look"};
cvar_t mobile_viewscale = {CF_CLIENT | CF_ARCHIVE, "mobile_viewscale", "0.7", "3D render resolution on mobile; replaces r_viewscale whenever game code resets it to 1"};
cvar_t mobile_affinity = {CF_CLIENT | CF_ARCHIVE, "mobile_affinity", "1", "pin the engine thread to the fastest CPU cores (big.LITTLE phones otherwise migrate it onto efficiency cores mid-frame)"};
cvar_t touch_cursor_pic = {CF_CLIENT | CF_ARCHIVE, "touch_cursor_pic", "gfx/cursor", "picture the game draws for its own mouse cursor; while it is on screen touches drive that cursor instead of the movement controls"};
cvar_t touch_cursor_auto = {CF_CLIENT | CF_ARCHIVE, "touch_cursor_auto", "1", "switch the touch controls to pointer mode whenever game code draws touch_cursor_pic (the ObjectN lobby)"};
cvar_t mobile_perfhint = {CF_CLIENT | CF_ARCHIVE, "mobile_perfhint", "1", "report frame work time to Android's performance hint API (Android 13+) so the scheduler keeps the engine thread boosted"};

/* CPU scheduling. The engine is single threaded and on big.LITTLE SoCs the scheduler
   moves it between core types and lets fast cores idle down between frames, which
   shows up as 45-50 ms frames no matter what is rendered. */
static int mobile_affinity_applied = -1;
static int mobile_bigcore_mask_bits;

static void Android_Perf_ApplyAffinity(int enable)
{
	cpu_set_t set;
	long maxfreq[64];
	long best = 0;
	int ncpu = (int)sysconf(_SC_NPROCESSORS_CONF);
	int i, count = 0;

	if (ncpu <= 0 || ncpu > 64)
		ncpu = 8;
	CPU_ZERO(&set);
	if (enable) {
		for (i = 0; i < ncpu; i++) {
			char path[128];
			FILE *f;
			maxfreq[i] = 0;
			dpsnprintf(path, sizeof(path), "/sys/devices/system/cpu/cpu%d/cpufreq/cpuinfo_max_freq", i);
			f = fopen(path, "rb");
			if (f) {
				if (fscanf(f, "%ld", &maxfreq[i]) != 1)
					maxfreq[i] = 0;
				fclose(f);
			}
			if (maxfreq[i] > best)
				best = maxfreq[i];
		}
		for (i = 0; i < ncpu; i++) {
			// cores within 10% of the fastest cluster; unknown frequencies fall back to the top quarter
			if ((best > 0 && maxfreq[i] >= best * 9 / 10) || (best == 0 && i >= ncpu - ncpu / 4)) {
				CPU_SET(i, &set);
				count++;
			}
		}
	}
	if (!enable || count == 0 || count == ncpu) {
		CPU_ZERO(&set);
		for (i = 0; i < ncpu; i++)
			CPU_SET(i, &set);
		count = ncpu;
	}
	if (sched_setaffinity(0, sizeof(set), &set) == 0)
		TOUCH_LOG("engine thread affinity: %d of %d cores (%s)", count, ncpu, enable ? "fast cores" : "all cores");
	else
		TOUCH_LOG("sched_setaffinity failed");
	mobile_bigcore_mask_bits = count;
}

typedef struct APerformanceHintManager APerformanceHintManager;
typedef struct APerformanceHintSession APerformanceHintSession;
static APerformanceHintManager *(*perf_getManager)(void);
static APerformanceHintSession *(*perf_createSession)(APerformanceHintManager *, const int32_t *, size_t, int64_t);
static int (*perf_reportActual)(APerformanceHintSession *, int64_t);
static void (*perf_closeSession)(APerformanceHintSession *);
static APerformanceHintSession *perf_session;
static int perf_loaded = -1;
static int64_t perf_frame_start;

static int64_t Android_NowNanos(void)
{
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	return (int64_t)ts.tv_sec * 1000000000LL + ts.tv_nsec;
}

static void Android_Perf_UpdateHint(int enable)
{
	int64_t now = Android_NowNanos();

	if (perf_loaded < 0) {
		void *lib = dlopen("libandroid.so", RTLD_NOW);
		perf_loaded = 0;
		if (lib) {
			perf_getManager = dlsym(lib, "APerformanceHint_getManager");
			perf_createSession = dlsym(lib, "APerformanceHint_createSession");
			perf_reportActual = dlsym(lib, "APerformanceHint_reportActualWorkDuration");
			perf_closeSession = dlsym(lib, "APerformanceHint_closeSession");
			perf_loaded = perf_getManager && perf_createSession && perf_reportActual && perf_closeSession;
		}
		TOUCH_LOG("performance hint API %s", perf_loaded ? "available" : "not available on this Android version");
	}
	if (!perf_loaded)
		return;

	if (enable && !perf_session) {
		static qbool perf_failed; // devices without a hint HAL refuse every attempt; retrying costs a binder call per frame
		APerformanceHintManager *manager;
		int32_t tid = (int32_t)syscall(SYS_gettid);
		if (perf_failed)
			return;
		manager = perf_getManager();
		if (manager)
			perf_session = perf_createSession(manager, &tid, 1, 16666666LL);
		perf_failed = !perf_session;
		TOUCH_LOG("performance hint session %s", perf_session ? "created (16.7 ms target)" : "could not be created");
		perf_frame_start = now;
		return;
	}
	if (!enable && perf_session) {
		perf_closeSession(perf_session);
		perf_session = NULL;
		TOUCH_LOG("performance hint session closed");
		return;
	}
	if (perf_session && perf_frame_start) {
		int64_t work = now - perf_frame_start;
		if (work > 0 && work < 1000000000LL)
			perf_reportActual(perf_session, work);
	}
	perf_frame_start = now;
}

JNIEXPORT void JNICALL Java_by_quake_zircon_TouchOverlay_nativeSetMove(JNIEnv *env, jclass cls, jfloat x, jfloat y)
{
	(void)env; (void)cls;
	SDL_AtomicLock(&touch_lock);
	touch_move_x = bound(-1.0f, x, 1.0f);
	touch_move_y = bound(-1.0f, y, 1.0f);
	SDL_AtomicUnlock(&touch_lock);
}

JNIEXPORT void JNICALL Java_by_quake_zircon_TouchOverlay_nativeAddLook(JNIEnv *env, jclass cls, jfloat dx, jfloat dy)
{
	(void)env; (void)cls;
	SDL_AtomicLock(&touch_lock);
	touch_look_dx += dx;
	touch_look_dy += dy;
	SDL_AtomicUnlock(&touch_lock);
}

JNIEXPORT void JNICALL Java_by_quake_zircon_TouchOverlay_nativeKey(JNIEnv *env, jclass cls, jstring name, jboolean down)
{
	const char *keyname;
	int keynum;
	int next;
	(void)cls;

	keyname = (*env)->GetStringUTFChars(env, name, NULL);
	if (!keyname)
		return;
	keynum = Key_StringToKeynum(keyname); // read-only table lookup, safe off the engine thread
	TOUCH_LOG("overlay key %s %s", keyname, down ? "down" : "up");
	(*env)->ReleaseStringUTFChars(env, name, keyname);
	if (keynum < 0)
		return;

	SDL_AtomicLock(&touch_lock);
	next = (touch_keyqueue_head + 1) % TOUCH_QUEUE_SIZE;
	if (next != touch_keyqueue_tail) { // full queue drops the event instead of blocking the UI thread
		touch_keyqueue[touch_keyqueue_head].key = keynum;
		touch_keyqueue[touch_keyqueue_head].down = down ? true : false;
		touch_keyqueue_head = next;
	}
	SDL_AtomicUnlock(&touch_lock);
}

JNIEXPORT void JNICALL Java_by_quake_zircon_TouchOverlay_nativeMenuPointer(JNIEnv *env, jclass cls, jfloat x, jfloat y, jint phase)
{
	int next;
	(void)env; (void)cls;
	SDL_AtomicLock(&touch_lock);
	next = (touch_pointerqueue_head + 1) % TOUCH_QUEUE_SIZE;
	if (next != touch_pointerqueue_tail) {
		touch_pointerqueue[touch_pointerqueue_head].phase = phase;
		touch_pointerqueue[touch_pointerqueue_head].x = x;
		touch_pointerqueue[touch_pointerqueue_head].y = y;
		touch_pointerqueue[touch_pointerqueue_head].homed = false;
		touch_pointerqueue_head = next;
	}
	SDL_AtomicUnlock(&touch_lock);
}

/* Console commands from customizable buttons ("+attack", "impulse 10"); drained into the
   command buffer on the engine thread in Android_Touch_Frame. */
#define TOUCH_COMMAND_QUEUE 32
#define TOUCH_COMMAND_LEN 256
static char touch_commandqueue[TOUCH_COMMAND_QUEUE][TOUCH_COMMAND_LEN];
static int touch_commandqueue_head, touch_commandqueue_tail;

JNIEXPORT void JNICALL Java_by_quake_zircon_TouchOverlay_nativeCommand(JNIEnv *env, jclass cls, jstring command)
{
	const char *text;
	int next;
	(void)cls;

	text = (*env)->GetStringUTFChars(env, command, NULL);
	if (!text)
		return;
	SDL_AtomicLock(&touch_lock);
	next = (touch_commandqueue_head + 1) % TOUCH_COMMAND_QUEUE;
	if (next != touch_commandqueue_tail) {
		dp_strlcpy(touch_commandqueue[touch_commandqueue_head], text, TOUCH_COMMAND_LEN);
		touch_commandqueue_head = next;
	}
	SDL_AtomicUnlock(&touch_lock);
	(*env)->ReleaseStringUTFChars(env, command, text);
}

JNIEXPORT jint JNICALL Java_by_quake_zircon_TouchOverlay_nativeGetState(JNIEnv *env, jclass cls)
{
	(void)env; (void)cls;
	return touch_state;
}

/* ObjectN's menu keeps its own cursor as a running sum of getmousepos(), which
   returns in_mouse_x/y deltas while the menu owns the mouse. The QC clamps that
   sum to the screen, so one huge negative delta pins it at 0,0; after that the
   position is known and each frame adds exactly the distance to the finger.
   A click waits until the cursor has sat on the finger for a frame, and down
   and up never share a frame. */
static float touch_qc_x, touch_qc_y;
static qbool touch_qc_synced;
static int touch_qc_settle;

static void Android_Touch_MenuCursorStep(void)
{
	float dx, dy;

	if (!touch_cursor_valid)
		return;
	if (!touch_qc_synced) {
		in_mouse_x = -100000;
		in_mouse_y = -100000;
		touch_qc_x = touch_qc_y = 0;
		touch_qc_synced = true;
		touch_qc_settle = 0;
		return;
	}
	dx = touch_cursor_x - touch_qc_x;
	dy = touch_cursor_y - touch_qc_y;
	if (dx != 0 || dy != 0) {
		in_mouse_x += dx;
		in_mouse_y += dy;
		touch_qc_x = touch_cursor_x;
		touch_qc_y = touch_cursor_y;
		touch_qc_settle = 0;
	} else {
		touch_qc_settle++;
	}
}

static void Android_Touch_MenuPointer(void)
{
	int i, consumed = 0;
	touch_pointerevent_t *ev;

	touch_cursor_applied = touch_qc_synced && touch_qc_settle >= 1 && touch_cursor_x == touch_qc_x && touch_cursor_y == touch_qc_y;

	for (i = 0; i < touch_numpointerpending; i++) {
		ev = &touch_pointerpending[i];
		if (ev->phase == TOUCH_POINTER_MOVE) {
			touch_cursor_x = ev->x;
			touch_cursor_y = ev->y;
			touch_cursor_valid = true;
			consumed = i + 1;
			continue;
		}
		if (ev->phase == TOUCH_POINTER_DOWN && !ev->homed) {
			ev->homed = true;
			touch_qc_synced = false; // resync on every press in case something else moved the menu cursor
			touch_cursor_x = ev->x;
			touch_cursor_y = ev->y;
			touch_cursor_valid = true;
			break;
		}
		if (!touch_cursor_valid || touch_cursor_x != ev->x || touch_cursor_y != ev->y || !touch_cursor_applied) {
			touch_cursor_x = ev->x;
			touch_cursor_y = ev->y;
			touch_cursor_valid = true;
			break;
		}
		TOUCH_LOG("menu click %s at %.0f,%.0f (in_client_mouse %d, key_dest %d)", ev->phase == TOUCH_POINTER_DOWN ? "down" : "up", ev->x, ev->y, (int)in_client_mouse, (int)key_dest);
		Key_Event(K_MOUSE1, 0, ev->phase == TOUCH_POINTER_DOWN);
		consumed = i + 1;
		break;
	}

	if (consumed > 0) {
		memmove(touch_pointerpending, touch_pointerpending + consumed, (touch_numpointerpending - consumed) * sizeof(touch_pointerpending[0]));
		touch_numpointerpending -= consumed;
	}
}

qbool Android_Touch_CursorOverride(float *x, float *y)
{
	if (!touch_cursor_valid)
		return false;
	*x = touch_cursor_x;
	*y = touch_cursor_y;
	touch_cursor_applied = true;
	return true;
}

void Android_Touch_Frame(void)
{
	touch_keyevent_t events[TOUCH_QUEUE_SIZE];
	int numevents = 0;
	int i, state;
	keydest_e keydest = Have_Flag(key_consoleactive, KEY_CONSOLEACTIVE_USER_1) ? key_console : key_dest;

	if (!touch_cvars_registered) {
		Cvar_RegisterVariable(&touch_look_sensitivity);
		Cvar_RegisterVariable(&touch_look_invert);
		Cvar_RegisterVariable(&mobile_viewscale);
		Cvar_RegisterVariable(&mobile_affinity);
		Cvar_RegisterVariable(&mobile_perfhint);
		Cvar_RegisterVariable(&touch_cursor_pic);
		Cvar_RegisterVariable(&touch_cursor_auto);
		touch_cvars_registered = true;
	}

	{
		// Frame-time summary every 5 s without per-frame console output; host_speeds prints a
		// line per frame, and that logging can itself cause periodic stalls on phone storage.
		static int64_t stat_last, stat_window_start;
		static unsigned short stat_ms[2048];
		static int stat_count;
		static double slow_swap, slow_sleep, slow_total, fast_swap, fast_sleep, fast_total;
		static int slow_n, fast_n;
		int64_t now = Android_NowNanos();
		double swap = android_swap_accum * 1000.0, slp = android_sleep_accum * 1000.0;
		android_swap_accum = android_sleep_accum = 0;
		if (stat_last) {
			int ms = (int)((now - stat_last) / 1000000);
			if (stat_count < (int)(sizeof(stat_ms) / sizeof(stat_ms[0])))
				stat_ms[stat_count++] = (unsigned short)(ms > 65535 ? 65535 : ms);
			if (ms > 33) {
				slow_swap += swap; slow_sleep += slp; slow_total += ms; slow_n++;
			} else {
				fast_swap += swap; fast_sleep += slp; fast_total += ms; fast_n++;
			}
		} else {
			stat_window_start = now;
		}
		stat_last = now;
		if (now - stat_window_start >= 5000000000LL && stat_count > 0) {
			int hist[256] = {0}, k, acc, med = 0, p90 = 0, over33 = 0, maxms = 0;
			for (k = 0; k < stat_count; k++) {
				int v = stat_ms[k];
				hist[v > 255 ? 255 : v]++;
				if (v > 33) over33++;
				if (v > maxms) maxms = v;
			}
			for (k = 0, acc = 0; k < 256; k++) {
				acc += hist[k];
				if (!med && acc >= stat_count / 2) med = k ? k : 1;
				if (!p90 && acc >= stat_count * 9 / 10) { p90 = k; break; }
			}
			TOUCH_LOG("frames %d in 5s: median %d ms, p90 %d ms, >33ms %.1f%%, max %d ms", stat_count, med, p90, 100.0 * over33 / stat_count, maxms);
			// previous frame's swap/sleep land in this frame's interval, so the split is approximate by one frame
			TOUCH_LOG("  slow frames avg: total %.1f swap %.1f sleep %.1f | fast frames avg: total %.1f swap %.1f sleep %.1f",
				slow_n ? slow_total / slow_n : 0, slow_n ? slow_swap / slow_n : 0, slow_n ? slow_sleep / slow_n : 0,
				fast_n ? fast_total / fast_n : 0, fast_n ? fast_swap / fast_n : 0, fast_n ? fast_sleep / fast_n : 0);
			slow_swap = slow_sleep = slow_total = fast_swap = fast_sleep = fast_total = 0;
			slow_n = fast_n = 0;
			stat_count = 0;
			stat_window_start = now;
		}
	}

	if (mobile_affinity.integer != mobile_affinity_applied) {
		Android_Perf_ApplyAffinity(mobile_affinity.integer != 0);
		mobile_affinity_applied = mobile_affinity.integer;
	}
	// runs once per host frame on the engine thread, so frame-to-frame delta is the work duration
	Android_Perf_UpdateHint(mobile_perfhint.integer != 0);

	{
		// Debug hook: files/data/android_cmd.cfg (pushed over adb) runs once as console input, then is deleted.
		// Lets settings be changed live on device for A/B profiling without restarting the engine.
		static double lastpoll;
		if (host.realtime - lastpoll > 1.0) {
			const char *base = SDL_AndroidGetInternalStoragePath();
			char path[1024];
			FILE *f;
			lastpoll = host.realtime;
			dpsnprintf(path, sizeof(path), "%s/data/android_cmd.cfg", base ? base : ".");
			f = fopen(path, "rb");
			if (f) {
				char buf[4096];
				size_t n = fread(buf, 1, sizeof(buf) - 2, f);
				fclose(f);
				remove(path);
				buf[n] = '\n';
				buf[n + 1] = 0;
				TOUCH_LOG("android_cmd.cfg: %s", buf);
				Cbuf_AddText(cmd_local, buf);
			}
		}
	}

	{
		// ObjectN's CSQC sets r_viewscale 1 on init and after note pages (0 while a page is up); keep 0 intact
		cvar_t *viewscale = Cvar_FindVar(&cvars_all, "r_viewscale", ALL_FLAGS_ANTIZERO);
		if (viewscale && viewscale->value == 1 && mobile_viewscale.value > 0 && mobile_viewscale.value != 1) {
			static qbool logged;
			Cvar_SetValueQuick(viewscale, mobile_viewscale.value);
			if (!logged) {
				TOUCH_LOG("r_viewscale 1 replaced by mobile_viewscale %.2f", mobile_viewscale.value);
				logged = true;
			}
		}
	}

	{
		// World realtime lighting and all shadows are unsupported on mobile; the Graphics menu presets
		// would otherwise turn them back on. Dynamic lights stay available for the flashlight.
		static const char *forced_off[] = { "r_shadow_realtime_dlight_shadows", "r_shadow_realtime_world", "r_shadow_realtime_world_shadows" };
		for (i = 0; i < (int)(sizeof(forced_off) / sizeof(forced_off[0])); i++) {
			cvar_t *var = Cvar_FindVar(&cvars_all, forced_off[i], ALL_FLAGS_ANTIZERO);
			if (var && var->integer)
				Cvar_SetValueQuick(var, 0);
		}
	}

	{
		// The lobby and page UI keep key_dest at key_game while drawing their own cursor,
		// so the drawn cursor picture is the only signal that the screen wants a pointer.
		double age = host.realtime - android_csqc_cursor_time;
		android_touch_cursor_ui = touch_cursor_auto.integer && android_csqc_cursor_time > 0
			&& age >= 0 && age < 0.25 && keydest == key_game && cls.state == ca_connected;
	}

	SDL_AtomicLock(&touch_lock);
	while (touch_keyqueue_tail != touch_keyqueue_head) {
		events[numevents++] = touch_keyqueue[touch_keyqueue_tail];
		touch_keyqueue_tail = (touch_keyqueue_tail + 1) % TOUCH_QUEUE_SIZE;
	}
	while (touch_commandqueue_tail != touch_commandqueue_head) {
		Cbuf_AddText(cmd_local, touch_commandqueue[touch_commandqueue_tail]);
		Cbuf_AddText(cmd_local, "\n");
		touch_commandqueue_tail = (touch_commandqueue_tail + 1) % TOUCH_COMMAND_QUEUE;
	}
	while (touch_pointerqueue_tail != touch_pointerqueue_head && touch_numpointerpending < TOUCH_QUEUE_SIZE) {
		touch_pointerpending[touch_numpointerpending++] = touch_pointerqueue[touch_pointerqueue_tail];
		touch_pointerqueue_tail = (touch_pointerqueue_tail + 1) % TOUCH_QUEUE_SIZE;
	}
	SDL_AtomicUnlock(&touch_lock);

	for (i = 0; i < numevents; i++)
		Key_Event(events[i].key, 0, events[i].down);

	Android_Touch_MenuPointer();
	if (keydest == key_menu || keydest == key_menu_grabbed || android_touch_cursor_ui)
		Android_Touch_MenuCursorStep();

	state = (keydest == key_game ? 1 : 0) | (keydest == key_console ? 2 : 0) | (keydest == key_menu || keydest == key_menu_grabbed ? 4 : 0)
		| (android_touch_cursor_ui ? 8 : 0);
	if (state != touch_laststate) {
		TOUCH_LOG("state %d (key_dest %d, in_client_mouse %d)", state, (int)key_dest, (int)in_client_mouse);
		touch_laststate = state;
	}
	touch_state = state;

	{
		// chat always needs typing; the console only when the player asked, since it also appears during loads
		qbool want;
		if (keydest != key_console)
			touch_keyboard_request = 0;
		want = keydest == key_message || (keydest == key_console && touch_keyboard_request);
		if (want != VID_ShowingKeyboard())
			VID_ShowKeyboard(want);
	}
}

void Android_Touch_Move(keydest_e keydest)
{
	float mx, my, dx, dy;

	SDL_AtomicLock(&touch_lock);
	mx = touch_move_x;
	my = touch_move_y;
	dx = touch_look_dx;
	dy = touch_look_dy;
	touch_look_dx = touch_look_dy = 0;
	SDL_AtomicUnlock(&touch_lock);

	if (keydest != key_game || cls.state != ca_connected || android_touch_cursor_ui)
		return; // pointer mode: the finger drives the game's cursor, not the view

	cl.mcmd.clx_forwardmove -= my * cl_forwardspeed.value;
	cl.mcmd.clx_sidemove += mx * cl_sidespeed.value;

	cl.viewangles[YAW] -= dx * touch_look_sensitivity.value;
	cl.viewangles[PITCH] += dy * touch_look_sensitivity.value * (touch_look_invert.integer ? -1.0f : 1.0f);
}
