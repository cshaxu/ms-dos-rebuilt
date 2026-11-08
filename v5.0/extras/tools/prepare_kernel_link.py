"""Prepare a fresh isolated DOS-tool experiment from reference assembly objects."""
from pathlib import Path
import argparse,hashlib,json,shutil,tempfile
root=Path(__file__).resolve().parent.parent.parent
evidence=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser();parser.add_argument('--local',action='store_true');args=parser.parse_args()
assembly=json.loads((evidence/('m4-t5-local-assembly.json' if args.local else 'm4-t5-reference-assembly.json')).read_text())
source=Path(assembly['stage'])
stage=Path(tempfile.mkdtemp(prefix='kernel-link-',dir=root/'extras/build'))
nt=Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
tool16=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
inputs={}
for u in assembly['units']:
    p=source/(u['module']+'.obj');assert u['exit']==0 and sha(p)==u['object_sha256']
    shutil.copyfile(p,stage/p.name);inputs[p.name]=sha(p)
tools={'link.exe':root.parent/'v6.0/c6ers/tools6/bin/link.exe',
       'reloc.exe':root.parent/'v6.0/c6ers/tools6/bin/reloc.exe',
       'stripz.exe':tool16/'stripz.exe','nosrvbld.exe':tool16/'nosrvbld.exe'}
assets={'msdos.lnk':nt/'doskrnl/dos/msdos.lnk','msdos.skl':nt/'doskrnl/dos/msdos.skl',
        'usa-ms.msg':nt/'messages/usa-ms.msg','usa-ms.idx':nt/'messages/usa-ms.idx'}
if args.local:assets={'msdos.lnk':root/'dos/msdos.lnk','msdos.skl':root/'dos/msdos.skl',
                     'usa-ms.msg':root/'extras/research/messages/dos/usa-ms.msg','usa-ms.idx':root/'extras/research/messages/dos/usa-ms.idx'}
for name,p in {**tools,**assets}.items():
    shutil.copyfile(p,stage/name);inputs[name]=sha(p)
commands=['nosrvbld msdos.skl usa-ms.msg > msg.log','link /MAP @msdos.lnk > link.log',
          'reloc ntdos.exe ntdos.bin > reloc.log','stripz ntdos.bin ntdos.sys > stripz.log']
batch='@echo off\r\n'+''.join(c+'\r\nif errorlevel 1 goto fail\r\n' for c in commands)
batch+='echo PASS > result.txt\r\ngoto end\r\n:fail\r\necho FAIL > result.txt\r\n:end\r\nexit\r\n'
(stage/'build.bat').write_bytes(batch.encode('ascii'))
config='[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n[autoexec]\nmount c "'+str(stage)+'"\nc:\nbuild.bat\n'
(stage/'dosbox.conf').write_text(config,encoding='ascii')
out={'stage':str(stage),'inputs':inputs,'assembly_stage':str(source),'local_sources':args.local,
     'note':'Messages generated for comparison; linked objects used reference-provided CL files.'}
(evidence/'m4-t5-link-prepared.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
