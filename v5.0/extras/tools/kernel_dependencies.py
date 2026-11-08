"""Conservative recursive INCLUDE inventory and collision-aware import plan."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent
nt=Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
search=[nt/'doskrnl/dos',nt/'inc',nt.parent.parent/'inc',nt/'messages']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
names=re.findall(r'(\w+)\.obj',(search[0]/'msdos.lnk').read_text(),re.I)
pending=[search[0]/(n+'.asm') for n in names]
pending += [search[0]/n for n in ['msdos.lnk','msdos.skl','makefile']]
pending += [nt/'make.inc',search[3]/'usa-ms.msg',search[3]/'usa-ms.idx']
seen={};edges=[];missing=[]
while pending:
    p=pending.pop().resolve();key=str(p).lower()
    if key in seen:continue
    seen[key]=p
    if p.suffix.lower() not in ('.asm','.inc','.sw'):continue
    for line,code in enumerate(p.read_text(errors='replace').splitlines(),1):
        m=re.match(r'\s*include\s+([^\s;]+)',code.split(';',1)[0],re.I)
        if not m:continue
        token=m.group(1).strip('"<>').replace('\\','/')
        found=next((base/token for base in search if (base/token).is_file()),None)
        if found is None:missing.append({'from':str(p),'line':line,'include':token});continue
        edges.append({'from':str(p),'line':line,'to':str(found.resolve())})
        pending.append(found)
rows=[]
for p in sorted(seen.values(),key=lambda p:str(p).lower()):
    parent=p.parent
    if parent==search[0]:dest=root/'dos'/p.name
    elif parent==search[1]:dest=root/'inc'/p.name
    elif parent==search[2]:dest=root/'inc/ntvdm'/p.name
    elif parent==search[3]:dest=root/'dos/messages'/p.name
    elif p==nt/'make.inc':dest=root/'dos/reference.make.inc'
    else:raise ValueError(p)
    collision=dest.exists() and sha(dest)!=sha(p)
    if collision:dest=root/'inc/kernel'/p.name
    rows.append({'source':str(p),'destination':dest.relative_to(root).as_posix(),
                 'sha256':sha(p),'bytes':p.stat().st_size,'shared_conflict':collision,
                 'existing_equal':dest.exists() and sha(dest)==sha(p)})
out={'mode':'Conservative lexical closure across all conditional branches; not active include trace.',
     'search_order':[str(p) for p in search],'files':rows,'edges':edges,'unresolved':missing,
     'note':'Kernel-specific override includes preserve existing COMMAND sources; messages kept separate because COMMAND message edits differ.'}
(root/'extras/docs/etc/evidence/m4-t5-kernel-dependencies.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'files':len(rows),'unresolved':missing,'conflicts':[r for r in rows if r['shared_conflict']]},indent=2))
