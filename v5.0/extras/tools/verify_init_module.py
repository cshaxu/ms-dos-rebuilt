"""Compare the complete reconstructed INIT code contribution to target DOS 5."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-init-z-build.json').read_text())['stage'])
mask = set()
end = None
for line in (stage/'init.lst').read_text(encoding='latin1').splitlines():
    m = re.match(r' ([0-9A-F]{4})  (.*?)\\(.*)', line)
    if not m:
        continue
    pos = int(m[1], 16)
    if re.match(r'\s*INIT\s+ENDS', m[3], re.I):
        end = pos
    previous = []
    for token in m[2].split():
        token = token.rstrip(':/')
        if token in ('E', 'R'):
            mask.update(previous)
        elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}', token):
            previous = list(range(pos, pos+len(token)//2))
            pos += len(token)//2
assert end == 0x8e5, end
with tempfile.TemporaryDirectory(prefix='dos5-init-module-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
start = 0x1460
differences = [i for i in range(end) if candidate[start+i] != target[start+i]]
unmasked = [i for i in differences if i not in mask]
assert not unmasked, unmasked
assert candidate[0x1d50:0x1d58] == target[0x1d50:0x1d58] == b'/DEV/CON'
# Exact seven-switch descriptor header and pointers precede COMMAND_FILE.
assert candidate[0x1dd6:0x1def] == target[0x1dd6:0x1def]
for path in ['init.asm', 'uinit.asm']:
    assert not re.search(r'^\s*(?:PUBLIC|extrn).*command_z_syn', (root/'cmd/command'/path).read_text(), re.I|re.M)
out = {'start': start, 'code_bytes': end, 'different_bytes': differences,
       'unmasked_differences': unmasked, 'seven_switch_descriptor_exact': True,
       'limitation': 'Complete INIT code layout verified with annotated address operands excluded; full image identity and guest behavior remain unverified.'}
(root/'extras/docs/etc/evidence/m2-t3-init-module-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps({'code_bytes': end, 'different_bytes': len(differences), 'unmasked_differences': unmasked}, indent=2))
