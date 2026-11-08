"""Bounded native MASM probe of untouched OpenNT kernel units; no VM/UI."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import tempfile
import argparse
import re

root=Path(__file__).resolve().parent.parent.parent
nt=Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
source=nt/'doskrnl/dos'
masm=Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
stage=Path(tempfile.mkdtemp(prefix='kernel-reference-',dir=root/'extras/build'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
units=[]
parser=argparse.ArgumentParser()
parser.add_argument('--all',action='store_true')
parser.add_argument('--local',action='store_true')
args=parser.parse_args()
if args.local:source=root/'dos'
names=re.findall(r'([\w]+)\.obj',(source/'msdos.lnk').read_text(),re.I) if args.all else ['origin','alloc','parse']
for name in names:
    shutil.copyfile(source/(name+'.asm'),stage/(name+'.asm'))
    includes=[source,nt/'inc',nt.parent.parent/'inc',nt/'messages']
    if args.local:includes=[source,root/'extras/research/inc/kernel',root/'inc',root/'extras/research/inc/ntvdm',source/'messages']
    command=[str(masm),'-Mx','-t','-W1',*['-I'+os.path.relpath(p,stage) for p in includes],
             f'{name}.asm,{name}.obj,{name}.lst;']
    try:
        run=subprocess.run(command,cwd=stage,capture_output=True,timeout=20)
        output=run.stdout+run.stderr;code=run.returncode
    except subprocess.TimeoutExpired as error:
        output=(error.stdout or b'')+(error.stderr or b'');code='timeout; child killed and reaped'
    (stage/(name+'.log')).write_bytes(output)
    units.append({'module':name,'source_sha256':sha(source/(name+'.asm')),
                  'command':command,'exit':code,'log_sha256':sha(stage/(name+'.log')),
                  'object_sha256':sha(stage/(name+'.obj')) if code==0 else None,
                  'diagnostics':output.decode('ascii',errors='replace')})
out={'stage':str(stage),'tool':str(masm),'tool_sha256':sha(masm),'units':units,
     'scope':'Untouched reference units with reference-generated includes; no link, no standalone DOS or target match claim.'}
(root/'extras/docs/etc/evidence'/('m4-t5-local-assembly.json' if args.local else 'm4-t5-reference-assembly.json')).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'stage':str(stage),'results':{u['module']:u['exit'] for u in units}},indent=2))
