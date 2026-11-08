"""Check TFOR instruction layout against the fixed target, masking MASM-marked words."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root=Path(__file__).resolve().parent.parent.parent
stage=root/'extras/build/t2-command'
reference=(stage/'command.com').read_bytes()
with tempfile.TemporaryDirectory(prefix='dos5-tfor-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),Path(d))
    target=(Path(d)/'COMMAND.COM').read_bytes()
ref_start=0x38c1
target_start=0x2fdf
length=0x2ce
operands=[]
mask=set()
for line in (stage/'tfor.lst').read_text(encoding='latin1').splitlines():
    m=re.match(r' ([0-9A-F]{4})  (.*?)\\(.*)',line)
    if not m: continue
    pos=int(m[1],16)
    previous=[]
    for token in m[2].strip().split():
        token=token.rstrip(':')
        if token in ('E','R'):
            assert len(previous)==2, 'only word annotations supported'
            mask.update(previous)
            offset=previous[0]
            operands.append({'module_offset':offset,'kind':token,'source':m[3].strip(),
                             'reference_word':int.from_bytes(reference[ref_start+offset:ref_start+offset+2],'little'),
                             'target_word':int.from_bytes(target[target_start+offset:target_start+offset+2],'little')})
        elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}',token):
            previous=list(range(pos,pos+len(token)//2));pos+=len(token)//2
diff=[i for i in range(length) if reference[ref_start+i]!=target[target_start+i]]
unexplained=[i for i in diff if i not in mask]
report={'reference_start':ref_start,'target_start':target_start,'length':length,'different_bytes':len(diff),
        'masked_bytes':len(mask),'unexplained_byte_offsets':unexplained,'operands':operands,
        'limitation':'MASM annotations include internal references and structure offsets; this is layout evidence, not a full relocation/link proof or behavior test.'}
(root/'extras/docs/etc/evidence/m1-t2-tfor-module.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
assert not unexplained
print('TFOR',length,'bytes; differing bytes',len(diff),'outside annotated words',len(unexplained))
print('changed annotated E words',sum(x['kind']=='E' and x['reference_word']!=x['target_word'] for x in operands))
print('changed annotated R words',sum(x['kind']=='R' and x['reference_word']!=x['target_word'] for x in operands))
