"""Verify restored INT 21 error map and target-relative ordered entry points."""
from pathlib import Path
import hashlib,json,re
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-dos6-order-probe.json').read_text());assert r['marker']=='PASS'
assert sha(e/'m4-t5-physical-sft-link-probe.json')==r['link_report_sha256']
stage=Path(r['stage']);candidate=(stage/'order.sys').read_bytes();assert sha(stage/'order.sys')==r['output_sha256']
target,source=read_target(root);mapping=(stage/'order.map').read_text()
symbols={m[2].lower():int(m[1],16) for m in re.finditer(r'^\s*0000:([0-9A-F]{4})\s+(\S+)\s*$',mapping,re.M)}
origin=int.from_bytes(candidate[3:5],'little')
expected={'command':0x31b,'$ioctl':0x235e,'$wait':0x5d2a,'dskstatchk':0x5254}
actual={name:symbols[name]-origin for name in expected}
assert actual==expected
start,end=0xb,0xbe
assert candidate[start:end]==target[start:end]
assert candidate[0x95:0x9b]==bytes.fromhex('5c0406012421')
table_start,table_end=0x19c,0x1fd
assert candidate[table_start]==0x30
assert candidate[table_start:table_end]==target[table_start:table_end]
out={'stage':str(stage),'target_source':source,'order_report_sha256':sha(e/'m4-t5-dos6-order-probe.json'),
     'map_sha256':sha(stage/'order.map'),'candidate_sha256':sha(stage/'order.sys'),
     'target_range':[start,end],'raw_exact_bytes':end-start,'lock_entry_offset':0x95,
     'internal_dispatch_range':[table_start,table_end],'internal_dispatch_raw_exact_bytes':table_end-table_start,
     'normalized_entry_offsets':actual,'scope':'Bounded raw INT 21 error map, internal dispatch table and four normalized linked addresses. Not whole-kernel or runtime acceptance.'}
(e/'m4-t5-ordered-error-table-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
