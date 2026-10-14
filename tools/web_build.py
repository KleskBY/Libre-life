"""Build a local FTE WebAssembly distribution from user-supplied game assets."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import urllib.request
import zipfile
from web_font import bake_font
from web_config import clean_aliases, web_config
from web_bsp import normalize_bsp

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / 'web'
OUTPUT = ROOT / 'dist' / 'web'
PROFILES = {
    'demos': ('', ('start', 'e1m', 'b_', 't0a0', 'hldemo')),
    'hazard': ('t0a0', ('t0a0',)),
    'uplink': ('hldemo1', ('hldemo',)),
    'halflife': ('c0a0', ()),
}
DEMO_MAPS = {'start', *(f'e1m{i}' for i in range(1, 9)),
             'hldemo1', 'hldemo2', 'hldemo3',
             't0a0', 't0a0a', 't0a0b', 't0a0b1', 't0a0b2', 't0a0c', 't0a0d'}
QUAKE_BRUSH_MODELS = {'b_batt0', 'b_batt1', 'b_bh10', 'b_bh100', 'b_bh25',
                      'b_explob', 'b_nail0', 'b_nail1', 'b_rock0', 'b_rock1',
                      'b_shell0', 'b_shell1'}
ASSET_DIRS = {'gfx', 'glsl', 'maps', 'models', 'particles', 'progs',
              'scripts', 'sound', 'sprites', 'textures', 'cubemaps'}
EXTENSIONS = {'.bsp', '.ent', '.lit', '.lux', '.iqm', '.mdl', '.md3', '.spr',
              '.framegroups', '.skin', '.bodyinfo', '.splitbone', '.png', '.jpg',
              '.jpeg', '.tga', '.pcx', '.lmp', '.ttf', '.wav', '.ogg', '.txt',
              '.shader', '.glsl', '.cfg', '.wad'}
ROOT_FILES = {'progs.dat', 'csprogs.dat', 'menu.dat', 'default.cfg', 'alias.cfg',
              'skill.cfg', 'effectinfo.txt', 'titles.txt'}


def eligible(name: str, prefixes: tuple[str, ...]) -> bool:
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or '\\' in name:
        return False
    if name in ROOT_FILES or (len(path.parts) == 1 and path.suffix == '.wad'):
        return True
    if path.parts[0] not in ASSET_DIRS or path.suffix.lower() not in EXTENSIONS:
        return False
    if path.parts[0] == 'maps':
        if prefixes == PROFILES['demos'][1]:
            return path.stem in DEMO_MAPS | QUAKE_BRUSH_MODELS
        return not prefixes or path.stem.startswith(prefixes)
    return True


def engine_files(cache: Path) -> dict:
    lock = json.loads((WEB / 'engine-lock.json').read_text())
    target = OUTPUT / 'engine'
    target.mkdir(parents=True, exist_ok=True)
    cache.mkdir(parents=True, exist_ok=True)
    for name, digest in lock['files'].items():
        source = cache / name
        if not source.exists():
            print(f'Downloading {name}...', flush=True)
            with urllib.request.urlopen(lock['base_url'] + name, timeout=90) as response:
                payload = response.read()
            if hashlib.sha256(payload).hexdigest() != digest:
                raise ValueError(f'{name}: upstream changed; obtain the pinned engine pair or review and update web/engine-lock.json')
            source.write_bytes(payload)
        if hashlib.sha256(source.read_bytes()).hexdigest() != digest:
            raise ValueError(f'{source}: SHA-256 mismatch against web/engine-lock.json')
        shutil.copy2(source, target / name)
    shutil.copy2(WEB / 'engine-lock.json', target / 'engine-lock.json')
    return lock


def build(args: argparse.Namespace) -> None:
    data = args.data.resolve()
    start_map, prefixes = PROFILES[args.profile]
    if not args.skip_compile:
        compiler = args.compiler.resolve()
        if not compiler.is_file():
            raise FileNotFoundError(f'FTEQCC not found: {compiler}')
        result = subprocess.run([str(compiler)], cwd=ROOT / 'src',
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        print(result.stdout)
        if result.returncode or result.stdout.count('Done. 0 warnings') != 3:
            raise RuntimeError('QuakeC compilation did not finish with three warning-free modules')
    for name in ROOT_FILES:
        if name.endswith('.dat') and not (data / name).is_file():
            raise FileNotFoundError(f'Missing {data / name}; compile/copy the three game modules first')

    OUTPUT.mkdir(parents=True, exist_ok=True)
    lock = engine_files(args.engine_cache.resolve())
    archives = ['quake_shareware.pk3', 'halflife_maps.pk3', 'halflife_wads.pk3', 'halflife_sound.pk3']
    if args.profile in {'uplink', 'demos'}:
        archives += ['uplink_maps.pk3', 'uplink_sound.pk3', 'uplink_sprites.pk3']
    # Merge known base packages, then loose files, matching loose-file overrides.
    entries: dict[str, tuple[Path, str | None]] = {}
    for name in archives:
        source = data / name
        if source.exists():
            with zipfile.ZipFile(source) as archive:
                for entry in archive.infolist():
                    quake_dirs = {'progs', 'sound', 'gfx', 'maps'} if args.profile == 'demos' else {'progs', 'sound', 'gfx'}
                    if name == 'quake_shareware.pk3' and PurePosixPath(entry.filename).parts[0] not in quake_dirs:
                        continue
                    if not entry.is_dir() and eligible(entry.filename, prefixes):
                        entries[entry.filename] = (source, entry.filename)
    for source in sorted(data.rglob('*')):
        if source.is_file():
            name = source.relative_to(data).as_posix()
            if eligible(name, prefixes):
                entries[name] = (source, None)
    maps = sorted(PurePosixPath(name).stem for name in entries if name.startswith('maps/') and name.endswith('.bsp') and PurePosixPath(name).stem not in QUAKE_BRUSH_MODELS)
    if args.profile == 'demos' and (missing := DEMO_MAPS - set(maps)):
        raise FileNotFoundError(f'Missing demo maps: {", ".join(sorted(missing))}')
    if start_map and start_map not in maps:
        raise FileNotFoundError(f'{start_map}.bsp missing from {data}; provide the selected campaign assets')
    for name in ['autoexec.cfg', 'web.cfg']:
        entries[name] = (WEB / name, None)
    if 'gfx/font.ttf' not in entries:
        raise FileNotFoundError(f'Missing {data / "gfx/font.ttf"}; the web UI font needs its source TTF')
    font_source, font_member = entries['gfx/font.ttf']
    if font_member is None:
        font_bytes = font_source.read_bytes()
    else:
        with zipfile.ZipFile(font_source) as font_archive:
            font_bytes = font_archive.read(font_member)
    generated = bake_font(font_bytes)
    package = OUTPUT / 'librelife.pk3'
    handles: dict[Path, zipfile.ZipFile] = {}
    bsp_fixes = {}
    try:
        with zipfile.ZipFile(package.with_suffix('.tmp'), 'w', compression=zipfile.ZIP_STORED) as archive:
            for name, (source, member) in sorted(entries.items()):
                if member is None:
                    payload = source.read_bytes()
                else:
                    if source not in handles:
                        handles[source] = zipfile.ZipFile(source)
                    payload = handles[source].read(member)
                if name == 'alias.cfg':
                    payload = clean_aliases(payload)
                elif name == 'web.cfg':
                    payload = web_config()
                if name.lower().endswith('.bsp'):
                    payload, fixed = normalize_bsp(payload)
                    if fixed:
                        bsp_fixes[name] = fixed
                info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
                archive.writestr(info, payload)
            for name, payload in generated.items():
                archive.writestr(zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0)), payload)
        package.with_suffix('.tmp').replace(package)
    finally:
        for handle in handles.values():
            handle.close()
    for name in ['index.html', 'launcher.js', 'touch.js', 'launcher.css', 'default.fmf',
                 'assets/logo.webp', 'assets/oswald-latin.woff2',
                 'assets/share-tech-mono-latin.woff2']:
        target = OUTPUT / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(WEB / name, target)
    report = dict(profile=args.profile, startMap=start_map, maps=maps,
                  campaigns=[dict(map=level, label=label) for level, label in
                             [('start', 'Quake 1 Shareware' if 'e2m1' not in maps else 'Quake 1'),
                              ('hldemo1', 'Half-Life: Uplink'), ('t0a0', 'Hazard Course'),
                              ('c0a0', 'Half-Life')] if level in maps],
                  package=package.name, packageBytes=package.stat().st_size,
                  packageSha256=hashlib.sha256(package.read_bytes()).hexdigest(),
                  bspEmptyLeafAreasNormalized=bsp_fixes,
                  fileCount=len(entries) + len(generated), engine=lock, localAssetsOnly=True)
    (OUTPUT / 'build.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'Built {OUTPUT}: {report["fileCount"]} files, {len(maps)} maps, {package.stat().st_size / 1048576:.1f} MiB')
    print('Local preview: python tools/web_serve.py')


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile', choices=PROFILES, default='hazard')
    parser.add_argument('--data', type=Path, default=ROOT / 'data')
    parser.add_argument('--compiler', type=Path, default=ROOT / 'src' / 'fteqcc64.exe')
    parser.add_argument('--skip-compile', action='store_true', help='Package existing .dat files')
    parser.add_argument('--engine-cache', type=Path, default=ROOT / '.web-cache')
    args = parser.parse_args()
    try:
        build(args)
    except (OSError, ValueError, RuntimeError, zipfile.BadZipFile) as error:
        parser.exit(1, f'Web build failed: {error}\n')


if __name__ == '__main__':
    main()
