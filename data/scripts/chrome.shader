// sphere-map ("chrome") surfaces.
// chrome/pure       Silver sphere-map
// chrome/overlay    Chrome additive layer over a lit base
// chrome/blue       Blue chrome for energy weapons
// chrome/dark       Dark steel chrome: muted, industrial
// chrome/lens       Semi-transparent chrome for glass and optical elements
// chrome/cubemap    Static environment cubemap reflection (xen10 sky)
chrome/pure
{
	{
		map textures/chrome_spheremap
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

chrome/overlay
{
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_ZERO GL_SRC_COLOR
	}
	{
		map textures/chrome_spheremap
		tcGen environment
		blendFunc GL_ONE GL_ONE
		rgbGen identity
	}
}

chrome/blue
{
	{
		map textures/chrome_spheremap
		tcGen environment
		rgbGen const ( 0.55 0.65 1.0 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

chrome/dark
{
	{
		map textures/chrome_spheremap
		tcGen environment
		rgbGen const ( 0.45 0.45 0.45 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

chrome/lens
{
	
	surfaceparm trans
	{
		map textures/chrome_spheremap
		tcGen environment
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen identity
		alphaGen const 0.6
	}
}

chrome/cubemap
{
	dpReflectCube gfx/env/xen10
	{
		map textures/chrome_spheremap
		tcGen environment
		blendFunc GL_ONE GL_ZERO
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


textures/models/shell/bulletchrome
{
	program chrome
	{
		map textures/models/shell/bulletchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmhandgun/bulletchrome
{
	program chrome
	{
		map textures/models/v_9mmhandgun/bulletchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


textures/models/v_357/bulletchrome
{
	program chrome
	{
		map textures/models/v_357/bulletchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_357ammo/bulletchrome
{
	program chrome
	{
		map textures/models/w_357ammo/bulletchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_357ammobox/bulletchrome
{
	program chrome
	{
		map textures/models/w_357ammobox/bulletchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/crossbow_bolt/boltchrome
{
	program chrome
	{
		map textures/models/crossbow_bolt/boltchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


// Standard silver for gun barrels and mechanical parts
textures/models/v_gauss/barrelchrome
{
	program chrome
	{
		map textures/models/v_gauss/barrelchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_gauss/wire_chrome
{
	program chrome
	{
		map textures/models/v_gauss/wire_chrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_gauss/barrelchrome
{
	program chrome
	{
		map textures/models/w_gauss/barrelchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_shotgun/barrel_chrome
{
	program chrome
	{
		map textures/models/v_shotgun/barrel_chrome
		tcGen environment
		rgbGen const ( .7 .7 .7)
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmar/hk_chrome
{
	program chrome
	{
		map textures/models/v_9mmar/hk_chrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmar/player_chrome2
{
	program chrome
	{
		map textures/models/v_9mmar/player_chrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_crossbow/bowchrome
{
	program chrome
	{
		map textures/models/w_crossbow/bowchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/miniturret/chrome2
{
	program chrome
	{
		map textures/models/miniturret/chrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_squeak/chrome1
{
	program chrome
	{
		map textures/models/v_squeak/chrome1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_grenade/grenchrome
{
	program chrome
	{
		map textures/models/v_grenade/grenchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_satchel/bucklechrome
{
	program chrome
	{
		map textures/models/v_satchel/bucklechrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_satchel_radio/flapchrome
{
	program chrome
	{
		map textures/models/v_satchel_radio/flapchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmhandgun/chrome
{
	program chrome
	{
		map textures/models/v_9mmhandgun/chrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

// LENS CHROME
// Semi-transparent, optical glass elements.
textures/models/v_crossbow/lenschrome
{
	program chrome
	
	surfaceparm trans
	{
		map textures/models/v_crossbow/lenschrome
		tcGen environment
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen identity
		alphaGen const 0.65
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_tripmine/lenschrome
{
	program chrome
	
	surfaceparm trans
	{
		map textures/models/v_tripmine/lenschrome
		tcGen environment
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen identity
		alphaGen const 0.65
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


// BLUE CHROME
// Cool-toned sphere mapping for energy weapons.
// The textures are blue-tinted spheremaps; the shader applies tcGen environment to animate them
textures/models/v_egon/bluechrome
{
	program chrome
	{
		map textures/models/v_egon/bluechrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_egon/egonchrome2
{
	program chrome
	{
		map textures/models/v_egon/egonchrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

// Ring chrome: uses additive blend to keep the ring bright against the dark egon body
textures/models/v_egon/ringchrome
{
	program chrome
	{
		map textures/models/v_egon/ringchrome
		tcGen environment
		blendFunc GL_ONE GL_ONE
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_357/bluesteelchrome
{
	program chrome
	{
		map textures/models/v_357/bluesteelchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


// RUBBER GLOVE CHROME
// Softer, darker chrome for gloved hands, using rgbGen const to keep the latex look without a blinding mirror finish
textures/models/v_357/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_357/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmar/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_9mmar/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmhandgun/gordon_glove_chrome
{
	program chrome
	{
		map textures/models/v_9mmhandgun/gordon_glove_chrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_chub/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_chub/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_crossbow/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_crossbow/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_egon/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_egon/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_gauss/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_gauss/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_grenade/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_grenade/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_rpg/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_rpg/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_satchel/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_satchel/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_satchel_radio/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_satchel_radio/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_shotgun/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_shotgun/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.6 0.6 0.6 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_squeak/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_squeak/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_tripmine/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_tripmine/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/v_9mmhandgun/rubberglovechrome
{
	program chrome
	{
		map textures/models/v_9mmhandgun/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


textures/models/scientist/sci2_chrome1
{
	program chrome
	{
		map textures/models/scientist/sci2_chrome1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


textures/models/islave/chrome_1
{
	program chrome
	{
		map textures/models/islave/chrome_1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/barney/bx_chrome1
{
	program chrome
	{
		map textures/models/barney/bx_chrome1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/controller/chrome_1
{
	program chrome
	{
		map textures/models/controller/chrome_1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/garg/garg_chrome2
{
	program chrome
	{
		map textures/models/garg/garg_chrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/icky/chrome_tooth
{
	program chrome
	{
		map textures/models/icky/chrome_tooth
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/player/player_chrome1
{
	program chrome
	{
		map textures/models/player/player_chrome1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/sentry/sentry_chrome2
{
	program chrome
	{
		map textures/models/sentry/sentry_chrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/sentry/sentry_chrome3
{
	program chrome
	{
		map textures/models/sentry/sentry_chrome3
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/turret/chrome2
{
	program chrome
	{
		map textures/models/turret/chrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_egon/egonchrome2
{
	program chrome
	{
		map textures/models/w_egon/egonchrome2
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_oxygen/chromebump
{
	program chrome
	{
		map textures/models/w_oxygen/chromebump
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_oxygen/highlightchrome
{
	program chrome
	{
		map textures/models/w_oxygen/highlightchrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_suit/player_chrome1
{
	program chrome
	{
		map textures/models/w_suit/player_chrome1
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_weaponbox/itemc_chrome
{
	program chrome
	{
		map textures/models/w_weaponbox/itemc_chrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


textures/models/w_longjump/black_chrome
{
	program chrome
	{
		map textures/models/w_longjump/black_chrome
		tcGen environment
		rgbGen const ( 0.45 0.45 0.45 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

textures/models/w_oxygen/chrome_scratch
{
	program chrome
	{
		map textures/models/w_oxygen/chrome_scratch
		tcGen environment
		rgbGen const ( 0.45 0.45 0.45 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


textures/models/hgrunt/goggle_chrome
{
	program chrome

	surfaceparm trans
	{
		map textures/models/hgrunt/goggle_chrome
		tcGen environment
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen identity
		alphaGen const 0.65
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


// Wet/slimy highlight, not a mirror finish, dimmed
// sphere-map for the headcrab bite chrome.
textures/models/baby_headcrab/babychrome
{
	program chrome
	{
		map textures/models/baby_headcrab/babychrome
		tcGen environment
		rgbGen const ( 0.6 0.6 0.6 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}


// Surface names come straight from the IQM material strings
// (mixed case). The map paths point at the on-disk lowercase
// PNGs. The GLOVED_sleeve / GLOVED_knuckle / GLOVE_handpak
// surfaces are plain diffuse and need no shader; the engine loads their PNGs directly

// Silver head chrome, standard mirror sphere-map.
textures/models/v_crowbar/chrome
{
	program chrome
	{
		map textures/models/v_crowbar/chrome
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

// Red-painted crowbar body. Uses a red-tinted sphere-map, and rgbGen identity preserves the red color
textures/models/v_crowbar/chrome_red
{
	program chrome
	{
		map textures/models/v_crowbar/chrome_red
		tcGen environment
		rgbGen identity
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}

// Gloved hand, soft rubber-glove chrome, dimmed to keep the
// latex look (matches the rubberglovechrome family above).
textures/models/v_crowbar/rubbergloveCHROME
{
	program chrome
	{
		map textures/models/v_crowbar/rubberglovechrome
		tcGen environment
		rgbGen const ( 0.8 0.8 0.8 )
	}
	{
		map $lightmap
		rgbGen identity
		blendFunc GL_DST_COLOR GL_ZERO
	}
}