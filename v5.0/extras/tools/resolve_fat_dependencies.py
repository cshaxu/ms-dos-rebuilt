"""Compare actual FAT EXTDEF names against the current kernel linker map."""
from pathlib import Path
import argparse,hashlib,json,re
parser=argparse.ArgumentParser()
parser.add_argument('--build',default='m4-t5-data-recovery-build.json')
parser.add_argument('--report',default='m4-t5-fat-symbol-resolution.json')
args=parser.parse_args()
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
probe=json.loads((e/'m4-t5-fat-full-cds-probe.json').read_text())
build=json.loads((e/args.build).read_text())
obj=Path(probe['stage'])/'fat.obj';mapping=Path(build['stage'])/'ntdos.map'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(obj)==probe['object_sha256'] and sha(mapping)==build['map_sha256']
symbols={m.group(3).lower():m.group(1)+':'+m.group(2) for m in re.finditer(r'^\s*([\dA-F]{4}):([\dA-F]{4})\s+(\S+)',mapping.read_text(),re.M)}
rows=[]
for name in probe['object_externals']:
    definitions=[]
    if name.lower() not in symbols:
        for p in (root.parent/'v6.0/dos').glob('*.asm'):
            for line,text in enumerate(p.read_text(errors='replace').splitlines(),1):
                code=text.split(';',1)[0]
                if re.search(r'\b'+re.escape(name)+r'\b',code,re.I) and re.search(r'\b(procedure|entry|public|i_am)\b',code,re.I):
                    definitions.append({'file':str(p),'line':line,'text':code.strip(),'sha256':sha(p)})
    rows.append({'name':name,'linked_address':symbols.get(name.lower()),'comparative_definition_candidates':definitions})
out={'build_report':args.build,'object_sha256':sha(obj),'map_sha256':sha(mapping),'dependencies':rows,
     'scope':'Name resolution only; an existing linked symbol does not prove compatible structure or semantics.'}
(e/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'resolved':sum(x['linked_address'] is not None for x in rows),'missing':[x for x in rows if x['linked_address'] is None]},indent=2))
