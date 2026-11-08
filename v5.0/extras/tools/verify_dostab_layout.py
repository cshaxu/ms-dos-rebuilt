"""Verify the restored EXEC allocation and initialized DOSTAB tail in native OMF.

The remaining NT EXEC extension is retained only to assemble this data probe.
This does not make its separated buffer ABI valid for NT msproc at runtime.
"""
from pathlib import Path
import hashlib,json,shutil,subprocess,tempfile
from target_kernel import read_target

root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
baseline=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text())
base=Path(baseline['stage'])
assert baseline['marker']=='PASS'
source=root/'dos/dostab.layout.recovery.asm'
reference=root.parent/'v6.0/dos/dostab.asm'
original=root/'dos/dostab.asm'
ref=reference.read_bytes();a=ref.index(b';smr; moved from TABLE segment')
z=ref.index(b';smr; eom',a)+len(b';smr; eom')
anchor=b';SR;\r\n; WIN386 instance table for DOS'
expected=original.read_bytes().replace(anchor,ref[a:z]+b'\r\n\r\n'+anchor)
expected=expected.replace(b'exec_init_sp, 0, 24',b'exec_init_sp, 0, 34')
expected=expected.replace(b'128,154,144,065,142,065,143,128',b'128,154,069,065,142,065,143,128',1)
assert source.read_bytes()==expected
stage=Path(tempfile.mkdtemp(prefix='dostab-layout-',dir=root/'extras/build'))
shutil.copytree(base/'src',stage/'src')
for p in base.glob('msdos.cl?'):shutil.copyfile(p,stage/p.name)
shutil.copyfile(source,stage/'src/dos/dostab.asm')
p=stage/'src/inc/lmstub.asm';t=p.read_bytes()
if b'\tI_am\texec_init_SP,WORD' in t:
    a=t.index(b'\tI_am\texec_init_SP,WORD');z=t.index(b'\tdb\t(EXEC_NEWHEADER_OFFSET',a)
    removed=t[a:z];p.write_bytes(t[:a]+t[z:])
else:
    # The integrated probe already removed the entire obsolete NT buffer.
    assert b'EXEC_NEWHEADER_OFFSET' not in t and b'exec_NE_offset' not in t
    removed=b''
shutil.copyfile(stage/'src/dos/msdata.asm',stage/'msdata.asm')
inputs={str(p.relative_to(stage)):sha(p) for p in stage.rglob('*') if p.is_file()}
tool=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
cmd=[str(tool),'-Mx','-t','-W1',*['-I'+d for d in
     ('.','src/dos','src/inc/kernel','src/inc','src/inc/ntvdm','src/dos/messages')],
     'msdata.asm,msdata.obj,msdata.lst;']
run=subprocess.run(cmd,cwd=stage,capture_output=True,timeout=30)
(stage/'assembly.log').write_bytes(run.stdout+run.stderr)
assert run.returncode==0,(run.stdout+run.stderr).decode(errors='replace')
assert all(sha(stage/p)==h for p,h in inputs.items())

def index(b,i):
    if b[i]&128:return ((b[i]&127)*256+b[i+1],i+2)
    return b[i],i+1

start,end=0xfe2,0x1061
data=bytearray(end-start);covered=set();fixups=[];publics={};names=[];segments=[]
raw=(stage/'msdata.obj').read_bytes();pos=0;segment=offset=None
while pos<len(raw):
    k=raw[pos];n=int.from_bytes(raw[pos+1:pos+3],'little')
    record=raw[pos:pos+3+n];pos+=3+n;assert sum(record)%256==0
    b=record[3:-1];i=0
    if k==0x96:
        while i<len(b):n=b[i];i+=1;names.append(b[i:i+n].decode());i+=n
    elif k==0x98:
        if b[0]>>5==0:segments.append(None);continue
        length=int.from_bytes(b[1:3],'little');name,_=index(b,3)
        segments.append((names[name-1],length))
    elif k==0x90:
        group,i=index(b,0);seg,i=index(b,i)
        if seg==0:i+=2
        while i<len(b):
            n=b[i];i+=1;name=b[i:i+n].decode().lower();i+=n
            value=int.from_bytes(b[i:i+2],'little');i+=2;_,i=index(b,i)
            if seg==3:publics[name]=value
    elif k==0xa0:
        segment,i=index(b,0);offset=int.from_bytes(b[i:i+2],'little');payload=b[i+2:]
        if segment==3:
            for j,v in enumerate(payload):
                at=offset+j
                if start<=at<end:
                    assert at not in covered;covered.add(at);data[at-start]=v
    elif k==0x9c:
        while i<len(b):
            loc=b[i];off=((loc&3)<<8)+b[i+1];flags=b[i+2];i+=3
            assert loc&128
            frame,i=index(b,i);dest,i=index(b,i);disp=0
            if not flags&4:disp=int.from_bytes(b[i:i+2],'little');i+=2
            at=offset+off
            if segment!=3 or not start<=at<end:continue
            assert at+1<end and ((loc>>2)&15)==1 and loc&64
            assert flags==0 and frame==dest==3
            value=int.from_bytes(data[at-start:at-start+2],'little')+disp
            data[at-start:at-start+2]=value.to_bytes(2,'little')
            fixups.append({'operand':at,'segment':'DOSDATA','value':value})
assert segments[2][0]=='DOSDATA' and covered==set(range(start,end))
anchors={'exec_init_sp':0xfc0,'exec_init_ss':0xfc2,'exec_init_ip':0xfc4,
         'exec_init_cs':0xfc6,'exec_signature':0xfc8,'exec_rle_table':0xfe0,
         'win386_info':0xfe2,'instance_table':0xff4,'win386_dosvars':0x1022,
         'iswin386':0x1030,'vxdpath':0x1031,'localsft':0x105d}
assert all(publics[k]==v for k,v in anchors.items()),anchors
msproc=root/'dos/msproc.asm'
consumer=msproc.read_bytes()
assert b'mov\tcx, Exec_Header_Len_NE' in consumer
assert b'mov\tDX,OFFSET DosData:Exec_Signature' in consumer
nt_read_end=anchors['exec_signature']+0x3e
assert nt_read_end-anchors['win386_info']==36
target,target_source=read_target(root)
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
expected=target[0x7eb0+start:0x7eb0+end]
diffs=[i+start for i,(a,b) in enumerate(zip(data,expected)) if a!=b]
out={'target_source':target_source,'stage':str(stage),'source':str(source),'source_sha256':sha(source),
     'nt_derived_original_sha256':sha(original),'reference_sha256':sha(reference),
     'inputs':inputs,'tool_sha256':sha(tool),'command':cmd,'exit':run.returncode,
     'object_sha256':sha(stage/'msdata.obj'),'allocation_bytes':34,'anchors':anchors,
     'initialized_range':[start,end],'initialized_bytes':len(data),'fixups':fixups,
     'candidate_sha256':hashlib.sha256(data).hexdigest(),
     'target_sha256':hashlib.sha256(expected).hexdigest(),'differences':diffs,
     'exact':not diffs,'probe_removed_block_sha256':hashlib.sha256(removed).hexdigest(),
     'unresolved_nt_consumer':{'source':str(msproc),'source_sha256':sha(msproc),
         'read_start':anchors['exec_signature'],'read_size':0x3e,
         'read_end_exclusive':nt_read_end,'would_overwrite_win386_bytes':36,
         'disposition':'Recover DOS 5 EXEC header-loading path before promoting this layout; do not retain NT extended-header read.'},
     'scope':'Native OMF initialized DOSTAB tail at target offsets and 34-byte EXEC allocation. Not linked/runtime verification. NT extended-header ABI remains incompatible with this split probe layout; production unchanged.'}
(e/'m4-t5-dostab-layout-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:out[k] for k in ('stage','allocation_bytes','initialized_bytes','anchors','differences','exact')},indent=2))
assert not diffs
