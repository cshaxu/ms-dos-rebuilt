"""Compile comparative storage modules with one shared scratch structure baseline."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,tempfile
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser();parser.add_argument('--expanded',action='store_true');args=parser.parse_args()
stage=Path(tempfile.mkdtemp(prefix='storage-probe-',dir=root/'extras/build'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs={};units=[]
for name in ('curdir.inc','sf.inc'):
    p=root.parent/'v6.0/inc'/name;shutil.copyfile(p,stage/name);inputs[str(p)]=sha(p)
tool=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
for name in ('fat','buf','disk','disk2','disk3')+(('rom','lock','close','delete') if args.expanded else ()):
    p=root.parent/'v6.0/dos'/(name+'.asm');shutil.copyfile(p,stage/p.name);inputs[str(p)]=sha(p)
    command=[str(tool),'-Mx','-t','-W1','-I.',*['-I'+os.path.relpath(root/d,stage) for d in ('dos','inc','extras/research/inc/ntvdm')],f'{name}.asm,{name}.obj,{name}.lst;']
    run=subprocess.run(command,cwd=stage,capture_output=True,timeout=30)
    (stage/(name+'.log')).write_bytes(run.stdout+run.stderr)
    unit={'name':name,'exit':run.returncode,'command':command,'diagnostics':(run.stdout+run.stderr).decode(errors='replace')}
    if run.returncode==0:
        obj=stage/(name+'.obj');unit['sha256']=sha(obj);data=obj.read_bytes();pos=0;ext=[];pub=[]
        def idx(b,i):return ((b[i]&127)*256+b[i+1],i+2) if b[i]&128 else (b[i],i+1)
        while pos<len(data):
            kind=data[pos];n=int.from_bytes(data[pos+1:pos+3],'little');record=data[pos:pos+3+n]
            assert len(record)==3+n and sum(record)%256==0
            b=record[3:-1];pos+=3+n;i=0
            if kind==0x8c:
                while i<len(b):
                    n=b[i];i+=1;ext.append(b[i:i+n].decode('ascii'));i+=n;_,i=idx(b,i)
            elif kind==0x90:
                group,i=idx(b,i);seg,i=idx(b,i)
                if seg==0:i+=2
                while i<len(b):
                    n=b[i];i+=1;pub.append(b[i:i+n].decode('ascii'));i+=n+2;_,i=idx(b,i)
        unit.update(externals=ext,publics=pub)
    units.append(unit)
build=json.loads((e/'m4-t5-gotdpb-build.json').read_text());mapping=Path(build['stage'])/'ntdos.map'
existing={x.lower() for x in re.findall(r'^\s*[0-9A-F]{4}:[0-9A-F]{4}\s+(\S+)',mapping.read_text(),re.M)}
provided={x.lower() for u in units for x in u.get('publics',[])}
missing=sorted({x for u in units for x in u.get('externals',[]) if x.lower() not in existing|provided})
out={'stage':str(stage),'inputs':inputs,'tool_sha256':sha(tool),'map_sha256':sha(mapping),'units':units,'unresolved_names_against_current_map_and_group':missing,
     'scope':'Consistent comparative CDS/SFT within this group only. Existing kernel has NT structures; no compatible integrated link or DOS 5 identity is established.'}
out['overlap_with_current_kernel']=sorted(existing&provided)
(e/('m4-t5-storage-expanded-probe.json' if args.expanded else 'm4-t5-storage-group-probe.json')).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'stage':str(stage),'results':{u['name']:u['exit'] for u in units},'unresolved':missing},indent=2))
