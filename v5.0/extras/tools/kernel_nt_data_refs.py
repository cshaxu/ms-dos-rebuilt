"""Inventory explicit source references to selected NTVDM DOSDATA symbols."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent
symbols=['vheVDM','SCS_COMSPEC','SCS_CMDTAIL','SCS_PBLOCK','SCS_ToSync','SCS_TSR',
         'SCS_Is_Dos_Binary','SCS_CMDPROMPT','SCS_DOSONLY','SCS_FDACCESS',
         'FAKE_NTDPB','NetCDS','SCS_ISDEBUG','DosWowDataStart','DOCLI','DOSTI','DOIRET']
pattern=re.compile(r'\b('+'|'.join(map(re.escape,symbols))+r')\b',re.I)
files=[p for d in ('dos','inc') for p in (root/d).rglob('*') if p.is_file() and p.suffix.lower() in ('.asm','.inc','.sw')]
rows={name:[] for name in symbols};canonical={name.lower():name for name in symbols};hashes={}
for p in files:
    data=p.read_bytes();found=False
    for n,line in enumerate(data.decode('latin1').splitlines(),1):
        code=line.split(';',1)[0]
        for match in pattern.finditer(code):
            found=True;rows[canonical[match.group().lower()]].append({'file':p.relative_to(root).as_posix(),'line':n,'text':code.strip()})
    if found:hashes[p.relative_to(root).as_posix()]=hashlib.sha256(data).hexdigest()
out={'symbols':rows,'source_hashes':hashes,'scope':'Lexical occurrences in local assembly/includes, including declarations and conditional branches; not proven active call graph.'}
(root/'extras/docs/etc/evidence/m4-t5-nt-data-references.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:len(v) for k,v in rows.items()},indent=2))
