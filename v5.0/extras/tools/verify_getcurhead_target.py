"""Locate the complete GetCurHead instruction pattern and record its operands."""
from pathlib import Path
import hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent
b=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(b).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
pattern=re.compile(bytes.fromhex('36c53e')+b'..'+bytes.fromhex('36c706')+b'..'+bytes.fromhex('ffff36893e')+b'..'+b'\xc3',re.S)
matches=[]
for m in pattern.finditer(b):
    data=m.group();matches.append({'file_offset':m.start(),'bytes':data.hex(),
        'BufferQueue_operand':int.from_bytes(data[3:5],'little'),
        'LastBuffer_operand':int.from_bytes(data[8:10],'little'),
        'FIRST_BUFF_ADDR_operand':int.from_bytes(data[15:17],'little')})
out={'matches':matches,'unique':len(matches)==1,
     'scope':'Complete 18-byte instruction pattern from DOS 6 GetCurHead; three address operands recorded, not yet independently proven as field identities.'}
(root/'extras/docs/etc/evidence/m4-t5-getcurhead-target.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert len(matches)==1
build=json.loads((root/'extras/docs/etc/evidence/m4-t5-getcurhead-build.json').read_text())
stage=Path(build['stage']);candidate=(stage/'ntdos.sys').read_bytes()
assert hashlib.sha256(candidate).hexdigest()==build['output_sha256']
m=re.search(r'0000:([0-9A-F]+)\s+GetCurHead\b',(stage/'ntdos.map').read_text(),re.I)
assert m
off=int(m[1],16)-int.from_bytes(candidate[3:5],'little')
actual=candidate[off:off+18];expected=bytes.fromhex(matches[0]['bytes'])
proof={'build':str(stage),'candidate_file_offset':off,'target_file_offset':matches[0]['file_offset'],
       'candidate_bytes':actual.hex(),'target_bytes':expected.hex(),'exact':actual==expected,
       'scope':'Entire GetCurHead routine including all address operands; file positions and rest of kernel remain different.'}
(root/'extras/docs/etc/evidence/m4-t5-getcurhead-verification.json').write_text(json.dumps(proof,indent=2),encoding='utf-8')
print(json.dumps(proof,indent=2));assert proof['exact']
