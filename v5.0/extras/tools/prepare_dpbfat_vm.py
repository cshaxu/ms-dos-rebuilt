"""Create a disposable candidate disk with Get-DPB and FAT diagnostics."""
from pathlib import Path
import hashlib
import json
import struct
import tempfile

from fat12_guest_file import read_root_file
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
base = root / 'extras/build/command-vm-h0vnbc95/boot.img'
expected_base = '524d75d8ca40106bb77a515b4885b17e5a2d96ba0ccd38c9b91084b0fc269167'
sha = lambda b: hashlib.sha256(b).hexdigest()
image = bytearray(base.read_bytes())
assert sha(image) == expected_base
candidate = json.loads((evidence / 'm6-three-file-existing-candidate.json').read_text())
payloads = {x['name']: (Path(candidate['stage']) / x['name']).read_bytes() for x in candidate['files']}
assert set(payloads) == {'IO.SYS', 'MSDOS.SYS', 'COMMAND.COM'}
for item in candidate['files']:
    assert sha(payloads[item['name']]) == item['sha256']
    assert read_root_file(base, item['name']) == payloads[item['name']]
for name in ('RESULTS.TXT', 'DONE.TXT', 'DPBFAT.COM', 'FATDATA.BIN'):
    assert read_root_file(base, name) is None
probe = (root / 'extras/build/dpbfat.com').read_bytes()
auto = b'@echo off\r\ncall A:\\SMOKE.BAT\r\necho FINISHED>A:\\DONE.TXT\r\n'
smoke = (b'@echo off\r\necho BEGIN-DPB-FAT>A:\\RESULTS.TXT\r\n'
         b'A:\\DPBFAT.COM >> A:\\RESULTS.TXT\r\n'
         b'if errorlevel 1 goto fail\r\necho PROBE-PASS>>A:\\RESULTS.TXT\r\n'
         b'goto end\r\n:fail\r\necho PROBE-FAIL>>A:\\RESULTS.TXT\r\n:end\r\n'
         + b'rem ' + b'x' * 390 + b'\r\n')
sector = struct.unpack_from('<H', image, 11)[0]
reserved = struct.unpack_from('<H', image, 14)[0]
fats = image[16]
fat_sectors = struct.unpack_from('<H', image, 22)[0]
root_entries = struct.unpack_from('<H', image, 17)[0]
assert sector == 512 and image[13] == 1 and fats == 2
root_offset = (reserved + fats * fat_sectors) * sector
data_offset = root_offset + ((root_entries * 32 + sector - 1) // sector) * sector
fat_offset = reserved * sector

def fat_get(c):
    at = fat_offset + c + c // 2
    word = int.from_bytes(image[at:at + 2], 'little')
    return word >> 4 if c & 1 else word & 0xfff

def fat_set(c, value):
    for index in range(fats):
        at = fat_offset + index * fat_sectors * sector + c + c // 2
        word = int.from_bytes(image[at:at + 2], 'little')
        word = ((word & 15) | (value << 4)) if c & 1 else ((word & 0xf000) | value)
        image[at:at + 2] = word.to_bytes(2, 'little')

def encoded(name):
    stem, ext = name.split('.')
    return (stem.ljust(8) + ext.ljust(3)).encode('ascii')

def put(name, data, create=False):
    wanted = encoded(name)
    slots = [p for p in range(root_offset, root_offset + root_entries * 32, 32) if image[p:p + 11] == wanted]
    if create:
        assert not slots
        slot = next(p for p in range(root_offset, root_offset + root_entries * 32, 32) if image[p] in (0, 0xe5))
        needed = (len(data) + sector - 1) // sector
        chain = [c for c in range(2, (len(image) - data_offset) // sector + 2) if fat_get(c) == 0][:needed]
        assert len(chain) == needed
        for i, c in enumerate(chain):
            fat_set(c, chain[i + 1] if i + 1 < len(chain) else 0xfff)
        image[slot:slot + 32] = bytes(32)
        image[slot:slot + 11] = wanted
        image[slot + 11] = 0x20
        struct.pack_into('<H', image, slot + 26, chain[0])
    else:
        assert len(slots) == 1
        slot = slots[0]
        c = struct.unpack_from('<H', image, slot + 26)[0]
        chain = []
        while 2 <= c < 0xff0:
            assert c not in chain
            chain.append(c)
            c = fat_get(c)
        assert c >= 0xff8
        assert (len(chain) - 1) * sector < len(data) <= len(chain) * sector, name
    for i, c in enumerate(chain):
        start = data_offset + (c - 2) * sector
        image[start:start + sector] = data[i * sector:(i + 1) * sector].ljust(sector, b'\0')
    struct.pack_into('<I', image, slot + 28, len(data))

for name, data in payloads.items():
    put(name, data)
put('AUTOEXEC.BAT', auto)
put('SMOKE.BAT', smoke)
put('DPBFAT.COM', probe, create=True)
stage = Path(tempfile.mkdtemp(prefix='dpbfat-vm-', dir=root / 'extras/build'))
output = stage / 'boot.img'
output.write_bytes(image)
for name, data in {**payloads, 'AUTOEXEC.BAT': auto, 'SMOKE.BAT': smoke, 'DPBFAT.COM': probe}.items():
    assert read_root_file(output, name) == data, name
assert inspect(output)['image']['fat_copies_equal']
report = {'stage': str(stage), 'base_image': str(base), 'base_sha256': expected_base,
          'image_before_sha256': sha(image), 'probe_sha256': sha(probe),
          'source_sha256': sha((root / 'extras/tests/dos/dpbfat.asm').read_bytes()),
          'system_files': {name: sha(data) for name, data in payloads.items()},
          'status': 'prepared; not executed'}
(evidence / 'm6-dpbfat-prepared.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
