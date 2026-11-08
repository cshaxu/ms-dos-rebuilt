"""Freeze exact resident-prefix differences after restoring the DOS path buffer."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-resident-buffer-build.json').read_text())['stage'])
symbols = {}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m = re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$', line)
    if m:
        symbols[m[3].lower()] = int(m[1], 16)*16+int(m[2], 16)
with tempfile.TemporaryDirectory(prefix='dos5-resident-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
expected_symbols = {'msgbuffer': 0x469, 'safepathbuffer': 0x469,
                    'int2fhandler': 0x4b9, 'resmsgend': 0x4bd,
                    'ressize': 0x4bf, 'rstack': 0x53e, 'oldds': 0x53e,
                    'loadhiflg': 0x540, 'conproc': 0x1560}
for name, value in expected_symbols.items():
    assert symbols[name] == value, (name, symbols[name])
assert symbols['int2fhandler']-symbols['msgbuffer'] == 80
assert candidate[0x441:0x447] == target[0x441:0x447] == b'ARIFYN'
assert candidate[0xe81:0xe84] == target[0xe81:0xe84] == bytes.fromhex('bc3e05')
assert candidate[0x1086:0x108a] == target[0x1086:0x108a] == bytes.fromhex('8f063e05')
# Explicitly identified word operands in the prefix, not arbitrary mismatch masks.
words = {0x226: 'TrnSize', 0x229: 'OldEnv', 0x22d: 'EnvSiz', 0x231: 'UsedEnv',
         0x29a: 'Chuckenv', 0x2ac: 'TranStart', 0x2b2: 'TranSpaceEnd',
         0x2eb: 'initialization error jump', 0xc86: 'initialization jump',
         0xe11: 'rounded transient size', 0xe5b: 'TranSpaceEnd',
         0xecb: 'transient variable destination', 0xff8: 'TranStart',
         0x1004: 'transient reload length', 0x1032: 'transient checksum length'}
allowed = {i for offset in words for i in (offset, offset+1)}
differences = [i for i in range(0x1460) if candidate[i] != target[i]]
assert len(differences) == 21
assert set(differences) <= allowed
out = {'prefix_bytes': 0x1460, 'equal_bytes': 0x1460-len(differences),
       'different_bytes': differences, 'resident_symbols': expected_symbols,
       'unresolved_operands': [{'offset': offset, 'description': name,
          'candidate': int.from_bytes(candidate[offset:offset+2], 'little'),
          'target': int.from_bytes(target[offset:offset+2], 'little')} for offset, name in words.items()],
       'limitation': 'Exact prefix comparison with explicit remaining words; their final values and guest execution remain unverified.'}
(root/'extras/docs/etc/evidence/m2-t3-resident-prefix-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps({'prefix_bytes': out['prefix_bytes'], 'equal_bytes': out['equal_bytes'], 'different_bytes': len(differences)}, indent=2))
