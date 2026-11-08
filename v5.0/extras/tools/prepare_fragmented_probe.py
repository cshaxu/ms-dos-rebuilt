"""Create a disposable fragmented-chain fixture; does not run an emulator."""
from pathlib import Path
import argparse
import hashlib
import json
import struct
import subprocess
import tempfile
from fat12_guest_file import read_root_file

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
parser = argparse.ArgumentParser()
mode = parser.add_mutually_exclusive_group()
mode.add_argument('--write', action='store_true', help='prepare the cross-cluster write probe')
mode.add_argument('--extend', action='store_true', help='prepare the file extension probe')
mode.add_argument('--truncate', action='store_true', help='prepare the file truncation probe')
mode.add_argument('--dpb-fields', action='store_true', help='prepare the DPB geometry probe')
mode.add_argument('--sft-handles', action='store_true', help='prepare the file-handle probe')
mode.add_argument('--setdpb', action='store_true', help='prepare the private SETDPB probe')
mode.add_argument('--setdpb-geometry', action='store_true', help='prepare the multi-geometry SETDPB probe')
args = parser.parse_args()
kind = 'setdpbgeom' if args.setdpb_geometry else ('setdpb' if args.setdpb else ('sfthandles' if args.sft_handles else ('dpbfields' if args.dpb_fields else ('fragtruncate' if args.truncate else ('fragextend' if args.extend else ('fragwrite' if args.write else 'fragread'))))))
source = ROOT / ('extras/tests/dos/' + kind + '.asm')
prior = json.loads((EVIDENCE / 'm6-dpbfat-headless-runtime.json').read_text())
base = Path(prior['stage']) / 'boot.img'
image = bytearray(base.read_bytes())
sha = lambda b: hashlib.sha256(b).hexdigest()
assert sha(image) == prior['image_after_sha256']
assert read_root_file(base, 'FATDATA.BIN') == bytes(range(256)) * 8
stage = Path(tempfile.mkdtemp(prefix=kind + '-vm-', dir=ROOT / 'extras/build'))
guest = stage / 'fragread.com'
subprocess.run(['nasm', '-f', 'bin', str(source), '-o', str(guest)], check=True, timeout=15)
program = guest.read_bytes()
bs, reserved, fats, spf, entries = struct.unpack_from('<H', image, 11)[0], struct.unpack_from('<H', image, 14)[0], image[16], struct.unpack_from('<H', image, 22)[0], struct.unpack_from('<H', image, 17)[0]
assert (bs, image[13], reserved, fats, spf) == (512, 1, 1, 2, 9)
root = (reserved + fats * spf) * bs
data = root + ((entries * 32 + bs - 1) // bs) * bs
def get(c):
    p = reserved * bs + c + c // 2
    w = int.from_bytes(image[p:p+2], 'little')
    return (w >> 4 if c & 1 else w) & 0xfff
def put(c, value):
    for i in range(fats):
        p = (reserved + i * spf) * bs + c + c // 2
        w = int.from_bytes(image[p:p+2], 'little')
        w = (w & 15) | value << 4 if c & 1 else (w & 0xf000) | value
        image[p:p+2] = w.to_bytes(2, 'little')
def block(c):
    return data + (c - 2) * bs
def entry(name):
    return next(p for p in range(root, root + entries * 32, 32) if image[p:p+11] == name)
def chain(c):
    out = []
    while c < 0xff8:
        assert 2 <= c < 2849 and c not in out
        out.append(c); c = get(c)
    return out
fat_entry = entry(b'FATDATA BIN')
old = chain(struct.unpack_from('<H', image, fat_entry + 26)[0])
assert old == [453, 454, 455, 456] and get(600) == get(700) == 0
for src, dst in ((454, 600), (456, 700)):
    image[block(dst):block(dst)+bs] = image[block(src):block(src)+bs]
new = [453, 600, 455, 700]
for index, c in enumerate(new): put(c, new[index+1] if index+1 < len(new) else 0xfff)
for c in (454, 456): put(c, 0)
probe_entry = entry(b'DPBFAT  COM')
old_probe = chain(struct.unpack_from('<H', image, probe_entry + 26)[0])
needed = (len(program) + bs - 1) // bs
assert 0 < needed <= len(old_probe)
for i, c in enumerate(old_probe[:needed]):
    image[block(c):block(c)+bs] = program[i*bs:(i+1)*bs].ljust(bs, b'\0')
    put(c, old_probe[i+1] if i+1 < needed else 0xfff)
for c in old_probe[needed:]: put(c, 0)
struct.pack_into('<I', image, probe_entry + 28, len(program))
output = stage / 'boot.img'; output.write_bytes(image)
assert read_root_file(output, 'FATDATA.BIN') == bytes(range(256)) * 8
assert read_root_file(output, 'DPBFAT.COM') == program
report = {'stage': str(stage), 'base_image': str(base), 'base_sha256': prior['image_after_sha256'],
          'image_before_sha256': sha(image), 'guest_source_sha256': sha(source.read_bytes()),
          'guest_probe_sha256': sha(program), 'fat_chain': new, 'system_files': prior['system_files'],
          'scope': 'Prepared disposable image only; execution and guest result are separate.'}
(stage/'prepared.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
