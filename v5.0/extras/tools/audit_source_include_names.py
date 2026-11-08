"""Inventory literal INCLUDE names in the source candidate without assembling it.

This is a name inventory, not a MASM preprocessor or include-path resolver.
Inactive branches and unused files are included deliberately.
"""
from pathlib import Path
import collections
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
candidate = json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())
package = Path(candidate['stage'])
groups = {
    'bios': ('bios', 'bios/inc', 'kernel-source/inc'),
    'kernel': ('kernel-source/dos', 'kernel-source/inc'),
    'command': ('cmd/command', 'inc', 'messages'),
}
include = re.compile(r'^\s*(?:%\s*)?include\s+([^\s;]+)', re.I)
result = {}
for group, directories in groups.items():
    files = sorted({p for directory in directories for p in (package / directory).rglob('*') if p.is_file()})
    names = {p.name.lower() for p in files}
    missing = collections.defaultdict(list)
    count = 0
    for path in files:
        if path.suffix.lower() not in ('.asm', '.inc', '.equ'):
            continue
        for line_number, line in enumerate(path.read_text(errors='replace').splitlines(), 1):
            match = include.match(line)
            if not match:
                continue
            count += 1
            name = match.group(1).strip('<>"\'').replace('\\', '/').split('/')[-1].lower()
            if name not in names:
                missing[name].append(f'{path.relative_to(package).as_posix()}:{line_number}')
    result[group] = {'directives': count, 'unmatched_names': dict(sorted(missing.items()))}

generated = {}
for component, report_name in (
    ('kernel', 'm4-t5-consolidated-kernel-build.json'),
    ('bios', 'm5-bios-singleconfig-probe.json'),
    ('command', 'm2-t3-command-repeat-build.json'),
):
    report = json.loads((EVIDENCE / report_name).read_text())
    stage = Path(report['stage'])
    generated[component] = [
        {'name': p.name, 'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
        for p in sorted(stage.glob('*.cl*')) if p.is_file()
    ]

output = {
    'candidate': str(package),
    'scope': 'Literal basename inventory only: no search-order, macro expansion, conditional evaluation, assembler execution, or dependency-closure claim.',
    'groups': result,
    'retained_generated_message_files': generated,
    'interpretation': [
        'MSBIO.CL2-CL9 and MSDOS.CL1-CL4 are retained generated message files; the recipes generate resources during builds.',
        'RESTRICT.INC is inside IFDEF RESTRICTED_BUILD in MSPROC.ASM; the normal kernel recipe does not request that optional build.',
        'The ampersand names are macro operands in SYSMSG.INC, not literal file names.',
        'Groups scan all files, including unused files and inactive branches; availability of a basename does not prove correct include-path resolution.',
        'Retained generated files are evidence of earlier builds, not proof that the current snapshot can reproduce them.',
    ],
}
destination = EVIDENCE / 'm6-source-include-name-inventory.json'
destination.write_text(json.dumps(output, indent=2) + '\n', encoding='utf-8')
print(json.dumps({name: {'directives': item['directives'], 'unmatched': len(item['unmatched_names'])} for name, item in result.items()}, indent=2))
