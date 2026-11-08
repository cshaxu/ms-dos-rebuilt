"""Verify the linked physical TempCDS and its ParaRound call against IO.SYS."""
from pathlib import Path
import hashlib
import json
import re
import struct

root=Path(__file__).resolve().parent.parent.parent
e=root/'extras/docs/etc/evidence'
build=json.loads((e/'m5-bios-singleconfig-probe.json').read_text())
assert build['candidate'] and build['oembase'] and build['singleconfig']
stage=Path(build['stage'])
digest=lambda b:hashlib.sha256(b).hexdigest()
candidate=(stage/'msbio.bin').read_bytes()
assert digest(candidate)==build['output']['sha256']
target=(root/'extras/build/target-io-inspect.bin').read_bytes()
assert digest(target)=='dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target=target[0x5a6:]
map_bytes=(stage/'msbio.map').read_bytes();maptext=map_bytes.decode(errors='replace')
def address(name):
    rows=re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+'+re.escape(name)+r'\s*$',maptext)
    values={int(seg,16)*16+int(off,16) for seg,off in rows}
    assert len(values)==1,(name,values)
    return values.pop()

start=address('tempcds'); para=address('ParaRound')
target_start=0x4c05;target_para=0x5120; length=0x98;call_offset=0x14
assert candidate[start+call_offset]==target[target_start+call_offset]==0xe8
cd=struct.unpack_from('<h',candidate,start+call_offset+1)[0]
td=struct.unpack_from('<h',target,target_start+call_offset+1)[0]
assert start+call_offset+3+cd==para
assert target_start+call_offset+3+td==target_para
assert candidate[para:para+12]==target[target_para:target_para+12]
normal=bytearray(candidate[start:start+length]); target_code=target[target_start:target_start+length]
assert len(normal)==len(target_code)==length
raw_equal=bytes(normal)==target_code
normal[call_offset+1:call_offset+3]=target_code[call_offset+1:call_offset+3]
assert bytes(normal)==target_code
report={'stage':str(stage),'candidate_sha256':digest(candidate),'target_bios_sha256':digest(target),
        'map_sha256':digest(map_bytes),'candidate_offset':start,'target_offset':target_start,
        'length':length,'candidate_pararound':para,'target_pararound':target_para,
        'pararound_matching_bytes':12,'call_offset':call_offset,
        'candidate_call_displacement':cd,'target_call_displacement':td,
        'raw_displaced_equal':raw_equal,'normalized_equal':True,
        'scope':'Actual linked TempCDS and named relative call; comparison normalization only. Does not prove startup runtime or complete IO.SYS.'}
(e/'m5-bios-tempcds-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
