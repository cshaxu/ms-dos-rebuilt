"""Compile the OpenNT COMMAND link-list modules without modifying reference inputs."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import shutil
import argparse
import os

root = Path(__file__).resolve().parent.parent.parent
parser = argparse.ArgumentParser()
parser.add_argument('--local-source', action='store_true')
args = parser.parse_args()
v86 = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
if args.local_source: v86 = root
source = v86 / 'cmd/command'
asm = Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
stage = root / ('extras/build/t2-local' if args.local_source else 'extras/build/t2-command')
stage.mkdir(parents=True, exist_ok=True)
names = re.findall(r'(?i)\b(\w+)\.obj\b', (source/'command.lnk').read_text())
results = []
for name in names:
    shutil.copyfile(source/(name+'.asm'), stage/(name+'.asm'))
    obj = stage/(name+'.obj')
    if obj.exists(): obj.unlink()
    shared = root/'extras/research/inc/ntvdm' if args.local_source else v86.parent.parent/'inc'
    command = [str(asm), '-Mx', '-t', '-W1', *['-I'+(os.path.relpath(p,stage) if args.local_source else str(p)) for p in [source,v86/'inc',shared,v86/'messages']], f'{name}.asm,{name}.obj,{name}.lst;']
    try:
        p = subprocess.run(command, cwd=stage, capture_output=True, timeout=15)
        log = p.stdout + p.stderr
        item = {'module':name,'exit_code':p.returncode,'object_bytes':obj.stat().st_size if obj.exists() else None}
    except subprocess.TimeoutExpired as e:
        log = (e.stdout or b'') + (e.stderr or b'')
        item = {'module':name,'timeout':True}
    (stage/(name+'.log')).write_bytes(log)
    item['diagnostics'] = log.decode('latin1')
    if obj.exists(): item['sha256'] = hashlib.sha256(obj.read_bytes()).hexdigest()
    results.append(item)
    print(name, item.get('exit_code','timeout'), flush=True)
(root/('extras/docs/etc/evidence/m1-t2-local-assembly.json' if args.local_source else 'extras/docs/etc/evidence/m1-t2-command-assembly.json')).write_text(json.dumps(results,indent=2),encoding='utf-8')
