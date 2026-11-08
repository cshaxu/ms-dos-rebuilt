"""Prepare a separate build workspace without invoking a build or emulator."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
EXPECTED = {
    'io': ('extras/build/target-io-inspect.bin', 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'),
    'kernel': ('extras/build/target-kernel-inspect.bin', '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'),
    'media': ('extras/build/command-vm-5e3s_yo_/boot.img', '30f75d94c68e94eeebee002a20197fd7633d5ee31dfadc1eb58f70beb26e15f9'),
    'runner': ('extras/build/isolated-tool-runner.exe', 'ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'),
}
digest = lambda data: hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True, help='new directory outside the source snapshot')
    for name in EXPECTED:
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if output == ROOT.resolve() or output.is_relative_to(ROOT.resolve()):
        parser.error('output must be outside the source snapshot')
    manifest_bytes = (ROOT/'SOURCE-MANIFEST.json').read_bytes()
    manifest = json.loads(manifest_bytes)
    copied = {}
    seen = set()
    for entry in manifest['files']:
        rel = Path(entry['path'])
        if rel.is_absolute() or rel.drive or '..' in rel.parts or not rel.parts:
            raise ValueError(f'invalid manifest path: {rel}')
        key = rel.as_posix().lower()
        if key in seen: raise ValueError(f'duplicate manifest path: {rel}')
        seen.add(key)
        path = ROOT/rel
        if path.is_symlink() or not path.is_file(): raise ValueError(f'invalid source: {rel}')
        data = path.read_bytes()
        if len(data) != entry['bytes'] or digest(data) != entry['sha256']:
            raise ValueError(f'source manifest mismatch: {rel}')
        copied[rel] = data
    inputs = {}
    for name, (destination, expected) in EXPECTED.items():
        path = getattr(args, name)
        if path.is_symlink() or not path.is_file(): raise ValueError(f'invalid input: {name}')
        data = path.read_bytes()
        if digest(data) != expected: raise ValueError(f'input hash mismatch: {name}')
        inputs[name] = {'source': str(path.resolve()), 'destination': destination, 'sha256': expected, 'bytes': len(data)}
        copied[Path(destination)] = data
    copied[Path('README.md')] = (ROOT/'README.md').read_bytes()
    copied[Path('SOURCE-MANIFEST.json')] = manifest_bytes
    output.mkdir(parents=True, exist_ok=False)
    for rel, data in copied.items():
        path = output/rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        if path.read_bytes() != data: raise IOError(f'copy verification failed: {rel}')
    (output/'extras/docs/etc/evidence').mkdir(parents=True, exist_ok=True)
    result = {'workspace': str(output), 'source_snapshot': str(ROOT), 'manifest_sha256': digest(manifest_bytes),
              'source_file_count': len(manifest['files']), 'inputs': inputs,
              'scope': 'Prepared separate local build workspace only. No build, emulator, desktop or runtime verification; existing automatic approval rejection remains in force.'}
    (output/'extras/build/workspace-inputs.json').write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
