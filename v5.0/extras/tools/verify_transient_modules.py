"""Compare sequential complete code contributions, excluding listing address words."""
from pathlib import Path
import argparse
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
ap = argparse.ArgumentParser()
ap.add_argument('--report', default='m2-t3-command-identity-build.json')
ap.add_argument('--output', default='m2-t3-transient-modules-verification.json')
args = ap.parse_args()
if any(Path(n).name != n for n in (args.report, args.output)):
    raise ValueError('report/output must be filenames')
stage = Path(json.loads((root/'extras/docs/etc/evidence'/args.report).read_text())['stage'])
candidate = (stage/'command.com').read_bytes()
with tempfile.TemporaryDirectory(prefix='dos5-modules-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
base = 0x2220
checks = []
for name in ['tcode', 'tbatch', 'tbatch2', 'tfor', 'dir', 'tcmd1b', 'tcmd2a',
             'tcmd2b', 'tenv', 'tenv2', 'tmisc1', 'tmisc2', 'tpipe', 'parse2',
             'path1', 'path2', 'tucode', 'copy', 'copypr1', 'copypr2', 'cparse',
             'tparse', 'tprintf', 'loadhi']:
    mask, end = set(), None
    for line in (stage/(name+'.lst')).read_text(encoding='latin1').splitlines():
        m = re.match(r' ([0-9A-F]{4})  (.*?)\\(.*)', line)
        if not m:
            continue
        pos = int(m[1], 16)
        if re.search(r'TRANCODE\s+ENDS', m[3], re.I):
            end = pos
        previous = []
        for token in m[2].split():
            token = token.rstrip(':/')
            if token in ('E', 'R'):
                assert len(previous) == 2, (name, line)
                mask.update(previous)
            elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}|----', token):
                previous = list(range(pos, pos+len(token)//2))
                pos += len(token)//2
    assert end is not None
    first = 0x104 if name == 'tcode' else 0
    differences = [i for i in range(first, end) if candidate[base+i] != target[base+i]]
    unmasked = [i for i in differences if i not in mask]
    assert not unmasked, (name, unmasked[:20])
    checks.append({'module': name, 'file_start': base+first, 'length': end-first,
                   'different_bytes': len(differences), 'unmasked_differences': unmasked})
    base += end
# Restored path scanner calls the target-corresponding scasb2 implementation.
call = 0x41cc  # PATH display's local offset 1F5 from module start 3FD7.
assert candidate[call] == target[call] == 0xe8
assert call+3+int.from_bytes(candidate[call+1:call+3], 'little', signed=True) == 0x46b2
assert candidate[call:call+3] == target[call:call+3]
assert candidate[0x46b2:0x46ba] == target[0x46b2:0x46ba] == bytes.fromhex('32c0b90001f2aec3')
assert candidate[0x4c31:0x4c3d] == target[0x4c31:0x4c3d] == bytes.fromhex('bf6904b95000fcf3a4bf5c00')
assert candidate[0x5547:0x5551] == target[0x5547:0x5551] == bytes.fromhex('b43a83f9027205386401')
version_message = b'\x14MS-DOS Version %1.%2'
version_offset = target.index(version_message)
assert candidate[version_offset:version_offset+len(version_message)] == version_message
out = {'checks': checks, 'next_module_start': base,
       'limitation': 'Whole code contributions modulo annotated operand words; targets of remaining address words and guest behavior are not proven.'}
(root/'extras/docs/etc/evidence'/args.output).write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
