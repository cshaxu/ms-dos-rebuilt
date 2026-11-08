"""Finite actual-link verification of the 39 frozen physical-storage units."""
from pathlib import Path
import hashlib,json,subprocess,sys
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
subprocess.run([sys.executable,str(root/'extras/tools/audit_storage_closure.py')],check=True,timeout=30,capture_output=True)
graph=e/'m4-t5-storage-closure-audit.json';g=json.loads(graph.read_text())
modules=[r['module'] for r in g['candidates']]
assert len(modules)==len(set(modules))==39
link=e/'m4-t5-physical-sft-link-probe.json';linkhash=sha(link)
rows=[];target_bytes=set();linked_bytes=set()
for name in modules:
    run=subprocess.run([sys.executable,str(root/'extras/tools/verify_probe_candidate.py'),'--module',name],
                       capture_output=True,text=True,timeout=30)
    assert run.returncode==0,(name,run.stdout,run.stderr)
    proof=e/f'm4-t5-{name}-probe-linked-verification.json'
    p=json.loads(proof.read_text());assert p['correspondence'] and not p['remaining_differences']
    assert p['link_report_sha256']==linkhash
    candidate=e/f'm4-t5-{name}-verification.json';c=json.loads(candidate.read_text())
    assert sha(candidate)==p['candidate_proof_sha256']
    a=set(range(c['target_start'],c['target_end']))
    b=set(range(p['linked_start'],p['linked_start']+p['bytes']))
    assert len(a)==len(b)==p['bytes'] and not a&target_bytes and not b&linked_bytes
    target_bytes|=a;linked_bytes|=b
    rows.append({'module':name,'proof':proof.name,'proof_sha256':sha(proof),
                 'target_range':[c['target_start'],c['target_end']],
                 'linked_range':[p['linked_start'],p['linked_start']+p['bytes']],
                 'bytes':p['bytes'],'fixups':len(p['named_fixups']),
                 'public_anchors':len(p['public_anchors']),'verified':True})
assert sha(link)==linkhash and all(row['verified'] for row in rows)
out={'universe':modules,'universe_source_sha256':sha(graph),'link_report_sha256':linkhash,
     'rows':rows,'unique_target_bytes':len(target_bytes),'unique_linked_bytes':len(linked_bytes),
     'total_fixups':sum(x['fixups'] for x in rows),'complete_for_declared_universe':True,
     'scope':'36 complete modules plus three DEV slices, verified in the actual linked probe with named OMF relocation adjustments. Excludes other kernel modules, transitive callee correctness, global layout identity, runtime and IO.SYS.'}
(e/'m4-t5-physical-storage-linked-suite.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:out[k] for k in ('unique_target_bytes','unique_linked_bytes','total_fixups','complete_for_declared_universe')},indent=2))
