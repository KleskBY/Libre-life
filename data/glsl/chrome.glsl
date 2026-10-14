!!ver 110
!!permu FRAMEBLEND
!!permu SKELETAL
!!permu FOG
!!samps diffuse

// chrome.glsl Half-Life sphere-map ("chrome") for FTEQW.
//
// Why this exists instead of plain `tcGen environment`:
//
// FTE generates environment texcoords on the CPU, in gl_backend.c:
//
//     case TC_GEN_ENVIRONMENT:
// Skeletal (IQM) models are skinned on the GPU, so there is no CPU-side
// normals array to read the tcgen silently falls through to the model's
// base UVs and the chrome renders as a static, pasted-on texture. DarkPlaces
// takes a different path, which is why it only looks wrong on FTE.
//
// Doing the projection here in the vertex shader puts it *after* skinning,
// where the post-skin normal and position actually exist.
//
// The math mirrors FTE's own tcgen_environment() so the look matches what the
// keyword was supposed to produce: reflect the eye->vertex vector about the
// vertex normal, then take the y/z of the reflection as the sphere-map lookup.
// e_eyepos is the view origin in model space, so it stays correct as the
// entity moves, turns, and animates.
//
// Wired in via `program chrome` in data/scripts/chrome.shader and
// hassassin.shader. DarkPlaces/Zircon ignores the `program` keyword and keeps
// using its own working tcGen environment, so both engines stay correct off
// the same material.

#include "sys/defs.h"
#include "sys/fog.h"

varying vec2 tc;
varying vec3 light;

#ifdef VERTEX_SHADER
#include "sys/skeletal.h"

void main ()
{
	vec3 w, n, s, t;
	gl_Position = skeletaltransform_wnst(w, n, s, t);

	vec3 viewer = normalize(e_eyepos - w);
	vec3 reflected = n * (2.0 * dot(n, viewer)) - viewer;

	tc = vec2(0.5 + reflected.y * 0.5,
	          0.5 - reflected.z * 0.5);

	// Equivalent of `rgbGen lightingDiffuse`, which the program replaces.
	light = e_light_ambient + (max(dot(n, e_light_dir), 0.0) * e_light_mul);
}
#endif

#ifdef FRAGMENT_SHADER
void main ()
{
	vec4 col = texture2D(s_diffuse, tc);
	col.rgb *= light;
	gl_FragColor = fog4(col * e_colourident);
}
#endif
