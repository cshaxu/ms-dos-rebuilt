"""Clean local-source COMMAND build; historical tools remain external dependencies."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import argparse
from command_source_snapshot import inventory, snapshot
from command_output_check import require_target

root=Path(__file__).resolve().parent.parent.parent
parser=argparse.ArgumentParser()
parser.add_argument('--report',default='m1-t2-clean-build.json')
args=parser.parse_args()
if Path(args.report).name != args.report: raise ValueError('report must be a filename')
tool16=Path(os.environ.get('DOS5_TOOLS16_ROOT', r'O:\repos.hobby\ntvdm64\tools\opennt\tools16'))
dos6=Path(os.environ.get('DOS5_DOS6_ROOT', r'O:\repos.hobby\ms-dos-archaeology\v6.0'))/'c6ers/tools6/bin'
dosbox=Path(os.environ.get('DOS5_DOSBOX_PATH', r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe'))
runner=root/'extras/build/isolated-tool-runner.exe'
(root/'extras/build').mkdir(exist_ok=True)
stage=Path(tempfile.mkdtemp(prefix='command-clean-',dir=root/'extras/build'))
print('Owned stage:',stage,flush=True)
source=stage/'src'
source_snapshot=snapshot(root,source,include_research=False)
tools={'masm.exe':tool16/'masm.exe','buildmsg.exe':tool16/'buildmsg.exe','buildidx.exe':tool16/'buildidx.exe','link.exe':dos6/'link.exe','reloc.exe':dos6/'reloc.exe'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(runner)=='ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
def dos_batch(name,commands):
    body='@echo off\r\n'+''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
    body+=f'echo PASS > {name}.ok\r\ngoto end\r\n:fail\r\necho FAIL > {name}.ok\r\n:end\r\nexit\r\n'
    (stage/(name+'.bat')).write_bytes(body.encode('ascii'))
    conf=stage/(name+'.conf')
    conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\n'+name+'.bat\n',encoding='ascii')
    command=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
    try:
        result=subprocess.run([str(runner),str(dosbox),str(stage),command],capture_output=True,timeout=75)
    except subprocess.TimeoutExpired:
        raise RuntimeError(name+' timed out; inspect isolated runner and owned stage')
    (stage/(name+'-host.log')).write_bytes(result.stdout+result.stderr)
    code=result.returncode
    marker=stage/(name+'.ok')
    if code!=0 or not marker.exists() or marker.read_text().strip()!='PASS':raise RuntimeError(name+' failed; inspect '+str(stage))
for name,path in tools.items():shutil.copyfile(path,stage/name)
for src in [source/'cmd/command/command.skl',source/'cmd/command/command.lnk',source/'messages/usa-ms.msg']:
    shutil.copyfile(src,stage/src.name)
dos_batch('messages',['buildidx usa-ms.msg > idx.log',
                      'buildmsg usa-ms command.skl > messages.log'])
objects=[]
for name in re.findall(r'(?i)\b(\w+)\.obj\b',(source/'cmd/command/command.lnk').read_text()):
    shutil.copyfile(source/'cmd/command'/(name+'.asm'),stage/(name+'.asm'))
    includes=[source/'cmd/command',source/'inc',source/'messages']
    p=subprocess.run([str(stage/'masm.exe'),'-Mx','-t','-W1',*['-I'+os.path.relpath(d,stage) for d in includes],f'{name}.asm,{name}.obj,{name}.lst;'],cwd=stage,capture_output=True,timeout=15)
    (stage/(name+'.log')).write_bytes(p.stdout+p.stderr)
    if p.returncode:raise RuntimeError(name+' failed: '+str(p.returncode))
    objects.append({'name':name,'sha256':sha(stage/(name+'.obj'))})
dos_batch('linkcom',['link @command.lnk > link.log','copy command.exc command.exe > copy.log','reloc command command.com > reloc.log'])
out=stage/'command.com'
if inventory(source)!=source_snapshot:raise RuntimeError('COMMAND source snapshot changed during build')
report={'stage':str(stage),'source_snapshot':source_snapshot,'tool_hashes':{name:sha(p) for name,p in tools.items()},'dosbox_sha256':sha(dosbox),'launcher_sha256':sha(runner),'objects':objects,'generated_index_sha256':sha(stage/'usa-ms.idx'),
        'working_message_sha256':sha(stage/'usa-ms.msg'),
        'messages':{p.name:sha(p) for p in sorted(stage.glob('COMMAND.CL*'))},'output_bytes':out.stat().st_size,'output_sha256':sha(out),'expected_reference_match':sha(out)=='908a77ac617c2d741f0aa1b73f73973dcf29adc91f092e5bcb02173c8c732c43','target_match':sha(out)=='74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'}
(stage/'result.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(root/'extras/docs/etc/evidence'/args.report).write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('objects','tool_hashes','source_snapshot')},indent=2))
require_target(out.read_bytes())
