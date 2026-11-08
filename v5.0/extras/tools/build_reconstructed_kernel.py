"""Build the consolidated physical kernel source in disposable stages."""
from pathlib import Path
import argparse,hashlib,json,os,re,shutil,subprocess,tempfile
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence';source=root/'dos'
parser=argparse.ArgumentParser();parser.add_argument('--report',default='m4-t5-consolidated-kernel-build.json');args=parser.parse_args()
if Path(args.report).name != args.report:parser.error('--report must be a filename')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
snapshot={str(Path('dos')/p.relative_to(source)):sha(p) for p in sorted(source.rglob('*')) if p.is_file()}
stage=Path(tempfile.mkdtemp(prefix='reconstructed-kernel-',dir=root/'extras/build'))
(stage/'src').mkdir()
shutil.copytree(source,stage/'src/dos')
include_manifest=root/'extras/tools/kernel_includes.txt'
manifest_bytes=include_manifest.read_bytes()
include_names=manifest_bytes.decode('ascii').splitlines()
if len(include_names)!=46 or len({n.lower() for n in include_names})!=46:
    raise ValueError('invalid kernel include manifest')
shared={}
(stage/'src/inc').mkdir()
for name in include_names:
    if not name or Path(name).name!=name:
        raise ValueError(f'invalid include name: {name}')
    common=root/'inc'/name
    shared[name]=sha(common)
    shutil.copyfile(common,stage/'src/inc'/name)
tool16=Path(os.environ.get('DOS5_TOOLS16_ROOT', r'O:\repos.hobby\ntvdm64\tools\opennt\tools16'));dos6=Path(os.environ.get('DOS5_DOS6_ROOT', r'O:\repos.hobby\ms-dos-archaeology\v6.0'))/'c6ers/tools6/bin'
tools={'masm.exe':tool16/'masm.exe','nosrvbld.exe':tool16/'nosrvbld.exe',
       'buildidx.exe':tool16/'buildidx.exe',
       'link.exe':dos6/'link.exe','reloc.exe':dos6/'reloc.exe','stripz.exe':tool16/'stripz.exe'}
for n,p in tools.items():shutil.copyfile(p,stage/n)
for n in ('msdos.skl','msdos.lnk'):shutil.copyfile(stage/'src/dos'/n,stage/n)
message_sources={'usa-ms.msg':root/'messages/usa-ms-dos.msg'}
shared_messages={n:sha(p) for n,p in message_sources.items()}
for n,p in message_sources.items():shutil.copyfile(p,stage/n)
runner=root/'extras/build/isolated-tool-runner.exe';dosbox=Path(os.environ.get('DOS5_DOSBOX_PATH', r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe'))
assert sha(runner)=='ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
def phase(name,commands):
    bat='@echo off\r\n'+''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
    bat+='echo PASS > '+name+'.ok\r\ngoto done\r\n:fail\r\necho FAIL > '+name+'.ok\r\n:done\r\nexit\r\n'
    (stage/(name+'.bat')).write_bytes(bat.encode('ascii'))
    conf=stage/(name+'.conf');conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\n'+name+'.bat\n',encoding='ascii')
    cmd=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
    r=subprocess.run([str(runner),str(dosbox),str(stage),cmd],capture_output=True,timeout=75)
    (stage/(name+'-host.log')).write_bytes(r.stdout+r.stderr)
    assert r.returncode==0 and (stage/(name+'.ok')).read_text().strip()=='PASS',name
phase('messages',['buildidx usa-ms.msg > idx.log',
                  'nosrvbld msdos.skl usa-ms.msg > msg.log'])
names=re.findall(r'(\w+)\.obj',(stage/'msdos.lnk').read_text(),re.I);assert len(names)==55 and len(set(names))==55
objects={}
for name in names:
    shutil.copyfile(stage/'src/dos'/f'{name}.asm',stage/f'{name}.asm')
    dirs=('.','src/dos','src/inc','src/dos/messages')
    cmd=[str(stage/'masm.exe'),'-Mx','-t','-W1',*['-I'+d for d in dirs],f'{name}.asm,{name}.obj,{name}.lst;']
    r=subprocess.run(cmd,cwd=stage,capture_output=True,timeout=30);(stage/f'{name}.log').write_bytes(r.stdout+r.stderr)
    assert r.returncode==0,name;objects[name]=sha(stage/f'{name}.obj')
phase('linkdos',['link /MAP @msdos.lnk > link.log','reloc msdos.exe msdos.bin > reloc.log','stripz msdos.bin msdos.sys > stripz.log'])
assert snapshot=={str(Path('dos')/p.relative_to(source)):sha(p) for p in sorted(source.rglob('*')) if p.is_file()}
assert shared=={name:sha(root/'inc'/name) for name in shared},'Shared includes changed during build'
assert include_manifest.read_bytes()==manifest_bytes,'Include manifest changed during build'
assert shared_messages=={n:sha(p) for n,p in message_sources.items()},'Shared messages changed during build'
target,target_source=read_target(root);actual=(stage/'msdos.sys').read_bytes()
out={'stage':str(stage),'source_snapshot':snapshot,'shared_include_snapshot':shared,'shared_message_snapshot':shared_messages,'include_manifest_sha256':hashlib.sha256(manifest_bytes).hexdigest(),'objects':objects,'tools':{n:sha(p) for n,p in tools.items()},
     'launcher_sha256':sha(runner),'generated_index_sha256':sha(stage/'usa-ms.idx'),
     'working_message_sha256':sha(stage/'usa-ms.msg'),'messages':{f'msdos.cl{i}':sha(stage/f'msdos.cl{i}') for i in range(1,5)},
     'target_source':target_source,'target_sha256':hashlib.sha256(target).hexdigest(),
     'output_sha256':sha(stage/'msdos.sys'),'output_bytes':len(actual),'exact':actual==target,
     'scope':'Consolidated experimental kernel source build; original media, runtime, IO.SYS and complete package acceptance remain open.'}
(e/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k not in ('source_snapshot','objects')},indent=2))
assert out['exact']
