"""Inventory physical-SFT transition surfaces; lexical uses are not active-code proof."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent
e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
b=json.loads((e/'m4-t5-fastopen-build.json').read_text())
physical=json.loads((e/'m4-t5-mknode-verification.json').read_text())
def fields(path):
    text=path.read_text(errors='replace')
    m=re.search(r'^SF_ENTRY[^\n]*?\t([0-9A-F]{4})\t[0-9A-F]{4}',text,re.M)
    assert m
    tail=text[m.end():]
    rows={}
    for line in tail.splitlines():
        if not line.strip():continue
        match=re.match(r'^  (SF_\w+)[ .]*\t([0-9A-F]{4})',line)
        if not match:break
        rows[match[1].lower()]=int(match[2],16)
    return {'size':int(m[1],16),'fields':rows,'listing':str(path),'listing_sha256':sha(path)}
nt=fields(Path(b['stage'])/'file.lst')
dos=fields(Path(physical['stage'])/'buf.lst')
assert nt['size']==33 and dos['size']==59
uses=[]
for rel,digest in b['source_snapshot'].items():
    path=root/rel
    assert sha(path)==digest,rel
    if path.suffix.lower() not in ('.asm','.inc'):continue
    for lineno,line in enumerate(path.read_text(errors='replace').splitlines(),1):
        code=line.split(';',1)[0]
        names=sorted(set(re.findall(r'\bsf_(?:nthandle|scs_console|nt_seek|nt_pipe_in)\b',code,re.I)))
        if names:uses.append({'file':rel,'line':lineno,'names':names,'code':code.strip()})
out={'build':'m4-t5-fastopen-build.json','nt':nt,'physical':dos,
 'field_changes':[{'field':n,'nt':nt['fields'].get(n),'physical':dos['fields'].get(n)}
 for n in sorted(nt['fields'].keys()|dos['fields'].keys()) if nt['fields'].get(n)!=dos['fields'].get(n)],
 'nt_lexical_uses':uses,'scope':'Frozen accepted build input set; lexical references may be inactive. Native listing proves structure offsets, not runtime correctness.',
 'default_table_padding':{'entries':5,'nt_padding':5*(59-33),'physical_padding':0,
 'source':'inc/kernel/const2.asm FILLSPACE preserves default SFT allocation area while entry stride changes'},
 'next':'Replace NT handle users/host paths coherently; use kernel-only physical sf.inc; reassemble and verify data offsets and code operands. Do not add NTHandle to physical structure or use dummy aliases.'}
(e/'m4-t5-sft-transition-audit.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'nt_size':nt['size'],'physical_size':dos['size'],'lexical_uses':len(uses),'files':sorted(set(x['file'] for x in uses))},indent=2))
