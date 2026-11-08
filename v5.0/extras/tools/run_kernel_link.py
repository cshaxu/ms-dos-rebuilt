"""Run only the prepared DOS-tool job through the private-desktop launcher."""
from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parent.parent.parent
evidence=root/'extras/docs/etc/evidence'
prepared=json.loads((evidence/'m4-t5-link-prepared.json').read_text())
stage=Path(prepared['stage'])
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
assert stage.resolve().is_relative_to((root/'extras/build').resolve())
for name,digest in prepared['inputs'].items(): assert sha(stage/name)==digest
assert not (stage/'result.txt').exists(),'Use a fresh prepared stage'
exe=Path(r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')
runner=root/'extras/build/isolated-tool-runner.exe'
command=subprocess.list2cmdline([str(exe),'-noconsole','-conf',str(stage/'dosbox.conf')])
try:
    run=subprocess.run([str(runner),str(exe),str(stage),command],capture_output=True,timeout=75)
    output=run.stdout+run.stderr;code=run.returncode
except subprocess.TimeoutExpired as error:
    output=(error.stdout or b'')+(error.stderr or b'');code=124
(stage/'isolated-run.log').write_bytes(output)
files={}
for name in ['result.txt','msg.log','link.log','reloc.log','stripz.log','ntdos.exe','ntdos.bin','ntdos.sys','ntdos.map','msdos.cl1','msdos.cl2','msdos.cl3','msdos.cl4']:
    p=stage/name
    if p.exists():
        files[name]={'bytes':p.stat().st_size,'sha256':sha(p)}
        if p.suffix in ('.txt','.log'):files[name]['text']=p.read_text(errors='replace')
nt=Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos')
out={'stage':str(stage),'launcher_exit':code,'launcher_log':output.decode(errors='replace'),
     'launcher_sha256':sha(runner),'dosbox_sha256':sha(exe),'files':files,
     'generated_messages_equal_reference':{name:(stage/name).read_bytes()==(nt/name).read_bytes()
          for name in ('msdos.cl1','msdos.cl2','msdos.cl3','msdos.cl4') if (stage/name).exists()},
     'scope':'NTDOS reference pipeline, not restored standalone MSDOS.SYS.'}
(evidence/('m4-t5-local-link.json' if prepared.get('local_sources') else 'm4-t5-reference-link.json')).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
