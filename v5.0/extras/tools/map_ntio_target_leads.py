"""Attach linked NTIO public-symbol leads to raw target byte matches."""
from pathlib import Path
import bisect
import hashlib
import json
import re

root = Path(__file__).resolve().parent.parent.parent
evidence = root/'extras/docs/etc/evidence'
build = json.loads((evidence/'m5-ntio-reference-build.json').read_text())
assert build['result']['equals_reference_fixture']
stage = Path(build['stage'])
binary = (stage/'ntio.sys').read_bytes()
assert hashlib.sha256(binary).hexdigest() == build['result']['sha256']
target = (root/'extras/build/target-io-inspect.bin').read_bytes()
assert hashlib.sha256(target).hexdigest() == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
mapfile = stage/'ntio.map'
publics = sorted((int(m[1],16)*16+int(m[2],16),m[3]) for m in re.finditer(
    r'(?m)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)', mapfile.read_text(errors='replace')))
assert publics
anchors = json.loads((evidence/'m5-io-reference-investigation.json').read_text())['common_byte_anchors']
result = []
for anchor in anchors:
    t, n, size = anchor['target_offset'], anchor['ntio_offset'], anchor['length']
    assert binary[n:n+size] == target[t:t+size] and len(target[t:t+size]) == size
    i = bisect.bisect_right(publics, (n, chr(0x10ffff)))-1
    offset, name = publics[i] if i >= 0 else (None, None)
    result.append({**anchor, 'preceding_public': name, 'public_linear_offset': offset,
                   'distance_from_public': n-offset if offset is not None else None})
report = {'map_sha256': hashlib.sha256(mapfile.read_bytes()).hexdigest(),
          'binary_sha256': build['result']['sha256'], 'public_count': len(publics),
          'leads': result,
          'scope': 'Nearest preceding public is an unbounded lead, not proof of ownership or a code match; matches may be data or padding.'}
(evidence/'m5-ntio-target-symbol-leads.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(f'{len(result)} byte ranges checked against {len(publics)} reference map publics')
