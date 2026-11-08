"""Reproduce the pinned private-desktop launcher without executing it."""
from pathlib import Path
import argparse
import hashlib
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent.parent
SOURCE = ROOT / 'extras/tools/isolated_tool_runner.c'
SOURCE_SHA256 = 'c28ccb33d1df915fbc726b62b8b80f2a2e0a1d8850724e9670b0fbacc051053b'
RUNNER_SHA256 = 'ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
SOURCE_DATE_EPOCH = '1794007563'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', default='isolated-tool-runner.exe',
                        help='new filename under build/; existing files are never overwritten')
    args = parser.parse_args()
    if Path(args.output).name != args.output:
        parser.error('output must be a filename')
    if digest(SOURCE) != SOURCE_SHA256:
        raise ValueError('launcher source differs from the pinned source')
    build = ROOT / 'extras/build'
    build.mkdir(exist_ok=True)
    output = build / args.output
    if output.exists():
        raise FileExistsError(output)
    env = os.environ.copy()
    env['SOURCE_DATE_EPOCH'] = SOURCE_DATE_EPOCH
    with tempfile.TemporaryDirectory(prefix='runner-compile-', dir=build) as tmp:
        candidate = Path(tmp) / 'runner.exe'
        subprocess.run(['gcc', '-O2', str(SOURCE), '-o', str(candidate), '-luser32'],
                       env=env, check=True, timeout=120)
        if digest(candidate) != RUNNER_SHA256:
            raise ValueError('compiled launcher does not match the pinned hash')
        with output.open('xb') as stream:
            stream.write(candidate.read_bytes())
    if digest(output) != RUNNER_SHA256:
        raise IOError('launcher write verification failed')
    print(f'{output}: {RUNNER_SHA256}')


if __name__ == '__main__':
    main()
