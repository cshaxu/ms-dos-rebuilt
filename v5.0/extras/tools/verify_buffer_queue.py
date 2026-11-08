"""Compare complete consecutive BUF routines to the target with no masking."""
from pathlib import Path
import hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
report=json.loads((e/'m4-t5-buffer-queue-build.json').read_text());stage=Path(report['stage'])
b=(stage/'ntdos.sys').read_bytes();assert hashlib.sha256(b).hexdigest()==report['output_sha256']
t=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(t).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
origin=int.from_bytes(b[3:5],'little');mapping=(stage/'ntdos.map').read_text()
names=['GetCurHead','ScanPlace','PLACEBUF','PointComp'];offsets={}
for name in names:
    m=re.search(r'0000:([0-9A-F]+)\s+'+name+r'\b',mapping,re.I);assert m
    offsets[name]=int(m[1],16)-origin
# Use the assembler's ENDP offset to avoid including the next linked module.
listing=(stage/'buf.lst').read_text(errors='replace')
end_symbol=re.search(r'^\s*([0-9A-F]{4})\s+.*PointComp\s+ENDP',listing,re.M|re.I)
assert end_symbol
end=offsets['GetCurHead']+int(end_symbol[1],16)
data=b[offsets['GetCurHead']:end];target_start=23206
out={'candidate_start':offsets['GetCurHead'],'target_start':target_start,'bytes':len(data),
     'candidate_hex':data.hex(),'target_hex':t[target_start:target_start+len(data)].hex(),
     'exact':data==t[target_start:target_start+len(data)],'routine_offsets':offsets,
     'scope':'Consecutive four routines including internal branch displacements and data operands; no masking.'}
(e/'m4-t5-buffer-queue-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
assert out['exact']
