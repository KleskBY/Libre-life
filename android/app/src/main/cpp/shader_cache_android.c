/* Persistent GLSL program cache for Android.
   Mobile GL drivers spend tens of milliseconds compiling each engine shader permutation,
   which shows up as frame spikes the first time a surface/light combination appears.
   Linked programs are stored with glGetProgramBinary under the app's internal storage and
   restored with glProgramBinary on later runs. The key covers every source string plus the
   GPU renderer and driver version, so a driver update simply misses and recompiles. */

#include <GLES3/gl3.h>
#include <SDL.h>
#include <android/log.h>

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#define CACHE_LOG(...) __android_log_print(ANDROID_LOG_INFO, "ObjectNShaderCache", __VA_ARGS__)
#define CACHE_MAGIC 0x31434853u /* "SHC1" */

static uint64_t cache_pending_key;
static int cache_hits, cache_misses;

static uint64_t fnv1a(uint64_t h, const char *s)
{
	if (!s)
		return h;
	while (*s) {
		h ^= (unsigned char)*s++;
		h *= 1099511628211ull;
	}
	h ^= 0xff; // separator so {"ab","c"} and {"a","bc"} differ
	h *= 1099511628211ull;
	return h;
}

static uint64_t cache_key(int vcount, const char **vlist, int fcount, const char **flist)
{
	uint64_t h = 1469598103934665603ull;
	int i;
	h = fnv1a(h, (const char *)glGetString(GL_RENDERER));
	h = fnv1a(h, (const char *)glGetString(GL_VERSION));
	for (i = 0; i < vcount; i++)
		h = fnv1a(h, vlist[i]);
	h = fnv1a(h, "--frag--");
	for (i = 0; i < fcount; i++)
		h = fnv1a(h, flist[i]);
	return h;
}

static void cache_path(char *out, size_t outsize, uint64_t key)
{
	const char *base = SDL_AndroidGetInternalStoragePath();
	snprintf(out, outsize, "%s/shadercache/%016llx.bin", base ? base : ".", (unsigned long long)key);
}

// Returns a linked program object on a cache hit, 0 on a miss (caller compiles and then calls Save).
unsigned int Android_ShaderCache_Load(int vcount, const char **vlist, int fcount, const char **flist)
{
	char path[1024];
	FILE *f;
	uint32_t header[3]; // magic, binary format, length
	void *blob;
	GLuint program;
	GLint linked = 0;

	cache_pending_key = cache_key(vcount, vlist, fcount, flist);
	cache_path(path, sizeof(path), cache_pending_key);

	f = fopen(path, "rb");
	if (!f) {
		cache_misses++;
		return 0;
	}
	if (fread(header, sizeof(header), 1, f) != 1 || header[0] != CACHE_MAGIC || header[2] == 0 || header[2] > 64 * 1024 * 1024) {
		fclose(f);
		remove(path);
		cache_misses++;
		return 0;
	}
	blob = malloc(header[2]);
	if (!blob || fread(blob, header[2], 1, f) != 1) {
		free(blob);
		fclose(f);
		remove(path);
		cache_misses++;
		return 0;
	}
	fclose(f);

	program = glCreateProgram();
	glProgramBinary(program, (GLenum)header[1], blob, (GLsizei)header[2]);
	free(blob);
	glGetProgramiv(program, GL_LINK_STATUS, &linked);
	while (glGetError() != GL_NO_ERROR) {
	}
	if (!linked) {
		// driver rejected it (updated driver, changed GPU state); recompile and overwrite
		glDeleteProgram(program);
		remove(path);
		cache_misses++;
		return 0;
	}
	cache_hits++;
	if ((cache_hits + cache_misses) % 10 == 0)
		CACHE_LOG("%d hits, %d misses", cache_hits, cache_misses);
	return program;
}

// Stores the program that was just compiled for the key computed by the preceding Load call.
void Android_ShaderCache_Save(unsigned int program)
{
	char dir[1024], path[1024];
	const char *base = SDL_AndroidGetInternalStoragePath();
	GLint length = 0;
	GLenum format = 0;
	GLsizei written = 0;
	void *blob;
	FILE *f;
	uint32_t header[3];

	if (!program || !cache_pending_key)
		return;
	glGetProgramiv(program, GL_PROGRAM_BINARY_LENGTH, &length);
	if (length <= 0)
		return; // driver cannot export binaries; nothing to cache
	blob = malloc(length);
	if (!blob)
		return;
	glGetProgramBinary(program, length, &written, &format, blob);
	while (glGetError() != GL_NO_ERROR) {
	}
	if (written <= 0) {
		free(blob);
		return;
	}

	snprintf(dir, sizeof(dir), "%s/shadercache", base ? base : ".");
	mkdir(dir, 0700);
	cache_path(path, sizeof(path), cache_pending_key);
	f = fopen(path, "wb");
	if (f) {
		header[0] = CACHE_MAGIC;
		header[1] = (uint32_t)format;
		header[2] = (uint32_t)written;
		fwrite(header, sizeof(header), 1, f);
		fwrite(blob, written, 1, f);
		fclose(f);
	}
	free(blob);
	cache_pending_key = 0;
	CACHE_LOG("stored program binary %d bytes (%d hits, %d misses so far)", (int)written, cache_hits, cache_misses);
}
