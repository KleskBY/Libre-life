

/////////////////////////////////////
////////////// INPUT ////////////////
/////////////////////////////////////

string KeyMap(float keynum) 
{
   string chrlist, key;

   if(keynum == 32) key = " ";
   else if(keynum >= 39 && keynum <= 61)
   {
      chrlist = "'  *+,-./0123456789 ; =";   
      key = substring(chrlist, keynum - 39, 1);
   }
   else if(keynum <= -39 && keynum >= -61)
   {
      chrlist = "\"    <_>?)!@#$%^&*( : +";
      key = substring(chrlist, (-keynum) - 39, 1);
   }
   else if(keynum >= 91 && keynum <= 93)
   {
      chrlist = "[\\]";
      key = substring(chrlist, keynum - 91, 1);
   }
   else if(keynum <= -91 && keynum >= -93)
   {
      chrlist = "{|}";
      key = substring(chrlist, (-keynum) - 91, 1);
   }   
   else if(keynum >= 97 && keynum <= 122)
   {
      chrlist = "abcdefghijklmnopqrstuvwxyz";
      key = substring(chrlist, keynum - 97, 1);
   }

   return key;
}

float Input_Update(float flEventType, float flKey, float flCharacter) 
{
	string key = KeyMap(flKey);
	string keybind = getkeybind(flKey);

	clicked = false;
	if (!flEventType) // key pressed down
	{	
		if (flKey == K_MOUSE1) 
		{
			clicked = 1;
			if(showCursor) return TRUE;
			
		}
		if (flKey == K_MOUSE2) 
		{
			clicked = 2;
			if(showCursor) return TRUE;
		}
	}
	
	if(HUD_Input(keybind, flEventType)) return TRUE;
	
	if (keybind == "+showscores")
	{
		if(!flEventType) showScores = TRUE;
		if(flEventType == 1) showScores = FALSE;
	}
	if (keybind == "+attack")
	{
		if(!flEventType) isAttacking = TRUE;
		if(flEventType == 1) isAttacking = FALSE;
	}
	// if (keybind == "+button3")
	// {
		// if(!flEventType) isCrouching = TRUE;
		// if(flEventType == 1) isCrouching = FALSE;
	// }
	if (keybind == "+jump")
	{
		if(!flEventType) isJumping = TRUE;
		if(flEventType == 1) isJumping = FALSE;
	}
	if (keybind == "+button4")
	{
		if(!flEventType) isRunning = TRUE;
		if(flEventType == 1) isRunning = FALSE;
	}
	if (keybind == "+button5")
	{
		if(!flEventType) enableScope();
		if(flEventType == 1) disableScope();
	}
	
	return FALSE;
}

