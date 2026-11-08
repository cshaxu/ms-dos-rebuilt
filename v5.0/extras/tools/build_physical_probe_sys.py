"""Convert the linked probe into a disposable SYS for binary-gap analysis."""
from pathlib import Path
import hashlib,json,shutil,subprocess,tempfile
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
source=Path(r['stage'])/'probe.exe';assert sha(source)==r['outputs']['probe.exe']
stage=Path(tempfile.mkdtemp(prefix='physical-sys-',dir=root/'extras/build'))
shutil.copyfile(source,stage/'probe.exe')
tools={'reloc.exe':root.parent/'v6.0/c6ers/tools6/bin/reloc.exe',
       'stripz.exe':Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\stripz.exe')}
for n,p in tools.items():shutil.copyfile(p,stage/n)
bat='@echo off\r\nreloc probe.exe probe.bin > reloc.log\r\nif errorlevel 1 goto fail\r\nstripz probe.bin probe.sys > stripz.log\r\nif errorlevel 1 goto fail\r\necho PASS > sysconv.ok\r\ngoto done\r\n:fail\r\necho FAIL > sysconv.ok\r\n:done\r\nexit\r\n'
(stage/'sysconv.bat').write_bytes(bat.encode('ascii'))
conf=stage/'sysconv.conf';conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\nsysconv.bat\n',encoding='ascii')
runner=root/'extras/build/isolated-tool-runner.exe';dosbox=Path(r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')
assert sha(runner)=='ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
cmd=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
run=subprocess.run([str(runner),str(dosbox),str(stage),cmd],capture_output=True,timeout=75)
(stage/'host.log').write_bytes(run.stdout+run.stderr)
assert sha(source)==r['outputs']['probe.exe']==sha(stage/'probe.exe')
marker=(stage/'sysconv.ok').read_text().strip() if (stage/'sysconv.ok').exists() else 'MISSING'
out={'stage':str(stage),'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),
     'input_sha256':sha(source),'tool_sha256':{n:sha(p) for n,p in tools.items()},
     'runner_sha256':sha(runner),'host_exit':run.returncode,'marker':marker,
     'logs':{n:(stage/n).read_text(errors='replace') for n in ('reloc.log','stripz.log') if (stage/n).exists()},
     'scope':'Disposable historical tool conversion of an experimental probe, for binary analysis only; no boot or production claim.'}
if marker=='PASS' and (stage/'probe.sys').exists():
    target,origin=read_target(root);candidate=(stage/'probe.sys').read_bytes()
    common=min(len(target),len(candidate));first=next((i for i in range(common) if target[i]!=candidate[i]),None)
    out.update(target_source=origin,target_sha256=hashlib.sha256(target).hexdigest(),target_bytes=len(target),
               output_sha256=sha(stage/'probe.sys'),output_bytes=len(candidate),first_difference=first,
               byte_differences_in_common=sum(a!=b for a,b in zip(target,candidate)),exact=candidate==target)
(e/'m4-t5-physical-probe-sys-conversion.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert run.returncode==0 and marker=='PASS'
