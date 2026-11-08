"""Compare current COMMAND source modules with the retained exact build."""
from pathlib import Path
import hashlib
import json
import re
from command_style_changes import apply_changes

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm2-t3-command-repeat-build.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
assert build['target_match']
command = (stage / 'COMMAND.COM').read_bytes()
assert len(command) == build['output_bytes'] and sha(command) == build['output_sha256']
names = re.findall(r'(?i)\b(\w+)\.obj\b', (root / 'cmd/command/command.lnk').read_text())
assert [x.lower() for x in names] == [x['name'].lower() for x in build['objects']]
modules = []
for unit in build['objects']:
    name = unit['name']
    source = (root / 'cmd/command' / (name + '.asm')).read_bytes()
    retained = (stage / (name + '.asm')).read_bytes()
    assert source == apply_changes(name, retained), name
    assert sha((stage / (name + '.obj')).read_bytes()) == unit['sha256'], name
    modules.append({'name': name, 'source_sha256': sha(source), 'retained_source_sha256': sha(retained),
                    'source_status': 'identical' if source == retained else 'known comment-only changes',
                    'object_sha256': unit['sha256']})
assets = []
for local, staged in [('cmd/command/command.lnk', 'command.lnk'),
                      ('cmd/command/command.skl', 'command.skl'),
                      ('messages/usa-ms.msg', 'usa-ms.msg'),
                      ('extras/research/messages/command/usa-ms-0419.idx', 'usa-ms.idx')]:
    data = (root / local).read_bytes()
    assert data == (stage / staged).read_bytes(), local
    assets.append({'path': local, 'sha256': sha(data)})
report = {'stage': str(stage), 'command_sha256': sha(command), 'modules': modules, 'assets': assets,
          'scope': 'Current 34 linked module sources match retained exact-build copies except six documented comment-only changes in TCODE and INIT; four staged assets are identical. Shared includes were read in place and were not snapshotted. No fresh assembly after the style changes.'}
(evidence / 'm3-command-local-source-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'modules': len(modules), 'assets': len(assets), 'stage': str(stage)}, indent=2))
