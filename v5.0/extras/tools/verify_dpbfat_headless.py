"""Verify the headless Get-DPB and multi-cluster FAT diagnostic artifacts."""
from pathlib import Path
import hashlib
import json
import struct

from fat12_guest_file import read_root_file
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
prepared = json.loads((evidence / 'm6-dpbfat-prepared.json').read_text())
stage = Path(prepared['stage'])
path = stage / 'boot.img'
image = path.read_bytes()
sha = lambda b: hashlib.sha256(b).hexdigest()
assert sha(Path(prepared['base_image']).read_bytes()) == prepared['base_sha256']
probe = root / 'extras/build/softpc-probe-56iubdoq/probe.exe'
assert sha(probe.read_bytes()) == 'b5b718d3f27e09242ae859b48756d80b83ba1d56843f7234962e7b3f17aa7aaa'
log = (stage / 'headless-probe.log').read_bytes()
for marker in (b'create=0', b'started state=1', b'state-before-stop=2', b'video-read=0'):
    assert marker in log
assert sha((root / 'extras/tests/dos/dpbfat.asm').read_bytes()) == prepared['source_sha256']
assert sha(read_root_file(path, 'DPBFAT.COM')) == prepared['probe_sha256']
results = read_root_file(path, 'RESULTS.TXT')
assert results == b'BEGIN-DPB-FAT\r\nDPB-PASS\r\nFAT-PASS\r\nPROBE-PASS\r\n'
assert read_root_file(path, 'DONE.TXT') == b'FINISHED\r\n'
data = read_root_file(path, 'FATDATA.BIN')
assert data == bytes(range(256)) * 8
for name, expected in prepared['system_files'].items():
    assert sha(read_root_file(path, name)) == expected, name
assert inspect(path)['image']['fat_copies_equal']
sector = struct.unpack_from('<H', image, 11)[0]
reserved = struct.unpack_from('<H', image, 14)[0]
fats = image[16]
fat_sectors = struct.unpack_from('<H', image, 22)[0]
root_entries = struct.unpack_from('<H', image, 17)[0]
root_offset = (reserved + fats * fat_sectors) * sector
entry = next(p for p in range(root_offset, root_offset + root_entries * 32, 32)
             if image[p:p + 11] == b'FATDATA BIN')
cluster = struct.unpack_from('<H', image, entry + 26)[0]
chain = []
while 2 <= cluster < 0xff0:
    assert cluster not in chain
    chain.append(cluster)
    pos = reserved * sector + cluster + cluster // 2
    word = int.from_bytes(image[pos:pos + 2], 'little')
    cluster = word >> 4 if cluster & 1 else word & 0xfff
assert cluster >= 0xff8 and len(chain) == 4
report = {'stage': str(stage), 'headless_probe_sha256': sha(probe.read_bytes()),
          'guest_probe_sha256': prepared['probe_sha256'], 'guest_source_sha256': prepared['source_sha256'],
          'log_sha256': sha(log), 'image_before_sha256': prepared['image_before_sha256'],
          'image_after_sha256': sha(image), 'results': results.decode('ascii'),
          'fat_file_bytes': len(data), 'fat_file_sha256': sha(data), 'fat_chain': chain,
          'fat_copies_equal': True, 'system_files': prepared['system_files'], 'passed': True,
          'scope': 'Headless SoftPC core on disposable media with existing source-built candidates. DOS Get-DPB AH=32h and 2048-byte file write/read passed. Not supplied product, fresh build, original-image or full FAT verification.'}
(evidence / 'm6-dpbfat-headless-runtime.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
