#!/usr/bin/env python3
"""Shared QuakeC source parsing.

One definition of which files are live, what counts as a definition, and which
spans of a line are code versus comment versus string literal. Every tool that
reads the QuakeC sources shares it, so they cannot drift apart.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SRC = REPO / "src"

# Files vendored from the engine or DarkPlaces. Every identifier inside is either
# ABI-locked by name, order-locked by struct layout, or a builtin prototype.
# Never renamed, never scanned for definitions we own.
VENDORED = {
    "progsdefs.qc",
    "dpextensions.qc",
    "dp.qc",
    "clientqc/csprogsdefs.qc",
    "clientqc/clientdefs.qc",
    "menuqc/menudefs.qc",
    "keycodes.qc",
    "clientqc/keycodes.qc",
}

QC_TYPES = (
    "void",
    "float",
    "string",
    "vector",
    "entity",
    "int",
    "bool",
    "BOOL",
    "var",
)

IDENT = r"[A-Za-z_][A-Za-z0-9_]*"


# ---------------------------------------------------------------------------
# Manifest resolution
# ---------------------------------------------------------------------------


def _read_manifest(path: Path) -> tuple[list[Path], list[Path]]:
    """Return (qc files, nested .src manifests) listed by one .src file.

    A .src manifest is a flat include list: the first non-directive line is the
    output .dat path, the rest are source paths relative to the manifest's own
    directory. `//`-commented lines are excluded from the build -- that is how
    files become dead.
    """
    qc: list[Path] = []
    nested: list[Path] = []
    base = path.parent
    for raw in path.read_text(encoding="latin-1").splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        if line.startswith("#pragma sourcefile"):
            nested.append((base / line.split()[-1]).resolve())
            continue
        if line.startswith("#"):
            continue
        if line.endswith(".dat"):
            continue
        if line.endswith(".qc"):
            qc.append((base / line).resolve())
    return qc, nested


def live_files(root_manifest: Path | None = None) -> list[Path]:
    """Every .qc file the build actually compiles, in manifest order, deduped.

    Shared files (gamedefs.qc, math.qc, ui/*.qc) appear in more than one
    manifest; they are returned once. A rename in one of those hits multiple
    .dat targets.
    """
    root = root_manifest or (SRC / "progs.src")
    seen: set[Path] = set()
    ordered: list[Path] = []
    queue = [root.resolve()]
    while queue:
        manifest = queue.pop(0)
        if not manifest.exists():
            continue
        qc, nested = _read_manifest(manifest)
        queue.extend(nested)
        for f in qc:
            if f not in seen:
                seen.add(f)
                ordered.append(f)
    return ordered


TARGET_MANIFESTS = {
    "serverqc": "serverqc/serverqc.src",
    "clientqc": "clientqc/clientqc.src",
    "menuqc": "menuqc/menuqc.src",
}


def targets() -> dict[str, list[Path]]:
    """Per-.dat file lists.

    Each manifest compiles into its own program against a different engine ABI.
    Shared files (gamedefs.qc, math.qc, ui/*.qc) appear in more than one list, so
    anything defined in them exists once per target -- and a prototype in a
    shared file whose definition lives only under serverqc/ is an orphan in the
    clientqc and menuqc builds even though a whole-tree scan sees it resolved.
    """
    return {
        name: live_files(SRC / rel_path)
        for name, rel_path in TARGET_MANIFESTS.items()
    }


def all_qc_files() -> list[Path]:
    return sorted(SRC.rglob("*.qc"))


def dead_files() -> list[Path]:
    live = set(live_files())
    return [f for f in all_qc_files() if f not in live]


def rel(path: Path) -> str:
    try:
        return path.resolve().relative_to(SRC).as_posix()
    except ValueError:
        return path.as_posix()


def is_vendored(path: Path) -> bool:
    return rel(path) in VENDORED


def owned_files() -> list[Path]:
    """Live files whose identifiers we are allowed to rename."""
    return [f for f in live_files() if not is_vendored(f)]


# ---------------------------------------------------------------------------
# Line span classification
# ---------------------------------------------------------------------------

SPAN_CODE = "code"
SPAN_STRING = "string"
SPAN_COMMENT = "comment"
SPAN_DIRECTIVE = "directive"


@dataclass
class Span:
    kind: str
    start: int
    end: int  # exclusive

    def contains(self, pos: int) -> bool:
        return self.start <= pos < self.end


def classify_line(line: str, in_block_comment: bool) -> tuple[list[Span], bool]:
    """Split one source line into code / string / comment spans.

    Returns (spans, still_in_block_comment). Handles `//`, `/* */` (including
    multi-line), and double-quoted strings with backslash escapes.

    A `#`-directive line is classified whole as SPAN_DIRECTIVE: `#define FOO bar`
    defines an identifier, so it must be renamable, but it is not ordinary code
    and the renamer reports it separately.
    """
    spans: list[Span] = []
    i = 0
    n = len(line)
    code_start = 0

    def flush_code(upto: int, kind: str = SPAN_CODE) -> None:
        if upto > code_start:
            spans.append(Span(kind, code_start, upto))

    if in_block_comment:
        end = line.find("*/")
        if end < 0:
            return [Span(SPAN_COMMENT, 0, n)], True
        spans.append(Span(SPAN_COMMENT, 0, end + 2))
        i = end + 2
        code_start = i

    if not in_block_comment and line.lstrip().startswith("#"):
        # Still scan for trailing comments so `#define X 1 // note` classifies.
        stripped = line
        cpos = stripped.find("//")
        if cpos >= 0:
            return (
                [Span(SPAN_DIRECTIVE, 0, cpos), Span(SPAN_COMMENT, cpos, n)],
                False,
            )
        return [Span(SPAN_DIRECTIVE, 0, n)], False

    while i < n:
        ch = line[i]
        if ch == '"':
            flush_code(i)
            j = i + 1
            while j < n:
                if line[j] == "\\":
                    j += 2
                    continue
                if line[j] == '"':
                    j += 1
                    break
                j += 1
            spans.append(Span(SPAN_STRING, i, min(j, n)))
            i = min(j, n)
            code_start = i
            continue
        if ch == "/" and i + 1 < n:
            if line[i + 1] == "/":
                flush_code(i)
                spans.append(Span(SPAN_COMMENT, i, n))
                return spans, False
            if line[i + 1] == "*":
                flush_code(i)
                end = line.find("*/", i + 2)
                if end < 0:
                    spans.append(Span(SPAN_COMMENT, i, n))
                    return spans, True
                spans.append(Span(SPAN_COMMENT, i, end + 2))
                i = end + 2
                code_start = i
                continue
        i += 1

    flush_code(n)
    return spans, False


def span_kind_at(spans: list[Span], pos: int) -> str:
    for s in spans:
        if s.contains(pos):
            return s.kind
    return SPAN_CODE


def iter_classified(path: Path):
    """Yield (lineno, line, spans) for a file, tracking block comments."""
    in_block = False
    text = path.read_text(encoding="latin-1")
    for lineno, line in enumerate(text.splitlines(), start=1):
        spans, in_block = classify_line(line, in_block)
        yield lineno, line, spans


def iter_scoped(path: Path):
    """Like iter_classified, plus the brace depth at the START of each line.

    Depth 0 is file scope: a declaration there is a global or a field. Depth > 0
    is inside a function body, so a declaration there is a local. The renamer
    needs this distinction to refuse renames that would collide with a local --
    e.g. `float range = 0;` inside FuncTank_Think shadows the global `range()`
    function today, and a blind whole-word replace would corrupt it.

    Braces inside comments and string literals are ignored.
    """
    depth = 0
    for lineno, line, spans in iter_classified(path):
        yield lineno, line, spans, depth
        code = _strip_to_code(line, spans)
        depth += code.count("{") - code.count("}")
        if depth < 0:
            depth = 0


# ---------------------------------------------------------------------------
# Definition scanning
# ---------------------------------------------------------------------------

# Modern form:  void Foo(...) {   |   void(float) Foo(...) {
DEF_MODERN = re.compile(
    r"^\s*(?:var\s+)?(?P<ret>" + "|".join(QC_TYPES) + r")\s*"
    r"(?:\([^;{]*\))?\s*"
    r"(?P<name>" + IDENT + r")\s*\((?P<params>[^);{]*)"
)

# Old form:  void() Foo = { ... }   |   void(float d) Bar = { ... }
# The type carries the signature and the name is followed by `=`.
DEF_OLD_STYLE = re.compile(
    r"^\s*(?:var\s+)?(?P<ret>" + "|".join(QC_TYPES) + r")\s*"
    r"\((?P<params>[^;{]*)\)\s*"
    r"(?P<name>" + IDENT + r")\s*="
)

# Old-style forward declaration:  void(entity e) Foo;   |   float() Bar;
# Same shape as DEF_OLD_STYLE but terminated by `;` instead of `=`. Easy to miss:
# it looks like neither `type Name(...)` nor `type(...) Name = {`, and four of
# these already live in gamedefs.qc. A prototype the renamer fails to see is the
# null-body bug.
PROTO_OLD_STYLE = re.compile(
    r"^\s*(?:var\s+)?(?P<ret>" + "|".join(QC_TYPES) + r")\s*"
    r"\((?P<params>[^;{]*)\)\s*"
    r"(?P<name>" + IDENT + r")\s*;"
)

# Old-style definition with the body brace on the FOLLOWING line:
#     void(entity targ, entity attacker) ClientObituary
#     {
# Nothing terminates the signature line, so it matches neither the `;` prototype
# form nor the `= {` form. combat.qc:4 is exactly this.
DEF_OLD_STYLE_BARE = re.compile(
    r"^\s*(?:var\s+)?(?P<ret>" + "|".join(QC_TYPES) + r")\s*"
    r"\((?P<params>[^;{]*)\)\s*"
    r"(?P<name>" + IDENT + r")\s*$"
)

# Entity field:  .float foo;  |  .void(entity a) usehl;
# One declaration may declare SEVERAL fields:
#     .float m_yawCenter, m_yawRate, m_yawRange, m_yawTolerance;
# so the head is matched here and the full declarator list is split out by
# `declared_names`. Capturing only the first name hid the rest from the denylist
# as well as from the renamer -- a map-bound field sitting after a comma would
# have looked unlocked.
FIELD_DEF = re.compile(
    r"^\s*\.\s*(?:" + "|".join(QC_TYPES) + r")\s*"
    r"(?:\([^;{]*\))?\s*"
    r"(?P<rest>" + IDENT + r"\s*(?:\[[^\]]*\])?\s*[;,=].*)"
)

DECLARATOR = re.compile(r"(" + IDENT + r")\s*(?:\[[^\]]*\])?\s*(?:=[^,;]*)?\s*(?=[,;]|$)")


def declared_names(rest: str) -> list[str]:
    """Every identifier declared by one comma-separated declarator list."""
    rest = rest.split(";", 1)[0]
    out: list[str] = []
    for part in rest.split(","):
        m = DECLARATOR.match(part.strip())
        if m:
            out.append(m.group(1))
    return out

DEFINE = re.compile(r"^\s*#\s*define\s+(?P<name>" + IDENT + r")")

# Plain variable declaration:  float g_talkWaitTime;  |  var float weapon_slot[17];
# Distinguished from an old-style function def by the absence of a `(...)`
# signature between the type and the name. At depth 0 this is a global; deeper
# it is a local.
VAR_DEF = re.compile(
    r"^\s*(?:var\s+)?(?:" + "|".join(QC_TYPES) + r")\s+"
    r"(?P<name>" + IDENT + r")\s*(?:\[[^\]]*\])?\s*(?:=[^;]*)?;"
)


@dataclass
class Definition:
    name: str
    path: Path
    lineno: int
    kind: str  # function | field | define | global | local
    style: str  # modern | oldstyle | n/a
    is_prototype: bool
    ret: str = ""
    params: str = ""

    def where(self) -> str:
        return f"{rel(self.path)}:{self.lineno}"

    @property
    def is_zero_arg_void(self) -> bool:
        """Signature the engine requires of a map spawn function: `void Foo()`.

        Anything taking arguments cannot be engine-invoked from a classname, so
        this is the first discriminator between a spawn function (frozen) and a
        same-prefixed callback like `light_use_hl` (free to rename).
        """
        if self.kind != "function" or self.ret != "void":
            return False
        p = self.params.strip()
        return p == "" or p == "void"


def _strip_to_code(line: str, spans: list[Span]) -> str:
    """Blank out comment and string spans, preserving column positions."""
    out = list(line)
    for s in spans:
        if s.kind in (SPAN_COMMENT, SPAN_STRING):
            for k in range(s.start, min(s.end, len(out))):
                out[k] = " "
    return "".join(out)


def scan_definitions(paths: list[Path]) -> list[Definition]:
    """Find function, field, and #define definitions across files.

    Catches both the modern `void Foo(...)` and the legacy `void() Foo = {...}`
    forms. Missing the legacy form is the classic refactor bug here: 81 live
    definitions use it.
    """
    KEYWORDS = {"if", "while", "for", "return", "else", "do", "switch", "local"}
    defs: list[Definition] = []
    for path in paths:
        for lineno, line, spans, depth in iter_scoped(path):
            kinds = {s.kind for s in spans}
            if kinds == {SPAN_COMMENT}:
                continue

            if SPAN_DIRECTIVE in kinds:
                m = DEFINE.match(line)
                if m:
                    defs.append(
                        Definition(m.group("name"), path, lineno, "define", "n/a", False)
                    )
                continue

            code = _strip_to_code(line, spans)

            m = FIELD_DEF.match(code)
            if m:
                for nm in declared_names(m.group("rest")):
                    defs.append(
                        Definition(nm, path, lineno, "field", "n/a", False)
                    )
                continue

            m = PROTO_OLD_STYLE.match(code)
            if m:
                defs.append(
                    Definition(
                        m.group("name"),
                        path,
                        lineno,
                        "function",
                        "oldstyle",
                        True,
                        m.group("ret"),
                        m.group("params"),
                    )
                )
                continue

            m = DEF_OLD_STYLE.match(code) or DEF_OLD_STYLE_BARE.match(code)
            if m:
                defs.append(
                    Definition(
                        m.group("name"),
                        path,
                        lineno,
                        "function",
                        "oldstyle",
                        False,
                        m.group("ret"),
                        m.group("params"),
                    )
                )
                continue

            m = DEF_MODERN.match(code)
            if m:
                name = m.group("name")
                if name in QC_TYPES or name in KEYWORDS:
                    continue
                # A prototype ends in `;` and opens no body. The `{` test matters
                # for the hybrid form `void m_shutdown() = {};`, which ends in a
                # semicolon but is a real (empty-bodied) definition.
                is_proto = code.rstrip().endswith(";") and "{" not in code
                defs.append(
                    Definition(
                        name,
                        path,
                        lineno,
                        "function",
                        "modern",
                        is_proto,
                        m.group("ret"),
                        m.group("params"),
                    )
                )
                continue

            m = VAR_DEF.match(code)
            if m:
                name = m.group("name")
                if name in QC_TYPES or name in KEYWORDS:
                    continue
                defs.append(
                    Definition(
                        name,
                        path,
                        lineno,
                        "global" if depth == 0 else "local",
                        "n/a",
                        False,
                    )
                )
    return defs


# ---------------------------------------------------------------------------
# String-literal harvesting
# ---------------------------------------------------------------------------

STRING_LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')


def harvest_strings(paths: list[Path], pattern: re.Pattern) -> dict[str, list[str]]:
    """Collect string literals on lines matching `pattern`.

    Used to find locked BSP key names (`key == "holdtime"`) and classnames
    (`classname == "monster_zombie"`) -- both are contracts with data outside
    the repo, so the literal is frozen even when the field or function it feeds
    is free to be renamed.
    """
    found: dict[str, list[str]] = {}
    for path in paths:
        for lineno, line, spans in iter_classified(path):
            if not pattern.search(line):
                continue
            for m in STRING_LIT.finditer(line):
                if span_kind_at(spans, m.start()) != SPAN_STRING:
                    continue
                val = m.group(1)
                if val:
                    found.setdefault(val, []).append(f"{rel(path)}:{lineno}")
    return found
