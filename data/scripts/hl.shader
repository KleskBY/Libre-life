aaatrigger
{
	qer_trans 0.50
	qer_nocarve
	surfaceparm nodraw
}

monsterclip
{
	qer_trans 0.35
	qer_nocarve
	surfaceparm nodraw
	surfaceparm monsterclip
}

clipmonster
{
	qer_trans 0.35
	qer_nocarve
	surfaceparm nodraw
	surfaceparm monsterclip
}

black
{
	qer_trans 0.50
	qer_nocarve
	surfaceparm trans
	surfaceparm noimpact
	surfaceparm nonsolid
	surfaceparm nomarks
	{
	    map black
        depthWrite
        rgbGen identity
	}
}

c1a3yellow2
{
	surfaceparm trans
	surfaceparm noimpact
	surfaceparm nonsolid
	surfaceparm nomarks
    cull back
	qer_alphaFunc gequal 0.5
    {
        map c1a3yellow
        blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
        alphaFunc GT0
        depthWrite
        rgbGen identity
    }
}
