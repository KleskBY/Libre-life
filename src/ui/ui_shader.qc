
float(string shadername, optional string defaultshader, ...) shaderforname = #238;

////////////////////   SHADER EDITOR   //////////////////////////////

string shader_name;         // e.g. "textures/editor/sphere"
string shader_file_path;    // e.g. "scripts/editor.shader"
float shader_version;       // incremented on each Apply to force new shader creation

void UI_ShaderInit()
{
	shader_file_path = "scripts/editor.shader";
	shader_name = "";
	shader_version = 0;

	// Load default shader text
	string default_text = strcat(
		"textures/test\n",
		"{\n",
		"\t{\n",
		"\t\tmap $lightmap\n",
		"\t}\n",
		"}"
	);
	UI_EditorSetText(default_text);
}

// Extract shader body (everything from the first '{' onward)
string UI_ShaderGetBody()
{
	float brace = strstrofs(UI_editor_text, "{", 0);
	if (brace < 0) return "";
	return substring(UI_editor_text, brace, strlen(UI_editor_text) - brace);
}

// Extract shader name from first line (trimmed)
string UI_ShaderGetName()
{
	string first_line = UI_EditorGetLine(0);
	// Trim leading whitespace
	while (strlen(first_line) > 0 && str2chr(first_line, 0) == 32)
		first_line = substring(first_line, 1, strlen(first_line) - 1);
	// Trim trailing whitespace
	while (strlen(first_line) > 0 && str2chr(first_line, strlen(first_line) - 1) == 32)
		first_line = substring(first_line, 0, strlen(first_line) - 1);
	return first_line;
}

// Apply shader: create it in engine memory via shaderforname (no file I/O needed)
void UI_ShaderApply()
{
	string name = UI_ShaderGetName();
	string body = UI_ShaderGetBody();
	if (strlen(name) == 0 || strlen(body) == 0)
	{
		print("ERROR: Shader needs a name (first line) and body (braces)\n");
		return;
	}

	if (shader_name) strunzone(shader_name);
	shader_name = strzone(name);

	// shaderforname caches by name, so we append a version to force creation
	// of a fresh shader each time the user edits and re-applies
	shader_version = shader_version + 1;
	string versioned_name = strcat(name, "##v", ftos(shader_version));

	// Create the shader directly in engine memory
	shaderforname(versioned_name, body);

	// Tell CSQC which shader handle to apply to the preview sphere
	cvar_set("editor_shader_name", versioned_name);

	print(strcat("Shader applied: ", name, " (v", ftos(shader_version), ")\n"));
}

// Save shader text to file (for project persistence)
void UI_ShaderSave()
{
	float fh = fopen(shader_file_path, FILE_WRITE);
	if (fh < 0)
	{
		print(strcat("ERROR: Cannot write ", shader_file_path, "\n"));
		return;
	}

	float total = UI_EditorLineCount(UI_editor_text);
	for (float i = 0; i < total; i++)
	{
		fputs(fh, strcat(UI_EditorGetLine(i), "\n"));
	}
	fclose(fh);

	// Also apply the shader live
	UI_ShaderApply();
	print(strcat("Shader saved to: ", shader_file_path, "\n"));
}

// Load shader from file
void UI_ShaderLoad(string path)
{
	float fh = fopen(path, FILE_READ);
	if (fh < 0)
	{
		print(strcat("ERROR: Cannot read ", path, "\n"));
		return;
	}

	string full = "";
	float line_num = 0;
	float max_lines = 4096;
	while (line_num < max_lines)
	{
		string line = fgets(fh);
		if (line == __NULL__)
			break;
		if (line_num > 0)
			full = strcat(full, "\n", line);
		else
			full = line;
		line_num = line_num + 1;
	}
	fclose(fh);

	if (shader_file_path) strunzone(shader_file_path);
	shader_file_path = strzone(path);
	UI_EditorSetText(full);
	print(strcat("Loaded shader: ", path, "\n"));
}

// Button callbacks
void UI_ShaderApplyCallback()
{
	UI_ShaderApply();
}

void UI_ShaderSaveCallback()
{
	UI_ShaderSave();
}

void UI_ShaderNewCallback()
{
	UI_ShaderInit();
}
