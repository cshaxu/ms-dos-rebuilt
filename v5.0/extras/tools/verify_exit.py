"""Check permanent COMMAND EXIT recycling against target code and MAP."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-exit-build.json').read_text())['stage'])
symbols = {}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m = re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$', line)
    if m:
        symbols[m[3].lower()] = int(m[1], 16)*16+int(m[2], 16)-256
with tempfile.TemporaryDirectory(prefix='dos5-exit-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
start, target_start = symbols['$exit'], 0x4439
mask = {3, 4, 7, 8, 14, 15, 20, 21}
assert all(candidate[start+i] == target[target_start+i] for i in range(22) if i not in mask)
for offset, name, expected in [(3, 'resseg', 0x8d77), (7, 'permcom', 0x2ab), (14, 'singlecom', 0x2ac)]:
    value = int.from_bytes(candidate[start+offset:start+offset+2], 'little')
    if name == 'resseg':
        # Transient operands use their group-relative MAP offset.
        assert value == symbols[name]-(symbols['tcommand']-0x104)
    else:
        assert value == symbols[name]+256
    assert int.from_bytes(target[target_start+offset:target_start+offset+2], 'little') == expected
assert candidate[start+19] == target[target_start+19] == 0xe9
assert start+22+int.from_bytes(candidate[start+20:start+22], 'little', signed=True) == symbols['tcommand']
assert target_start+22+int.from_bytes(target[target_start+20:target_start+22], 'little', signed=True) == 0x2324
out = {'candidate_exit': start, 'target_exit': target_start, 'length': 22,
       'operand_symbols_verified': True, 'recycle_destination_verified': True,
       'limitation': 'Bounded static control-flow verification; guest execution and full identity remain unproven.'}
(root/'extras/docs/etc/evidence/m2-t3-exit-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
