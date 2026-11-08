from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root=Path(__file__).resolve().parent.parent.parent
stage=Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-startup-build.json').read_text())['stage'])
symbols={}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m=re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$',line)
    if m:symbols[m[3].lower()]=int(m[1],16)*16+int(m[2],16)-256
mask=set()
for line in (stage/'init.lst').read_text(encoding='latin1').splitlines():
    m=re.match(r' ([0-9A-F]{4})  (.*?)\\',line)
    if not m:continue
    pos=int(m[1],16);previous=[]
    for token in m[2].split():
        token=token.rstrip(':')
        if token in ('E','R'):mask.update(previous)
        elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}',token):previous=list(range(pos,pos+len(token)//2));pos+=len(token)//2
with tempfile.TemporaryDirectory(prefix='dos5-start-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target=(Path(d)/'COMMAND.COM').read_bytes()
candidate=(stage/'command.com').read_bytes();start=symbols['conproc'];length=0x78
diff=[i for i in range(length) if candidate[start+i]!=target[0x1460+i] and i not in mask]
out={'candidate_entry':start,'target_entry':0x1460,'prefix_length':length,'unmasked_differences':diff,'limitation':'Instruction layout with MASM word annotations masked; full addresses and runtime not verified.'}
(root/'extras/docs/etc/evidence/m2-t3-startup-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert not diff
