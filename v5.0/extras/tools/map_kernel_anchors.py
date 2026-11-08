"""Unique exact byte-block anchors; candidates, not semantic function identity."""
from pathlib import Path
import bisect,difflib,hashlib,json,re
from fat12_guest_file import read_root_file
from target_fat12 import inspect
root=Path(__file__).resolve().parent.parent.parent;evidence=root/'extras/docs/etc/evidence'
report=json.loads((evidence/'m4-t5-clean-kernel-build.json').read_text())
stage=Path(report['stage']);reference=(stage/'ntdos.sys').read_bytes()
assert hashlib.sha256(reference).hexdigest()==report['output_sha256']
image=Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
manifest=inspect(image);target=read_root_file(image,'MSDOS.SYS')
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
origin=int.from_bytes(reference[3:5],'little')
symbols={}
for line in (stage/'ntdos.map').read_text().splitlines():
    m=re.match(r'\s*0000:([0-9A-Fa-f]{4})\s+(\S+)',line)
    if m:
        off=int(m.group(1),16)-origin
        if off>=0:symbols.setdefault(off,set()).add(m.group(2))
offsets=sorted(symbols);anchors=[]
for match in difflib.SequenceMatcher(None,reference,target,autojunk=False).get_matching_blocks():
    if match.size<24:continue
    block=reference[match.a:match.a+match.size]
    if reference.find(block,match.a+1)!=-1 or reference.find(block)!=match.a:continue
    if target.find(block,match.b+1)!=-1 or target.find(block)!=match.b:continue
    index=bisect.bisect_right(offsets,match.a)-1
    near=offsets[index] if index>=0 else None
    anchors.append({'reference_file_offset':match.a,'target_file_offset':match.b,'bytes':match.size,
                    'block_sha256':hashlib.sha256(block).hexdigest(),
                    'nearest_preceding_public':sorted(symbols[near]) if near is not None else [],
                    'distance_from_public':match.a-near if near is not None else None})
out={'reference_sha256':report['output_sha256'],'target_sha256':manifest['files']['MSDOS.SYS']['sha256'],
     'reference_origin':origin,'target_origin_header':int.from_bytes(target[3:5],'little'),
     'reference_entry_jump_file_destination':3+int.from_bytes(reference[1:3],'little',signed=True),
     'target_entry_jump_file_destination':3+int.from_bytes(target[1:3],'little',signed=True),
     'anchors':anchors,'matched_bytes_in_retained_blocks':sum(a['bytes'] for a in anchors),
     'limits':'Greedy monotonic exact blocks, length >=24, unique in both files. Nearest public is context only; blocks may be data or cross function boundaries. Not coverage of recovered source or proof of equivalent semantics.'}
(evidence/'m4-t5-kernel-anchors.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k!='anchors'},indent=2))
print(json.dumps(sorted(anchors,key=lambda a:-a['bytes'])[:8],indent=2))
