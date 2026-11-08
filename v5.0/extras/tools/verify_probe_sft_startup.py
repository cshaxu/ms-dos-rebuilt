"""Check physical SFT initialization and abort in the actual linked probe EXE."""
from pathlib import Path
import hashlib,json,re
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
stage=Path(r['stage'])
for name,digest in r['outputs'].items():assert sha(stage/name)==digest
raw=(stage/'probe.exe').read_bytes();assert raw[:2]==b'MZ'
load=raw[int.from_bytes(raw[8:10],'little')*16:]
syms={m[2].lower():int(m[1],16) for m in re.finditer(r'^\s*0000:([0-9A-F]{4})\s+(\S+)',(stage/'probe.map').read_text(),re.M)}
t,target_source=read_target(root)
assert hashlib.sha256(t).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
lst=stage/'msinit.lst';assert sha(lst)==r['inputs']['msinit.lst']
s=lst.read_text(errors='replace')
a=re.search(r'^\s*([0-9A-F]{4})\s+.*DosInit:',s,re.M|re.I)
z=re.search(r'^\s*([0-9A-F]{4})\s+BF 0006 E[^\n]*sftabl',s,re.M|re.I)
assert a and z
start=syms['dosinit']-int(a[1],16)+int(z[1],16)
assert load[start:start+51]==t[0x7a60:0x7a93]
abort_start=syms['dos_abort'];expected=bytearray(t[0x2fdd:0x304a]);edges=[]
for site,name,dest in ((0x2feb,'$close',0x68fb),(0x3021,'sffromsfn',0x6874)):
    i=site-0x2fdd;actual=load[abort_start+i:abort_start+i+3]
    assert actual[0]==expected[i]==0xe8
    assert (site+3+int.from_bytes(expected[i+1:i+3],'little',signed=True))&65535==dest
    assert (abort_start+i+3+int.from_bytes(actual[1:],'little',signed=True))&65535==syms[name]
    expected[i+1:i+3]=((syms[name]-abort_start-i-3)&65535).to_bytes(2,'little')
    edges.append({'symbol':name,'linked_offset':syms[name]})
assert load[abort_start:abort_start+109]==expected
out={'target_source':target_source,'link_report':'m4-t5-physical-sft-link-probe.json','stage':str(stage),'sft_init':{'target_start':0x7a60,'linked_code_offset':start,'bytes':51,'raw_exact':True},'abort':{'target_start':0x2fdd,'linked_code_offset':abort_start,'bytes':109,'relocation_correspondence':True,'named_calls':edges},'scope':'Actual linked MZ load-image slices only; not runtime, complete startup, physical data layout, or whole-kernel acceptance.'}
(e/'m4-t5-sft-init-abort-linked-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
