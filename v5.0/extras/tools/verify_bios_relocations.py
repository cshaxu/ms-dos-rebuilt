"""Check bounded SYSINIT displacement effects without patching a build."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parent.parent.parent
evidence = root/'extras/docs/etc/evidence'
build = json.loads((evidence/'m5-bios-singleconfig-probe.json').read_text())
assert build['candidate'] and build['oembase'] and build['singleconfig']
stage = Path(build['stage'])
binary = (stage/'msbio.bin').read_bytes()
sha = lambda b:hashlib.sha256(b).hexdigest()
assert sha(binary)==build['output']['sha256']
target = (root/'extras/build/target-io-inspect.bin').read_bytes()
assert sha(target)=='dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target = target[0x5a6:]
listing = (stage/'sysinit1.lst').read_text(errors='replace')
maptext = (stage/'msbio.map').read_text(errors='replace')
def value(name):
    rows=re.findall(r'(?im)^'+re.escape(name)+r'\s+(?:\.\s*)+\s*[^\r\n]*?\b([0-9A-F]{4})\s+SYSINITSEG\b',listing)
    assert len(rows)==1,(name,rows)
    return int(rows[0],16)

symbols={n:value(n) for n in ('ClrVDISKHeader','ClrdVDISKHead','src_desc','bmove','FTryToMovDOSHi')}
rows=re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+FTryToMovDOSHi\s*$',maptext)
assert rows and all(int(s,16)*16+int(o,16)==0x3fd0+symbols['FTryToMovDOSHi'] for s,o in rows)
candidate_start=0x3fd0+symbols['ClrVDISKHeader']; target_start=0x4b6e
displacement=candidate_start-target_start
assert -0x100 < displacement < 0x100
size=42
candidate=bytearray(binary[candidate_start:candidate_start+size]); expected=target[target_start:target_start+size]
assert len(candidate)==len(expected)==size
fixups=[]
for rel,label,addend in [(14,'ClrdVDISKHead',0),(21,'src_desc',2),
                         (26,'src_desc',4),(34,'bmove',0)]:
    old=int.from_bytes(candidate[rel:rel+2],'little')
    assert old==symbols[label]+addend
    inferred=old-displacement
    target_value=int.from_bytes(expected[rel:rel+2],'little')
    assert target_value==inferred
    candidate[rel:rel+2]=inferred.to_bytes(2,'little')
    fixups.append({'routine_offset':rel,'symbol':label,'addend':addend,
                   'candidate_value':old,'target_value':target_value})
assert bytes(candidate)==expected
assert binary[0x8f8]==target[0x8f8]==0xff
pointer=int.from_bytes(binary[0x8f9:0x8fb],'little')
target_pointer=int.from_bytes(target[0x8f9:0x8fb],'little')
assert pointer==symbols['FTryToMovDOSHi'] and target_pointer==pointer-displacement
assert binary[0x8fb:0x8fd]==target[0x8fb:0x8fd]
report={'stage':str(stage),'binary_sha256':sha(binary),'target_sha256':sha(target),
        'map_sha256':sha((stage/'msbio.map').read_bytes()),
        'listing_sha256':sha((stage/'sysinit1.lst').read_bytes()),
        'candidate_routine_offset':candidate_start,'target_routine_offset':target_start,
        'displacement':displacement,'routine_bytes':size,'symbols':symbols,'fixups':fixups,
        'normalized_routine_equal':True,'bios_pointer_offset':0x8f9,
        'pointer_candidate':pointer,'pointer_target':target_pointer,
        'scope':'Comparison-only displacement normalization for four named words and one BIOS pointer; no output patching or runtime proof.'}
(evidence/'m5-bios-vdisk-relocation-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
