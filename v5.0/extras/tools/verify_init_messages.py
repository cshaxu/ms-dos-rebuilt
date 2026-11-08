"""Direct message and complete pre-transient prefix comparison."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-message-build.json').read_text())['stage'])
with tempfile.TemporaryDirectory(prefix='dos5-messages-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
symbols = {}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m = re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$', line)
    if m:
        symbols[m[3].lower()] = int(m[1], 16)*16+int(m[2], 16)-256
assert symbols['tcommand'] == 0x2324
assert symbols['copyrightmsg'] == 0x1e9b
banner = b'\r\n\r\nMicrosoft(R) MS-DOS(R) Version 5.00\r\n             (C)Copyright Microsoft Corp 1981-1991.\r\n'
assert len(banner) == 94
assert candidate[0x1e9b:0x1efa] == target[0x1e9b:0x1efa] == bytes([len(banner)])+banner
assert candidate[0x1e9b:0x21e2] == target[0x1e9b:0x21e2]
# Known remaining later-layout operands; record differences, never patch them.
words = [0x2b2, 0xe11, 0xe5b, 0xecb, 0x1004, 0x1032,
         0x154e, 0x1569, 0x180d, 0x18e4, 0x1a3d, 0x1d94, 0x1d98, 0x1dca]
allowed = {i for a in words for i in (a, a+1)}
differences = [i for i in range(0x2220) if candidate[i] != target[i]]
assert len(differences) == 18 and set(differences) <= allowed
out = {'prefix_bytes': 0x2220, 'equal_bytes': 0x2220-len(differences),
       'different_offsets': differences, 'message_bytes_exact': 0x21e2-0x1e9b,
       'tcommand_offset_exact': 0x2324,
       'operand_words': [{'offset': a, 'candidate': int.from_bytes(candidate[a:a+2], 'little'),
                          'target': int.from_bytes(target[a:a+2], 'little')} for a in words],
       'limitation': 'Remaining transient addresses and lengths prevent complete binary identity; no guest execution claim.'}
(root/'extras/docs/etc/evidence/m2-t3-message-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps({k: v for k, v in out.items() if k not in ('operand_words', 'different_offsets')}, indent=2))
