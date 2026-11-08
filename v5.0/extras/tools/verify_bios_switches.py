"""Verify the linked non-multi SWITCHES parameter table against IO.SYS."""
from pathlib import Path
import hashlib
import json
import re

root=Path(__file__).resolve().parent.parent.parent
e=root/'extras/docs/etc/evidence'
build=json.loads((e/'m5-bios-singleconfig-probe.json').read_text())
assert build['candidate'] and build['oembase'] and build['singleconfig']
stage=Path(build['stage'])
sha=lambda b:hashlib.sha256(b).hexdigest()
actual=(stage/'msbio.bin').read_bytes()
assert sha(actual)==build['output']['sha256']
target=(root/'extras/build/target-io-inspect.bin').read_bytes()
assert sha(target)=='dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target=target[0x5a6:]
listing=(stage/'sysconf.lst').read_text(errors='replace')
mapbytes=(stage/'msbio.map').read_bytes(); maptext=mapbytes.decode(errors='replace')
def local(name):
    vals=re.findall(r'(?im)^'+re.escape(name)+r'\s+(?:\.\s*)+\s*[^\r\n]*?\b([0-9A-F]{4})\s+SYSINITSEG\b',listing)
    assert len(vals)==1,(name,vals)
    return int(vals[0],16)
rows=re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+doconf\s*$',maptext)
vals={(int(s,16),int(o,16)) for s,o in rows};assert len(vals)==1
segment,global_doconf=vals.pop(); module_base=global_doconf-local('doconf')
labels=('swit_parms','swit_parmsx','swit_k_ctrl','swit_t_ctrl','swit_w_ctrl','result_val','noval','dos_parms')
symbols={name:local(name) for name in labels}
start=segment*16+module_base+symbols['swit_parms']
end=segment*16+module_base+symbols['dos_parms']
target_start=0x6082; displacement=start-target_start
assert displacement==0 and end-start==54
data=bytearray(actual[start:end]);expected=target[target_start:target_start+len(data)]
assert len(data)==len(expected)==54
fixups=[]
for offset,label in [(0,'swit_parmsx'),(8,'swit_k_ctrl'),(10,'swit_t_ctrl'),(12,'swit_w_ctrl'),
                     (19,'result_val'),(21,'noval'),(31,'result_val'),(33,'noval'),
                     (43,'result_val'),(45,'noval')]:
    old=int.from_bytes(data[offset:offset+2],'little')
    assert old==module_base+symbols[label],(offset,label,old)
    observed=int.from_bytes(expected[offset:offset+2],'little')
    assert observed==old-displacement,(label,old,observed)
    data[offset:offset+2]=observed.to_bytes(2,'little')
    fixups.append({'table_offset':offset,'symbol':label,'candidate':old,'target':observed})
assert bytes(data)==expected
report={'stage':str(stage),'candidate_sha256':sha(actual),'target_bios_sha256':sha(target),
        'map_sha256':sha(mapbytes),'listing_sha256':sha((stage/'sysconf.lst').read_bytes()),
        'candidate_offset':start,'target_offset':target_start,'length':len(data),
        'module_base':module_base,'symbols':symbols,'fixups':fixups,'normalized_equal':True,
        'scope':'Non-multi SWITCHES parameter table; ten named comparison-only relocations. No runtime or full BIOS identity claim.'}
(e/'m5-bios-switches-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
