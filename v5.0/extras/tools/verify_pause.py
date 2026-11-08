from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root=Path(__file__).resolve().parent.parent.parent
stage=Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-pause-build.json').read_text())['stage'])
symbols={}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m=re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$',line)
    if m:symbols[m[3].lower()]=int(m[1],16)*16+int(m[2],16)-256
data=(stage/'command.com').read_bytes();offset=symbols['pause']
with tempfile.TemporaryDirectory(prefix='dos5-pause-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target=(Path(d)/'COMMAND.COM').read_bytes()
assert [data[offset+j] for j in (0,3,6,9,12)]==[0xba,0xe8,0xe8,0xe8,0xc3]
assert [target[0x3c6a+j] for j in (0,3,6,9,12)]==[0xba,0xe8,0xe8,0xe8,0xc3]
calls=[]
for j,name,target_dest in [(3,'std_printf',0x7232),(6,'getkeystroke',0x2775),(9,'crlf2',0x48d7)]:
    actual=offset+j+3+int.from_bytes(data[offset+j+1:offset+j+3],'little',signed=True)
    assert actual==symbols[name]
    assert 0x3c6a+j+3+int.from_bytes(target[0x3c6a+j+1:0x3c6a+j+3],'little',signed=True)==target_dest
    calls.append({'symbol':name,'candidate_destination':actual,'target_destination':target_dest})
out={'candidate_pause':offset,'target_pause':0x3c6a,'length':13,'calls':calls,'limitation':'Call graph and opcode layout verified, final addresses/message data and runtime unproven.'}
(root/'extras/docs/etc/evidence/m2-t3-pause-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
