"""Audit named code dependencies of the frozen physical storage candidates."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
modules=('macro2-full','util-full','srvcall-full','alloc-full','macro-full','cpmio-full','msdisp-full','cpmio2-full','msctrlc-full','mscode-full','misc-full','dinfo-full','getset-full','ioctl-full','path-full','search-full','disk-full','disk2-full','disk3-full','rom-full','mknode','dircall','share','create-full','dev-iofunc','dev-openclose','dev-io','delete-full','lock-full','close-full','finfo-full','rename-full','open-full','isearch-full','abort-full','handle-full','file-full','fcbio-full','fcbio2-full')
def index(b,p):
    if b[p]&128:return ((b[p]&127)*256+b[p+1],p+2)
    return b[p],p+1
def publics(path):
    data=path.read_bytes();pos=0;out={}
    while pos<len(data):
        kind=data[pos];n=int.from_bytes(data[pos+1:pos+3],'little');record=data[pos:pos+3+n];pos+=3+n
        assert sum(record)%256==0
        if kind!=0x90:continue
        b=record[3:-1];group,i=index(b,0);seg,i=index(b,i)
        if seg==0:i+=2
        while i<len(b):
            n=b[i];i+=1;name=b[i:i+n].decode().upper();i+=n
            offset=int.from_bytes(b[i:i+2],'little');i+=2;_,i=index(b,i)
            if seg==1:out[name]=offset
    return out
b=json.loads((e/'m4-t5-lock-build.json').read_text());mp=Path(b['stage'])/'ntdos.map';assert sha(mp)==b['map_sha256']
linked={m[1].upper() for m in re.finditer(r'^\s*0000:[0-9A-F]{4}\s+(\S+)',mp.read_text(),re.M)}
providers={};rows=[]
for module in modules:
    p=e/f'm4-t5-{module}-verification.json';r=json.loads(p.read_text());assert r['exact']
    assert sha(Path(r['source']))==r['source_sha256']
    obj=Path(r['stage'])/'buf.obj';assert sha(obj)==r['object_sha256']
    exports=publics(obj)
    for name,offset in exports.items():
        assert name not in providers,(name,module,providers[name])
        providers[name]={'module':module,'target_offset':r['target_start']+offset}
    rows.append({'module':module,'proof':p.name,'proof_sha256':sha(p),'bytes':r['bytes'],'exports':exports,'imports':r['external_code_target_attributions']})
edges=[]
for row in rows:
    for name,(site,target) in row['imports'].items():
        provider=providers.get(name)
        if provider:assert provider['target_offset']==target,(name,provider,target)
        edges.append({'caller':row['module'],'symbol':name,'target':target,'candidate_provider':provider,'present_in_accepted_map':name in linked})
missing=sorted({x['symbol'] for x in edges if not x['candidate_provider'] and not x['present_in_accepted_map']})
snap={}
for report in ('m4-t5-lock-build.json','m2-t3-command-exact-verification.json'):
    d=json.loads((e/report).read_text())['source_snapshot'];bad=[p for p,h in d.items() if sha(root/p)!=h];assert not bad
    snap[report]={'inputs':len(d),'mismatches':bad}
out={'build':'m4-t5-lock-build.json','candidates':rows,'edges':edges,'missing_named_code_providers':missing,'snapshots':snap,'scope':'Frozen candidate code-name graph with native OMF public offsets checked against decoded target call addresses. Existing linked symbol presence is not callee correctness. Does not cover data ABI, indirect calls, all transitive runtime dependencies, or production integration.'}
(e/'m4-t5-storage-closure-audit.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'modules':len(rows),'edges':len(edges),'missing_named_code_providers':missing,'snapshots':snap},indent=2))
