"""Verify the linked DOS buffer-hash initialization against the target."""
from pathlib import Path
import hashlib,json,re
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
stage=Path(r['stage'])
for n,h in r['outputs'].items():assert sha(stage/n)==h
lst=stage/'msinit.lst';assert sha(lst)==r['inputs']['msinit.lst']
text=lst.read_text(errors='replace')
a=re.search(r'^\s*([0-9A-F]{4})\s+.*DosInit:',text,re.M|re.I)
b=re.search(r'^\s*([0-9A-F]{4})\s+.*mov\s+word ptr es:\[buffhead\+2\],es',text,re.M|re.I)
assert a and b
mapping=(stage/'probe.map').read_text();m=re.search(r'^\s*0000:([0-9A-F]{4})\s+DosInit\s*$',mapping,re.M|re.I);assert m
start=int(m[1],16)-int(a[1],16)+int(b[1],16)
raw=(stage/'probe.exe').read_bytes();assert raw[:2]==b'MZ'
load=raw[int.from_bytes(raw[8:10],'little')*16:];target,source=read_target(root)
expected=target[0x7c3e:0x7c4b];actual=load[start:start+len(expected)]
assert actual==expected==bytes.fromhex('268c063a00be6d002689363800')
out={'stage':str(stage),'target_source':source,'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),
     'source_sha256':sha(root/'dos/msinit.physical.recovery.asm'),'target_range':[0x7c3e,0x7c4b],
     'linked_start':start,'bytes':len(expected),'raw_exact':True,
     'scope':'Thirteen actual linked initialization bytes only; not full initialization or runtime acceptance.'}
(e/'m4-t5-hash-init-probe-linked-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
