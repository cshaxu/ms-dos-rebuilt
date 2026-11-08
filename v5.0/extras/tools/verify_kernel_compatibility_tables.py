"""Check selected compatibility data against references and pinned kernel."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos')
DOS6 = ROOT.parent / 'v6.0/dos'
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
sha = lambda data: hashlib.sha256(data).hexdigest()
candidate = ROOT / 'kernel-source/dos'
package = Path(json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())['stage'])
exepatch = (candidate / 'exepatch.asm').read_bytes()
assert exepatch == (NT / 'exepatch.asm').read_bytes()
assert exepatch == (package / 'kernel-source/dos/exepatch.asm').read_bytes()
assert b'CPScanPattern' in exepatch and b'RScanPattern2' in exepatch

def table(path, name):
    text = path.read_text(encoding='latin1')
    match = re.search(r'^' + re.escape(name) + r'\s+label\s+byte\b(.*?)^\s*endif\b', text, re.I | re.M | re.S)
    assert match
    alternate = re.split(r'^\s*else\s*$', match[1], maxsplit=1, flags=re.I | re.M)
    assert len(alternate) == 2 and re.search(r'^\s*dw\s+128\b', alternate[1], re.I | re.M)
    values = []
    for line in alternate[1].splitlines():
        m = re.match(r'^\s*db\s+([\d,\s]+)', line, re.I)
        if m: values.extend(int(value.strip()) for value in m[1].split(',') if value.strip())
    assert len(values) == 128 and all(0 <= value <= 255 for value in values)
    return b'\x80\x00' + bytes(values)

kernel = (ROOT / 'extras/build/target-kernel-inspect.bin').read_bytes()
assert sha(kernel) == '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
source = candidate / 'dostab.asm'
assert source.read_bytes() == (package / 'kernel-source/dos/dostab.asm').read_bytes()
records = []
for name, offset in [('UCASE_TAB', 35165), ('FILE_UCASE_TAB', 35295)]:
    actual = table(source, name)
    nt = table(NT / 'dostab.asm', name)
    dos6 = table(DOS6 / 'dostab.asm', name)
    assert kernel[offset:offset + len(actual)] == actual
    assert actual == dos6
    differences = [{'index': i - 2, 'nt': nt[i], 'candidate': actual[i]}
                   for i in range(2, len(actual)) if nt[i] != actual[i]]
    records.append({'name': name, 'target_offset': offset, 'bytes': len(actual),
                    'candidate_sha256': sha(actual), 'matches_dos6': True,
                    'opennt_value_differences': differences})
assert records[0]['opennt_value_differences'] == [{'index': 2, 'nt': 144, 'candidate': 69}]
assert records[1]['opennt_value_differences'] == []
report = {'exepatch_sha256': sha(exepatch), 'exepatch_equals_opennt': True,
          'dostab_sha256': sha(source.read_bytes()), 'target_kernel_sha256': sha(kernel),
          'tables': records,
          'scope': 'OpenNT source identity for EXEPATCH and two 130-byte non-DBCS tables against pinned extracted MSDOS.SYS; no whole-module provenance or runtime behavior claim.'}
(EVIDENCE / 'm6-kernel-compatibility-table-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
