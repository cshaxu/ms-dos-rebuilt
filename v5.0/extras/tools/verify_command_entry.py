"""Check bounded entry layout and restored calls against the target."""
from pathlib import Path
import argparse
import json
import re
import tempfile
from target_fat12 import inspect

root=Path(__file__).resolve().parent.parent.parent
ap=argparse.ArgumentParser();ap.add_argument('report');ap.add_argument('--length',type=lambda x:int(x,0),default=0x130);ap.add_argument('--output',default='m2-t3-prompt-verification.json');args=ap.parse_args()
if Path(args.output).name!=args.output:raise ValueError('output must be a filename')
report=json.loads(Path(args.report).read_text());stage=Path(report['stage'])
reference=(stage/'command.com').read_bytes()
with tempfile.TemporaryDirectory(prefix='dos5-entry-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target=(Path(d)/'COMMAND.COM').read_bytes()
symbols={}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m=re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$',line)
    if m:symbols[m[3].lower()]=int(m[1],16)*16+int(m[2],16)-256
mask=set()
for line in (stage/'tcode.lst').read_text(encoding='latin1').splitlines():
    m=re.match(r' ([0-9A-F]{4})  (.*?)\\',line)
    if not m:continue
    pos=int(m[1],16)-0x104;previous=[]
    for token in m[2].split():
        token=token.rstrip(':')
        if token in ('E','R'):mask.update(previous)
        elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}',token):previous=list(range(pos,pos+len(token)//2));pos+=len(token)//2
length=args.length;start=symbols['tcommand']
differences=[i for i in range(length) if reference[start+i]!=target[0x2324+i] and i not in mask]
def call_destination(data,offset):
    assert data[offset]==0xe8
    return offset+3+int.from_bytes(data[offset+1:offset+3],'little',signed=True)
calls=[]
for offset,name in [(0x23fd,'crlf2'),(0x2437,'print_prompt')]:
    actual=start+offset-0x2324
    assert call_destination(reference,actual)==symbols[name]
    calls.append({'symbol':name,'candidate_call':actual,'target_call':offset,'target_destination':call_destination(target,offset)})
assert call_destination(reference,symbols['docom'])==symbols['crlf2']
assert call_destination(target,0x24f5)==0x48d7
result={'prefix_length':length,'unmasked_differences':differences,'calls':calls,'docom_call_verified':True,'limitation':'Address words masked; full target identity and runtime behavior unproven.'}
(root/'extras/docs/etc/evidence'/args.output).write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2));assert not differences
