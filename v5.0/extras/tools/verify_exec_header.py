"""Verify DOS 5 EXEC header and read/ownership chain from full source OMF.

The full comparative MSPROC candidate remains unverified outside these slices.
"""
from pathlib import Path
import hashlib,json,os,re,shutil,subprocess,tempfile
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=root/'dos/msproc.full.recovery.asm';reference=root.parent/'v6.0/dos/msproc.asm'
expected_source=reference.read_bytes()
for before,after in ((b'\tLeaveCrit   CritMem',b'\tinvoke\tLcritMem'),
                     (b'\tEnterCrit   CritMEM',b'\tinvoke\tEcritMem'),
                     (b'\tLeaveCrit   CritMEM',b'\tinvoke\tLcritMem')):
    assert expected_source.count(before)==1
    expected_source=expected_source.replace(before,after)
expected_source=expected_source.replace(b'\tcall\tword ptr [Rational386PatchPtr]\r\n',b'')
expected_source=expected_source.replace(b'cmp     AX,200h                 ; enough memory for PSP and stack?',b'cmp     AX,100h                 ; enough memory for PSP?')
expected_source=expected_source.replace(b'\textrn\tRational386PatchPtr:word\r\n',b'')
assert source.read_bytes()==expected_source
stage=Path(tempfile.mkdtemp(prefix='exec-header-',dir=root/'extras/build'))
shutil.copyfile(source,stage/'buf.asm')
headers={str(p.relative_to(root)):sha(p) for d in ('dos','inc') for p in (root/d).rglob('*.inc')}
tool=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
cmd=[str(tool),'-Mx','-t','-W1',*['-I'+os.path.relpath(root/d,stage) for d in ('dos','extras/research/inc/kernel','inc','extras/research/inc/ntvdm')],'buf.asm,buf.obj,buf.lst;']
run=subprocess.run(cmd,cwd=stage,capture_output=True,timeout=30)
(stage/'assembly.log').write_bytes(run.stdout+run.stderr)
assert run.returncode==0,(run.stdout+run.stderr).decode(errors='replace')
assert all(sha(root/p)==h for p,h in headers.items())
listing=(stage/'buf.lst').read_text()
labels={}
for name in ('Exec_Read_Header','Exec_Save_Start','Exec_Com_File','ExecRead','exec_dealloc','exec_alloc','ChangeOwners','ChangeOwner','Scan_Execname'):
    m=re.search(r'^ ([0-9A-F]{4})\s+\\\s*'+name+r'(?:\s+PROC\s+NEAR|:)',listing,re.M|re.I)
    assert m,name
    labels[name.lower()]=int(m[1],16)
local_targets={'execread':0x62bf,'exec_dealloc':0x62ce,'exec_alloc':0x62d9,
               'changeowners':0x62e7,'changeowner':0x62f8,'exec_com_file':0x604d}
layout=json.loads((e/'m4-t5-dostab-layout-verification.json').read_text());assert layout['exact']
assert sha(Path(layout['source']))==layout['source_sha256']
values={'exec_header_len':26,'exec_signature':layout['anchors']['exec_signature'],
        'exec_max_bss':layout['anchors']['exec_signature']+12,'currentpdb':0x330,
        '$read':0x6a0a,'ecritmem':0x1356,'lcritmem':0x1376}
target=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
def index(b,i):
    if b[i]&128:return ((b[i]&127)*256+b[i+1],i+2)
    return b[i],i+1
raw=(stage/'buf.obj').read_bytes();pos=0;ext=[];image=bytearray(65536);covered=set();relocs=[]
while pos<len(raw):
    k=raw[pos];n=int.from_bytes(raw[pos+1:pos+3],'little');record=raw[pos:pos+3+n];pos+=3+n
    assert sum(record)%256==0;b=record[3:-1];i=0
    if k==0x8c:
        while i<len(b):n=b[i];i+=1;ext.append(b[i:i+n].decode().lower());i+=n;_,i=index(b,i)
    elif k==0xa0:
        seg,i=index(b,0);assert seg==1
        offset=int.from_bytes(b[i:i+2],'little');payload=b[i+2:]
        assert not covered.intersection(range(offset,offset+len(payload)))
        covered.update(range(offset,offset+len(payload)));image[offset:offset+len(payload)]=payload
    elif k==0x9c:
        while i<len(b):
            loc=b[i];off=((loc&3)<<8)+b[i+1];flags=b[i+2];i+=3
            assert loc&128 and ((loc>>2)&15)==1
            frame,i=index(b,i);dest,i=index(b,i);disp=0
            if not flags&4:disp=int.from_bytes(b[i:i+2],'little');i+=2
            relocs.append((offset+off,loc,flags,frame,dest,disp))
rows=[]
for name,a,z,target_start,target_end in (
    ('header',labels['exec_read_header'],labels['exec_save_start'],0x5e26,0x5e5c),
    ('read_ownership',labels['execread'],labels['scan_execname'],0x62bf,0x6306)):
    assert z-a==target_end-target_start and set(range(a,z))<=covered
    buf=bytearray(image[a:z]);fixups=[]
    for at,loc,flags,frame,dest,disp in relocs:
        if not a<=at<z:continue
        assert at+1<z
        addend=int.from_bytes(image[at:at+2],'little');relative=not bool(loc&64)
        if flags&2:
            assert flags in (2,6,0x26),(hex(at),hex(flags),frame,dest)
            symbol=ext[dest-1]
            if flags==0x26:assert frame==dest and symbol=='exec_header_len'
            value=values[symbol]+disp+addend
        else:
            assert frame==dest==1 and flags in (0,4)
            destination=disp+addend
            matches=[n for n in local_targets if labels[n]==destination]
            assert len(matches)==1,(hex(at),hex(destination))
            symbol=matches[0];value=local_targets[symbol]
        if relative:value-=target_start+(at-a)+2
        buf[at-a:at-a+2]=(value&65535).to_bytes(2,'little')
        fixups.append({'offset':at-a,'symbol':symbol,'relative':relative,'value':value&65535})
    expected=target[target_start:target_end]
    diffs=[i for i,(x,y) in enumerate(zip(buf,expected)) if x!=y]
    rows.append({'name':name,'source_range':[a,z],'target_range':[target_start,target_end],
        'bytes':len(buf),'fixups':fixups,'differences':diffs,'exact':not diffs,
        'candidate_sha256':hashlib.sha256(buf).hexdigest(),'target_sha256':hashlib.sha256(expected).hexdigest()})
out={'stage':str(stage),'source_sha256':sha(source),'reference_sha256':sha(reference),
     'tool_sha256':sha(tool),'object_sha256':sha(stage/'buf.obj'),'listing_sha256':sha(stage/'buf.lst'),
     'headers':headers,'command':cmd,'exit':run.returncode,'labels':labels,'rows':rows,
     'header_bytes':26,'header_end':values['exec_signature']+26,
     'scope':'Two native OMF slices with named code/data fixups at target layout. Full MSPROC candidate, its external callees, linked kernel and runtime are not verified.'}
assert out['header_end']==layout['anchors']['win386_info']
(e/'m4-t5-exec-header-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'stage':str(stage),'rows':rows,'header_end':out['header_end']},indent=2))
assert all(r['exact'] for r in rows)

