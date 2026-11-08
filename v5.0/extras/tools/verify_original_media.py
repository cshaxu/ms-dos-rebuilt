"""Compare fresh/deployed DOS files directly to the pinned original image."""
from pathlib import Path
import argparse
import hashlib
import json
from fat12_guest_file import read_root_file
from target_fat12 import inspect

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
ORIGINAL_SHA = '168bd67f0d0feaca7f47c0677e64aab51666460c116dd8bbaf8343e83364948c'
ORIGINAL_LENGTH = 258048
TARGETS = {
    'IO.SYS': (33430, 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'),
    'MSDOS.SYS': (37394, '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'),
    'COMMAND.COM': (47845, '74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'),
}
digest = lambda data: hashlib.sha256(data).hexdigest()

def require_original(data):
    if len(data) != ORIGINAL_LENGTH or digest(data) != ORIGINAL_SHA:
        raise ValueError('image is not the pinned original byte sequence')

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--image', type=Path, default=Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'))
    args = parser.parse_args()
    initial = args.image.read_bytes()
    require_original(initial)
    inspection = inspect(args.image)
    if inspection['image']['sha256'] != ORIGINAL_SHA:
        raise ValueError('image changed during inspection')
    deployment = json.loads((EVIDENCE/'m6-fresh-deployment.json').read_text())
    build = Path(deployment['fresh_build_stage'])
    entries = []
    for name, (length, expected) in TARGETS.items():
        target = read_root_file(args.image, name)
        if target is None or len(target) != length or digest(target) != expected:
            raise ValueError(f'{name}: original target mismatch')
        fresh = (build/name).read_bytes()
        deployed = (Path(r'O:\DOS')/name).read_bytes()
        if fresh != target or deployed != target:
            raise ValueError(f'{name}: candidate or deployment differs from original')
        entries.append({'name': name, 'bytes': length, 'sha256': expected,
                        'fresh_byte_equal': True, 'deployment_byte_equal': True})
    if args.image.read_bytes() != initial:
        raise ValueError('original image changed during verification')
    report = {'image': str(args.image), 'image_sha256': ORIGINAL_SHA, 'image_bytes': ORIGINAL_LENGTH,
              'files': entries, 'fresh_build_stage': str(build), 'deployment': r'O:\DOS',
              'scope': 'Direct comparison to the pinned original image bytes present at verification time. Missing disk tail, product runtime, full filesystem behavior and rights are separate.'}
    (EVIDENCE/'m6-original-media-revalidation.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report, indent=2))

if __name__ == '__main__':
    main()
