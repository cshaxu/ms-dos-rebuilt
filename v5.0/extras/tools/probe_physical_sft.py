"""Native-only physical-SFT assembly probe; never modifies production sources."""
from pathlib import Path
import hashlib,json,re,shutil,subprocess,tempfile
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
b=json.loads((e/'m4-t5-lock-build.json').read_text());accepted=Path(b['stage'])
for p,h in b['source_snapshot'].items():assert sha(root/p)==h,p
stage=Path(tempfile.mkdtemp(prefix='physical-sft-probe-',dir=root/'extras/build'))
shutil.copytree(accepted/'src',stage/'src')
for i in range(1,5):shutil.copyfile(accepted/f'msdos.cl{i}',stage/f'msdos.cl{i}')
sf=root.parent/'v6.0/inc/sf.inc';shutil.copyfile(sf,stage/'src/inc/kernel/sf.inc')
from target_kernel import read_target
target,target_source=read_target(root);assert int.from_bytes(target[3:5],'little')==0x3dd0
origin=root/'extras/research/inc/origin.target.recovery.inc';shutil.copyfile(origin,stage/'src/inc/origin.inc')
overlays={'origin':{'source':str(origin),'sha256':sha(origin),'target_source':target_source,'classification':'target-derived provisional origin pending BIOS build'}}
def put(name,path,classification):
    shutil.copyfile(path,stage/'src/dos'/f'{name}.asm')
    overlays[name]={'source':str(path),'sha256':sha(path),'classification':classification}
for name in ('disk','disk2','disk3','rom','close','dircall','finfo','delete','rename','create','open','isearch','abort','handle','file','fcbio','fcbio2','msproc','search','path','ioctl','getset','dinfo','misc','mscode','msctrlc','cpmio2','msdisp','cpmio','macro','alloc','srvcall','util','macro2'):
    put(name,root/'dos'/f'{name}.full.recovery.asm','target-layout verified candidate')
for name in ('mknode','share'):
    put(name,root/'dos'/f'{name}.recovery.asm','target-layout verified candidate')

put('dostab',root/'dos/dostab.layout.recovery.asm','target-layout verified initialized tail and EXEC allocation')
put('mstable',root/'dos/mstable.physical.recovery.asm','target-backed lock error map and physical internal services candidate')
lmstub=root/'extras/research/inc/lmstub.tail.recovery.asm'
shutil.copyfile(lmstub,stage/'src/inc/lmstub.asm')
overlays['lmstub']={'source':str(lmstub),'sha256':sha(lmstub),'classification':'physical A20/instance-table candidate; verification pending'}
# Replace the NT IOFUNC/tables, retaining the already verified production tail.
dev=(root/'dos/dev.asm').read_text();io=(root/'dos/dev.iofunc.recovery.asm').read_text()
a=dev.index('Public DEV001S');z=dev.index(';**\tDev_Open_SFT')
u=io.index('Public DEV001S');v=io.index('DOSCODE ENDS')
newdev=dev[:a]+io[u:v]+dev[z:]
(stage/'src/dos/dev.asm').write_text(newdev)
overlays['dev']={'sources':{str(root/'dos/dev.asm'):sha(root/'dos/dev.asm'),str(root/'dos/dev.iofunc.recovery.asm'):sha(root/'dos/dev.iofunc.recovery.asm')},'classification':'verified pieces combined for probe; full module integration not yet proven'}
# Probe-only physical structure restoration; validate target startup separately.
fcb=root.parent/'v6.0/inc/cpmfcb.inc'
shutil.copyfile(fcb,stage/'src/inc/kernel/cpmfcb.inc')
p=stage/'src/inc/kernel/const2.asm';t=p.read_text()
t=t.replace('\tDB\tFILLSPACE DUP (0)\t; PAD to maintain correct offsets','')
p.write_text(t)
p=stage/'src/dos/msinit.asm';init_source=root/'dos/msinit.physical.recovery.asm';t=init_source.read_text();ref=(root.parent/'v6.0/dos/msinit.asm').read_text()
overlays['msinit']={'source':str(init_source),'sha256':sha(init_source),'classification':'physical hash initialization candidate combined with SFT startup'}
a=t.index('        .errnz  sf_time-(sf_devptr+4)')
t=t[:a]+t[a:].replace('        .errnz  sf_time-(sf_devptr+4)','\t.errnz\tsf_firclus-(sf_devptr+4)\n\tstosw\t\t\t\t; firclus\n\t.errnz\tsf_time-(sf_firclus+2)',1)
u=ref.index('\tadd\tdi,sf_name - sf_cluspos');v=ref.index('\tpop\tsi',u)
a=t.index('        pop     si                      ; get back pointer to header')
t=t[:a]+ref[u:v]+t[a:];p.write_text(t)
probe_adjustments={str(p.relative_to(stage)):sha(p) for p in (stage/'src/inc/kernel/sf.inc',stage/'src/inc/kernel/cpmfcb.inc',stage/'src/inc/kernel/const2.asm',stage/'src/dos/msinit.asm',stage/'src/dos/msctrlc.asm',stage/'src/inc/lmstub.asm',stage/'src/inc/origin.inc')}
names=re.findall(r'(\w+)\.obj',(root/'dos/msdos.lnk').read_text(),re.I)
names=[n for n in names if n!='diskread']
for n in ('dinfo','disk3','close','mknode','share','create','finfo','rename','isearch'):
    if n not in names:names.append(n)
tool=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
results=[]
for name in names:
    shutil.copyfile(stage/'src/dos'/f'{name}.asm',stage/f'{name}.asm')
    dirs=['.','src/dos','src/inc/kernel','src/inc','src/inc/ntvdm','src/dos/messages']
    cmd=[str(tool),'-Mx','-t','-W1',*['-I'+d for d in dirs],f'{name}.asm,{name}.obj,{name}.lst;']
    run=subprocess.run(cmd,cwd=stage,capture_output=True,timeout=30)
    log=run.stdout+run.stderr;(stage/f'{name}.log').write_bytes(log)
    results.append({'module':name,'exit':run.returncode,'log_sha256':sha(stage/f'{name}.log'),'errors':[line for line in log.decode(errors='replace').splitlines() if 'error ' in line.lower()]})
assert all(sha(root/p)==h for p,h in b['source_snapshot'].items())
out={'stage':str(stage),'accepted_build':'m4-t5-lock-build.json','tool_sha256':sha(tool),'physical_sft':{'source':str(sf),'sha256':sha(sf)},'overlays':overlays,'probe_adjustments':probe_adjustments,'fcb_reference':{'source':str(fcb),'sha256':sha(fcb)},'results':results,'scope':'Native assembly only. Target-layout proofs do not by themselves prove integrated binary equality, data layout or runtime.'}
(e/'m4-t5-physical-sft-probe.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'stage':str(stage),'modules':len(results),'failures':[x for x in results if x['exit']]},indent=2))
