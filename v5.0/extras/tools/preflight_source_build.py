"""Read-only inventory of inputs required by the integrated source recipe.

This tool never launches a build, runner, emulator, or desktop application.
Its result is not authorization to execute the build or proof of isolation.
"""
from pathlib import Path
import hashlib
import json
import os
import sys
from target_files import BASELINE, TARGETS

ROOT = Path(__file__).resolve().parent.parent.parent
tool16 = Path(os.environ.get('DOS5_TOOLS16_ROOT', r'O:\repos.hobby\ntvdm64\tools\opennt\tools16'))
dos6 = Path(os.environ.get('DOS5_DOS6_ROOT', r'O:\repos.hobby\ms-dos-archaeology\v6.0'))
checks = [
    ('masm', tool16 / 'masm.exe', 'e54afaa9565e046cd862c29a015d685de43311acccf796469030e162ced6d00d'),
    ('nosrvbld', tool16 / 'nosrvbld.exe', 'e49e569b7e0775bdd731bcf18cea1d85c29dabc1aa9a7285de51249387711665'),
    ('buildidx', tool16 / 'buildidx.exe', '6a301eaee8ea8516e541da2a61a22f1db7d09b15c278a88a8d73083aac0f4d91'),
    ('buildmsg', tool16 / 'buildmsg.exe', '0d8ea59396a769e440549322a2ec9d1ab70423147e702ef1b1f42606cadd50cd'),
    ('stripz', tool16 / 'stripz.exe', '6d424555368e2f61d201dd249532672a12164c35afb507a3e3556595511ea689'),
    ('link', dos6 / 'c6ers/tools6/bin/link.exe', '163d8b86c18b93ccae9b2380d850cd42a9a5e1fd89a163b16170979afbbabb07'),
    ('reloc', dos6 / 'c6ers/tools6/bin/reloc.exe', '300b58668d46c3281ef2c017409aa9300499155d6593a8a9552781d2d96cc2b3'),
    ('dosbox', Path(os.environ.get('DOS5_DOSBOX_PATH', r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')), 'dcfd46fa521f5ce89dce3bf026056f3a1d15533f80321ee887403e30d7949f5e'),
    ('runner', ROOT / 'extras/build/isolated-tool-runner.exe', 'ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'),
    *((name.lower(), BASELINE / name, expected)
      for name, (_, expected) in TARGETS.items()),
]

def inspect(name, path, expected):
    try:
        data = path.read_bytes()
    except OSError as exc:
        return {'name': name, 'path': str(path), 'status': 'unavailable', 'error': str(exc)}
    actual = hashlib.sha256(data).hexdigest()
    return {'name': name, 'path': str(path), 'status': 'match' if actual == expected else 'mismatch',
            'bytes': len(data), 'sha256': actual, 'expected_sha256': expected}

def main():
    results = [inspect(*check) for check in checks]
    report = {'root': str(ROOT), 'checks': results,
              'scope': 'Read-only hash inventory; three retained system files are required. No source closure, runtime isolation, build success, or execution authorization is established.'}
    print(json.dumps(report, indent=2))
    return 0 if all(item['status'] == 'match' for item in results) else 1

if __name__ == '__main__':
    sys.exit(main())
