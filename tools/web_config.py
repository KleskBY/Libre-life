"""Shared runtime defaults for both web package builders."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def web_config(game='librelife', lite=False):
    payload = (ROOT / 'web' / 'web.cfg').read_bytes()
    if lite:
        payload += b'\nr_glsl_offsetmapping 0\n'
    if game == 'qualker':
        payload += b'\n' + (ROOT / 'web' / 'qualker' / 'web.cfg').read_bytes()
    return payload


def clean_aliases(payload):
    commands = set(re.findall(rb'registercommand\("([^"]+)"\)',
                             (ROOT / 'src' / 'clientqc' / 'main.qc').read_bytes()))
    lines = []
    for line in payload.splitlines(keepends=True):
        match = re.match(rb'\s*alias\s+"?([^"\s]+)', line, re.I)
        if not match or match[1].lower() not in commands:
            lines.append(line)
    return b''.join(lines)
