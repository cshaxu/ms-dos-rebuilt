"""Validate target-backed resident handle restoration and variable placement."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root=Path(__file__).resolve().parent.parent.parent
report=json.loads((root/'extras/docs/etc/evidence/m2-t3-handles-build.json').read_text())
stage=Path(report['stage']);symbols={}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m=re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$',line)
    if m:symbols[m[3].lower()]=int(m[1],16)*16+int(m[2],16)
expected={'batch':0x252,'echoflag':0x2a6,'io_save':0x2a8,'singlecom':0x2ac,'verval':0x2ae,'forflag':0x2b2,'forptr':0x2b3,'nest':0x2b5,'nullflag':0x2bb}
assert all(symbols[k]==v for k,v in expected.items())
with tempfile.TemporaryDirectory(prefix='dos5-handles-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target=(Path(d)/'COMMAND.COM').read_bytes()
candidate=(stage/'command.com').read_bytes()
signature=bytes.fromhex('33db8b0ea8028b161800')
assert candidate.count(signature)==1
start=candidate.index(signature) # HeadFix is a module-local label, not in public MAP
length=70
assert candidate[start:start+length]==target[0xf0d:0xf0d+length], 'HeadFix bytes differ'
out={'resident_addresses':expected,'candidate_headfix_after_call':start,'target_headfix_after_call':0xf0d,'exact_bytes':length,'limitation':'Static byte and layout checks, not guest runtime verification.'}
(root/'extras/docs/etc/evidence/m2-t3-handles-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
