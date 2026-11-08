"""Verify CONFIG.SYS multi-pass dispatch against the physical DOS 5 target."""
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
listing_bytes = (stage / 'sysconf.lst').read_bytes()
map_text = map_bytes.decode(errors='replace')
listing = listing_bytes.decode(errors='replace')
def address(name):
    rows = re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+' + re.escape(name) + r'\s*$', map_text)
    values = {int(seg, 16) * 16 + int(off, 16) for seg, off in rows}
    assert len(values) == 1, (name, values)
    return values.pop()
def local(name):
    rows = re.findall(r'(?im)^' + re.escape(name) + r'\s+(?:\.\s*)+[^\r\n]*?\b([0-9A-F]{4})\s+SYSINITSEG\b', listing)
    assert len(rows) == 1, (name, rows)
    return int(rows[0], 16)

entry = address('doconf')
base = entry - local('doconf')
start_offset, end_offset, target_entry = 0x94, 0x13e, 0x612e
actual = bytearray(candidate[entry + start_offset:entry + end_offset])
expected = target[target_entry + start_offset:target_entry + end_offset]
assert len(actual) == len(expected) == end_offset - start_offset
fixups = []
for offset, symbol, target_dest, opcode in [
    (0xb4, 'getchr', 0x6a24, 0xe8), (0xb9, 'organize', 0x7204, 0xe8),
    (0xbc, 'getchr', 0x6a24, 0xe8), (0xd5, 'getchr', 0x6a24, 0xe8),
    (0xe1, 'badop', 0x69ec, 0xe9), (0xe6, 'newline', 0x743b, 0xe8),
    (0xeb, 'getchr', 0x6a24, 0xe8), (0x120, 'do_install_exec', 0x509f, 0xe8),
]:
    pos = offset - start_offset
    assert actual[pos] == expected[pos] == opcode
    actual_dest = entry + offset + 3 + struct.unpack_from('<h', actual, pos + 1)[0]
    reference_dest = base + local(symbol) if symbol == 'badop' else address(symbol)
    expected_dest = target_entry + offset + 3 + struct.unpack_from('<h', expected, pos + 1)[0]
    assert actual_dest == reference_dest, (symbol, actual_dest, reference_dest)
    assert expected_dest == target_dest, (symbol, expected_dest, target_dest)
    fixups.append({'offset': offset - start_offset + 1, 'symbol': symbol,
                   'candidate_destination': actual_dest, 'target_destination': expected_dest})
    actual[pos + 1:pos + 3] = expected[pos + 1:pos + 3]
assert actual == expected
# Both branches whose destinations lie beyond this interval retain their own
# relative offsets; verify the destination symbols rather than assuming this.
assert entry + 0xf9 + 3 + struct.unpack_from('<h', candidate, entry + 0xfa)[0] == base + local('multi_try_doshi')
assert entry + 0x112 + 2 + struct.unpack_from('<b', candidate, entry + 0x113)[0] == base + local('tryb')
report = {'stage': str(stage), 'candidate_sha256': digest(candidate), 'target_bios_sha256': digest(target),
          'map_sha256': digest(map_bytes), 'listing_sha256': digest(listing_bytes),
          'candidate_offset': entry + start_offset, 'target_offset': target_entry + start_offset,
          'length': len(actual), 'fixups': fixups, 'normalized_equal': True,
          'scope': 'Linked multi_pass through INSTALL dispatch; eight named comparison-only branch fixups. No runtime or whole BIOS identity claim.'}
(evidence / 'm5-bios-multipass-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))

