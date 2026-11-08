"""Direct baseline comparison; no claim that reference offsets map to target."""
from pathlib import Path
import hashlib,json
from fat12_guest_file import read_root_file
from target_fat12 import inspect
root=Path(__file__).resolve().parent.parent.parent
evidence=root/'extras/docs/etc/evidence'
report=json.loads((evidence/'m4-t5-reference-link.json').read_text())
stage=Path(report['stage'])
original=Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
manifest=inspect(original)
assert manifest['image']['sha256']=='168bd67f0d0feaca7f47c0677e64aab51666460c116dd8bbaf8343e83364948c'
target=read_root_file(original,'MSDOS.SYS')
assert hashlib.sha256(target).hexdigest()==manifest['files']['MSDOS.SYS']['sha256']
reference=(stage/'ntdos.sys').read_bytes();binary=(stage/'ntdos.bin').read_bytes()
strip_count=int.from_bytes(binary[:2],'little')
out={'reference_bytes':len(reference),'target_bytes':len(target),
     'reference_sha256':hashlib.sha256(reference).hexdigest(),
     'target_sha256':hashlib.sha256(target).hexdigest(),
     'exact':reference==target,'size_delta_target_minus_reference':len(target)-len(reference),
     'first_difference':next((i for i,(a,b) in enumerate(zip(reference,target)) if a!=b),None),
     'reference_prefix':reference[:32].hex(),'target_prefix':target[:32].hex(),
     'stripz_prefix_bytes':strip_count,'stripz_matches_binary_suffix':binary[strip_count:]==reference,
     'map_offset_rule':'For reference DOSCODE offsets only: file offset = mapped offset - stripz_prefix_bytes. Target mapping still unproven.'}
(evidence/'m4-t5-reference-comparison.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
