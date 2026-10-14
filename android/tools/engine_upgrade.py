"""Upgrade the Zircon engine under the Android port, keeping our patches.

The upgrade workspace (default D:/GameDev/ObjectN/engine_upgrade) is a git repo with
three branches:

    base      pristine Zircon release the port was built from
    upstream  pristine newer Zircon releases, one commit per dump
    android   base + ObjectN/Steam customizations + the Android port (what we ship)

Upgrading is a real 3-way merge, so upstream edits and ours combine instead of
overwriting each other. Every snapshot is normalized to LF first: the Zircon dumps
mix CRLF and LF per file, and without normalizing, git sees whole files as changed
and every merge conflicts.

    python tools/engine_upgrade.py status
    python tools/engine_upgrade.py import <dump_dir>   # new release -> upstream branch
    python tools/engine_upgrade.py merge [--auto-upstream]
    python tools/engine_upgrade.py export              # android branch -> engine_source

See ENGINE_UPGRADE.md for the full procedure.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # android/
PROJECT = os.path.abspath(os.path.join(ROOT, ".."))                  # ObjectN/
# The engine tree and upgrade workspace usually live outside this repo (large, mostly vendored
# upstream code). Point at them with ZIRCON_UPGRADE_WORKSPACE / ZIRCON_ENGINE_DIR.
WORKSPACE = os.environ.get("ZIRCON_UPGRADE_WORKSPACE") or os.path.join(PROJECT, "engine_upgrade")
ENGINE = os.environ.get("ZIRCON_ENGINE_DIR") or os.path.join(PROJECT, "engine_source")

TEXT_EXT = {".c", ".h", ".cpp", ".m", ".txt", ".md", ".cbp", ".sln", ".vcxproj", ".filters",
            ".user", ".bat", ".sh", ".pl", ".qc", ".cfg", ".xml", ".yml", ".inc", ".rc",
            ".plist", ".props", ".config", ".template"}
TEXT_NAMES = {"makefile", "bsdmakefile", "makefile.inc", "doxyfile", "todo", "copying"}

# Conflicts in these are upstream's own Steam/net integration, which absorbed the
# ObjectN KLESKBY_STEAM extension; taking upstream keeps future merges small.
PREFER_UPSTREAM = {"lhnet.c", "lhnet.h", "netconn.c", "netconn.h", "prvm_cmds.h", "prvm_steam.h",
                   "svvm_cmds.c", "svvm_cmds_table.h", "clvm_cmds_table.h", "sys_sdl.c",
                   "steam.c", "steam.h", "steam_net.c", "steam_net.h"}

MARKERS = "ANDROID_TOUCH_OVERLAY, android_touch_cursor_ui, android_csqc_cursor_time, frameskip"


def git(*args, check=True):
    r = subprocess.run(["git", "-C", WORKSPACE] + list(args), text=True, capture_output=True)
    if check and r.returncode != 0:
        sys.exit("git " + " ".join(args) + " failed:\n" + (r.stderr or "") + (r.stdout or ""))
    return (r.stdout or "").strip()


def normalize(root):
    changed = 0
    for dirpath, dirs, files in os.walk(root):
        if ".git" in dirs:
            dirs.remove(".git")
        for name in files:
            if os.path.splitext(name)[1].lower() not in TEXT_EXT and name.lower() not in TEXT_NAMES:
                continue
            path = os.path.join(dirpath, name)
            try:
                data = open(path, "rb").read()
            except OSError:
                continue
            if b"\r\n" in data:
                open(path, "wb").write(data.replace(b"\r\n", b"\n"))
                changed += 1
    return changed


def replace_worktree(src):
    for entry in os.listdir(WORKSPACE):
        if entry == ".git":
            continue
        path = os.path.join(WORKSPACE, entry)
        if os.path.isdir(path):
            shutil.rmtree(path)
        else:
            os.remove(path)
    shutil.copytree(src, WORKSPACE, dirs_exist_ok=True)
    for stray in (".gitignore", ".gitattributes"):
        p = os.path.join(WORKSPACE, stray)
        if os.path.exists(p):
            os.remove(p)
    normalize(WORKSPACE)


def release_of(tree):
    path = os.path.join(tree, "_zircon_beta_changes.txt")
    best = 0
    if os.path.isfile(path):
        text = open(path, encoding="utf-8", errors="replace").read()
        for m in re.finditer(r"Zircon Beta Release (\d+)", text):
            best = max(best, int(m.group(1)))
    return best or "?"


def cmd_status(args):
    print("workspace: " + WORKSPACE)
    print(git("log", "--oneline", "--graph", "--all", "--decorate"))
    print("\nengine_source release: Beta " + str(release_of(ENGINE)))


def cmd_import(args):
    dump = os.path.abspath(args.dump)
    if not os.path.isfile(os.path.join(dump, "quakedef.h")):
        sys.exit(dump + " does not look like a Zircon source dump")
    rel = release_of(dump)
    git("checkout", "-q", "upstream")
    replace_worktree(dump)
    git("add", "-A", "-f")
    git("commit", "-q", "-m", "Zircon Beta {0} (upstream dump {1})".format(rel, os.path.basename(dump)))
    print("imported Beta {0} onto upstream: {1}".format(rel, git("log", "--oneline", "-1")))
    print("next: python tools/engine_upgrade.py merge --auto-upstream")


def cmd_merge(args):
    git("checkout", "-q", "android")
    subprocess.run(["git", "-C", WORKSPACE, "merge", "--no-commit", "--no-ff", "upstream"],
                   text=True, capture_output=True)
    conflicts = [f for f in git("diff", "--name-only", "--diff-filter=U").splitlines() if f]
    if not conflicts:
        git("commit", "-q", "-m", "Merge upstream Zircon release")
        print("merged with no conflicts: " + git("log", "--oneline", "-1"))
        return
    print("{0} conflict(s):".format(len(conflicts)))
    handled = []
    for f in conflicts:
        base = os.path.basename(f)
        gone = subprocess.run(["git", "-C", WORKSPACE, "cat-file", "-e", "upstream:" + f],
                              capture_output=True).returncode != 0
        if args.auto_upstream and (gone or base in PREFER_UPSTREAM):
            if gone:
                git("rm", "-q", "--", f)
                print("  removed (upstream dropped it): " + f)
            else:
                git("checkout", "--theirs", "--", f)
                git("add", "--", f)
                print("  took upstream: " + f)
            handled.append(f)
        else:
            print("  MANUAL: " + f)
    left = [f for f in conflicts if f not in handled]
    if left:
        print("\nResolve the files above by hand, keeping BOTH sides: upstream's new code")
        print("plus our Android hunks (search for " + MARKERS + ").")
        print("Then: git -C engine_upgrade add <files> && git -C engine_upgrade commit")
    else:
        git("commit", "-q", "-m", "Merge upstream Zircon release (Steam/net conflicts taken from upstream)")
        print("\nmerged: " + git("log", "--oneline", "-1"))
    print("\nthen: python tools/check_android_patches.py " + WORKSPACE)


def cmd_export(args):
    git("checkout", "-q", "android")
    if os.path.exists(ENGINE):
        backup = os.path.join(PROJECT, "engine_source_beta{0}".format(release_of(ENGINE)))
        if os.path.exists(backup):
            shutil.rmtree(backup)
        shutil.move(ENGINE, backup)
        print("previous engine kept at " + backup)
    os.makedirs(ENGINE, exist_ok=True)
    for entry in os.listdir(WORKSPACE):
        if entry == ".git":
            continue
        src = os.path.join(WORKSPACE, entry)
        dst = os.path.join(ENGINE, entry)
        if os.path.isdir(src):
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)
    print("engine_source is now Beta " + str(release_of(ENGINE)))
    print("next: python tools/check_android_patches.py, then build and test on device")


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    imp = sub.add_parser("import")
    imp.add_argument("dump")
    imp.set_defaults(func=cmd_import)
    mrg = sub.add_parser("merge")
    mrg.add_argument("--auto-upstream", action="store_true",
                     help="resolve known Steam/net conflicts to upstream")
    mrg.set_defaults(func=cmd_merge)
    sub.add_parser("export").set_defaults(func=cmd_export)
    args = p.parse_args()
    if not os.path.isdir(os.path.join(WORKSPACE, ".git")):
        sys.exit("no upgrade workspace at " + WORKSPACE + " (see ENGINE_UPGRADE.md)")
    return args.func(args) or 0


if __name__ == "__main__":
    sys.exit(main())
