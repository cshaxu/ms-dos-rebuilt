"""Check DOS executable-search path and recovered transient data spacing."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-execpath-layout-build.json').read_text())['stage'])
symbols, relative = {}, {}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m = re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$', line)
    if m:
        symbols[m[3].lower()] = int(m[1], 16)*16+int(m[2], 16)-256
        relative[m[3].lower()] = int(m[2], 16)
with tempfile.TemporaryDirectory(prefix='dos5-execpath-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
pattern = bytes.fromhex('c605002e803e')
positions = [i-3 for i in range(len(candidate)) if candidate.startswith(pattern, i)]
assert len(positions) == 1, positions
start = positions[0]
mask = {1, 2, 9, 10, 15, 16, 27, 28}
assert all(candidate[start+i] == target[0x4bf5+i] for i in range(29) if i not in mask)
assert int.from_bytes(candidate[start+1:start+3], 'little') == relative['execpath']
assert int.from_bytes(candidate[start+9:start+11], 'little') == relative['rom_call']
assert start+17+int.from_bytes(candidate[start+15:start+17], 'little', signed=True) == symbols['path_search']
assert 0x4bf5+17+int.from_bytes(target[0x4c04:0x4c06], 'little', signed=True) == 0x54f1
# Target EXECPATH 8C9F -> RESSEG 8D77: 131-byte pathname + 83-byte
# redirection pathname + 2-byte resident-call offset. No NT cmdinfo intervenes.
assert relative['resseg']-relative['execpath'] == 0x8d77-0x8c9f == 216
assert relative['re_instr']-relative['execpath'] == 131
assert relative['headcall']-relative['re_instr'] == 83
search = symbols['path_search']
assert candidate[search:search+7] == target[0x54f1:0x54f8]
bound = bytes.fromhex('bb8000')
ci = candidate.find(bound, search, search+60)
ti = target.find(bound, 0x54f1, 0x54f1+60)
assert ci-search == ti-0x54f1 and ci >= search
assert not any(name.startswith('scs_') or name in {'execpath_size', 'execext_type', 'execpath_seg', 'execpath_off'} for name in symbols)
out = {'candidate_search_entry': start, 'target_search_entry': 0x4bf5,
       'checked_prefix_bytes': 29, 'data_spacing_bytes': 216,
       'path_search_capacity': 128, 'execpath_storage': 131,
       'limitation': 'Bounded opcode/data-spacing checks; absolute layout and full target identity remain unfinished.'}
(root/'extras/docs/etc/evidence/m2-t3-execpath-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
