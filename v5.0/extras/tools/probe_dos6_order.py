"""Compare the physical probe using DOS 6 reference module ordering."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,tempfile
from target_kernel import read_target
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
source=Path(r['stage']);stage=Path(tempfile.mkdtemp(prefix='dos6-order-',dir=root/'extras/build'))
reference=root.parent/'v6.0/dos/msdos.lnk'
reference_order=re.findall(r'(\w+)\.obj',reference.read_text(errors='replace'),re.I)
existing=r['module_order'];names=[x for x in reference_order if x in existing]
missing=[x for x in reference_order if x not in existing]
extra=[x for x in existing if x not in reference_order]
assert len(names)==len(set(names)) and set(names)|set(extra)==set(existing)
names+=extra
for n in names:
    p=source/f'{n}.obj';assert sha(p)==r['inputs'][p.name];shutil.copyfile(p,stage/p.name)
tools={'link.exe':root.parent/'v6.0/c6ers/tools6/bin/link.exe',
       'reloc.exe':root.parent/'v6.0/c6ers/tools6/bin/reloc.exe',
       'stripz.exe':Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\stripz.exe')}
for n,p in tools.items():shutil.copyfile(p,stage/n)
(stage/'order.lnk').write_text(' +\n'.join(n+'.obj' for n in names)+'\norder.exe\norder.map;\n',encoding='ascii')
bat='@echo off\r\nlink /MAP @order.lnk > order.log\r\nif errorlevel 1 goto fail\r\nreloc order.exe order.bin > reloc.log\r\nif errorlevel 1 goto fail\r\nstripz order.bin order.sys > stripz.log\r\nif errorlevel 1 goto fail\r\necho PASS > order.ok\r\ngoto done\r\n:fail\r\necho FAIL > order.ok\r\n:done\r\nexit\r\n'
(stage/'order.bat').write_bytes(bat.encode('ascii'))
conf=stage/'order.conf';conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\norder.bat\n',encoding='ascii')
runner=root/'extras/build/isolated-tool-runner.exe';dosbox=Path(r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe')
assert sha(runner)=='ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'
cmd=subprocess.list2cmdline([str(dosbox),'-noconsole','-conf',str(conf)])
run=subprocess.run([str(runner),str(dosbox),str(stage),cmd],capture_output=True,timeout=75)
marker=(stage/'order.ok').read_text().strip() if (stage/'order.ok').exists() else 'MISSING'
assert all(sha(stage/f'{n}.obj')==r['inputs'][f'{n}.obj'] for n in names)
out={'stage':str(stage),'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),
     'reference_order_sha256':sha(reference),'module_order':names,'reference_missing':missing,'extra_modules':extra,
     'tools':{n:sha(p) for n,p in tools.items()},'runner_sha256':sha(runner),'host_exit':run.returncode,'marker':marker,
     'logs':{n:(stage/n).read_text(errors='replace') for n in ('order.log','reloc.log','stripz.log') if (stage/n).exists()},
     'scope':'Disposable link-order experiment with existing candidate objects. Not target or runtime acceptance.'}
if marker=='PASS' and (stage/'order.sys').exists():
    target,src=read_target(root);b=(stage/'order.sys').read_bytes();n=min(len(b),len(target))
    out.update(target_source=src,output_bytes=len(b),output_sha256=sha(stage/'order.sys'),target_bytes=len(target),
               common_byte_differences=sum(x!=y for x,y in zip(b,target)),
               first_difference=next((i for i in range(n) if b[i]!=target[i]),None),exact=b==target)
(e/'m4-t5-dos6-order-probe.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k not in ('module_order','logs')},indent=2))
assert run.returncode==0 and marker=='PASS'
