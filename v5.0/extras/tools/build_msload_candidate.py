"""Build the comparative MSLOAD source; measure it against the IO target."""
from pathlib import Path
from target_files import read_target
import hashlib
import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--local-source', action='store_true')
parser.add_argument('--report', default='m5-msload-candidate-build.json')
args = parser.parse_args()
if Path(args.report).name != args.report: parser.error('--report must be a filename')
dos6 = Path(os.environ.get('DOS5_DOS6_ROOT', r'O:\repos.hobby\ms-dos-archaeology\v6.0'))
nt = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
tool16 = Path(os.environ.get('DOS5_TOOLS16_ROOT', r'O:\repos.hobby\ntvdm64\tools\opennt\tools16'))
runner = root/'extras/build/isolated-tool-runner.exe'
dosbox = Path(os.environ.get('DOS5_DOSBOX_PATH', r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(runner) == 'ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
stage = Path(tempfile.mkdtemp(prefix='msload-candidate-', dir=root/'extras/build'))
shutil.copytree(root/'bios/inc' if args.local_source else dos6/'inc', stage/'inc')
if args.local_source:
    for name in (root/'extras/tools/bios_shared_includes.txt').read_text(encoding='ascii').splitlines():
        if not name or Path(name).name != name:
            raise ValueError('invalid shared BIOS include name')
        shutil.copyfile(root/'inc'/name, stage/'inc'/name)
shutil.copyfile(root/'inc/versiona.inc', stage/'inc/versiona.inc')
assets = {'msload.asm':root/'bios/msload.asm',
          'masm.exe':tool16/'masm.exe',
          'link.exe':dos6/'c6ers/tools6/bin/link.exe', 'reloc.exe':dos6/'c6ers/tools6/bin/reloc.exe'}
if args.local_source:
    assets.update({'msbio.skl':root/'bios/msbio.skl',
                   'usa-ms.msg':root/'messages/usa-ms-dos.msg',
                   'usa-ibm.msg':root/'messages/usa-ibm.msg',
                   'nosrvbld.exe':tool16/'nosrvbld.exe',
                   'buildidx.exe':tool16/'buildidx.exe'})
else:
    assets['msbio.cl1'] = root/'bios/msbio.cl1'
for name, path in assets.items():
    shutil.copyfile(path, stage/name)
inputs = {name: sha(path) for name,path in assets.items()}
includes = {str(p.relative_to(stage/'inc')): sha(p) for p in sorted((stage/'inc').rglob('*')) if p.is_file()}

def phase(name, commands):
    batch = '@echo off\r\n'+''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
    batch += 'echo PASS > '+name+'.ok\r\ngoto done\r\n:fail\r\necho FAIL > '+name+'.ok\r\n:done\r\nexit\r\n'
    (stage/(name+'.bat')).write_bytes(batch.encode('ascii'))
    conf = stage/(name+'.conf')
    conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\n'+name+'.bat\n',encoding='ascii')
    command = subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
    run = subprocess.run([str(runner),str(dosbox),str(stage),command],capture_output=True,timeout=75)
    (stage/(name+'-host.log')).write_bytes(run.stdout+run.stderr)
    marker = stage/(name+'.ok')
    if run.returncode or not marker.exists() or marker.read_text().strip() != 'PASS':
        raise RuntimeError(f'{name} failed; inspect {stage}')

if args.local_source:
    ibm = (stage/'usa-ibm.msg').read_bytes()
    boot = re.search(rb'(?im)^BOOT\s+[^\r\n]*\r?\n0001[^\r\n]*\r?\n[^\r\n]*\r?\n', ibm)
    if not boot:
        raise ValueError('BOOT message missing from usa-ibm.msg')
    with (stage/'usa-ms.msg').open('ab') as message:
        message.write(b'\r\n' + boot.group())
    phase('messages', ['buildidx usa-ms.msg > idx.log',
                       'nosrvbld msbio.skl usa-ms.msg > msg.log'])
    if not (stage/'msbio.cl1').is_file():
        raise ValueError('NOSRVBLD did not generate class 1 messages')

command = [str(stage/'masm.exe'),'-Mx','-t','-W1','-I.','-Iinc','msload.asm,msload.obj,msload.lst;']
run = subprocess.run(command,cwd=stage,capture_output=True,timeout=30)
(stage/'masm.log').write_bytes(run.stdout+run.stderr)
if run.returncode:
    raise RuntimeError(f'assembly failed; inspect {stage}/masm.log')
phase('linkload',['link /MAP msload.obj,msload,msload,; > link.log',
                  'reloc msload.exe msload.com > reloc.log'])
target = read_target('IO.SYS')
assert hashlib.sha256(target).hexdigest() == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
output = (stage/'msload.com').read_bytes()
common = min(len(output),len(target))
diff = [i for i in range(common) if output[i] != target[i]]
first = diff[0] if diff else None
report = {'stage':str(stage),'local_source':args.local_source,'inputs':inputs,'includes':includes,'masm_command':command,
          'launcher_sha256':sha(runner),'messages':{p.name:sha(p) for p in sorted(stage.glob('msbio.cl*'))},
          'output':{'length':len(output),'sha256':sha(stage/'msload.com'),
                    'target_prefix_equal':output == target[:len(output)],
                    'first_difference':first,'common_prefix_differences':len(diff)},
          'scope':'DOS 6 comparative MSLOAD candidate, DOS 5 version constant; no complete IO.SYS or runtime claim.'}
(root/'extras/docs/etc/evidence'/args.report).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('inputs','includes')},indent=2))
