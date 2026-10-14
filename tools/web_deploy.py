"""Prepare an offline deployment archive from the combined web demo build."""
from __future__ import annotations

import gzip
import hashlib
import json
import os
from pathlib import Path
import shutil
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / 'web'
BUILD = ROOT / 'dist' / 'web'
TEMPLATES = ROOT / 'web' / 'deploy'


def prepare() -> None:
    report = json.loads((BUILD / 'build.json').read_text())
    if report['profile'] != 'demos':
        raise ValueError('First run: python tools/web_build.py --profile demos')
    if hashlib.sha256((BUILD / report['package']).read_bytes()).hexdigest() != report['packageSha256']:
        raise ValueError('Game package hash differs from build.json; rebuild first')
    archive_path = ROOT / 'dist' / 'librelife-web-demos.tar.gz'
    with tempfile.TemporaryDirectory(prefix='web-deploy-', dir=ROOT / 'dist') as scratch:
        stage = Path(scratch)
        public = stage / 'public'
        public.mkdir()
        names = ['index.html', 'launcher.js', 'touch.js', 'launcher.css', 'default.fmf',
                 'build.json', report['package'], 'engine/engine-lock.json',
                 'assets/logo.webp', 'assets/oswald-latin.woff2',
                 'assets/share-tech-mono-latin.woff2']
        names += ['engine/' + name for name in report['engine']['files']]
        for name in names:
            source = BUILD / name
            target = public / name
            target.parent.mkdir(parents=True, exist_ok=True)
            if name.startswith('engine/') and source.name in report['engine']['files']:
                if hashlib.sha256(source.read_bytes()).hexdigest() != report['engine']['files'][source.name]:
                    raise ValueError(f'Engine hash mismatch: {name}')
            shutil.copy2(source, target)
        compressed = 0
        for name in names:
            if Path(name).suffix not in {'.pk3', '.wasm', '.js', '.css', '.html', '.json', '.fmf'}:
                continue
            source = public / name
            target = source.with_name(source.name + '.gz')
            with source.open('rb') as incoming, target.open('wb') as outgoing:
                with gzip.GzipFile(filename='', mode='wb', fileobj=outgoing, mtime=0, compresslevel=9) as stream:
                    shutil.copyfileobj(incoming, stream)
            os.utime(target, (source.stat().st_atime, source.stat().st_mtime))
            compressed += target.stat().st_size
        (public / 'licenses').mkdir()
        for name in ['gpl-2.0.txt', 'gpl-3.0.txt', 'DejaVu-Fonts-License.txt']:
            shutil.copy2(ROOT / 'licenses' / name, public / 'licenses' / name)
        shutil.copy2(WEB / 'assets' / 'OFL-Oswald.txt', public / 'licenses' / 'OFL-Oswald.txt')
        shutil.copy2(WEB / 'assets' / 'OFL-ShareTechMono.txt', public / 'licenses' / 'OFL-ShareTechMono.txt')
        shutil.copy2(TEMPLATES / 'NOTICES.txt', public / 'NOTICES.txt')
        for name in ['nginx.conf', 'DEPLOY.md', 'apache.conf', 'APACHE.md']:
            shutil.copy2(TEMPLATES / name, stage / name)
        info = dict(profile='demos', maps=report['maps'],
                    compressedWebBytes=compressed,
                    publicDiskBytes=sum(p.stat().st_size for p in public.rglob('*') if p.is_file()),
                    gamePackageSha256=report['packageSha256'])
        (stage / 'package-info.json').write_text(json.dumps(info, indent=2) + '\n', encoding='utf-8', newline='\n')
        files = sorted(p for p in stage.rglob('*') if p.is_file())
        (stage / 'SHA256SUMS').write_text(''.join(
            f'{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(stage).as_posix()}\n'
            for p in files), encoding='utf-8', newline='\n')
        with tarfile.open(archive_path.with_suffix('.tmp'), 'w:gz', compresslevel=6) as archive:
            for source in sorted(stage.rglob('*')):
                entry = archive.gettarinfo(str(source), arcname=source.relative_to(stage).as_posix())
                entry.uid = entry.gid = 0
                entry.uname = entry.gname = ''
                entry.mode = 0o755 if source.is_dir() else 0o644
                if source.is_file():
                    with source.open('rb') as incoming:
                        archive.addfile(entry, incoming)
                else:
                    archive.addfile(entry)
        archive_path.with_suffix('.tmp').replace(archive_path)
    digest = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    archive_path.with_name(archive_path.name + '.sha256').write_text(f'{digest}  {archive_path.name}\n', newline='\n')
    print(f'Created {archive_path} ({archive_path.stat().st_size / 1048576:.1f} MiB)')
    print(f'Compressed web files: {compressed / 1048576:.1f} MiB; public disk: {info["publicDiskBytes"] / 1048576:.1f} MiB')


if __name__ == '__main__':
    prepare()
