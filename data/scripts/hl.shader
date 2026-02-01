aaatrigger
{
	qer_trans 0.50
	qer_nocarve
	surfaceparm nodraw
}

black
{
	qer_trans 0.50
	qer_nocarve
	surfaceparm nodraw
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

water4b2
{
	qer_trans 0.50
	qer_nocarve
	surfaceparm water
	{
		//map water4b
		blendFunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA
		rgbGen identity
		alphaGen vertex	
		tcmod scale 1 1			
		tcMod turb 0 .15 0 .015	
	}	
}
