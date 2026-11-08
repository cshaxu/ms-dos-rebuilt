from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root=Path(__file__).resolve().parent.parent.parent
stage=Path(json.loads((root/'extras/docs/etc/evidence/m2-t3-comspec-build.json').read_text())['stage'])
symbols={}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m=re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$',line)
    if m:symbols[m[3].lower()]=int(m[1],16)*16+int(m[2],16)
with tempfile.TemporaryDirectory(prefix='dos5-init-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target=(Path(d)/'COMMAND.COM').read_bytes()
candidate=(stage/'command.com').read_bytes();start=symbols['envmaximum']-256
assert candidate[start-2:start]==target[0x18da:0x18dc]==b'\x0e\x1f'
mask={1,2,8,9}
assert all(candidate[start+i]==target[0x18dc+i] for i in range(23) if i not in mask)
removed={'scs_pause','scs_is_first','scs_prompt16','scs_firsttsr','res_rdrinfo','res_batstatus'}
assert not removed.intersection(symbols)
result={'candidate_envmaximum':start,'target_envmaximum':0x18dc,'checksum_prefix_bytes':23,'masked_offsets':sorted(mask),'removed_publics':sorted(removed),'pipefiles_candidate':symbols['pipefiles'],'pipefiles_target':0x31f,'limitation':'Static instruction and symbol checks; remaining NT fields and runtime unverified.'}
(root/'extras/docs/etc/evidence/m2-t3-comspec-verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
