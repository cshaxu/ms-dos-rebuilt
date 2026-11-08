"""Verify restored absolute BIOS layout without comparison fixups."""
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
map_text = map_bytes.decode(errors='replace')
listing_bytes = (stage / 'sysconf.lst').read_bytes()
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
assert entry == 0x612e
assert address('sysinit_base') == 0x512c
assert address('InitDevLoad') == 0x6b2f
assert address('SizeDevice') == 0x6c32
assert address('ExecDev') == 0x6c81
assert address('DevSetBreak') == 0x6cd3
assert entry - local('doconf') + local('swit_parms') == 0x6082
intervals = []
for name, start, end in [('sysinit_base_through_checksum_error', 0x512c, 0x5160),
                         ('switches_and_dos_parameter_tables', 0x6082, 0x612e),
                         ('comment_and_rem_dispatch', 0x6906, 0x691d),
                         ('unknown_and_null_dispatch', 0x69a7, 0x69b9),
                         ('sysinit_parser_wrapper', 0x69b9, 0x69e0),
                         ('umb_device_load_and_size_parser', 0x6b2f, 0x6d69),
                         ('organizer_before_table_pointer', 0x7204, 0x723d),
                         ('organizer_after_table_pointer', 0x7240, 0x7420)]:
    assert actual[start:end] == target[start:end], name
    intervals.append({'name': name, 'start': start, 'end': end, 'length': end-start,
                      'raw_equal': True, 'sha256': digest(actual[start:end])})
report = {'stage': str(stage), 'candidate_sha256': digest(actual), 'target_bios_sha256': digest(target),
          'map_sha256': digest(map_bytes), 'listing_sha256': digest(listing_bytes),
          'intervals': intervals, 'scope': 'Two actual linked intervals, compared at absolute target positions without fixups; no complete BIOS or runtime claim.'}
(evidence / 'm5-bios-absolute-layout-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
