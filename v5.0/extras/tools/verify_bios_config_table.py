"""Check CONFIG.SYS command table and DRIVPARM setup against target IO.SYS."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm5-bios-singleconfig-probe.json').read_text())
assert build['candidate'] and build['oembase'] and build['singleconfig']
stage = Path(build['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
actual = (stage / 'msbio.bin').read_bytes()
assert digest(actual) == build['output']['sha256']
image = (root / 'extras/build/target-io-inspect.bin').read_bytes()
assert digest(image) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target = image[0x5a6:]
map_bytes = (stage / 'msbio.map').read_bytes()
listing_bytes = (stage / 'sysinit2.lst').read_bytes()
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
base = address('commnd') - local('commnd')
table = base + local('comtab')
target_table, table_length = 0x78bd, 0x91
assert actual[table:table + table_length] == target[target_table:target_table + table_length]
# The organizer's table pointer must actually reference the compared table.
assert actual[0x723d] == target[0x723d] == 0xbe
assert int.from_bytes(actual[0x723e:0x7240], 'little') + 0x3fd0 == table
assert int.from_bytes(target[0x723e:0x7240], 'little') + 0x3fd0 == target_table
start, length = address('setparms'), 0x57
assert start == 0x7025 and address('diddleback') == 0x7060
code = bytearray(actual[start:start + length])
expected = target[start:start + length]
refs = [(0x0b, 'drive', 0, 0x3aa6), (0x10, 'deviceparameters', 0, 0x397e),
        (0x1e, 'switches', 0, 0x3aa7), (0x26, 'drive', 0, 0x3aa6),
        (0x40, 'deviceparameters', 4, 0x3982), (0x46, 'deviceparameters', 1, 0x397f),
        (0x4b, 'deviceparameters', 2, 0x3980), (0x51, 'switches', 0, 0x3aa7)]
fixups = []
for offset, name, addend, target_value in refs:
    value = int.from_bytes(code[offset:offset + 2], 'little')
    expected_value = int.from_bytes(expected[offset:offset + 2], 'little')
    assert value == address(name) - 0x3fd0 + addend, (name, value)
    assert expected_value == target_value, (name, expected_value)
    fixups.append({'offset': offset, 'symbol': name, 'addend': addend,
                   'candidate': value, 'target': expected_value})
    code[offset:offset + 2] = expected[offset:offset + 2]
assert code == expected
report = {'stage': str(stage), 'candidate_sha256': digest(actual), 'target_bios_sha256': digest(target),
          'map_sha256': digest(map_bytes), 'listing_sha256': digest(listing_bytes),
          'command_table': {'candidate_offset': table, 'target_offset': target_table,
                            'length': table_length, 'displaced_raw_equal': True},
          'drive_parameters': {'candidate_offset': start, 'target_offset': start, 'length': length,
                               'fixups': fixups, 'normalized_equal': True},
          'scope': 'Linked command table and DRIVPARM helpers; named address normalization is comparison-only. No runtime or complete IO.SYS claim.'}
(evidence / 'm5-bios-config-table-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
