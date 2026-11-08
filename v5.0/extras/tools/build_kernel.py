"""Clean local kernel build, generated messages first; GUI tools private-desktop only."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,tempfile
root=Path(__file__).resolve().parent.parent.parent
evidence=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser();parser.add_argument('--report',default='m4-t5-clean-kernel-build.json');args=parser.parse_args()
assert Path(args.report).name==args.report
stage=Path(tempfile.mkdtemp(prefix='kernel-clean-',dir=root/'extras/build'))
print('Owned stage:',stage,flush=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
tool16=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16')
dos6=root.parent/'v6.0/c6ers/tools6/bin'
tools={'masm.exe':tool16/'masm.exe','nosrvbld.exe':tool16/'nosrvbld.exe',
       'link.exe':dos6/'link.exe','reloc.exe':dos6/'reloc.exe','stripz.exe':tool16/'stripz.exe'}
runner=root/'extras/build/isolated-tool-runner.exe'
dosbox=Path(r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')
plan=json.loads((evidence/'m4-t5-kernel-import.json').read_text())
for name in re.findall(r'(\w+)\.obj',(root/'dos/msdos.lnk').read_text(),re.I):
    rel='dos/'+name+'.asm'
    if not any(row['destination'].lower()==rel.lower() for row in plan['files']):
        plan['files'].append({'destination':rel})
snapshot={}
for src in sorted((root/'extras/research/inc/kernel').glob('*')):
    if src.is_file():
        rel='inc/kernel/'+src.name
        if not any(row['destination'].lower()==rel.lower() for row in plan['files']):
            plan['files'].append({'destination':rel})
for row in plan['files']:
    rel=Path(row['destination']);src=root/rel
    if rel.parts[:2] in (('inc','kernel'),('inc','ntvdm')):src=root/'extras/research'/rel
    # Exclude imported generated CL files; the new run must generate them.
    if re.fullmatch(r'msdos\.cl[1-4]',rel.name,re.I):continue
    dest=stage/'src'/rel;dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(src,dest);snapshot[rel.as_posix()]=sha(src)
for name,p in tools.items():shutil.copyfile(p,stage/name)
for name in ['msdos.skl','msdos.lnk']:shutil.copyfile(stage/'src/dos'/name,stage/name)
for name in ['usa-ms.msg','usa-ms.idx']:shutil.copyfile(stage/'src/dos/messages'/name,stage/name)
phases=[]
def dos_phase(name,commands):
    batch='@echo off\r\n'+''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
    batch+=f'echo PASS > {name}.ok\r\ngoto end\r\n:fail\r\necho FAIL > {name}.ok\r\n:end\r\nexit\r\n'
    (stage/(name+'.bat')).write_bytes(batch.encode('ascii'))
    conf=stage/(name+'.conf')
    conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\n'+name+'.bat\n',encoding='ascii')
    command=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
    run=subprocess.run([str(runner),str(dosbox),str(stage),command],capture_output=True,timeout=75)
    (stage/(name+'-host.log')).write_bytes(run.stdout+run.stderr)
    phases.append({'phase':name,'host_exit':run.returncode,'host_log_sha256':sha(stage/(name+'-host.log'))})
    assert run.returncode==0 and (stage/(name+'.ok')).read_text().strip()=='PASS',name
dos_phase('messages',['nosrvbld msdos.skl usa-ms.msg > msg.log'])
generated={f'msdos.cl{i}':sha(stage/f'msdos.cl{i}') for i in range(1,5)}
names=re.findall(r'(\w+)\.obj',(stage/'msdos.lnk').read_text(),re.I)
objects=[]
for name in names:
    shutil.copyfile(stage/'src/dos'/(name+'.asm'),stage/(name+'.asm'))
    dirs=['.','src/dos','src/inc/kernel','src/inc','src/inc/ntvdm','src/dos/messages']
    command=[str(stage/'masm.exe'),'-Mx','-t','-W1',*['-I'+d for d in dirs],f'{name}.asm,{name}.obj,{name}.lst;']
    run=subprocess.run(command,cwd=stage,capture_output=True,timeout=20)
    (stage/(name+'.log')).write_bytes(run.stdout+run.stderr)
    assert run.returncode==0,name
    objects.append({'module':name,'sha256':sha(stage/(name+'.obj'))})
dos_phase('linkdos',['link /MAP @msdos.lnk > link.log','reloc ntdos.exe ntdos.bin > reloc.log','stripz ntdos.bin ntdos.sys > stripz.log'])
assert all(sha(root/rel)==digest for rel,digest in snapshot.items()),'Sources changed during build'
out={'stage':str(stage),'source_snapshot':snapshot,'tool_hashes':{n:sha(p) for n,p in tools.items()},
     'launcher_sha256':sha(runner),'dosbox_sha256':sha(dosbox),'phases':phases,
     'generated_messages':generated,'objects':objects,'output_bytes':(stage/'ntdos.sys').stat().st_size,
     'output_sha256':sha(stage/'ntdos.sys'),'map_sha256':sha(stage/'ntdos.map'),
     'scope':'Clean local OpenNT-derived kernel baseline; not target MSDOS.SYS recovery.'}
(stage/'result.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
(evidence/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k not in ('source_snapshot','objects')},indent=2))
