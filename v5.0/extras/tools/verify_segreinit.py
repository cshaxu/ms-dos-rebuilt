"""Verify the full linked segment-reinitialization procedure with named operands."""
from pathlib import Path
import argparse,hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser()
parser.add_argument('--build',default='m4-t5-segreinit-build.json')
parser.add_argument('--report',default='m4-t5-segreinit-verification.json')
parser.add_argument('--patchmisc',action='store_true')
args=parser.parse_args()
r=json.loads((e/args.build).read_text());stage=Path(r['stage'])
b=(stage/'ntdos.sys').read_bytes();assert hashlib.sha256(b).hexdigest()==r['output_sha256']
mp=stage/'ntdos.map';assert hashlib.sha256(mp.read_bytes()).hexdigest()==r['map_sha256']
symbols={m[3].lower():int(m[2],16) for m in re.finditer(r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',mp.read_text(),re.M)}
listing=(stage/'msinit.lst').read_text(errors='replace')
def local(name,kind):
    m=re.search(r'^\s*([0-9A-F]{4})\s+.*\b'+name+r'\s*'+kind,listing,re.M|re.I)
    assert m,(name,kind)
    return int(m[1],16)
base=symbols['dosinit']-local('dosinit',':')
origin=int.from_bytes(b[3:5],'little')
start=base+local('seg_reinit','proc')-origin
size=local('seg_reinit','endp')-local('seg_reinit','proc');assert size==137
t=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(t).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
target_start=0x7ce7;expected=bytearray(t[target_start:target_start+size]);actual=b[start:start+size];operands=[]
def word(site,name,value,target_value,kind):
    i=site-target_start
    assert int.from_bytes(expected[i:i+2],'little')==target_value
    assert int.from_bytes(actual[i:i+2],'little')==value,(name,value,actual[i:i+2].hex())
    expected[i:i+2]=value.to_bytes(2,'little')
    operands.append(dict(site=site,name=name,kind=kind,target=target_value,candidate=value))
word(0x7ceb,'header DOSDATA segment',origin+7,0x3dd7,'code-data')
for site,name,target_value in [(0x7cf8,'num_entry',0xbab6),(0x7d6b,'num_entry',0xbab6)]:
    word(site,name,base+local(name,'db'),target_value,'code-data')
for site,name,target_value in [(0x7d08,'DOSINTTABLE',0x1062),(0x7d24,'DosHasHMA',0x1211),
 (0x7d29,'fixexepatch',0x1212),(0x7d2b,'exepatch',0xb530),(0x7d2f,'ChkCopyProt',0x61),
 (0x7d31,'IsCopyProt',0xb734),(0x7d5d,'RationalPatchPtr',0x1214),(0x7d5f,'RationalPatch',0xb66d)]:
    word(site,name,symbols[name.lower()],target_value,'named absolute symbol')
for site,name,dest in [(0x7ced,'patch_misc_segments',0x7db3),(0x7cff,'patch_vec_segments',0x7d70),
 (0x7d02,'patch_offset',0x7e04),(0x7d1a,'check_XMM',0x7cbc),
 (0x7d1f,'patch_in_nops',0x7e90),(0x7d65,'patch_vec_segments',0x7d70)]:
    i=site-target_start;assert actual[i]==expected[i]==0xe8
    target_disp=(dest-site-3)&65535
    candidate_dest=base+local(name,'proc')-origin
    word(site+1,name,(candidate_dest-(start+i)-3)&65535,target_disp,'near call')
diffs=[i for i,(a,c) in enumerate(zip(actual,expected)) if a!=c]
out=dict(build_report=args.build,bytes=size,candidate_start=start,target_start=target_start,
         raw_exact=actual==t[target_start:target_start+size],named_operands=operands,
         remaining_difference_offsets=diffs,correspondence=not diffs,
         scope='Full procedure with enumerated symbol operands. DOSDATA offsets still differ; no whole-layout or runtime claim.')
if args.patchmisc:
    target_start=0x7db3;start=base+local('patch_misc_segments','proc')-origin
    size=local('patch_misc_segments','endp')-local('patch_misc_segments','proc');assert size==81
    expected=bytearray(t[target_start:target_start+size]);actual=b[start:start+size];operands=[]
    for site,name,value in [(0x7dbb,'jshare',0x90),(0x7dbf,'temp_dosloc',0xaaa),
                           (0x7dd5,'country_cdpg',0x122a),(0x7deb,'fastopentable',0xd30),
                           (0x7def,'temp_dosloc',0xaaa),(0x7df6,'temp_dosloc',0xaaa)]:
        word(site,name,symbols[name],value,'named data symbol')
    diff=[i for i,(a,c) in enumerate(zip(actual,expected)) if a!=c]
    out['patch_misc_segments']=dict(bytes=size,candidate_start=start,target_start=target_start,
        raw_exact=actual==t[target_start:target_start+size],named_operands=operands,
        remaining_difference_offsets=diff,correspondence=not diff)
    out['correspondence']=out['correspondence'] and not diff
(e/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert out['correspondence']
