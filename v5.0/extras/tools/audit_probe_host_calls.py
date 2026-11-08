"""Inventory emitted BOP encodings with listing and actual-link witnesses."""
from pathlib import Path
import argparse,hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
ap=argparse.ArgumentParser();ap.add_argument('--report',default='m4-t5-probe-host-calls.json');args=ap.parse_args()
assert Path(args.report).name==args.report
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
s=Path(r['stage'])
for n,h in r['outputs'].items():assert sha(s/n)==h
syms={m[3].lower():(int(m[1],16),int(m[2],16)) for m in re.finditer(r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',(s/'probe.map').read_text(),re.M)}
raw=(s/'probe.exe').read_bytes();load=raw[int.from_bytes(raw[8:10],'little')*16:]
def index(b,i):
    if b[i]&128:return ((b[i]&127)*256+b[i+1],i+2)
    return b[i],i+1
rows=[]
for name in r['module_order']:
    for ext in ('obj','lst'):assert sha(s/f'{name}.{ext}')==r['inputs'][f'{name}.{ext}']
    raw=(s/f'{name}.obj').read_bytes();pos=0;segments={};publics=[]
    while pos<len(raw):
        k=raw[pos];n=int.from_bytes(raw[pos+1:pos+3],'little');record=raw[pos:pos+3+n];pos+=n+3
        assert sum(record)%256==0;b=record[3:-1]
        if k==0xa0:
            seg,i=index(b,0);off=int.from_bytes(b[i:i+2],'little');payload=b[i+2:]
            im,cov=segments.setdefault(seg,(bytearray(65536),set()))
            im[off:off+len(payload)]=payload;cov.update(range(off,off+len(payload)))
        elif k==0x90:
            group,i=index(b,0);seg,i=index(b,i)
            if seg==0:i+=2
            while i<len(b):
                n=b[i];i+=1;label=b[i:i+n].decode().lower();i+=n
                off=int.from_bytes(b[i:i+2],'little');i+=2;_,i=index(b,i)
                if seg==1:publics.append((label,off))
    listing=(s/f'{name}.lst').read_text().splitlines()
    for seg,(im,cov) in segments.items():
        at=0
        while (at:=im.find(b'\xc4\xc4',at))>=0:
            assert seg==1 and set(range(at,at+3))<=cov
            starts={syms[n][1]-o for n,o in publics if syms[n][0]==0};assert len(starts)==1
            linked=starts.pop()+at
            assert load[linked:linked+3]==im[at:at+3]
            hits=[i for i,line in enumerate(listing) if re.match(r'^ '+f'{at:04X}'+r'\s+C4 C4 ',line)]
            assert len(hits)==1,(name,at)
            i=hits[0]
            rows.append({'module':name,'object_offset':at,'linked_offset':linked,
                         'opcode':im[at:at+3].hex(),'service':im[at+3] if im[at+2]==0x50 else None,
                         'listing_line':i+1,'listing_context':listing[max(0,i-3):i+2]})
            at+=2
out={'stage':str(s),'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),
     'universe':r['module_order'],'sites':rows,'count':len(rows),'modules_with_sites':sorted({x['module'] for x in rows}),
     'scope':'C4 C4 BOP encodings in all linked input LEDATA, confirmed by emitted listings and actual linked bytes. Does not inventory other host dependencies, indirect calls or runtime reachability.'}
(e/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'count':len(rows),'modules':out['modules_with_sites']},indent=2))
