"""Compare the pinned IO.SYS fixture and BIOS reference link inventories."""
from pathlib import Path
import hashlib
import json
import re

from fat12_guest_file import read_root_file

ROOT = Path(__file__).resolve().parent.parent.parent
TARGET_HASH = 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\bios')
DOS6 = ROOT.parent / 'v6.0/bios'
DOS4 = ROOT.parent / 'v4.0/src/BIOS'
hash_bytes = lambda data: hashlib.sha256(data).hexdigest()

images = [ROOT / 'extras/build/command-vm-5e3s_yo_/boot.img',
          ROOT / 'extras/build/command-vm-h0vnbc95/boot.img']
targets = [read_root_file(path, 'IO.SYS') for path in images]
assert all(data is not None and len(data) == 33430 and hash_bytes(data) == TARGET_HASH
           for data in targets)
assert targets[0] == targets[1]
fixture = ROOT / 'extras/build/target-io-inspect.bin'
if fixture.exists():
    assert fixture.read_bytes() == targets[0]
else:
    fixture.write_bytes(targets[0])

def modules(path):
    data = path.read_bytes().decode('ascii').split(',')[0]
    return re.findall(r'[A-Za-z_][A-Za-z_0-9]*', data)

links = {'opennt': modules(NT / 'msbio_4.lnk'),
         'dos6': modules(DOS6 / 'msbio.lnk'),
         'dos4': modules(DOS4 / 'MSBIO.LNK')}
nt_binary = (NT / 'NTIO.SYS').read_bytes()
target = targets[0]
# Unique 16-byte anchors, extended in both directions. These are correspondence
# leads only: identical instruction bytes do not establish source identity.
n = 16
nt_index = {}
for i in range(len(nt_binary) - n + 1):
    key = nt_binary[i:i+n]
    nt_index.setdefault(key, []).append(i)
anchors = set()
for j in range(len(target) - n + 1):
    offsets = nt_index.get(target[j:j+n], ())
    if len(offsets) != 1:
        continue
    i = offsets[0]
    left = 0
    while i > left and j > left and nt_binary[i-left-1] == target[j-left-1]:
        left += 1
    right = n
    while i+right < len(nt_binary) and j+right < len(target) and nt_binary[i+right] == target[j+right]:
        right += 1
    if left + right >= 32:
        anchors.add((j-left, i-left, left+right))
longest = sorted(anchors, key=lambda a: (-a[2], a[0]))[:40]
report = {'target': {'length': len(target), 'sha256': hash_bytes(target),
                     'fixture': str(fixture), 'fixture_images': [str(p) for p in images]},
          'reference_ntio': {'length': len(nt_binary), 'sha256': hash_bytes(nt_binary)},
          'link_modules': links,
          'common_byte_anchors': [{'target_offset': t, 'ntio_offset': s, 'length': length,
                                   'zero_bytes': target[t:t+length].count(0),
                                   'distinct_byte_values': len(set(target[t:t+length]))}
                                  for t, s, length in longest],
          'scope': 'Hash-pinned fixture and raw byte correspondence leads only; no source or runtime equivalence established.'}
output = ROOT / 'extras/docs/etc/evidence/m5-io-reference-investigation.json'
output.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
