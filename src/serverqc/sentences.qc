
// sentences.txt parser and chained playback.
#define MAX_SENTENCES        1280
#define MAX_SENT_WORDS       4096
#define MAX_SENT_GROUP       64      // max variants in one digit-suffixed group
#define SENT_WORD_FALLBACK_DUR  0.6   // per-word estimate when soundlength unavailable
#define SENT_COMMA_PAUSE     0.25

string snt_name[MAX_SENTENCES];      // exact name, digits kept: "HEV_A0"
string snt_group[MAX_SENTENCES];     // digit-stripped group:    "HEV_A"
float  snt_range[MAX_SENTENCES];     // packed: firstWord * 64 + wordCount (count <= 63)
float  sentence_count;

string sw_path[MAX_SENT_WORDS];      // "fvox/blip.wav"
float  sw_params[MAX_SENT_WORDS];    // packed: pitch * 1024 + vol * 4 + pauseFlag
float  sw_count;

// Packed-field accessors.
#define SNT_FIRST(i)   floor(snt_range[i] / 64)
#define SNT_WORDS(i)   (snt_range[i] - floor(snt_range[i] / 64) * 64)
#define SW_PITCH(i)    floor(sw_params[i] / 1024)
#define SW_VOL(i)      floor((sw_params[i] - floor(sw_params[i] / 1024) * 1024) / 4)
#define SW_PAUSE(i)    ((sw_params[i] - floor(sw_params[i] / 4) * 4) ? SENT_COMMA_PAUSE : 0)

// Reused scratch array so group picks don't allocate on every call.
float sentence_pick_idx[MAX_SENT_GROUP];

// ASCII codes (str2chr returns ints; can't compare strings directly).
#define ASCII_0     48
#define ASCII_9     57
#define ASCII_A     65
#define ASCII_Z     90
#define ASCII_SLASH 47
#define ASCII_COMMA 44
#define ASCII_DOT   46
#define ASCII_BANG  33
#define ASCII_QMARK 63
#define ASCII_LPAREN 40
#define ASCII_RPAREN 41
#define ASCII_SPACE 32
#define ASCII_TAB   9
#define ASCII_LC_P  112
#define ASCII_LC_V  118

// Strip trailing decimal digits to get group base.
string Sentences_StripDigits(string s)
{
    float n = strlen(s);
    while (n > 0)
    {
        float c = str2chr(s, n - 1);
        if (c < ASCII_0 || c > ASCII_9) break;
        n = n - 1;
    }
    return substring(s, 0, n);
}

// Line parser

// Running per-line parse state (module-scope so the emit helper sees it).
string sent_parse_dir;
float  sent_parse_pitch;
float  sent_parse_vol;

float sent_param_pitch;
float sent_param_vol;
void Sentences_ParseParams(string params)
{
    float i = 0;
    float n = strlen(params);
    while (i < n)
    {
        float c = str2chr(params, i);
        if ((c >= ASCII_A && c <= ASCII_Z) || (c >= ASCII_A + 32 && c <= ASCII_Z + 32))
        {
            float key = c;
            if (key < ASCII_A + 32) key = key + 32;   // lowercase
            i = i + 1;
            float val = 0;
            float got = FALSE;
            while (i < n)
            {
                float d = str2chr(params, i);
                if (d < ASCII_0 || d > ASCII_9) break;
                val = val * 10 + (d - ASCII_0);
                got = TRUE;
                i = i + 1;
            }
            if (got)
            {
                if (key == ASCII_LC_P) sent_param_pitch = val;
                else if (key == ASCII_LC_V) sent_param_vol = val;
            }
        }
        else
            i = i + 1;
    }
}

void Sentences_EmitWord(string w, float pitch, float vol, float pause)
{
    // Dir prefix?
    float slash = strstrofs(w, "/", 0);
    if (slash >= 0)
    {
        sent_parse_dir = substring(w, 0, slash + 1);
        w = substring(w, slash + 1, strlen(w) - slash - 1);
    }
    if (w == "") return;

    if (sw_count >= MAX_SENT_WORDS)
    {
        dprint("Sentences: MAX_SENT_WORDS exceeded\n");
        return;
    }

    string path = strtolower(strcat(sent_parse_dir, w, ".wav"));
    if (pitch > 255) pitch = 255;
    if (vol > 255) vol = 255;
    sw_path[sw_count]   = strzone(path);
    sw_params[sw_count] = pitch * 1024 + vol * 4 + (pause > 0);
    precache_sound(sw_path[sw_count]);
    sw_count = sw_count + 1;
}

// Parse the word section of a sentence line (everything after the name).
// Returns the number of words emitted.
float Sentences_ParseWords(string rest)
{
    sent_parse_dir   = "vox/";
    sent_parse_pitch = 100;
    sent_parse_vol   = 100;

    string word = "";          // accumulating bare word (may include dir)
    float wordPitch = 100;     // attached-paren override, else running default
    float wordVol = 100;
    float haveOverride = FALSE;

    float startCount = sw_count;
    float i = 0;
    float n = strlen(rest);

    while (i <= n)   // one extra iteration flushes the final word
    {
        float c = (i < n) ? str2chr(rest, i) : ASCII_SPACE;

        if (c == ASCII_LPAREN)
        {
            // Collect params up to ')'
            float j = i + 1;
            string params = "";
            while (j < n && str2chr(rest, j) != ASCII_RPAREN)
            {
                params = strcat(params, substring(rest, j, 1));
                j = j + 1;
            }
            i = j + 1;

            sent_param_pitch = -1;
            sent_param_vol = -1;
            Sentences_ParseParams(params);

            float dirOnly = (word != "" && str2chr(word, strlen(word) - 1) == ASCII_SLASH);

            if (word != "" && !dirOnly)
            {
                wordPitch = (sent_param_pitch >= 0) ? sent_param_pitch : sent_parse_pitch;
                wordVol   = (sent_param_vol   >= 0) ? sent_param_vol   : sent_parse_vol;
                haveOverride = TRUE;
            }
            else
            {
                if (sent_param_pitch >= 0) sent_parse_pitch = sent_param_pitch;
                if (sent_param_vol   >= 0) sent_parse_vol   = sent_param_vol;
            }
            continue;
        }

        if (c == ASCII_SPACE || c == ASCII_TAB || c == ASCII_COMMA || c == ASCII_DOT)
        {
            if (word != "")
            {
                float p = haveOverride ? wordPitch : sent_parse_pitch;
                float v = haveOverride ? wordVol   : sent_parse_vol;
                float pause = (c == ASCII_COMMA || c == ASCII_DOT) ? SENT_COMMA_PAUSE : 0;
                Sentences_EmitWord(word, p, v, pause);
                word = "";
                haveOverride = FALSE;
            }
            else if ((c == ASCII_COMMA || c == ASCII_DOT) && sw_count > startCount)
            {
                // set the pause bit on the previous word if not already set.
                float prev = sw_count - 1;
                if (!(sw_params[prev] - floor(sw_params[prev] / 4) * 4))
                    sw_params[prev] = sw_params[prev] + 1;
            }
            i = i + 1;
            continue;
        }

        if (c == ASCII_QMARK)
        {
            i = i + 1;
            continue;
        }

        if (c == ASCII_RPAREN)
        {
            i = i + 1;
            continue;
        }

        word = strcat(word, substring(rest, i, 1));
        i = i + 1;
    }

    return sw_count - startCount;
}

// Loader
void Sentences_LoadFile(string filename)
{
    float fh = fopen(filename, FILE_READ);
    if (fh < 0)
    {
        dprint("Sentences_LoadFile: could not open ");
        dprint(filename);
        dprint("\n");
        return;
    }

    string line;
    while ((line = fgets(fh)))
    {
        if (line == "") continue;

        // Name = first whitespace-delimited token.
        float sp = 0;
        float ln = strlen(line);
        while (sp < ln)
        {
            float c = str2chr(line, sp);
            if (c == ASCII_SPACE || c == ASCII_TAB) break;
            sp = sp + 1;
        }
        if (sp <= 0 || sp >= ln) continue;

        string nameTok = substring(line, 0, sp);
        string rest    = substring(line, sp + 1, ln - sp - 1);

        if (str2chr(nameTok, 0) == ASCII_BANG)
            nameTok = substring(nameTok, 1, strlen(nameTok) - 1);
        if (nameTok == "") continue;

        // Skip comments and stray entries.
        float firstChar = str2chr(nameTok, 0);
        if (firstChar == ASCII_SLASH) continue;
        if (firstChar < ASCII_A || firstChar > ASCII_Z) continue;

        if (sentence_count >= MAX_SENTENCES)
        {
            dprint("Sentences: MAX_SENTENCES exceeded\n");
            break;
        }

        float first = sw_count;
        float wcount = Sentences_ParseWords(rest);
        if (wcount <= 0) continue;
        if (wcount > 63) wcount = 63;	// range packing cap (longest line is 29)

        snt_name[sentence_count]  = strzone(nameTok);
        snt_group[sentence_count] = strzone(Sentences_StripDigits(nameTok));
        snt_range[sentence_count] = first * 64 + wcount;
        sentence_count = sentence_count + 1;
    }

    fclose(fh);
    dprint("Sentences: loaded ");
    dprint(ftos(sentence_count));
    dprint(" sentences / ");
    dprint(ftos(sw_count));
    dprint(" words from ");
    dprint(filename);
    dprint("\n");
}

// Lookup

// Exact sentence by name ("HEV_A0"), -1 if absent.
float Sentences_FindExact(string name)
{
    for (float i = 0; i < sentence_count; i = i + 1)
        if (snt_name[i] == name) return i;
    return -1;
}

// Random member of a digit-suffixed group ("SC_HELLO"), -1 if none.
float Sentences_PickGroup(string groupBase)
{
    float nm = 0;
    for (float i = 0; i < sentence_count && nm < MAX_SENT_GROUP; i = i + 1)
    {
        if (snt_group[i] == groupBase)
        {
            sentence_pick_idx[nm] = i;
            nm = nm + 1;
        }
    }
    if (nm == 0) return -1;
    float pick = floor(random() * nm);
    if (pick >= nm) pick = nm - 1;
    return sentence_pick_idx[pick];
}

// Chained playback

.float sp_idx;      // next word index (into word pool)
.float sp_end;      // one past last word
.float sp_chan;
.float sp_vol;      // caller volume 0..1
.float sp_attn;
.float sp_pitch;    // caller pitch scale, 100 = as authored

float sent_soundlength_ok;      // 0 = unprobed, 1 = available, -1 = absent
float Sentences_WordDuration(string path)
{
    float dur = 0;
    if (!sent_soundlength_ok)
        sent_soundlength_ok = (IsFTE() || checkextension("DP_SND_GETSOUNDTIME")) ? 1 : -1;
    if (sent_soundlength_ok > 0) dur = soundlength(path);
    if (dur <= 0) dur = SENT_WORD_FALLBACK_DUR;
    return dur;
}

void SentencePlayer_Think()
{
    entity src = self.owner;
    if (!src || wasfreed(src) || self.sp_idx >= self.sp_end)
    {
        remove(self);
        return;
    }

    float i = self.sp_idx;
    self.sp_idx = i + 1;

    float pit = SW_PITCH(i) * self.sp_pitch / 100;
    float vol = self.sp_vol * SW_VOL(i) / 100;
    if (vol > 1) vol = 1;
    Sound_Emit(src, self.sp_chan, sw_path[i], vol, self.sp_attn, pit, 0);

    if (self.sp_idx >= self.sp_end)
    {
        remove(self);
        return;
    }
    self.think = SentencePlayer_Think;
    float wdur = Sentences_WordDuration(sw_path[i]);
    if (pit > 0 && pit != 100) wdur = wdur * 100 / pit;
    self.nextthink = time + wdur + SW_PAUSE(i);
}

void Sentences_Stop(entity src, float chan)
{
    entity e = find(world, classname, "sentence_player");
    while (e)
    {
        entity nxt = find(e, classname, "sentence_player");
        if (e.owner == src && e.sp_chan == chan)
            remove(e);
        e = nxt;
    }
}

float Sentences_Play(entity src, float chan, string groupBase,
                     float vol, float attn, float pitch)
{
    if (groupBase != "" && str2chr(groupBase, 0) == ASCII_BANG)
        groupBase = substring(groupBase, 1, strlen(groupBase) - 1);

    float idx = Sentences_FindExact(groupBase);
    if (idx < 0) idx = Sentences_PickGroup(groupBase);
    if (idx < 0)
    {
        dprint("Sentences_Play: '");
        dprint(groupBase);
        dprint("' not found\n");
        return 0;
    }

    Sentences_Stop(src, chan);

    entity e = spawn();
    e.classname = "sentence_player";
    e.owner     = src;
    e.sp_idx    = SNT_FIRST(idx);
    e.sp_end    = SNT_FIRST(idx) + SNT_WORDS(idx);
    e.sp_chan   = chan;
    e.sp_vol    = vol;
    e.sp_attn   = attn;
    e.sp_pitch  = pitch;

    // Total duration estimate (pitch-scaled for chain spacing)
    float dur = 0;
    for (float i = e.sp_idx; i < e.sp_end; i = i + 1)
    {
        float wdur = Sentences_WordDuration(sw_path[i]);
        float wpit = SW_PITCH(i) * pitch / 100;
        if (wpit > 0 && wpit != 100) wdur = wdur * 100 / wpit;
        dur = dur + wdur + SW_PAUSE(i);
    }

    // Fire the first word immediately
    entity stemp = self;
    self = e;
    SentencePlayer_Think();
    self = stemp;

    return dur;
}

// Boot
void Sentences_Init()
{
    sentence_count = 0;
    sw_count = 0;
    Sentences_LoadFile("sound/sentences.txt");
}
