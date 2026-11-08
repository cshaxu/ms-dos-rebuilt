"""Run a bounded historical linker/RELOC experiment in DOSBox."""
raise SystemExit('Disabled: this legacy hidden-window launcher does not use an isolated desktop.')
from pathlib import Path
import subprocess
import shutil
import json
import hashlib

root = Path(__file__).resolve().parent.parent.parent
stage = root/'extras/build/t2-command'
toolbase = root.parent/'v6.0/c6ers/tools6/bin'
for name in ['link.exe', 'reloc.exe']:
    shutil.copyfile(toolbase/name, stage/name)
for name in ['linkdone.txt','command.exc','command.exe','command.com']:
    p = stage/name
    if p.exists(): p.unlink()
(stage/'linkcmd.bat').write_bytes(b'@echo off\r\nlink @command.lnk > doslink.log\r\nif errorlevel 1 goto fail\r\ncopy command.exc command.exe > copy.log\r\nif errorlevel 1 goto fail\r\nreloc command command.com > reloc.log\r\nif errorlevel 1 goto fail\r\necho PASS > linkdone.txt\r\ngoto end\r\n:fail\r\necho FAIL > linkdone.txt\r\n:end\r\nexit\r\n')
si = subprocess.STARTUPINFO()
si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
si.wShowWindow = 0
p = subprocess.Popen([r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe','-noconsole','-c','cycles max','-c','mount c '+str(stage),'-c','c:','-c','linkcmd.bat'], startupinfo=si)
print('PID',p.pid,flush=True)
try:
    code = p.wait(timeout=55)
except subprocess.TimeoutExpired:
    p.kill(); p.wait()
    raise SystemExit('Timeout: inconclusive, owned process stopped')
result = {'dosbox_exit':code,'files':[]}
for name in ['linkdone.txt','doslink.log','reloc.log','command.com','command.exc','command.map','link.exe','reloc.exe']:
    f=stage/name
    if f.exists():
        b=f.read_bytes()
        item={'name':name,'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()}
        if f.suffix in ['.txt','.log']: item['text']=b.decode('latin1');print(name,item['text'])
        result['files'].append(item)
(root/'extras/docs/etc/evidence/m1-t2-command-link.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
