"""Verify the retained results of a separately run headless fragment probe."""
from pathlib import Path
import hashlib
import json
import struct
import sys
from fat12_guest_file import read_root_file

ROOT = Path(__file__).resolve().parent.parent.parent
stage = Path(sys.argv[1]).resolve()
extend = stage.name.startswith('fragextend-vm-')
write = stage.name.startswith('fragwrite-vm-')
truncate = stage.name.startswith('fragtruncate-vm-')
assert stage.parent == (ROOT / 'extras/build').resolve() and (truncate or extend or write or stage.name.startswith('fragread-vm-'))
prepared = json.loads((stage / 'prepared.json').read_text())
assert Path(prepared['stage']).resolve() == stage
sha = lambda b: hashlib.sha256(b).hexdigest()
assert sha(Path(prepared['base_image']).read_bytes()) == prepared['base_sha256']
kind = 'fragtruncate' if truncate else ('fragextend' if extend else ('fragwrite' if write else 'fragread'))
source = ROOT / ('extras/tests/dos/' + kind + '.asm')
assert sha(source.read_bytes()) == prepared['guest_source_sha256']
probe = ROOT / 'extras/build/softpc-probe-56iubdoq/probe.exe'
assert sha(probe.read_bytes()) == 'b5b718d3f27e09242ae859b48756d80b83ba1d56843f7234962e7b3f17aa7aaa'
log = (stage / 'headless-probe.log').read_bytes()
assert all(marker in log for marker in (b'create=0', b'started state=1', b'state-before-stop=2', b'video-read=0'))
path = stage / 'boot.img'; image = path.read_bytes()
marker = b'FRAGTRUNCATE-PASS' if truncate else (b'FRAGEXTEND-PASS' if extend else (b'FRAGWRITE-PASS' if write else b'FRAG-PASS'))
assert read_root_file(path, 'RESULTS.TXT') == b'BEGIN-DPB-FAT\r\n' + marker + b'\r\nPROBE-PASS\r\n'
assert read_root_file(path, 'DONE.TXT') == b'FINISHED\r\n'
assert sha(read_root_file(path, 'DPBFAT.COM')) == prepared['guest_probe_sha256']
expected_data = bytearray(bytes(range(256)) * 8)
if write:
    expected_data[510:516] = bytes.fromhex('a5 5a 3c c3 96 69')
if extend:
    expected_data.extend(b'\xa5' * 1024)
if truncate:
    del expected_data[600:]
assert read_root_file(path, 'FATDATA.BIN') == expected_data
for name, expected in prepared['system_files'].items(): assert sha(read_root_file(path, name)) == expected
bs = struct.unpack_from('<H', image, 11)[0]; res = struct.unpack_from('<H', image, 14)[0]
fats = image[16]; spf = struct.unpack_from('<H', image, 22)[0]
assert (bs, res, fats, spf) == (512, 1, 2, 9)
assert image[bs:bs*(1+spf)] == image[bs*(1+spf):bs*(1+2*spf)]
root = (res + fats*spf)*bs
entry = next(p for p in range(root, root+224*32, 32) if image[p:p+11] == b'FATDATA BIN')
c = struct.unpack_from('<H', image, entry+26)[0]; chain = []
while c < 0xff8:
    assert 2 <= c < 2849 and c not in chain
    chain.append(c); p = res*bs+c+c//2; w = int.from_bytes(image[p:p+2], 'little')
    c = (w >> 4 if c & 1 else w) & 0xfff
assert prepared['fat_chain'] == [453, 600, 455, 700]
if truncate:
    assert chain == prepared['fat_chain'][:2]
else:
    assert chain[:4] == prepared['fat_chain'] and len(chain) == (6 if extend else 4)
freed = []
if truncate:
    for c in prepared['fat_chain'][2:]:
        p = res*bs+c+c//2; w = int.from_bytes(image[p:p+2], 'little')
        assert ((w >> 4 if c & 1 else w) & 0xfff) == 0
        freed.append(c)
report = {'stage': str(stage), 'image_before_sha256': prepared['image_before_sha256'],
          'image_after_sha256': sha(image), 'guest_source_sha256': prepared['guest_source_sha256'],
          'guest_probe_sha256': prepared['guest_probe_sha256'], 'headless_probe_sha256': sha(probe.read_bytes()),
          'log_sha256': sha(log), 'fat_chain': chain, 'freed_clusters': freed, 'fat_copies_equal': True,
          'system_files': prepared['system_files'], 'results': marker.decode('ascii') + '; PROBE-PASS', 'passed': True,
          'scope': ('Existing source-built binaries on one disposable FAT12 floppy, using headless SoftPC core; '
                    + ('one fragmented-file truncation and two freed clusters.' if truncate else ('one fragmented-file extension by two clusters.' if extend else ('one cross-cluster write followed by close and reopen.' if write else 'sequential and boundary-seek reads of one fragmented file.')))
                    + ' Not supplied product, fresh build, original image, or comprehensive FAT verification.')}
name = 'm6-fragmented-fat-truncate-runtime.json' if truncate else ('m6-fragmented-fat-extend-runtime.json' if extend else ('m6-fragmented-fat-write-runtime.json' if write else 'm6-fragmented-fat-runtime.json'))
(ROOT/'extras/docs/etc/evidence'/name).write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
