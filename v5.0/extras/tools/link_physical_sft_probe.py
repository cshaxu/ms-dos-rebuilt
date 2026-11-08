"""Link the native physical-SFT probe on the verified private desktop."""
from pathlib import Path
import hashlib,json,shutil,subprocess
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-probe.json').read_text());stage=Path(r['stage'])
assert stage.resolve().parent==(root/'extras/build').resolve()
assert all(row['exit']==0 for row in r['results'])
names=[row['module'] for row in r['results'] if row['module']!='msinit']+['msinit']
inputs={p.name:sha(p) for n in names for p in (stage/f'{n}.asm',stage/f'{n}.obj',stage/f'{n}.lst')}
# Freeze the actual probe objects; no production output/deployment is replaced.
(stage/'probe.lnk').write_text(' +\n'.join(n+'.obj' for n in names)+'\nprobe.exe\nprobe.map;\n',encoding='ascii')
tool=root.parent/'v6.0/c6ers/tools6/bin/link.exe';shutil.copyfile(tool,stage/'link.exe')
bat='@echo off\r\nlink /MAP @probe.lnk > probelnk.log\r\nif errorlevel 1 goto fail\r\necho PASS > probelnk.ok\r\ngoto done\r\n:fail\r\necho FAIL > probelnk.ok\r\n:done\r\nexit\r\n'
(stage/'probelnk.bat').write_bytes(bat.encode('ascii'))
conf=stage/'probelnk.conf';conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\nprobelnk.bat\n',encoding='ascii')
runner=root/'extras/build/isolated-tool-runner.exe';dosbox=Path(r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')
assert sha(runner)=='ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
cmd=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
run=subprocess.run([str(runner),str(dosbox),str(stage),cmd],capture_output=True,timeout=75)
(stage/'probelnk-host.log').write_bytes(run.stdout+run.stderr)
assert all(sha(stage/p)==h for p,h in inputs.items())
log=(stage/'probelnk.log').read_text(errors='replace') if (stage/'probelnk.log').exists() else ''
marker=(stage/'probelnk.ok').read_text().strip() if (stage/'probelnk.ok').exists() else 'MISSING'
out={'stage':str(stage),'probe_report_sha256':sha(e/'m4-t5-physical-sft-probe.json'),'inputs':inputs,'module_order':names,'link_tool_sha256':sha(tool),'runner_sha256':sha(runner),'host_exit':run.returncode,'marker':marker,'link_log':log,'outputs':{p.name:sha(p) for p in (stage/'probe.exe',stage/'probe.map') if p.exists()},'scope':'Experimental full physical-SFT probe link only; remaining comparative callers and full initialization/layout remain target-unverified, not an accepted MSDOS.SYS or boot test.'}
(e/'m4-t5-physical-sft-link-probe.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k not in ('inputs','module_order')},indent=2))
assert run.returncode==0 and marker=='PASS'
