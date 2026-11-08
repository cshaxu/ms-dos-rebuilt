"""Raw linked low-memory A20/interrupt stub comparison; no runtime claim."""
from pathlib import Path
import hashlib,json,re
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
p=json.loads((e/'m4-t5-physical-sft-probe.json').read_text())
assert sha(e/'m4-t5-physical-sft-probe.json')==r['probe_report_sha256']
stage=Path(r['stage']);assert str(stage)==p['stage']
for name,h in r['outputs'].items():assert sha(stage/name)==h
for name in ('msdata.obj','msdata.lst'):assert sha(stage/name)==r['inputs'][name]
source=root/'extras/research/inc/lmstub.tail.recovery.asm'
assert sha(source)==p['overlays']['lmstub']['sha256']
assert sha(stage/'src/inc/lmstub.asm')==p['probe_adjustments']['src\\inc\\lmstub.asm']
assert (stage/'src/inc/lmstub.asm').read_bytes()==source.read_bytes()
syms={m[3].lower():(int(m[1],16),int(m[2],16)) for m in re.finditer(
    r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',(stage/'probe.map').read_text(),re.M)}
raw=(stage/'probe.exe').read_bytes();assert raw[:2]==b'MZ'
load=raw[int.from_bytes(raw[8:10],'little')*16:]
segment=syms['ldivov'][0];start,end=0x108a,0x122a
anchors={'ldivov':start,'lirett':0x10da,'disa20_xfer':0x1115,
         'disa20_iret':0x112d,'oldinstancejunk':0x11e7,
         'doshashma':0x1211,'fixexepatch':0x1212,'mark3':end}
assert all(syms[n]==(segment,o) for n,o in anchors.items())
target,target_source=read_target(root)
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
actual=load[segment*16+start:segment*16+end];expected=target[0x7eb0+start:0x7eb0+end]
assert len(actual)==len(expected)==end-start
diffs=[i+start for i,(a,b) in enumerate(zip(actual,expected)) if a!=b]
out={'target_source':target_source,'stage':str(stage),'source_sha256':sha(source),
     'nt_reference_sha256':sha(root/'inc/lmstub.asm'),
     'dos6_reference_sha256':sha(root.parent/'v6.0/inc/lmstub.asm'),
     'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),
     'range':[start,end],'raw_bytes':len(actual),'anchors':anchors,
     'candidate_sha256':hashlib.sha256(actual).hexdigest(),
     'target_sha256':hashlib.sha256(expected).hexdigest(),'differences':diffs,'raw_exact':not diffs,
     'scope':'Actual linked low-memory interrupt/A20 stubs, Windows 2.x instance table, HMA flag, patch slots and reserve through Mark3. No relocation masking. DOSINTTABLE code pointers before this range and NT tail after it are excluded; no runtime acceptance.'}
(e/'m4-t5-lmstub-probe-linked-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert not diffs
