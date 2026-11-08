"""Compare initialization-derived target DOSDATA with linked reference DOSDATA."""
from pathlib import Path
import argparse,difflib,hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent; evidence=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser();parser.add_argument('--build',default='m4-t5-init-recovery-build.json');parser.add_argument('--report',default='m4-t5-data-anchors.json');args=parser.parse_args()
assert Path(args.build).name==args.build and Path(args.report).name==args.report
build=json.loads((evidence/args.build).read_text())
stage=Path(build['stage']); image=(stage/'ntdos.sys').read_bytes()
assert hashlib.sha256(image).hexdigest()==build['output_sha256']
target=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
mapping=(stage/'ntdos.map').read_text()
match=re.search(r'^\s*([0-9A-F]+)H\s+([0-9A-F]+)H\s+([0-9A-F]+)H\s+DOSDATA\s+DATA',mapping,re.M|re.I)
assert match
start,stop,size=(int(x,16) for x in match.groups());origin=int.from_bytes(image[3:5],'little')
assert stop-start+1==size
a=image[start-origin:start-origin+size];b=target[0x7eb0:]
assert len(a)==size and len(b)==0x1362
blocks=[]
for block in difflib.SequenceMatcher(None,a,b,autojunk=False).get_matching_blocks():
    if block.size<16:continue
    data=a[block.a:block.a+block.size]
    if a.count(data)!=1 or b.count(data)!=1:continue
    blocks.append({'reference_data_offset':block.a,'target_data_offset':block.b,'size':block.size,
                   'sha256':hashlib.sha256(data).hexdigest()})
out={'reference_data_file_offset':start-origin,'reference_data_size':size,'target_data_file_offset':0x7eb0,
     'target_data_size':len(b),'blocks':blocks,'total_anchor_bytes':sum(x['size'] for x in blocks),
     'scope':'Greedy monotonic unique exact blocks of at least 16 bytes; candidate alignment only, not field identity or semantic equivalence.'}
(evidence/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'reference_size':size,'target_size':len(b),'anchor_count':len(blocks),'anchor_bytes':out['total_anchor_bytes'],'largest':sorted(blocks,key=lambda x:-x['size'])[:5]},indent=2))
