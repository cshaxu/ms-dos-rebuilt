"""Compare the linked single-configuration CONFIG.SYS open/read entry."""
from pathlib import Path
import hashlib
import json
import re
import struct

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm5-bios-singleconfig-probe.json').read_text())
assert build['candidate'] and build['oembase'] and build['singleconfig']
stage = Path(build['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
candidate = (stage / 'msbio.bin').read_bytes()
assert digest(candidate) == build['output']['sha256']
image = (root / 'extras/build/target-io-inspect.bin').read_bytes()
assert digest(image) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target = image[0x5a6:]
map_bytes = (stage / 'msbio.map').read_bytes()
map_text = map_bytes.decode(errors='replace')
def address(name):
    rows = re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+' + re.escape(name) + r'\s*$', map_text)
    values = {int(seg, 16) * 16 + int(off, 16) for seg, off in rows}
    assert len(values) == 1, (name, values)
    return values.pop()

start, target_start, length = address('doconf'), 0x612e, 0x94
actual = bytearray(candidate[start:start + length])
expected = target[target_start:target_start + length]
assert len(actual) == len(expected) == length
fixups = []
for offset, symbol, target_address in [(0x3b, 'ParaRound', 0x5120),
                                        (0x47, 'tempcds', 0x4c05),
                                        (0x90, 'badfil', 0x7701)]:
    assert actual[offset] == expected[offset] == 0xe8
    actual_dest = start + offset + 3 + struct.unpack_from('<h', actual, offset + 1)[0]
    target_dest = target_start + offset + 3 + struct.unpack_from('<h', expected, offset + 1)[0]
    assert actual_dest == address(symbol), (symbol, actual_dest, address(symbol))
    assert target_dest == target_address, (symbol, target_dest)
    fixups.append({'offset': offset + 1, 'symbol': symbol, 'candidate_destination': actual_dest,
                   'target_destination': target_dest})
    actual[offset + 1:offset + 3] = expected[offset + 1:offset + 3]
for offset in (0x0c, 0x8e):
    candidate_pointer = int.from_bytes(actual[offset:offset + 2], 'little')
    target_pointer = int.from_bytes(expected[offset:offset + 2], 'little')
    assert 0x3fd0 + candidate_pointer == address('config')
    assert target_pointer == 0x3814
    assert candidate[address('config'):address('config') + 11] == target[0x3fd0 + target_pointer:0x3fd0 + target_pointer + 11]
    fixups.append({'offset': offset, 'symbol': 'config', 'candidate': candidate_pointer, 'target': target_pointer})
    actual[offset:offset + 2] = expected[offset:offset + 2]
assert actual == expected
report = {'stage': str(stage), 'candidate_sha256': digest(candidate), 'target_bios_sha256': digest(target),
          'map_sha256': digest(map_bytes), 'candidate_offset': start, 'target_offset': target_start,
          'length': length, 'fixups': fixups, 'normalized_equal': True,
          'scope': 'Linked doconf through error return; five named comparison-only address fixups. No runtime or whole BIOS identity claim.'}
(evidence / 'm5-bios-doconf-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
