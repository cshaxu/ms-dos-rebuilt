"""Verify retained private-buffer SETDPB geometry and FAT-capacity probe."""
from pathlib import Path
import hashlib
import json
import sys
from fat12_guest_file import read_root_file
from target_fat12 import inspect

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
stage = Path(sys.argv[1]).resolve()
geometry = stage.name.startswith('setdpbgeom-vm-')
assert stage.parent == (ROOT/'extras/build').resolve() and (geometry or stage.name.startswith('setdpb-vm-'))
prepared = json.loads((stage/'prepared.json').read_text())
assert Path(prepared['stage']).resolve() == stage
sha = lambda data: hashlib.sha256(data).hexdigest()
assert sha(Path(prepared['base_image']).read_bytes()) == prepared['base_sha256']
source = ROOT/('extras/tests/dos/setdpbgeom.asm' if geometry else 'extras/tests/dos/setdpb.asm')
assert sha(source.read_bytes()) == prepared['guest_source_sha256']
probe = ROOT/'extras/build/softpc-probe-56iubdoq/probe.exe'
assert sha(probe.read_bytes()) == 'b5b718d3f27e09242ae859b48756d80b83ba1d56843f7234962e7b3f17aa7aaa'
log = (stage/'headless-probe.log').read_bytes()
assert all(marker in log for marker in (b'create=0', b'started state=1', b'state-before-stop=2', b'video-read=0'))
image = stage/'boot.img'
marker = b'SETDPBGEOM-PASS' if geometry else b'SETDPB-PASS'
assert read_root_file(image, 'RESULTS.TXT') == b'BEGIN-DPB-FAT\r\n' + marker + b'\r\nPROBE-PASS\r\n'
assert read_root_file(image, 'DONE.TXT') == b'FINISHED\r\n'
assert sha(read_root_file(image, 'DPBFAT.COM')) == prepared['guest_probe_sha256']
assert read_root_file(image, 'FATDATA.BIN') == bytes(range(256))*8
assert inspect(image)['image']['fat_copies_equal']
deployment = json.loads((EVIDENCE/'m6-fresh-deployment.json').read_text())
fresh = Path(deployment['fresh_build_stage'])
for name, expected in prepared['system_files'].items():
    data = read_root_file(image, name)
    assert sha(data) == expected and data == (fresh/name).read_bytes()
cases = ({'fat12_720k': {'sectors_per_cluster': 2, 'first_data_sector': 14, 'max_cluster': 714},
          'fat16_64m': {'sectors_per_cluster': 4, 'first_data_sector': 289, 'max_cluster': 32696,
                        'total_sectors_32bit': 131072}}
         if geometry else
         {'normal': {'first_data_sector': 33, 'max_cluster': 2848, 'fat_sectors': 9, 'root_sector': 19},
          'short_fat': {'first_data_sector': 17, 'max_cluster': 340, 'fat_sectors': 1, 'root_sector': 3}})
report = {'stage': str(stage), 'image_before_sha256': prepared['image_before_sha256'],
          'image_after_sha256': sha(image.read_bytes()), 'guest_source_sha256': prepared['guest_source_sha256'],
          'guest_probe_sha256': prepared['guest_probe_sha256'], 'headless_probe_sha256': sha(probe.read_bytes()),
          'log_sha256': sha(log), 'system_files': prepared['system_files'], 'fresh_build_stage': str(fresh),
          'checked_cases': cases,
          'results': marker.decode('ascii') + '; PROBE-PASS', 'passed': True,
          'scope': 'INT 21h/AH=53h on two private BPB/DPB buffers using binaries equal to the fresh build. Not a test of writing real DPBs, other geometries, supplied product, or original media.'}
name = 'm6-setdpb-geometry-headless.json' if geometry else 'm6-setdpb-capacity-headless.json'
(EVIDENCE/name).write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
