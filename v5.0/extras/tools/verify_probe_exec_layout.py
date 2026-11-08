"""Verify linked MSPROC and raw DOSTAB tail in the physical-SFT probe."""
from pathlib import Path
import hashlib,json,re
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
c=json.loads((e/'m4-t5-msproc-full-verification.json').read_text());assert c['exact']
b=json.loads((e/'m4-t5-msproc-target-bindings.json').read_text())
assert sha(e/'m4-t5-msproc-target-bindings.json')==c['bindings_sha256']
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
stage=Path(r['stage'])
for name,h in r['outputs'].items():assert sha(stage/name)==h
assert sha(stage/'msproc.asm')==sha(Path(c['source']))==c['source_sha256']==r['inputs']['msproc.asm']
syms={m[3].lower():(int(m[1],16),int(m[2],16)) for m in re.finditer(
    r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(?:Abs\s+)?(\S+)',(stage/'probe.map').read_text(),re.M)}
raw=(stage/'probe.exe').read_bytes();assert raw[:2]==b'MZ'
load=raw[int.from_bytes(raw[8:10],'little')*16:]
expected=bytearray((Path(c['stage'])/'msproc.resolved.bin').read_bytes())
assert hashlib.sha256(expected).hexdigest()==c['target_slice_sha256']
start=syms['$wait'][1];assert syms['$wait'][0]==0
target_start=c['target_range'][0];fixups=[]
for x in c['fixups']:
    i=x['offset'];name=x['symbol'];value=x['value'];relative=x['relative']
    assert int.from_bytes(expected[i:i+2],'little')==value
    if name=='DOSCODE':old=target_start+(0 if relative else 0x3dd0);new=start
    else:
        old=(b['code'] if name in b['code'] else b['data'])[name]['value']
        new=syms[name][1]
    value+=new-old
    if relative:value-=start-target_start
    expected[i:i+2]=(value&65535).to_bytes(2,'little')
    fixups.append({'offset':i,'symbol':name,'old':old,'new':new,'relative':relative})
actual=load[start:start+len(expected)];assert len(actual)==len(expected)
diffs=[i for i,(a,b) in enumerate(zip(actual,expected)) if a!=b]
d=json.loads((e/'m4-t5-dostab-layout-verification.json').read_text());assert d['exact']
assert sha(stage/'src/dos/dostab.asm')==sha(Path(d['source']))==d['source_sha256']
anchors={name:{'target':offset,'linked':syms[name][1]} for name,offset in d['anchors'].items()}
assert all(v['target']==v['linked'] for v in anchors.values())
data_seg=syms['win386_info'][0]*16
target,target_source=read_target(root)
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
a,z=d['initialized_range'];tail=load[data_seg+a:data_seg+z]
assert tail==target[0x7eb0+a:0x7eb0+z]
remaining=[{'symbol':x['symbol'],'target':x['target'],'linked':syms[x['symbol']][1]}
           for x in c['data_layout_differences'] if syms[x['symbol']][1]!=x['target']]
out={'target_source':target_source,'stage':str(stage),'candidate_proof_sha256':sha(e/'m4-t5-msproc-full-verification.json'),
     'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),
     'bytes':len(expected),'fixups':fixups,'differences':diffs,'correspondence':not diffs,
     'dostab_raw_exact_bytes':len(tail),'anchors':anchors,'remaining_data_differences':remaining,
     'scope':'Complete actual linked MSPROC with only candidate OMF fixups adjusted; raw exact DOSTAB initialized tail and allocation offsets. Not whole-kernel identity or runtime acceptance.'}
(e/'m4-t5-exec-layout-probe-linked-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:out[k] for k in ('stage','bytes','differences','dostab_raw_exact_bytes','remaining_data_differences')},indent=2))
assert not diffs
