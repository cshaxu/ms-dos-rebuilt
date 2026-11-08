"""Inventory target code ranges covered by the current linked probe proofs."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
suite=e/'m4-t5-physical-storage-linked-suite.json';s=json.loads(suite.read_text())
link=e/'m4-t5-physical-sft-link-probe.json';linkhash=sha(link)
assert s['complete_for_declared_universe'] and s['link_report_sha256']==linkhash
spans=[{'start':r['target_range'][0],'end':r['target_range'][1],
        'source':r['proof'],'proof_sha256':r['proof_sha256']} for r in s['rows']]
for name,start,end in (('m4-t5-exec-layout-probe-linked-verification.json',0x5d2a,0x63f2),
                       ('m4-t5-sft-init-abort-linked-verification.json',0x7a60,0x7a93),
                       ('m4-t5-hash-init-probe-linked-verification.json',0x7c3e,0x7c4b)):
    p=e/name;r=json.loads(p.read_text());assert r['stage']==json.loads(link.read_text())['stage']
    if 'link_report_sha256' in r:assert r['link_report_sha256']==linkhash
    spans.append({'start':start,'end':end,'source':name,'proof_sha256':sha(p)})
spans.sort(key=lambda x:x['start']);cursor=0;gaps=[]
for x in spans:
    assert cursor<=x['start']<x['end']<=0x7eb0
    if cursor<x['start']:gaps.append({'start':cursor,'end':x['start'],'bytes':x['start']-cursor})
    cursor=x['end']
if cursor<0x7eb0:gaps.append({'start':cursor,'end':0x7eb0,'bytes':0x7eb0-cursor})
out={'target_range':[0,0x7eb0],'suite_sha256':sha(suite),'link_sha256':linkhash,
     'covered':spans,'gaps':gaps,'covered_bytes':sum(x['end']-x['start'] for x in spans),
     'gap_bytes':sum(x['bytes'] for x in gaps),
     'scope':'Coverage by this linked-proof set only. Gaps may have other bounded or production proofs; covered bytes use declared relocation adjustments and do not imply original layout, complete code semantics, runtime or whole-file equality.'}
assert out['covered_bytes']+out['gap_bytes']==0x7eb0
(e/'m4-t5-probe-code-coverage.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'covered_bytes':out['covered_bytes'],'gap_bytes':out['gap_bytes'],'gaps':gaps},indent=2))
