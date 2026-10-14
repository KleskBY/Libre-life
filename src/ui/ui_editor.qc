
///////////////////////   TEXT EDITOR   /////////////////////////////

// Editor state
string ui_editor_text;          // full text (newlines as \n)
float ui_editor_cursor;         // character index in text
float ui_editor_cursor_prev;    // cursor position last frame (for auto-scroll)
float ui_editor_scroll;         // first visible line
float ui_editor_active;         // is editor focused

float ui_editor_line_count;

float ui_editor_cursor_line;
float ui_editor_cursor_col;
float ui_editor_cursor_cache_pos;  // cursor position when cache was last computed

// Selection: -1 = no selection, otherwise the anchor position.
// The selection range is between ui_editor_sel and ui_editor_cursor.
float ui_editor_sel;

// Context menu
float  ui_editor_ctx_open;
vector ui_editor_ctx_pos;

///////////////////   LINE UTILITIES   //////////////////////////////

// Recompute cached line count from text (call after any text mutation)
void UI_EditorUpdateLineCount()
{
	ui_editor_line_count = 1;
	for (float i = 0; i < strlen(ui_editor_text); i++)
		if (str2chr(ui_editor_text, i) == CHAR_NEWLINE)
			ui_editor_line_count = ui_editor_line_count + 1;
}

// Recompute cached cursor line/col if cursor has moved
void UI_EditorUpdateCursorCache()
{
	if (ui_editor_cursor == ui_editor_cursor_cache_pos) return;
	ui_editor_cursor_cache_pos = ui_editor_cursor;

	// Single pass: count newlines up to cursor for line, track col from last newline
	float line = 0;
	float col = 0;
	for (float i = 0; i < ui_editor_cursor && i < strlen(ui_editor_text); i++)
	{
		if (str2chr(ui_editor_text, i) == CHAR_NEWLINE)
		{
			line = line + 1;
			col = 0;
		}
		else
			col = col + 1;
	}
	ui_editor_cursor_line = line;
	ui_editor_cursor_col = col;
}

float UI_EditorLineCount(string txt)
{
	if (strlen(txt) == 0) return 1;
	float count = 1;
	for (float i = 0; i < strlen(txt); i++)
		if (str2chr(txt, i) == CHAR_NEWLINE)
			count = count + 1;
	return count;
}

float UI_EditorCursorLine()
{
	float line = 0;
	for (float i = 0; i < ui_editor_cursor && i < strlen(ui_editor_text); i++)
		if (str2chr(ui_editor_text, i) == CHAR_NEWLINE)
			line = line + 1;
	return line;
}

float UI_EditorCursorCol()
{
	float col = 0;
	for (float i = ui_editor_cursor - 1; i >= 0; i--)
	{
		if (str2chr(ui_editor_text, i) == CHAR_NEWLINE)
			break;
		col = col + 1;
	}
	return col;
}

float UI_EditorLineStart(float line)
{
	if (line <= 0) return 0;
	float cur = 0;
	for (float i = 0; i < strlen(ui_editor_text); i++)
	{
		if (str2chr(ui_editor_text, i) == CHAR_NEWLINE)
		{
			cur = cur + 1;
			if (cur >= line) return i + 1;
		}
	}
	return strlen(ui_editor_text);
}

float UI_EditorLineLen(float line)
{
	float start = UI_EditorLineStart(line);
	float len = 0;
	for (float i = start; i < strlen(ui_editor_text); i++)
	{
		if (str2chr(ui_editor_text, i) == CHAR_NEWLINE)
			break;
		len = len + 1;
	}
	return len;
}

string UI_EditorGetLine(float line)
{
	float start = UI_EditorLineStart(line);
	float len = UI_EditorLineLen(line);
	return substring(ui_editor_text, start, len);
}

///////////////////   SELECTION HELPERS   ////////////////////////////

float UI_EditorHasSelection()
{
	return (ui_editor_sel >= 0 && ui_editor_sel != ui_editor_cursor);
}

float UI_EditorSelMin()
{
	if (ui_editor_sel < ui_editor_cursor) return ui_editor_sel;
	return ui_editor_cursor;
}

float UI_EditorSelMax()
{
	if (ui_editor_sel > ui_editor_cursor) return ui_editor_sel;
	return ui_editor_cursor;
}

string UI_EditorGetSelection()
{
	if (!UI_EditorHasSelection()) return "";
	return substring(ui_editor_text, UI_EditorSelMin(), UI_EditorSelMax() - UI_EditorSelMin());
}

void UI_EditorDeleteSelection()
{
	if (!UI_EditorHasSelection()) return;
	float a = UI_EditorSelMin();
	float b = UI_EditorSelMax();
	string before = substring(ui_editor_text, 0, a);
	string after = substring(ui_editor_text, b, strlen(ui_editor_text) - b);
	if (ui_editor_text) strunzone(ui_editor_text);
	ui_editor_text = strzone(strcat(before, after));
	ui_editor_cursor = a;
	ui_editor_sel = -1;
	UI_EditorUpdateLineCount();
}

void UI_EditorClearSelection()
{
	ui_editor_sel = -1;
}

// Begin or extend a selection from the current cursor position
void UI_EditorBeginSelection()
{
	if (ui_editor_sel < 0)
		ui_editor_sel = ui_editor_cursor;
}

///////////////////   EDITING OPERATIONS   //////////////////////////

void UI_EditorInsert(string s)
{
	if (UI_EditorHasSelection())
		UI_EditorDeleteSelection();
	string before = substring(ui_editor_text, 0, ui_editor_cursor);
	string after = substring(ui_editor_text, ui_editor_cursor, strlen(ui_editor_text) - ui_editor_cursor);
	if (ui_editor_text) strunzone(ui_editor_text);
	ui_editor_text = strzone(strcat(before, s, after));
	ui_editor_cursor = ui_editor_cursor + strlen(s);
	ui_editor_sel = -1;
	UI_EditorUpdateLineCount();
}

void UI_EditorBackspace()
{
	if (UI_EditorHasSelection()) { UI_EditorDeleteSelection(); return; }
	if (ui_editor_cursor <= 0) return;
	string before = substring(ui_editor_text, 0, ui_editor_cursor - 1);
	string after = substring(ui_editor_text, ui_editor_cursor, strlen(ui_editor_text) - ui_editor_cursor);
	if (ui_editor_text) strunzone(ui_editor_text);
	ui_editor_text = strzone(strcat(before, after));
	ui_editor_cursor = ui_editor_cursor - 1;
	UI_EditorUpdateLineCount();
}

void UI_EditorDelete()
{
	if (UI_EditorHasSelection()) { UI_EditorDeleteSelection(); return; }
	if (ui_editor_cursor >= strlen(ui_editor_text)) return;
	string before = substring(ui_editor_text, 0, ui_editor_cursor);
	string after = substring(ui_editor_text, ui_editor_cursor + 1, strlen(ui_editor_text) - ui_editor_cursor - 1);
	if (ui_editor_text) strunzone(ui_editor_text);
	ui_editor_text = strzone(strcat(before, after));
	UI_EditorUpdateLineCount();
}

void UI_EditorSetText(string txt)
{
	if (ui_editor_text) strunzone(ui_editor_text);
	ui_editor_text = strzone(txt);
	ui_editor_cursor = 0;
	ui_editor_scroll = 0;
	ui_editor_sel = -1;
	UI_EditorUpdateLineCount();
	ui_editor_cursor_cache_pos = -1; // invalidate cursor cache
}

void UI_EditorSelectAll()
{
	ui_editor_sel = 0;
	ui_editor_cursor = strlen(ui_editor_text);
}

///////////////////   CLIPBOARD   ///////////////////////////////////

void UI_EditorCopy()
{
	if (!UI_EditorHasSelection()) return;
	clipboard_set(0, UI_EditorGetSelection());
}

void UI_EditorCut()
{
	if (!UI_EditorHasSelection()) return;
	UI_EditorCopy();
	UI_EditorDeleteSelection();
}

void UI_EditorPaste()
{
	// clipboard_get(0) delivers paste content asynchronously via m_keydown ascii
	// callbacks, not as a return value. The editor's input handler processes each
	// character as it arrives.
	clipboard_get(0);
}

///////////////////   INPUT PROCESSING   ////////////////////////////

// Helper: move cursor to target line/col (used by up/down arrows)
void UI_EditorMoveCursorToLine(float target_line, float desired_col)
{
	float ls = UI_EditorLineStart(target_line);
	float ll = UI_EditorLineLen(target_line);
	if (desired_col > ll) desired_col = ll;
	ui_editor_cursor = ls + desired_col;
}

float UI_ProcessEditorInput(float key, float ascii)
{
	if (!ui_editor_active) return FALSE;

	// Escape
	if (key == K_ESCAPE)
	{
		if (UI_EditorHasSelection())
			UI_EditorClearSelection();
		else
			ui_editor_active = FALSE;
		return TRUE;
	}

	// Ctrl combos (ascii control codes)

	// Ctrl+A
	if (ascii == 1)
	{
		UI_EditorSelectAll();
		return TRUE;
	}
	// Ctrl+C
	if (ascii == 3)
	{
		UI_EditorCopy();
		return TRUE;
	}
	// Ctrl+
	if (ascii == 24)
	{
		UI_EditorCut();
		return TRUE;
	}
	// Ctrl+V
	if (ascii == 22)
	{
		if (UI_EditorHasSelection())
			UI_EditorDeleteSelection();
		UI_EditorPaste();
		return TRUE;
	}

	// Navigation keys
	if (key == K_LEFTARROW)
	{
		if (ui_shift_held) // Shift+Left
		{
			UI_EditorBeginSelection();
			if (ui_editor_cursor > 0)
				ui_editor_cursor = ui_editor_cursor - 1;
		}
		else
		{
			if (UI_EditorHasSelection())
				ui_editor_cursor = UI_EditorSelMin();
			else if (ui_editor_cursor > 0)
				ui_editor_cursor = ui_editor_cursor - 1;
			UI_EditorClearSelection();
		}
		return TRUE;
	}
	if (key == K_RIGHTARROW)
	{
		if (ui_shift_held)
		{
			UI_EditorBeginSelection();
			if (ui_editor_cursor < strlen(ui_editor_text))
				ui_editor_cursor = ui_editor_cursor + 1;
		}
		else
		{
			if (UI_EditorHasSelection())
				ui_editor_cursor = UI_EditorSelMax();
			else if (ui_editor_cursor < strlen(ui_editor_text))
				ui_editor_cursor = ui_editor_cursor + 1;
			UI_EditorClearSelection();
		}
		return TRUE;
	}
	if (key == K_UPARROW)
	{
		if (ui_shift_held) UI_EditorBeginSelection();
		else UI_EditorClearSelection();
		float line = UI_EditorCursorLine();
		if (line > 0)
			UI_EditorMoveCursorToLine(line - 1, UI_EditorCursorCol());
		return TRUE;
	}
	if (key == K_DOWNARROW)
	{
		if (ui_shift_held) UI_EditorBeginSelection();
		else UI_EditorClearSelection();
		float line2 = UI_EditorCursorLine();
		if (line2 < ui_editor_line_count - 1)
			UI_EditorMoveCursorToLine(line2 + 1, UI_EditorCursorCol());
		return TRUE;
	}
	
	
	if (key == K_HOME)
	{
		if (ui_shift_held) UI_EditorBeginSelection();
		else UI_EditorClearSelection();
		float ln = UI_EditorCursorLine();
		ui_editor_cursor = UI_EditorLineStart(ln);
		return TRUE;
	}
	if (key == K_END)
	{
		if (ui_shift_held) UI_EditorBeginSelection();
		else UI_EditorClearSelection();
		float ln2 = UI_EditorCursorLine();
		ui_editor_cursor = UI_EditorLineStart(ln2) + UI_EditorLineLen(ln2);
		return TRUE;
	}
	

	//Keys
	if (key == K_BACKSPACE) { UI_EditorBackspace(); return TRUE; }
	if (key == K_DEL)       { UI_EditorDelete();    return TRUE; }
	if (key == K_TAB)       { UI_EditorInsert("\t"); return TRUE; }
	
	//Autoindent
	if (key == K_ENTER)
	{
		
		float aln = UI_EditorCursorLine();
		string aline = UI_EditorGetLine(aln);
		string indent = "";
		for (float ti = 0; ti < strlen(aline); ti++)
		{
			if (str2chr(aline, ti) == CHAR_TAB)
				indent = strcat(indent, "\t");
			else
				break;
		}
		UI_EditorInsert(strcat("\n", indent));
		return TRUE;
	}
	
	if (ascii == 10 || ascii == 13) { UI_EditorInsert("\n"); return TRUE; }
	if (ascii == 9)                 { UI_EditorInsert("\t"); return TRUE; }

	if (ascii >= 32 && ascii < 127)
	{
		UI_EditorInsert(chr2str(ascii));
		return TRUE;
	}

	return FALSE;
}

///////////////////   SYNTAX HIGHLIGHTING   /////////////////////////

vector UI_EditorKeywordColor(string token)
{
	if (token == "map" || token == "clampmap" || token == "animmap") return UI_SYN_KEYWORD;
	if (token == "blendFunc" || token == "alphaFunc" || token == "depthFunc") return UI_SYN_KEYWORD;
	if (token == "rgbGen" || token == "alphaGen" || token == "tcGen") return UI_SYN_KEYWORD;
	if (token == "tcMod" || token == "depthWrite" || token == "detail") return UI_SYN_KEYWORD;

	if (token == "surfaceparm" || token == "cull" || token == "deformVertexes") return UI_SYN_DIRECTIVE;
	if (token == "nopicmip" || token == "nomipmaps" || token == "polygonOffset") return UI_SYN_DIRECTIVE;
	if (token == "sort" || token == "tessSize" || token == "q3map_sun") return UI_SYN_DIRECTIVE;
	if (token == "qer_editorimage" || token == "qer_nocarve" || token == "qer_trans") return UI_SYN_DIRECTIVE;
	if (token == "skyparms" || token == "fogparms" || token == "portal") return UI_SYN_DIRECTIVE;

	if (token == "GL_ONE" || token == "GL_ZERO" || token == "GL_SRC_ALPHA") return UI_SYN_BLEND;
	if (token == "GL_ONE_MINUS_SRC_ALPHA" || token == "GL_DST_COLOR") return UI_SYN_BLEND;
	if (token == "GL_SRC_COLOR" || token == "GL_ONE_MINUS_DST_COLOR") return UI_SYN_BLEND;
	if (token == "GL_ONE_MINUS_SRC_COLOR" || token == "GL_DST_ALPHA") return UI_SYN_BLEND;
	if (token == "GL_ONE_MINUS_DST_ALPHA") return UI_SYN_BLEND;
	if (token == "add" || token == "filter" || token == "blend") return UI_SYN_BLEND;

	if (token == "wave" || token == "sin" || token == "triangle") return UI_SYN_WAVE;
	if (token == "square" || token == "sawtooth" || token == "inversesawtooth") return UI_SYN_WAVE;
	if (token == "noise") return UI_SYN_WAVE;

	if (token == "$lightmap" || token == "$whiteimage") return UI_SYN_BUILTIN;

	return UI_SYN_DEFAULT;
}

void UI_EditorDrawLine(string line, vector pos, vector font_v)
{
	float x = pos_x;
	float i = 0;
	float len = strlen(line);

	while (i < len)
	{
		float ch = str2chr(line, i);

		if (ch == CHAR_SPACE || ch == CHAR_TAB)
		{
			float space_w;
			if (ch == CHAR_TAB) space_w = font_v_x * UI_EDITOR_TAB_WIDTH;
			else space_w = stringwidth(" ", true, font_v);
			x = x + space_w;
			i = i + 1;
			continue;
		}

		if (ch == CHAR_LBRACE || ch == CHAR_RBRACE)
		{
			string brace = substring(line, i, 1);
			drawstring([x, pos_y], brace, font_v, UI_SYN_BRACE, UI_TEXT_ALPHA, 0);
			x = x + stringwidth(brace, true, font_v);
			i = i + 1;
			continue;
		}

		if (ch == CHAR_SLASH && i + 1 < len && str2chr(line, i + 1) == CHAR_SLASH)
		{
			string comment = substring(line, i, len - i);
			drawstring([x, pos_y], comment, font_v, UI_SYN_COMMENT, UI_TEXT_ALPHA, 0);
			return;
		}

		float tok_start = i;
		while (i < len)
		{
			float c2 = str2chr(line, i);
			if (c2 == CHAR_SPACE || c2 == CHAR_TAB || c2 == CHAR_LBRACE || c2 == CHAR_RBRACE)
				break;
			i = i + 1;
		}

		string token = substring(line, tok_start, i - tok_start);
		vector color = UI_EditorKeywordColor(token);
		drawstring([x, pos_y], token, font_v, color, UI_TEXT_ALPHA, 0);
		x = x + stringwidth(token, true, font_v);
	}
}

float UI_EditorCursorX(string line, float col, vector font_v)
{
	float x = 0;
	for (float i = 0; i < col && i < strlen(line); i++)
	{
		float ch = str2chr(line, i);
		if (ch == CHAR_TAB) x = x + font_v_x * UI_EDITOR_TAB_WIDTH;
		else x = x + stringwidth(substring(line, i, 1), true, font_v);
	}
	return x;
}

///////////////////   DRAWING   /////////////////////////////////////

void UI_TextEditor(vector pos, vector size)
{
	vector font_v = [ui_font_size, ui_font_size];
	float row_h = ui_font_size * UI_EDITOR_ROW_HEIGHT_MULT;
	float gutter_w = ui_font_size * UI_EDITOR_GUTTER_MULT;
	float visible = floor(size_y / row_h);
	if (visible < 1) visible = 1;

	UI_FrameInput(pos, size);

	// Context menu constants (used for both input and drawing)
	float ctx_item_h = ui_font_size * UI_EDITOR_CTX_ITEM_H_MULT;
	float ctx_w      = ui_font_size * UI_EDITOR_CTX_W_MULT;
	float ctx_h      = ctx_item_h * UI_EDITOR_CTX_ITEMS;

	// Context menu input (priority: before main click logic)
	if (ui_editor_ctx_open)
	{
		if (ui_clicked)
		{
			if (UI_MouseInRectSize(ui_editor_ctx_pos, [ctx_w, ctx_h]))
			{
				float item_idx = floor((ui_mouse_pos_y - ui_editor_ctx_pos_y) / ctx_item_h);
				if (item_idx == 0) UI_EditorCopy();
				else if (item_idx == 1) UI_EditorCut();
				else if (item_idx == 2)
				{
					if (UI_EditorHasSelection()) UI_EditorDeleteSelection();
					UI_EditorPaste();
				}
				ui_editor_ctx_open = 0;
				ui_clicked = 0;
			}
			else
			{
				// Click outside menu: close it, let click fall through to editor
				ui_editor_ctx_open = 0;
			}
		}
	}

	// Update cursor cache once per frame
	UI_EditorUpdateCursorCache();

	// Before the click handling below, so a press on the scrollbar scrolls
	// rather than moving the text cursor.
	ui_editor_scroll = UI_ScrollbarInput(UI_SB_ID_EDITOR, pos + [size_x - ui_font_size * 0.4, 0],
	                                     size_y, ui_editor_line_count, visible, ui_editor_scroll);

	// Click to focus and position cursor
	float hovering = UI_MouseInRectSize(pos, size);
	if (hovering && ui_clicked && !UI_IsBehindWindow())
	{
		ui_editor_active = TRUE;
		ui_clicked = 0;

		float click_line = ui_editor_scroll + floor((ui_mouse_pos_y - pos_y) / row_h);
		float total = ui_editor_line_count;
		if (click_line >= total) click_line = total - 1;
		if (click_line < 0) click_line = 0;

		float line_start = UI_EditorLineStart(click_line);
		string line_text = UI_EditorGetLine(click_line);
		float click_x = ui_mouse_pos_x - pos_x - gutter_w;

		// Find the inter-character gap closest to click_x (O(n) incremental)
		float best_col = 0;
		float best_dist = fabs(0 - click_x);
		float snap_x = 0;
		for (float c = 0; c < strlen(line_text); c++)
		{
			float ch_click = str2chr(line_text, c);
			float cw_click = (ch_click == CHAR_TAB) ? font_v_x * UI_EDITOR_TAB_WIDTH : stringwidth(substring(line_text, c, 1), true, font_v);
			snap_x = snap_x + cw_click;
			float dist = fabs(snap_x - click_x);
			if (dist < best_dist) { best_dist = dist; best_col = c + 1; }
		}
		ui_editor_cursor = line_start + best_col;
		ui_editor_sel = ui_editor_cursor;
	}

	// Right-click: open context menu
	if (hovering && ui_mouse2_clicked && !UI_IsBehindWindow())
	{
		ui_editor_active = TRUE;
		ui_editor_ctx_open = 1;
		ui_editor_ctx_pos = ui_mouse_pos;
		ui_mouse2_clicked = 0;
	}

	// Drag to extend selection
	if (ui_editor_active && ui_mouse1_held && !ui_clicked && hovering)
	{
		float drag_line = ui_editor_scroll + floor((ui_mouse_pos_y - pos_y) / row_h);
		float drag_total = ui_editor_line_count;
		if (drag_line >= drag_total) drag_line = drag_total - 1;
		if (drag_line < 0) drag_line = 0;

		float drag_ls = UI_EditorLineStart(drag_line);
		string drag_lt = UI_EditorGetLine(drag_line);
		float drag_cx = ui_mouse_pos_x - pos_x - gutter_w;

		float drag_bc = 0;
		float drag_bd = fabs(0 - drag_cx);
		float drag_sx = 0;
		for (float dc = 0; dc < strlen(drag_lt); dc++)
		{
			float ch_drag = str2chr(drag_lt, dc);
			float cw_drag = (ch_drag == CHAR_TAB) ? font_v_x * UI_EDITOR_TAB_WIDTH : stringwidth(substring(drag_lt, dc, 1), true, font_v);
			drag_sx = drag_sx + cw_drag;
			float dd = fabs(drag_sx - drag_cx);
			if (dd < drag_bd) { drag_bd = dd; drag_bc = dc + 1; }
		}
		ui_editor_cursor = drag_ls + drag_bc;
	}

	if (ui_editor_active && ui_clicked && !hovering)
	{
		ui_editor_active = FALSE;
		UI_EditorClearSelection();
	}

	// Auto-scroll to cursor only when cursor moved
	UI_EditorUpdateCursorCache();
	float cursor_line = ui_editor_cursor_line;
	if (ui_editor_cursor != ui_editor_cursor_prev)
	{
		ui_editor_cursor_prev = ui_editor_cursor;
		if (cursor_line < ui_editor_scroll)
			ui_editor_scroll = cursor_line;
		if (cursor_line >= ui_editor_scroll + visible)
			ui_editor_scroll = cursor_line - visible + 1;
	}

	// Mouse wheel
	float total_lines = ui_editor_line_count;
	if (hovering && ui_wheel != 0)
	{
		ui_editor_scroll = ui_editor_scroll - ui_wheel * 3;
		if (ui_editor_scroll < 0) ui_editor_scroll = 0;
		float maxscroll = total_lines - visible;
		if (maxscroll < 0) maxscroll = 0;
		if (ui_editor_scroll > maxscroll) ui_editor_scroll = maxscroll;
		ui_wheel = 0;
	}

	// Precompute selection range
	float sel_active = UI_EditorHasSelection();
	float sel_min = 0;
	float sel_max = 0;
	if (sel_active)
	{
		sel_min = UI_EditorSelMin();
		sel_max = UI_EditorSelMax();
	}

	float cursor_col = ui_editor_cursor_col;

	// Single forward scan: find start of first visible line, then walk line by line
	float text_len = strlen(ui_editor_text);
	float scan_pos = 0;
	float scan_ln = 0;
	while (scan_ln < ui_editor_scroll && scan_pos < text_len)
	{
		if (str2chr(ui_editor_text, scan_pos) == CHAR_NEWLINE) scan_ln = scan_ln + 1;
		scan_pos = scan_pos + 1;
	}

	for (float r = 0; r < visible; r++)
	{
		float ln = ui_editor_scroll + r;
		if (ln >= total_lines) break;

		// Find line boundaries incrementally (no full-text rescan)
		float ls = scan_pos;
		float scan_end = scan_pos;
		while (scan_end < text_len && str2chr(ui_editor_text, scan_end) != CHAR_NEWLINE)
			scan_end = scan_end + 1;
		float ll = scan_end - ls;
		float le = ls + ll;
		string line_text2 = substring(ui_editor_text, ls, ll);

		vector line_pos = pos + [0, row_h * r];

		// Selection highlight
		if (sel_active && sel_min < le + 1 && sel_max > ls)
		{
			float hl_start = sel_min;
			if (hl_start < ls) hl_start = ls;
			float hl_end = sel_max;
			if (hl_end > le) hl_end = le;

			float x1 = UI_EditorCursorX(line_text2, hl_start - ls, font_v);
			float x2 = UI_EditorCursorX(line_text2, hl_end - ls, font_v);

			// Extend highlight past EOL if selection spans the newline
			if (sel_max > le && ln < total_lines - 1)
				x2 = x2 + font_v_x * 0.5;

			if (x2 > x1)
				drawfill(line_pos + [gutter_w + x1, row_h * 0.05], [x2 - x1, row_h * 0.9], UI_SEL_COLOR, UI_SEL_ALPHA, 0);
		}

		// Line number
		string num = ftos(ln + 1);
		float num_w = stringwidth(num, true, font_v);
		drawstring(line_pos + [gutter_w - num_w - ui_font_size * 0.3, row_h * UI_EDITOR_TEXT_Y_OFFSET], num, font_v, '0.45 0.45 0.45', 0.7, 0);

		// Syntax-highlighted text
		UI_EditorDrawLine(line_text2, line_pos + [gutter_w, row_h * UI_EDITOR_TEXT_Y_OFFSET], font_v);

		// Blinking cursor
		if (ui_editor_active && ln == cursor_line)
		{
			float f = rint(UI_GetTime() * UI_CURSOR_BLINK_RATE) % UI_CURSOR_BLINK_MOD;
			if (f < UI_CURSOR_BLINK_THRESHOLD)
			{
				float cx2 = UI_EditorCursorX(line_text2, cursor_col, font_v);
				drawfill(line_pos + [gutter_w + cx2, row_h * 0.1], [1, row_h * 0.8], '1 1 1', UI_TEXT_ALPHA, 0);
			}
		}

		// Advance past newline to next line start
		scan_pos = scan_end + 1;
	}

	// Gutter line
	drawfill(pos + [gutter_w - 1, 0], [1, size_y], '0.4 0.4 0.4', 0.3, 0);

	// Scrollbar
	UI_DrawScrollbar(pos + [size_x - ui_font_size * 0.4, 0], size_y, total_lines, visible, ui_editor_scroll);

	// Context menu drawing (on top of everything)
	if (ui_editor_ctx_open)
	{
		// Clamp to stay inside editor bounds
		vector ctx_pos = ui_editor_ctx_pos;
		if (ctx_pos_x + ctx_w > pos_x + size_x) ctx_pos_x = pos_x + size_x - ctx_w;
		if (ctx_pos_y + ctx_h > pos_y + size_y) ctx_pos_y = pos_y + size_y - ctx_h;
		if (ctx_pos_x < pos_x) ctx_pos_x = pos_x;
		if (ctx_pos_y < pos_y) ctx_pos_y = pos_y;
		ui_editor_ctx_pos = ctx_pos;

		UI_Frame(ctx_pos, [ctx_w, ctx_h], FALSE);

		string ctx_names[3];
		ctx_names[0] = "Copy";
		ctx_names[1] = "Cut";
		ctx_names[2] = "Paste";

		for (float ci = 0; ci < 3; ci++)
		{
			vector item_pos  = ctx_pos + [0, ctx_item_h * ci];
			vector item_size = [ctx_w, ctx_item_h];
			if (UI_MouseInRectSize(item_pos, item_size))
				drawfill(item_pos, item_size, UI_SEL_COLOR, 0.35, 0);
			UI_TextCentered(ctx_names[ci], item_pos + [ctx_w * 0.5, ctx_item_h * 0.5]);
			if (ci < 2)
				drawfill(item_pos + [0, ctx_item_h - 1], [ctx_w, 1], '1 1 1', 0.08, 0);
		}
	}
}
