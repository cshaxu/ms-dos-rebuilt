"""Build an untouched OpenNT BIOS reference in a disposable stage."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent.parent
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
TOOLS16 = Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16')
DOS6TOOLS = ROOT.parent / 'v6.0/c6ers/tools6/bin'
RUNNER = ROOT / 'extras/build/isolated-tool-runner.exe'
DOSBOX = Path(r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')
sha = lambda path: hashlib.sha256(path.read_bytes()).hexdigest()
assert sha(RUNNER) == 'ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
stage = Path(tempfile.mkdtemp(prefix='ntio-reference-', dir=ROOT / 'extras/build'))
for name, source in [('bios', NT / 'doskrnl/bios'), ('inc', NT / 'inc'),
                     ('cinc', NT.parent.parent / 'inc'), ('messages', NT / 'messages')]:
    shutil.copytree(source, stage / 'src' / name)
sources = {str(p.relative_to(stage / 'src')): sha(p)
           for p in sorted((stage / 'src').rglob('*')) if p.is_file()}
tools = {'masm.exe': TOOLS16 / 'masm.exe', 'nosrvbld.exe': TOOLS16 / 'nosrvbld.exe',
         'link.exe': DOS6TOOLS / 'link.exe', 'reloc.exe': DOS6TOOLS / 'reloc.exe'}
for name, path in tools.items():
    shutil.copyfile(path, stage / name)
for name, path in [('msbio.skl', stage/'src/bios/msbio.skl'),
                   ('usa-ms.msg', stage/'src/messages/usa-ms.msg'),
                   ('usa-ms.idx', stage/'src/messages/usa-ms.idx'),
                   ('msbio_4.lnk', stage/'src/bios/msbio_4.lnk')]:
    shutil.copyfile(path, stage/name)

def phase(name, commands):
    batch = '@echo off\r\n' + ''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
    batch += 'echo PASS > '+name+'.ok\r\ngoto done\r\n:fail\r\necho FAIL > '+name+'.ok\r\n:done\r\nexit\r\n'
    (stage/(name+'.bat')).write_bytes(batch.encode('ascii'))
    conf = stage/(name+'.conf')
    conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\n'+name+'.bat\n', encoding='ascii')
    command = subprocess.list2cmdline([str(DOSBOX), '-noconsole', '-conf', str(conf)])
    run = subprocess.run([str(RUNNER), str(DOSBOX), str(stage), command], capture_output=True, timeout=75)
    (stage/(name+'-host.log')).write_bytes(run.stdout+run.stderr)
    marker = stage/(name+'.ok')
    if run.returncode or not marker.exists() or marker.read_text().strip() != 'PASS':
        raise RuntimeError(f'{name} failed; inspect {stage}')

phase('messages', ['nosrvbld msbio.skl usa-ms.msg > msg.log'])
names = re.findall(r'[A-Za-z_][A-Za-z_0-9]*', (stage/'msbio_4.lnk').read_text().split(',')[0])
assert len(names) == 12 and len(set(names)) == 12
units = []
for name in names:
    shutil.copyfile(stage/'src/bios'/f'{name}.asm', stage/f'{name}.asm')
    dirs = ('.', 'src/bios', 'src/inc', 'src/cinc', 'src/messages')
    command = [str(stage/'masm.exe'), '-Mx', '-t', '-W1', *['-I'+d for d in dirs],
               f'{name}.asm,{name}.obj,{name}.lst;']
    run = subprocess.run(command, cwd=stage, capture_output=True, timeout=30)
    (stage/f'{name}.log').write_bytes(run.stdout+run.stderr)
    units.append({'name': name, 'exit': run.returncode,
                  'object_sha256': sha(stage/f'{name}.obj') if (stage/f'{name}.obj').exists() else None})
    if run.returncode:
        raise RuntimeError(f'{name} failed; inspect {stage/name}.log')
phase('linkbio', ['link /MAP @msbio_4.lnk > link.log', 'reloc ntio.exe ntio.sys 70 > reloc.log'])
assert sources == {str(p.relative_to(stage/'src')): sha(p)
                   for p in sorted((stage/'src').rglob('*')) if p.is_file()}
actual = (stage/'ntio.sys').read_bytes()
fixture = (NT/'doskrnl/bios/NTIO.SYS').read_bytes()
target = (ROOT/'extras/build/target-io-inspect.bin').read_bytes()
assert hashlib.sha256(target).hexdigest() == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
generated = {p.name: sha(p) for p in sorted(stage.glob('msbio.cl*'))}
report = {'stage': str(stage), 'inputs': sources, 'tools': {n: sha(p) for n,p in tools.items()},
          'launcher_sha256': sha(RUNNER), 'units': units, 'messages': generated,
          'result': {'length': len(actual), 'sha256': hashlib.sha256(actual).hexdigest(),
                     'reference_fixture_length': len(fixture),
                     'reference_fixture_sha256': hashlib.sha256(fixture).hexdigest(),
                     'equals_reference_fixture': actual == fixture, 'equals_target_io': actual == target},
          'scope': 'Untouched NT-hosted reference build, not recovered physical IO.SYS.'}
(ROOT/'extras/docs/etc/evidence/m5-ntio-reference-build.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k != 'inputs'}, indent=2))
