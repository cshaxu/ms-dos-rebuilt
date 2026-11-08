"""Resolve complete MSPROC at pinned target symbol placements, not runtime ABI."""
from pathlib import Path
import contextlib,hashlib,io,json,re,runpy
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Also verifies the two independently bounded header/read-chain slices.
with contextlib.redirect_stdout(io.StringIO()):g=runpy.run_path(str(root/'extras/tools/verify_exec_header.py'))
bindings=e/'m4-t5-msproc-target-bindings.json';b=json.loads(bindings.read_text())
start,end=0x5d2a,0x63f2;origin=0x3dd0
assert g['covered']==set(range(end-start))
image=bytearray(g['image'][:end-start]);target=g['target'];fixups=[]
assert target[3:5]==origin.to_bytes(2,'little')
old=json.loads((e/'m4-t5-lock-build.json').read_text());mp=Path(old['stage'])/'ntdos.map'
assert sha(mp)==old['map_sha256']
syms={m[2].lower():int(m[1],16) for m in re.finditer(r'^\s*[0-9A-F]{4}:([0-9A-F]{4})\s+(\S+)',mp.read_text(),re.M)}
differences_in_data=[]
for name,row in b['data'].items():
    if name=='exec_header_len':assert row['value']==26;continue
    if syms[name]!=row['value']:
        differences_in_data.append({'symbol':name,'production':syms[name],'target':row['value']})
for at,loc,flags,frame,dest,disp in g['relocs']:
    relative=not bool(loc&64);addend=int.from_bytes(image[at:at+2],'little')
    if flags&2:
        name=g['ext'][dest-1]
        table=b['code'] if name in b['code'] else b['data'];binding=table[name]
        assert (flags&~4)==(binding['flags']&~4) and (frame==dest if flags==0x26 else frame==binding['frame']),(name,hex(at),flags,frame,binding)
        value=binding['value']+disp+addend
        # Independently inspect each named code-address witness.
        if table is b['code']:
            if name=='dosdseg':
                assert not relative and value==origin+7
                assert target[start+at-3:start+at]==bytes.fromhex('2e8e1e')
            elif name=='leavedos':
                assert not relative and target[start+at-1]==0xb9
            else:
                assert relative and target[start+at-1] in (0xe8,0xe9)
    else:
        assert flags in (0,4) and frame==dest==1
        name='DOSCODE';value=start+disp+addend
        if not relative:value+=origin
    if relative:value-=start+at+2
    image[at:at+2]=(value&65535).to_bytes(2,'little')
    fixups.append({'offset':at,'symbol':name,'relative':relative,'value':value&65535})
expected=target[start:end]
(g['stage']/'msproc.resolved.bin').write_bytes(image)
diffs=[{'offset':i,'candidate':a,'target':b} for i,(a,b) in enumerate(zip(image,expected)) if a!=b]
out={'stage':str(g['stage']),'source':str(g['source']),'source_sha256':sha(g['source']),
     'reference_sha256':sha(g['reference']),'object_sha256':sha(g['stage']/'buf.obj'),
     'bindings_sha256':sha(bindings),'header_proof_sha256':sha(e/'m4-t5-exec-header-verification.json'),
     'target_range':[start,end],'bytes':len(image),'fixups':fixups,'data_layout_differences':differences_in_data,
     'differences':diffs,'exact':not diffs,'candidate_sha256':hashlib.sha256(image).hexdigest(),
     'target_slice_sha256':hashlib.sha256(expected).hexdigest(),
     'scope':'Whole native MSPROC object at pinned target symbol placements. Some symbol attributions inferred from target operands; actual production data placement and linked/runtime behavior are not verified.'}
(e/'m4-t5-msproc-full-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'bytes':len(image),'fixups':len(fixups),'data_layout_differences':differences_in_data,'differences':diffs,'exact':not diffs},indent=2))
assert not diffs
