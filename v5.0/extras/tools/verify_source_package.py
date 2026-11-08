"""Verify a retained source-only candidate package against its manifest."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
report = json.loads((evidence / 'm6-source-package-candidate.json').read_text())
stage = Path(report['stage'])
assert stage.parent.resolve() == (root / 'extras/build').resolve()
manifest = report['files']
sha = lambda data: hashlib.sha256(data).hexdigest()
assert len({x['path'].lower() for x in manifest}) == len(manifest)
for entry in manifest:
    relative = Path(entry['path'])
    assert not relative.is_absolute() and '..' not in relative.parts
    source = root / relative
    packaged = stage / relative
    data = packaged.read_bytes()
    assert len(data) == entry['bytes'] and sha(data) == entry['sha256'], relative
    assert data == source.read_bytes(), relative
    assert relative.suffix.lower() not in {'.sys', '.com', '.exe', '.exc', '.obj', '.map'}
expected = {x['path'].lower() for x in manifest} | {'readme.md', 'source-manifest.json'}
actual = {p.relative_to(stage).as_posix().lower() for p in stage.rglob('*') if p.is_file()}
assert actual == expected, (actual - expected, expected - actual)
for directory, link in [('kernel-source/dos', 'msdos.lnk'), ('cmd/command', 'command.lnk')]:
    base = stage / directory
    names = re.findall(r'(?i)\b(\w+)\.obj\b', (base / link).read_text(errors='replace'))
    assert names and all((base / (name + '.asm')).is_file() for name in names)
names = re.findall(r'[A-Za-z_][A-Za-z_0-9]*', (stage / 'bios/msbio.lnk').read_text().split(',')[0])
assert len(names) == 15 and all((stage / 'bios' / (name + '.asm')).is_file() for name in names)
assert json.loads((stage / 'SOURCE-MANIFEST.json').read_text()) == report
print(json.dumps({'stage': str(stage), 'files_verified': len(manifest),
                  'system_binaries_included': False, 'manifest_exact': True,
                  'scope': 'Static package/source identity and link-list membership only; no fresh build, runtime or rights determination.'}, indent=2))
