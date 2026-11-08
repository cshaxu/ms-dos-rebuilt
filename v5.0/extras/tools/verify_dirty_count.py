"""Verify complete dirty-count routines against target without masked bytes."""
from pathlib import Path
import hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
r=json.loads((e/'m4-t5-dirty-count-build.json').read_text());stage=Path(r['stage'])
b=(stage/'ntdos.sys').read_bytes();assert hashlib.sha256(b).hexdigest()==r['output_sha256']
t=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(t).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
mapping=(stage/'ntdos.map').read_text();origin=int.from_bytes(b[3:5],'little');rows=[]
for name,offset,size in [('INC_DIRTY_COUNT',0x5d16,6),('DEC_DIRTY_COUNT',0x5d1c,14)]:
    m=re.search(r'0000:([0-9A-F]+)\s+'+name+r'\b',mapping);assert m
    actual=int(m[1],16)-origin;a=b[actual:actual+size];expected=t[offset:offset+size]
    rows.append({'name':name,'candidate_offset':actual,'target_offset':offset,'bytes':size,'candidate':a.hex(),'target':expected.hex(),'exact':a==expected})
out={'routines':rows,'all_exact':all(x['exact'] for x in rows),'scope':'Two complete routines only; no whole-kernel or runtime claim.'}
(e/'m4-t5-dirty-count-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert out['all_exact']
