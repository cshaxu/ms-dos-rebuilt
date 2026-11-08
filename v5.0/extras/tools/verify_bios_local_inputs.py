"""Check local BIOS source inputs against the retained exact-build stage."""
from pathlib import Path
import hashlib
import json
from sysimes_source import active_lines

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm5-bios-singleconfig-probe.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
modules = []
for unit in build['units']:
    name = unit['name'] + '.asm'
    local = (root / 'bios' / name).read_bytes()
    if name in {'sysinit1.asm', 'sysinit2.asm', 'sysconf.asm'}:
        assert local.count(b'MULTI_CONFIG equ 1') == 1, name
        local = local.replace(b'MULTI_CONFIG equ 1', b';MULTI_CONFIG equ 1')
    reference = (stage / 'src' / name).read_bytes()
    assert sha(reference) == build['inputs']['src\\' + name], name
    if name in {'sysimes.asm', 'msend.asm'}:
        assert active_lines(local) == active_lines(reference), name
    else:
        assert local == reference, name
    modules.append({'name': name, 'current_sha256': sha(local), 'staged_sha256': sha(reference),
                    'comparison': 'literal active statements' if name in {'sysimes.asm', 'msend.asm'} else 'identical'})

snapshot = json.loads((evidence / 'm5-bios-include-snapshot.json').read_text())
assert snapshot['stage'] == str(stage)
for item in snapshot['files']:
    data = (root / item['name']).read_bytes()
    assert sha(data) == item['sha256'], item['name']
    assert data == Path(item['source']).read_bytes(), item['name']
for local, reference in [('bios/copyrigh.inc', 'inc/copyrigh.inc'),
                         ('inc/versiona.inc', 'inc/versiona.inc'),
                         ('bios/msbio.cl3', 'msbio.cl3')]:
    assert (root / local).read_bytes() == (stage / reference).read_bytes(), local
assets = json.loads((evidence / 'm5-bios-local-build-inputs.json').read_text())
for item in assets['files']:
    data = Path(item['destination']).read_bytes()
    assert sha(data) == item['sha256'], item['name']
    assert sha(data) == build['inputs'][item['name']], item['name']

loader_report = json.loads((evidence / 'm5-msload-candidate-build.json').read_text())
loader_stage = Path(loader_report['stage'])
for name in ('msload.asm', 'msbio.cl1'):
    data = (root / 'bios' / name).read_bytes()
    assert sha(data) == loader_report['inputs'][name], name
    assert data == (loader_stage / name).read_bytes(), name
# Audit includes recursively in both active and inactive source branches.
import re
queue = [loader_stage / 'msload.asm']
seen = set()
loader_includes = []
while queue:
    path = queue.pop()
    if str(path).lower() in seen:
        continue
    seen.add(str(path).lower())
    for line in path.read_text(encoding='latin1').splitlines():
        match = re.match(r'^\s*include\s+([^;\s]+)', line, re.I)
        if not match:
            continue
        name = match.group(1).strip("\"' <>")
        original = next((x for x in (loader_stage / name, loader_stage / 'inc' / name) if x.is_file()), None)
        assert original is not None, name
        if name.lower() == 'msbio.cl1':
            continue
        local = root / 'inc/versiona.inc' if name.lower() == 'versiona.inc' else root / 'bios/inc' / name
        assert local.read_bytes() == original.read_bytes(), name
        loader_includes.append(name)
        queue.append(original)

report = {'stage': str(stage), 'modules': modules, 'include_count': len(snapshot['files']), 'build_assets': len(assets['files']),
          'loader_static_includes': sorted(set(loader_includes), key=str.lower),
          'scope': 'Static comparison to retained prior exact build inputs; SYSIMES and MSEND differ but have matching literal active statements. No new build, dynamic include completeness, original-image or runtime claim.'}
(evidence / 'm5-bios-local-source-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'verified_modules': len(modules), 'verified_includes': len(snapshot['files']), 'verified_assets': len(assets['files']),
                  'verified_loader_includes': len(set(loader_includes)), 'stage': str(stage)}, indent=2))
