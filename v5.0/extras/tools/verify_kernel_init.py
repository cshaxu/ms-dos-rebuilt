"""Check DOSINIT's recovered prefix; report layout operands separately."""
from pathlib import Path
import hashlib,json
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;evidence=root/'extras/docs/etc/evidence'
build=json.loads((evidence/'m4-t5-init-recovery-build.json').read_text())
p=Path(build['stage'])/'ntdos.sys';candidate=p.read_bytes()
assert hashlib.sha256(candidate).hexdigest()==build['output_sha256']
target=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(target).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
entry=lambda b:3+int.from_bytes(b[1:3],'little',signed=True)
a=candidate[entry(candidate):][:88];b=target[entry(target):][:88]
# Explicit operand positions from disassembly of the target entry, not a
# permissive wildcard pattern. These word values remain unresolved layout.
fields={9:'memstrt',26:'InitBioDataSeg',36:'MSDAT001e/data length',
        50:'BiosDataPtr',54:'BiosDataPtr+2',59:'dosdseg',64:'LowInt23Addr+2',
        69:'LowInt24Addr+2',74:'LowInt28Addr+2',78:'memory size storage',
        82:'saved SP',86:'saved SS'}
excluded={i for off in fields for i in (off,off+1)}
diff=[{'offset':i,'candidate':x,'target':y} for i,(x,y) in enumerate(zip(a,b)) if x!=y]
unexplained=[d for d in diff if d['offset'] not in excluded]
out={'candidate_entry_file_offset':entry(candidate),'target_entry_file_offset':entry(target),
     'prefix_bytes':88,'prefix_candidate_hex':a.hex(),'prefix_target_hex':b.hex(),
     'native_entry_8_bytes_equal':a[:8]==b[:8]==bytes.fromhex('fafc52561e578cc3'),
     'unexplained_differences':unexplained,
     'layout_operands':[{'offset':off,'meaning':meaning,'candidate':int.from_bytes(a[off:off+2],'little'),
                        'target':int.from_bytes(b[off:off+2],'little')} for off,meaning in fields.items()],
     'exact_prefix':a==b,'structure_matches_except_explicit_layout_words':not unexplained,
     'scope':'Initial 88-byte DOSINIT instruction structure only; 24 operand bytes excluded. No whole-function, whole-kernel or runtime equivalence claim.'}
target_origin=int.from_bytes(target[3:5],'little')
code_end=int.from_bytes(b[9:11],'little')
data_size=int.from_bytes(b[36:38],'little')
data_start=((code_end+15)&~15)-target_origin
out['target_layout_inferred_from_init']={'origin':target_origin,'code_end_offset':code_end,
    'data_file_offset':data_start,'data_bytes':data_size,
    'accounted_file_bytes':data_start+data_size,'matches_target_length':data_start+data_size==len(target),
    'basis':'DOSINIT mov ax,memstrt; paragraph round; mov cx,data length; rep movsb, corroborated by exact file length.'}
(evidence/'m4-t5-init-prefix-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
assert len(a)==len(b)==88 and out['native_entry_8_bytes_equal'] and not unexplained
