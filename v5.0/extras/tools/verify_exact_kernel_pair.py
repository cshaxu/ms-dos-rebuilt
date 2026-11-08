"""Verify two independent physical-kernel builds against the pinned extract."""
from pathlib import Path
import hashlib,json
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
first=json.loads((e/'m4-t5-exact-kernel-run1.json').read_text())
second=json.loads((e/'m4-t5-dos6-order-probe.json').read_text())
assert first['marker']==second['marker']=='PASS' and first['exact'] and second['exact']
assert first['stage']!=second['stage']
target,source=read_target(root);outputs=[]
for r in (first,second):
    p=Path(r['stage'])/'order.sys';b=p.read_bytes()
    assert b==target and sha(p)==r['output_sha256']==hashlib.sha256(target).hexdigest()
    outputs.append({'stage':r['stage'],'bytes':len(b),'sha256':sha(p)})
frozen=json.loads((e/'m4-t5-exact-kernel-run1-inputs.json').read_text())
first_stage=Path(frozen['stage'])
second_probe=json.loads((e/'m4-t5-physical-sft-probe.json').read_text());second_stage=Path(second_probe['stage'])
assert first_stage!=second_stage
current={str(p.relative_to(second_stage)):sha(p) for p in sorted((second_stage/'src').rglob('*')) if p.is_file()}
assert current==frozen['inputs']
assert all(sha(first_stage/name)==digest for name,digest in frozen['inputs'].items())
out={'target_source':source,'target_sha256':hashlib.sha256(target).hexdigest(),
     'outputs':outputs,'independent_staged_sources':len(current),'source_snapshots_identical':True,
     'run1_report_sha256':sha(e/'m4-t5-exact-kernel-run1.json'),
     'run1_inputs_sha256':sha(e/'m4-t5-exact-kernel-run1-inputs.json'),
     'run2_report_sha256':sha(e/'m4-t5-dos6-order-probe.json'),
     'scope':'Two independent private build stages produce byte-identical MSDOS.SYS to the pinned extracted target. Source is a staged reconstruction, original media was not readable, and standalone boot, IO.SYS and package acceptance remain unverified.'}
(e/'m4-t5-exact-kernel-pair-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
