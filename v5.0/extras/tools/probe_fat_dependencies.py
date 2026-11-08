"""Assemble DOS 6 FAT comparison source against the current local kernel headers."""
from pathlib import Path
import argparse,hashlib,json,os,shutil,subprocess,tempfile
root=Path(__file__).resolve().parent.parent.parent
parser=argparse.ArgumentParser();parser.add_argument('--dos6-cds',action='store_true');args=parser.parse_args()
source=root.parent/'v6.0/dos/fat.asm'
stage=Path(tempfile.mkdtemp(prefix='fat-probe-',dir=root/'extras/build'))
shutil.copyfile(source,stage/'fat.asm')
if args.dos6_cds:shutil.copyfile(root.parent/'v6.0/inc/curdir.inc',stage/'curdir.inc')
tool=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
dirs=[root/'dos',root/'inc',root/'extras/research/inc/ntvdm']
command=[str(tool),'-Mx','-t','-W1','-I.',*['-I'+os.path.relpath(p,stage) for p in dirs],'fat.asm,fat.obj,fat.lst;']
run=subprocess.run(command,cwd=stage,capture_output=True,timeout=30)
(stage/'fat.log').write_bytes(run.stdout+run.stderr)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
out={'stage':str(stage),'source':str(source),'source_sha256':sha(source),'tool_sha256':sha(tool),
     'command':command,'exit':run.returncode,'diagnostics':(run.stdout+run.stderr).decode(errors='replace'),
     'scope':'Comparison-source assembly probe, not imported production source or target identity.'}
if args.dos6_cds:out['cds_override_sha256']=sha(stage/'curdir.inc')
if run.returncode==0:
    out['object_sha256']=sha(stage/'fat.obj')
    data=(stage/'fat.obj').read_bytes();pos=0;externals=[]
    while pos<len(data):
        kind=data[pos];length=int.from_bytes(data[pos+1:pos+3],'little');payload=data[pos+3:pos+2+length];pos+=3+length
        if kind!=0x8c:continue
        i=0
        while i<len(payload):
            n=payload[i];i+=1;externals.append(payload[i:i+n].decode('ascii'));i+=n
            i+=2 if payload[i]&0x80 else 1
    out['object_externals']=externals
(root/'extras/docs/etc/evidence'/('m4-t5-fat-full-cds-probe.json' if args.dos6_cds else 'm4-t5-fat-dependency-probe.json')).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
