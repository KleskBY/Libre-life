
//Fade
float Fade;
float TargetFade;
void FadeIn()
{
	TargetFade = 1;
};

void FadeOut()
{
	TargetFade = 0;
};



void DrawFade()
{
	Fade = Lerp(Fade, TargetFade, 5 * frametime);
	if(Fade > 0) drawfill('0 0 0', [vid_x, vid_y], '0.1 0.1 0.1', Fade, 0);
};

string Letter1 = 	"The alarm hummed through the tunnels, \n\n";
string Letter2 = 	"the crimson light flickered on the shabby walls, \n\n";
string Letter3 = 	"as if the lab itself was aware of the approaching end. \n\n";
string Letter4 = 	"The hero, with a pulse in his temples, climbed out of  \n\n";
string Letter5 = 	"the engineering bay. He knew there was no turning back.\n\n";
string Letter6 = 	"All that was left of the project, of the secret \n\n";
string Letter7 = 	"experiments and suffering within these walls, \n\n";
string Letter8 = 	"would be erased by the flash. He ran up the inclined \n\n";
string Letter9 = 	"tunnel, away from the red-hot hell, feeling the metal \n\n";
string Letter10 = 	"shudder under his feet, the air filling with heat. \n\n";
string Letter11 = 	"The hero burst out into the dark night. \n\n";
string Letter12 = 	"A huge column of flame and smoke burst from the ground, \n\n";
string Letter13 = 	"throwing up concrete fragments into the sky and a flash \n\n";
string Letter14 = 	"that illuminated the forest like a daytime fire. \n\n";
string Letter15 = 	"He stood, breathing hard, looking at what he had left. \n\n";
string Letter16 = 	"No more secrets. No more experiments. \n\n";
string Letter17 = 	"He turned and walked into the darkness. Free.";



float letterStart;
float letters;
float lastLetters;
string lastLetter;
float letterOffset;
void print_letter(string letter, float length)
{
	letterOffset = letterOffset + 1;
	string txt = substring(letter, 0, letters - length);
	if(strlen(txt) != strlen(letter))
	{
		lastLetter = substring(txt, -1, 1);
		// print(lastLetter, "\n");
	}
	UI_Text(txt, [font_size * 4, font_size * letterOffset]);
	// text_center(text, [0, font_size * letterOffset]);
}

void DrawLetter()
{
	if(!letterStart) letterStart = time;
	letters = rint((time - letterStart) * 10);
	
	
	letterOffset = 3;
	if(letters > 0) print_letter(Letter1, 0);
	float len1 = strlen(Letter1);
	if(letters > len1) print_letter(Letter2, len1);
	float len2 = strlen(Letter2) + strlen(Letter1);
	if(letters > len2) print_letter(Letter3, len2);
	float len3 = strlen(Letter3) + len2;
	if(letters > len3) print_letter(Letter4, len3);
	float len4 = strlen(Letter4) + len3;
	if(letters > len4) print_letter(Letter5, len4);
	float len5 = strlen(Letter5) + len4;
	if(letters > len5) print_letter(Letter6, len5);
	float len6 = strlen(Letter6) + len5;
	if(letters > len6) print_letter(Letter7, len6);
	float len7 = strlen(Letter7) + len6;
	if(letters > len7) print_letter(Letter8, len7);
	float len8 = strlen(Letter8) + len7;
	if(letters > len8) print_letter(Letter9, len8);
	float len9 = strlen(Letter9) + len8;
	if(letters > len9) print_letter(Letter10, len9);
	float len10 = strlen(Letter10) + len9;
	if(letters > len10) print_letter(Letter11, len10);
	float len11 = strlen(Letter11) + len10;
	if(letters > len11) print_letter(Letter12, len11);
	float len12 = strlen(Letter12) + len11;
	if(letters > len12) print_letter(Letter13, len12);
	float len13 = strlen(Letter13) + len12;
	if(letters > len13) print_letter(Letter14, len13);
	float len14 = strlen(Letter14) + len13;
	if(letters > len14) print_letter(Letter15, len14);
	float len15 = strlen(Letter15) + len14;
	if(letters > len15) print_letter(Letter16, len15);
	letterOffset = letterOffset + 1;
	float len16 = strlen(Letter16) + len15;
	if(letters > len16) print_letter(Letter17, len16);
	
	
	float len17 = strlen(Letter17) + len16;
	if(letters != lastLetters && letters < len17)
	{
		if(lastLetter == "\n")
		{
			precache_sound("story/typewriter5.wav");
			localsound("story/typewriter5.wav");
		}
		else if(lastLetter != " ")
		{
			float r = RandomInt(0, 4);
			string filename = strcat("story/typewriter", ftos(r));
			filename = strcat(filename, ".wav");
			precache_sound(filename);
			localsound(filename);
		}
		lastLetters = letters;
	}
	

};




float storyStart;
float storyTime;
string lastSound;
void PlaySound(string f)
{
	if(lastSound != f)
	{
		precache_sound(f);
		localsound(f);
		lastSound = f;
	}
}

void Story_Draw()
{
	if(intermission != 2) return;
	if(mapname != "maps/e1m8.bsp") return;
	if(!storyStart) storyStart = time;
	storyTime = rint(time - storyStart);
	DrawLetter();
};