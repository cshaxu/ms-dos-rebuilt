"""Compare ordered probe DOSDATA with pinned target at their own segment bases."""
from pathlib import Path
import hashlib,json,re
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-dos6-order-probe.json').read_text());assert r['marker']=='PASS'
stage=Path(r['stage']);sys=stage/'order.sys';mp=stage/'order.map'
assert sha(sys)==r['output_sha256']
probe=sys.read_bytes();target,source=read_target(root)
match=re.search(r'^\s*([0-9A-F]+)H\s+([0-9A-F]+)H\s+([0-9A-F]+)H\s+DOSDATA\s+DATA',mp.read_text(),re.M|re.I)
assert match
begin,stop,length=(int(x,16) for x in match.groups());assert stop-begin+1==length
origin=int.from_bytes(probe[3:5],'little');file_start=begin-origin
target_start=0x7eb0;size=len(target)-target_start
assert file_start>=0 and len(probe)>=file_start+size
a=target[target_start:];b=probe[file_start:file_start+size]
diff=[i for i,(x,y) in enumerate(zip(a,b)) if x!=y]
ranges=[]
for i in range(0,size,0x200):
    z=min(i+0x200,size);ranges.append({'start':i,'end':z,'different_bytes':sum(a[j]!=b[j] for j in range(i,z))})
out={'stage':str(stage),'order_report_sha256':sha(e/'m4-t5-dos6-order-probe.json'),
     'map_sha256':sha(mp),'probe_sha256':sha(sys),'target_source':source,
     'target_sha256':hashlib.sha256(target).hexdigest(),
     'target_data_file_start':target_start,'probe_data_file_start':file_start,
     'target_data_bytes':size,'probe_segment_bytes':length,
     'different_bytes':len(diff),'difference_offsets':diff,'blocks':ranges,
     'scope':'Raw comparison after segment-base alignment only; no relocations masked. Target trailing bytes may be initialized data or residual bytes; their origin is not inferred. Not runtime or full-file identity.'}
(e/'m4-t5-ordered-data-differences.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:out[k] for k in ('target_data_file_start','probe_data_file_start','target_data_bytes','probe_segment_bytes','different_bytes','blocks')},indent=2))
