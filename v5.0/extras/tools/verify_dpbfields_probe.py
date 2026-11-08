"""Validate the retained guest DPB-geometry probe and fixture BPB."""
from pathlib import Path
import hashlib
import json
import struct
import sys
from fat12_guest_file import read_root_file

ROOT = Path(__file__).resolve().parent.parent.parent
stage = Path(sys.argv[1]).resolve()
assert stage.parent == (ROOT/'extras/build').resolve() and stage.name.startswith('dpbfields-vm-')
prepared = json.loads((stage/'prepared.json').read_text())
assert Path(prepared['stage']).resolve() == stage
sha = lambda data: hashlib.sha256(data).hexdigest()
assert sha(Path(prepared['base_image']).read_bytes()) == prepared['base_sha256']
assert sha((ROOT/'extras/tests/dos/dpbfields.asm').read_bytes()) == prepared['guest_source_sha256']
probe = ROOT/'extras/build/softpc-probe-56iubdoq/probe.exe'
assert sha(probe.read_bytes()) == 'b5b718d3f27e09242ae859b48756d80b83ba1d56843f7234962e7b3f17aa7aaa'
log = (stage/'headless-probe.log').read_bytes()
assert all(marker in log for marker in (b'create=0', b'started state=1', b'state-before-stop=2', b'video-read=0'))
path = stage/'boot.img'; image = path.read_bytes()
assert read_root_file(path, 'RESULTS.TXT') == b'BEGIN-DPB-FAT\r\nDPBFIELDS-PASS\r\nPROBE-PASS\r\n'
assert read_root_file(path, 'DONE.TXT') == b'FINISHED\r\n'
assert sha(read_root_file(path, 'DPBFAT.COM')) == prepared['guest_probe_sha256']
for name, expected in prepared['system_files'].items(): assert sha(read_root_file(path, name)) == expected
word = lambda off: struct.unpack_from('<H', image, off)[0]
bs, spc, reserved, fats, entries, sectors, spf = word(11), image[13], word(14), image[16], word(17), word(19), word(22)
assert (bs, spc, reserved, fats, entries, sectors, spf, image[21]) == (512, 1, 1, 2, 224, 2880, 9, 0xf0)
root_sector = reserved + fats * spf
first_data = root_sector + (entries * 32 + bs - 1) // bs
max_cluster = (sectors - first_data) // spc + 1
assert (root_sector, first_data, max_cluster) == (19, 33, 2848)
assert image[bs:bs*(1+spf)] == image[bs*(1+spf):bs*(1+2*spf)]
report = {'stage': str(stage), 'image_before_sha256': prepared['image_before_sha256'],
          'image_after_sha256': sha(image), 'guest_source_sha256': prepared['guest_source_sha256'],
          'guest_probe_sha256': prepared['guest_probe_sha256'], 'headless_probe_sha256': sha(probe.read_bytes()),
          'log_sha256': sha(log), 'system_files': prepared['system_files'],
          'checked_dpb_fields': {'drive': 0, 'unit': 0, 'sector_size': bs, 'cluster_mask': spc-1,
                                 'cluster_shift': 0, 'first_fat': reserved, 'fat_count': fats,
                                 'root_entries': entries, 'first_data_sector': first_data,
                                 'max_cluster': max_cluster, 'fat_size': spf,
                                 'root_sector': root_sector, 'media': image[21]},
          'results': 'DPBFIELDS-PASS; PROBE-PASS', 'passed': True,
          'scope': 'Guest comparisons for one 1.44 MB FAT12 geometry on existing binaries, using headless SoftPC core. Not fresh-source build, supplied product, original image, or all DPB fields and geometries.'}
(ROOT/'extras/docs/etc/evidence/m6-dpbfields-headless-runtime.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
