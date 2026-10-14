// titles.txt parser and dispatch for env_message.

#define MAX_TITLES 512
#define ENV_MESSAGE_CHANNEL 1

#define ASCII_SLASH_T 47
#define ASCII_DOLLAR  36
#define ASCII_CR_T    13
#define ASCII_LF_T    10
#define ASCII_LBRACE  123
#define ASCII_RBRACE  125

string  title_name[MAX_TITLES];
string  title_message[MAX_TITLES];
float   title_x[MAX_TITLES];
float   title_y[MAX_TITLES];
float   title_effect[MAX_TITLES];
vector  title_rgb1[MAX_TITLES];
float   title_a1[MAX_TITLES];
vector  title_rgb2[MAX_TITLES];
float   title_a2[MAX_TITLES];
float   title_fadein[MAX_TITLES];
float   title_fadeout[MAX_TITLES];
float   title_holdtime[MAX_TITLES];
float   title_fxtime[MAX_TITLES];
float   title_count;

// Current parser state: carried across entries.
float   tp_x, tp_y, tp_effect;
vector  tp_rgb1, tp_rgb2;
float   tp_a1, tp_a2;
float   tp_fadein, tp_fadeout, tp_holdtime, tp_fxtime;

void Titles_ResetParserState()
{
    tp_x = -1; tp_y = -1;
    tp_effect = 2;
    tp_rgb1 = '100 100 100'; tp_a1 = 255;
    tp_rgb2 = '240 110 0';   tp_a2 = 255;
    tp_fadein = 0.01;
    tp_fadeout = 1.5;
    tp_holdtime = 3.5;
    tp_fxtime = 0.25;
}

void Titles_ApplyDirective(string key, float ntok)
{
    if (key == "$position") {
        if (ntok >= 3) { tp_x = stof(argv(1)); tp_y = stof(argv(2)); }
    } else if (key == "$effect") {
        if (ntok >= 2) tp_effect = stof(argv(1));
    } else if (key == "$color") {
        if (ntok >= 4) tp_rgb1 = [stof(argv(1)), stof(argv(2)), stof(argv(3))];
        if (ntok >= 5) tp_a1 = stof(argv(4));
    } else if (key == "$color2") {
        if (ntok >= 4) tp_rgb2 = [stof(argv(1)), stof(argv(2)), stof(argv(3))];
        if (ntok >= 5) tp_a2 = stof(argv(4));
    } else if (key == "$fadein") {
        if (ntok >= 2) tp_fadein = stof(argv(1));
    } else if (key == "$fadeout") {
        if (ntok >= 2) tp_fadeout = stof(argv(1));
    } else if (key == "$holdtime") {
        if (ntok >= 2) tp_holdtime = stof(argv(1));
    } else if (key == "$fxtime") {
        if (ntok >= 2) tp_fxtime = stof(argv(1));
    }
}

// Strip trailing CR/LF from a raw fgets line.
string Titles_StripEol(string s)
{
    float n = strlen(s);
    while (n > 0)
    {
        float c = str2chr(s, n - 1);
        if (c != ASCII_CR_T && c != ASCII_LF_T) break;
        n = n - 1;
    }
    return substring(s, 0, n);
}

// Drop characters that break the hudmsg stuffcmd wire format:
string Titles_SanitizeBody(string s)
{
    string out = "";
    float i = 0;
    float n = strlen(s);
    while (i < n)
    {
        float c = str2chr(s, i);
        if (c != 34 && c != 59 && c != 124)
            out = strcat(out, substring(s, i, 1));
        i = i + 1;
    }
    return out;
}

void Titles_Commit(string name, string body)
{
    if (title_count >= MAX_TITLES)
    {
        dprint("Titles: MAX_TITLES exceeded; dropping ");
        dprint(name);
        dprint("\n");
        if (body != "") strunzone(body);
        return;
    }
    title_name[title_count]     = strzone(name);
    title_message[title_count]  = (body != "") ? body : strzone("");
    title_x[title_count]        = tp_x;
    title_y[title_count]        = tp_y;
    title_effect[title_count]   = tp_effect;
    title_rgb1[title_count]     = tp_rgb1;
    title_a1[title_count]       = tp_a1;
    title_rgb2[title_count]     = tp_rgb2;
    title_a2[title_count]       = tp_a2;
    title_fadein[title_count]   = tp_fadein;
    title_fadeout[title_count]  = tp_fadeout;
    title_holdtime[title_count] = tp_holdtime;
    title_fxtime[title_count]   = tp_fxtime;
    title_count = title_count + 1;
}

void Titles_LoadFile(string filename)
{
    Titles_ResetParserState();

    float fh = fopen(filename, FILE_READ);
    if (fh < 0)
    {
        dprint("Titles_LoadFile: could not open ");
        dprint(filename);
        dprint("\n");
        return;
    }

    // State machine: 0=expect name, 1=expect '{', 2=reading body.
    float state = 0;
    string pendingName = "";
    string body = "";

    string line;
    while ((line = fgets(fh)))
    {
        string raw = Titles_StripEol(line);
        float n = tokenize(raw);

        // Body lines preserve original spacing; everything else is token-based.
        if (state == 2)
        {
            // Detect '}' even if surrounded by whitespace.
            if (n >= 1 && argv(0) == "}")
            {
                Titles_Commit(pendingName, body);
                pendingName = "";
                body = "";
                state = 0;
                continue;
            }
            // Append raw line, joining with '|' for CSQC hud_message splitting via tokenizebyseparator(msg, "|").
            string clean = Titles_SanitizeBody(raw);
            string next;
            if (body == "") next = strzone(clean);
            else            next = strzone(strcat(body, "|", clean));
            if (body != "") strunzone(body);
            body = next;
            continue;
        }

        if (n == 0) continue;

        string first = argv(0);

        // Skip line comments.
        if (strlen(first) >= 2
            && str2chr(first, 0) == ASCII_SLASH_T
            && str2chr(first, 1) == ASCII_SLASH_T)
            continue;

        if (state == 0)
        {
            if (str2chr(first, 0) == ASCII_DOLLAR)
            {
                Titles_ApplyDirective(first, n);
                continue;
            }
            if (first == "{" || first == "}") continue;
            // Treat as new entry name.
            pendingName = first;
            state = 1;
            continue;
        }

        if (first == "{")
        {
            body = "";
            state = 2;
            continue;
        }
        if (str2chr(first, 0) == ASCII_DOLLAR)
        {
            Titles_ApplyDirective(first, n);
            continue;
        }
        // Stray content: abandon pending name, treat this as a new name.
        pendingName = first;
    }

    if (body != "") strunzone(body);
    fclose(fh);

    dprint("Titles: loaded ");
    dprint(ftos(title_count));
    dprint(" entries from ");
    dprint(filename);
    dprint("\n");
}

float Titles_Find(string name)
{
    if (name == "") return -1;
    for (float i = 0; i < title_count; i = i + 1)
    {
        if (title_name[i] == name) return i;
    }
    return -1;
}

float Title_Send(string name, entity dest)
{
    if (!dest || dest.classname != "player")
    {
        dprint("Title_Send: bad dest for '"); dprint(name); dprint("'\n");
        return FALSE;
    }
    float idx = Titles_Find(name);
    if (idx < 0)
    {
        dprint("Title_Send: not found '"); dprint(name); dprint("'\n");
        return FALSE;
    }
    dprint("Title_Send: send '"); dprint(name); dprint("'\n");

    vector rgb1 = title_rgb1[idx];
    vector rgb2 = title_rgb2[idx];

    string part1 = sprintf("hudmsg %d %f %f %d",
        (float)ENV_MESSAGE_CHANNEL,
        title_x[idx], title_y[idx],
        (float)title_effect[idx]);
    string part2a = sprintf(" %d %d %d %d",
        (float)rgb1_x, (float)rgb1_y, (float)rgb1_z, (float)title_a1[idx]);
    string part2b = sprintf(" %d %d %d %d",
        (float)rgb2_x, (float)rgb2_y, (float)rgb2_z, (float)title_a2[idx]);
    string part3 = sprintf(" %f %f %f %f \"%s\"\n",
        title_fadein[idx], title_fadeout[idx],
        title_holdtime[idx], title_fxtime[idx],
        title_message[idx]);

    stuffcmd(dest, strcat(part1, part2a, part2b, part3));
    return TRUE;
}

// Broadcast variant.
float Title_SendAll(string name)
{
    if (Titles_Find(name) < 0) return FALSE;
    entity p = find(world, classname, "player");
    while (p)
    {
        Title_Send(name, p);
        p = find(p, classname, "player");
    }
    return TRUE;
}

void Titles_Init()
{
    title_count = 0;
    Titles_LoadFile("titles.txt");
}
