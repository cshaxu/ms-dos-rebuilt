"""Compare literal COMMAND include search in workspace and packaged snapshot."""
from pathlib import Path
import hashlib
import json
import re
from command_source_snapshot import inventory

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
package = Path(json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())['stage'])
baseline = inventory(ROOT)
assert inventory(package) == baseline
dirs = ('cmd/command', 'inc', 'inc/ntvdm', 'messages')
expression = re.compile(r'^\s*(?:%\s*)?include\s+([^\s;]+)', re.I)

def resolve(root, name):
    for directory in dirs:
        path = root / directory / name
        if path.is_file():
            data = path.read_bytes()
            return {'path': path.relative_to(root).as_posix().lower(), 'sha256': hashlib.sha256(data).hexdigest()}
    return None

names = {}
dynamic = []
for relative in baseline:
    path = ROOT / relative
    if path.suffix.lower() not in ('.asm', '.inc', '.equ'):
        continue
    for line_number, line in enumerate(path.read_text(encoding='latin1').splitlines(), 1):
        match = expression.match(line)
        if not match:
            continue
        name = match[1].strip('<>"\'')
        location = f'{relative}:{line_number}'
        if any(char in name for char in '&%') or '/' in name or '\\' in name:
            dynamic.append({'operand': name, 'location': location})
        else:
            names.setdefault(name.lower(), []).append(location)
records = []
for name, locations in sorted(names.items()):
    old = resolve(ROOT, name)
    new = resolve(package, name)
    records.append({'name': name, 'occurrences': len(locations), 'workspace': old,
                    'package': new, 'equal': old == new, 'locations': locations})
differences = [item for item in records if not item['equal']]
unresolved = [item['name'] for item in records if item['workspace'] is None]
report = {'package': str(package), 'literal_names': len(records), 'different': differences,
          'unresolved': unresolved, 'dynamic_operands': dynamic, 'records': records,
          'scope': 'Lexical literal lookup through the four explicit include directories only; does not model MASM conditionals, macro expansion, generated files, current working-directory precedence, or actual assembly.'}
(EVIDENCE / 'm6-command-include-search-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({key: report[key] for key in ('literal_names', 'different', 'unresolved', 'dynamic_operands', 'scope')}, indent=2))
if differences:
    raise SystemExit('literal include selection differs')
