"""Map exact public-symbol byte prefixes; candidates are not function proofs."""
from pathlib import Path
import json
import re
import struct
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = root/'extras/build/t2-command'
exe = (stage/'command.exe').read_bytes()
reference = (stage/'command.com').read_bytes()
header = struct.unpack_from('<H',exe,8)[0]*16
assert struct.unpack_from('<H',exe,6)[0] == 0, 'unexpected MZ relocations'
assert exe[header+256:] == reference, 'COM conversion is not header+PSP removal'
with tempfile.TemporaryDirectory(prefix='dos5-symbols-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
symbols = set()
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m=re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$',line)
    if m: symbols.add((int(m[1],16)*16+int(m[2],16)-256,m[3]))
rows=[]
for offset,name in sorted(symbols):
    if not 0<=offset<=len(reference)-32: continue
    prefix=reference[offset:offset+32]
    first=target.find(prefix)
    hits=[]
    while first>=0:
        hits.append(first);first=target.find(prefix,first+1)
    row={'symbol':name,'reference_file_offset':offset,'target_prefix_offsets':hits}
    if len(hits)==1:
        length=32
        while offset+length<len(reference) and hits[0]+length<len(target) and reference[offset+length]==target[hits[0]+length]:length+=1
        row['exact_forward_bytes']=length
    rows.append(row)
result={'map_to_file_bias':-256,'conversion_verified':True,'prefix_bytes':32,'scope':'public symbol prefixes, includes data; not whole-function equivalence','symbols':rows}
(root/'extras/docs/etc/evidence/m1-t2-command-symbol-map.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print('symbols',len(rows),'unique prefix matches',sum(len(r['target_prefix_offsets'])==1 for r in rows))
for row in rows:
    if row['symbol'].lower() in ('$for','foroff','nextarg'):print(row)
