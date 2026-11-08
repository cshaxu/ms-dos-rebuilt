"""Inventory linked kernel modules against same-named reference files."""
from pathlib import Path
import collections
import difflib
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos')
DOS6 = ROOT.parent / 'v6.0/dos'
source = ROOT / 'kernel-source/dos'
build = json.loads((EVIDENCE / 'm4-t5-consolidated-kernel-build.json').read_text())
package = Path(json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())['stage'])
stage = Path(build['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
names = re.findall(r'(?i)\b(\w+)\.obj\b', (source / 'msdos.lnk').read_text())
assert len(names) == 55 and len(set(x.lower() for x in names)) == 55
assert set(x.lower() for x in names) == {x.lower() for x in build['objects']}
assert build['exact'] and build['output_sha256'] == '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
assert digest((stage / 'msdos.sys').read_bytes()) == build['output_sha256']
hashes = {key.replace('\\', '/').lower(): value for key, value in build['source_snapshot'].items()}
object_hashes = {key.lower(): value for key, value in build['objects'].items()}

def compare(candidate, reference):
    if not reference.is_file():
        return {'status': 'missing'}
    other = reference.read_bytes()
    matcher = difflib.SequenceMatcher(None, other.decode('latin1').splitlines(),
                                      candidate.decode('latin1').splitlines(), autojunk=False)
    changes = collections.Counter()
    for operation, i, j, k, l in matcher.get_opcodes():
        if operation != 'equal':
            changes['reference_lines'] += j - i
            changes['candidate_lines'] += l - k
            changes['changed_blocks'] += 1
    return {'status': 'identical' if candidate == other else 'different',
            'sha256': digest(other), 'changed_blocks': changes['changed_blocks'],
            'reference_lines_in_changes': changes['reference_lines'], 'candidate_lines_in_changes': changes['candidate_lines']}

records = []
for name in names:
    path = source / (name + '.asm')
    data = path.read_bytes()
    assert digest(data) == hashes['dos/' + name.lower() + '.asm'], name
    assert data == (package / 'kernel-source/dos' / path.name).read_bytes(), name
    assert digest((stage / (name + '.obj')).read_bytes()) == object_hashes[name.lower()], name
    references = {'opennt': compare(data, NT / path.name), 'dos6': compare(data, DOS6 / path.name)}
    exact = [key for key, value in references.items() if value['status'] == 'identical']
    records.append({'module': name, 'source_sha256': digest(data), 'object_sha256': object_hashes[name.lower()],
                    'identical_references': exact, 'references': references})
counts = collections.Counter('both' if len(r['identical_references']) == 2 else
                             r['identical_references'][0] if r['identical_references'] else 'neither' for r in records)
report = {'stage': str(stage), 'package': str(package), 'kernel_sha256': build['output_sha256'],
          'summary': dict(counts), 'modules': records,
          'scope': 'Exact-byte comparison and line-diff inventory against same-named current references, not proof of historical authorship, reference ancestry, behavior, or source-to-instruction mapping.'}
(EVIDENCE / 'm6-kernel-module-reference-inventory.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'modules': len(records), 'summary': dict(counts), 'scope': report['scope']}, indent=2))
