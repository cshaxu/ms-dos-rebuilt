"""Read-only kernel link-unit inventory; lexical seams are review candidates."""
from pathlib import Path
import hashlib
import json
import re

root=Path(__file__).resolve().parent.parent.parent
nt=Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
trees={'opennt':nt/'doskrnl/dos','dos6':root.parent/'v6.0/dos',
       'dos4':root.parent/'v4.0/src/DOS'}
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
orders={k:re.findall(r'([\w]+)\.obj', (p/'msdos.lnk').read_text(errors='replace'),re.I)
        for k,p in trees.items() if (p/'msdos.lnk').exists()}
inventory={}
for key,base in trees.items():
    inventory[key]=[{ 'file':p.name,'bytes':p.stat().st_size,'sha256':sha(p)}
                    for p in sorted(base.iterdir()) if p.is_file()]
units=[]
for name in dict.fromkeys(orders['opennt']+orders['dos6']):
    paths={k:p/(name+'.asm') for k,p in trees.items()}
    source=paths['opennt']
    seams=[]; includes=[]
    if source.exists():
        for number,line in enumerate(source.read_text(errors='replace').splitlines(),1):
            code=line.split(';',1)[0]
            if re.search(r'\b(BOP|SVC|DOS_SVC|VINT|WOW)\b|\bSVC\w*|\bBOP\w*',code,re.I):
                seams.append({'line':number,'code':code.strip()})
            m=re.match(r'\s*include\s+([^\s;]+)',code,re.I)
            if m:includes.append(m.group(1))
    units.append({'module':name,'sources':{k:sha(p) if p.exists() else None for k,p in paths.items()},
                  'opennt_direct_includes':includes,'lexical_host_seam_candidates':seams,
                  'disposition':'unmapped; no target identity or standalone behavior established'})
out={'scope':'Immediate kernel directories; link lists and direct lexical references only. Not transitive dependency closure.',
     'trees':{k:str(p) for k,p in trees.items()},'link_order':orders,'inventory':inventory,'units':units,
     'dos6_only_link_units':[n for n in orders['dos6'] if n not in orders['opennt']],
     'build_recipe':{'opennt_make_inc':str(nt/'make.inc'),'opennt_make_inc_sha256':sha(nt/'make.inc'),
                     'pipeline':['NOSRVBLD msdos.skl usa-ms.msg','MASM per linked unit','LINK /MAP @msdos.lnk','RELOC','STRIPZ'],
                     'status':'Execution evidence is separately recorded in m4-t5-reference-link.json'}}
path=root/'extras/docs/etc/evidence/m4-t5-kernel-baseline.json'
path.write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'linked_units':{k:len(v) for k,v in orders.items()},
                  'dos6_only':out['dos6_only_link_units'],
                  'seam_candidates':sum(len(u['lexical_host_seam_candidates']) for u in units),
                  'report_sha256':sha(path)},indent=2))
