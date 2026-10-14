//Back is front in FTE
!bwater1
{
	qer_editorimage textures/liquids_extracted/bwater1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/bwater1.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.012 0.008
	}
	//dp_reflect 8 0.75 0.82 1.0 0.85
}

!bwater2
{
	qer_editorimage textures/liquids_extracted/bwater2.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/bwater2.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.012 0.008
	}
	//dp_reflect 8 0.75 0.82 1.0 0.7
}

!bwater3
{
	qer_editorimage textures/liquids_extracted/bwater3.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/bwater3.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.012 0.008
	}
	//dp_reflect 8 0.75 0.82 1.0 0.55
}


// =====================  CLEAR WATER  ========================
// water1/2a/2b/2c: fog alpha ~0, very transparent.
// Sharp planar reflection, low tint.

!water1
{
	qer_editorimage textures/liquids_extracted/water1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water1.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.85 0.92 1.0 0.75
}

!water2a
{
	qer_editorimage textures/liquids_extracted/water2a.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2a.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.9 0.9 1.0 0.9
}

!water2b
{
	qer_editorimage textures/liquids_extracted/water2b.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2b.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.9 0.9 1.0 0.9
}

!water2c
{
	qer_editorimage textures/liquids_extracted/water2c.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2c.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.85 0.9 1.0 0.8
}


// =================  DEEP CAMPAIGN WATER (c2a5)  =============
// Bigger pools: fresnel reflect+refract (//dpwater) for depth,
// plus the same double-turb wobble.

!c2a5
{
	qer_editorimage textures/liquids_extracted/c2a5.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a5.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.010 0.007
	}
	//dpwater 0.10 0.90  0.06 0.06  0.30 0.45 0.72  0.45 0.60 0.85  0.55
}

!c2a52
{
	qer_editorimage textures/liquids_extracted/c2a52.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a52.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.010 0.007
	}
	//dpwater 0.10 0.90  0.06 0.06  0.20 0.35 0.68  0.40 0.55 0.85  0.55
}

!c2a52b
{
	qer_editorimage textures/liquids_extracted/c2a52b.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a52b.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.010 0.007
	}
	//dp_reflect 8 0.6 0.75 1.0 0.85
}

// olive-tinted variants (fog ~42 39 14)
!c2a53
{
	qer_editorimage textures/liquids_extracted/c2a53.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a53.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.009 0.007
	}
	//dpwater 0.10 0.85  0.07 0.07  0.55 0.50 0.30  0.60 0.58 0.42  0.6
}

!c2a54
{
	qer_editorimage textures/liquids_extracted/c2a54.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a54.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.009 0.007
	}
	//dpwater 0.10 0.85  0.07 0.07  0.60 0.50 0.28  0.62 0.56 0.40  0.6
}

!c2a542
{
	qer_editorimage textures/liquids_extracted/c2a542.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a542.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.009 0.007
	}
	//dpwater 0.10 0.85  0.07 0.07  0.55 0.58 0.45  0.60 0.62 0.52  0.6
}

!c2a54b
{
	qer_editorimage textures/liquids_extracted/c2a54b.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a54b.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.009 0.007
	}
	//dpwater 0.10 0.85  0.07 0.07  0.45 0.50 0.28  0.55 0.58 0.40  0.6
}


// ==================  GREEN WATER / SLIME  ===================
// fog ~24 38 8 -> murky green. Thick: taller/slower waves,
// heavier turb, opaque (no reflection).

!gwater1
{
	qer_editorimage textures/liquids_extracted/gwater1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater1.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.06 0.5 0.03
		tcMod turb 1 0.06 1.0 0.03
		tcMod scroll 0.006 0.004
	}
}

!gwater2
{
	qer_editorimage textures/liquids_extracted/gwater2.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater2.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.06 0.5 0.03
		tcMod turb 1 0.06 1.0 0.03
		tcMod scroll 0.006 0.004
	}
}

!gwater3
{
	qer_editorimage textures/liquids_extracted/gwater3.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater3.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.06 0.5 0.03
		tcMod turb 1 0.06 1.0 0.03
		tcMod scroll 0.006 0.004
	}
}

!gwater4a
{
	qer_editorimage textures/liquids_extracted/gwater4a.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater4a.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.12 0.5 0.05
		tcMod turb 1 0.12 1.0 0.05
		tcMod scroll 0.005 0.004
	}
}

!gwater4b
{
	qer_editorimage textures/liquids_extracted/gwater4b.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater4b.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.12 0.5 0.05
		tcMod turb 1 0.12 1.0 0.05
		tcMod scroll 0.005 0.004
	}
}

!gwater5
{
	qer_editorimage textures/liquids_extracted/gwater5.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater5.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.12 0.5 0.05
		tcMod turb 1 0.12 1.0 0.05
		tcMod scroll 0.005 0.004
	}
}

!gwater5b
{
	qer_editorimage textures/liquids_extracted/gwater5b.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater5b.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.12 0.5 0.05
		tcMod turb 1 0.12 1.0 0.05
		tcMod scroll 0.005 0.004
	}
}

!gwater6
{
	qer_editorimage textures/liquids_extracted/gwater6.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater6.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.12 0.5 0.05
		tcMod turb 1 0.12 1.0 0.05
		tcMod scroll 0.005 0.004
	}
}


// ==================  "R" WATER (rwater)  ====================
// fog 24 38 8 (green). Small tiles, moderate churn.

!rwater1
{
	qer_editorimage textures/liquids_extracted/rwater1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/rwater1.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.11 0.5 0.07
		tcMod turb 1 0.11 1.0 0.07
		tcMod scroll 0.008 0.005
	}
}

!rwater2
{
	qer_editorimage textures/liquids_extracted/rwater2.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/rwater2.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.11 0.5 0.07
		tcMod turb 1 0.11 1.0 0.07
		tcMod scroll 0.008 0.005
	}
}

!rwater3
{
	qer_editorimage textures/liquids_extracted/rwater3.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/rwater3.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.11 0.5 0.07
		tcMod turb 1 0.11 1.0 0.07
		tcMod scroll 0.008 0.005
	}
}


// ====================  RADIOACTIVE  =========================
// fog 41 81 0 -> toxic green. Fast boil: quick low waves,
// strong turb + slow rotate. Unlit = glowing.

!radio
{
	qer_editorimage textures/liquids_extracted/radio.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/radio.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.08 0 0.15
		tcMod turb 1 0.08 0.5 0.07
		tcMod turb 1 0.08 1.0 0.07
		tcMod rotate 5
		tcMod scroll 0.010 0.008
	}
}


// ==================  SCROLLING TOXIC  =======================
// Conveyor-style toxic surface: fast steady scroll + wobble.

scrolltoxic
{
	qer_editorimage textures/liquids_extracted/scrolltoxic.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/scrolltoxic.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.08 0.5 0.09
		tcMod scroll 0.0 0.35
	}
}


// ==================  ANIMATED WATERFALL  ====================
// HL '+0..+4 waterfall1' = 5-frame animated texture on a wall.
// Cycle frames + scroll down. No wave deform (vertical face).

+0waterfall1
{
	qer_editorimage textures/liquids_extracted/waterfall1_0.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		animmap 8 textures/liquids_extracted/waterfall1_0.png textures/liquids_extracted/waterfall1_1.png textures/liquids_extracted/waterfall1_2.png textures/liquids_extracted/waterfall1_3.png textures/liquids_extracted/waterfall1_4.png
		rgbGen identity
		tcMod scroll 0.0 1.2
	}
}


!water_02
{
	qer_editorimage textures/liquids_extracted/water2a.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2a.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.9 0.9 1.0 0.85
}

!water_03
{
	qer_editorimage textures/liquids_extracted/water2b.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2b.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.85 0.9 1.0 0.85
}

!water_04
{
	qer_editorimage textures/liquids_extracted/water2c.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2c.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.010
	}
	//dp_reflect 8 0.85 0.9 1.0 0.8
}

!waterblue
{
	qer_editorimage textures/liquids_extracted/bwater1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/bwater1.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.012 0.008
	}
	//dp_reflect 8 0.6 0.72 1.0 0.85
}

!watergreen
{
	qer_editorimage textures/liquids_extracted/gwater1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater1.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.06 0.5 0.03
		tcMod turb 1 0.06 1.0 0.03
		tcMod scroll 0.006 0.004
	}
}

// toxic / swamp
!toxic_slime
{
	qer_editorimage textures/liquids_extracted/scrolltoxic.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/scrolltoxic.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.06 0.5 0.03
		tcMod turb 1 0.06 1.0 0.03
		tcMod scroll 0.0 0.12
	}
}

!boloto
{
	qer_editorimage textures/liquids_extracted/gwater5.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/gwater5.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.12 0.5 0.05
		tcMod turb 1 0.12 1.0 0.05
		tcMod scroll 0.005 0.004
	}
}

// chemical
!chemikal_08
{
	qer_editorimage textures/liquids_extracted/c2a53.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a53.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.13 0.5 0.1
		tcMod turb 1 0.13 1.0 0.1
		tcMod rotate 3
		tcMod scroll 0.01 0.01
	}
}

!chemikal_09
{
	qer_editorimage textures/liquids_extracted/c2a542.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/c2a542.png
		rgbGen identity
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.05 0 0.03
		tcMod turb 1 0.13 0.5 0.1
		tcMod turb 1 0.13 1.0 0.1
		tcMod rotate 3
		tcMod scroll 0.01 0.01
	}
}

// generic fluid
!fluid1a
{
	qer_editorimage textures/liquids_extracted/water1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water1.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.012
	}
	//dp_reflect 8 0.85 0.92 1.0 0.7
}

!fluid1b
{
	qer_editorimage textures/liquids_extracted/water1.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water1.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.012
	}
	//dp_reflect 8 0.85 0.92 1.0 0.7
}

!fluid2b
{
	qer_editorimage textures/liquids_extracted/water2c.png
	surfaceparm water
	surfaceparm nomarks
	surfaceparm trans
	surfaceparm nolightmap
	//cull back
	{
		map textures/liquids_extracted/water2c.png
		rgbGen identity
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		alphaGen const 0.65
		tcmod scale 0.25 0.25
			tcMod stretch sin 1 0.03 0 0.08
		tcMod turb 1 0.05 0.5 0.06
		tcMod turb 1 0.05 1.0 0.06
		tcMod scroll 0.015 0.012
	}
	//dp_reflect 8 0.85 0.9 1.0 0.75
}
