"""Verify integrated storage slices, accounting explicitly for external calls.

Only enumerated E8 displacement words are relocated from the target layout;
every linked call must resolve to the named symbol in the actual linker map.
Raw equality is reported separately from relocation-aware correspondence.
"""
from pathlib import Path
import argparse,hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser()
parser.add_argument('--build',default='m4-t5-storage-linked-build.json')
parser.add_argument('--report',default='m4-t5-linked-storage-verification.json')
parser.add_argument('--init',action='store_true',help='Include recovered startup DPB construction')
parser.add_argument('--setdpb',action='store_true',help='Include direct BPB conversion and its code constant')
parser.add_argument('--devicepath',action='store_true',help='Verify restored device parser and caller ABI')
parser.add_argument('--lock',action='store_true',help='Verify full physical file locking module')
parser.add_argument('--openclose',action='store_true',help='Verify physical device open/close dispatch')
parser.add_argument('--chdir',action='store_true',help='Check physical CHDIR and shared return layout')
args=parser.parse_args()
r=json.loads((e/args.build).read_text());stage=Path(r['stage'])
b=(stage/'ntdos.sys').read_bytes();assert hashlib.sha256(b).hexdigest()==r['output_sha256']
mp=stage/'ntdos.map';assert hashlib.sha256(mp.read_bytes()).hexdigest()==r['map_sha256']
origin=int.from_bytes(b[3:5],'little')
syms={m[2].lower():int(m[1],16)-origin for m in re.finditer(r'^\s*0000:([0-9A-F]{4})\s+(\S+)',mp.read_text(),re.M)}
t=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(t).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
cases=[('getcurhead',0,0x5aa6,644,[(0x5b91,'fatsecrd'),(0x5b98,'dread'),(0x5cea,'dwrite')]),
       ('fatsecrd',-1,0x3836,72,[(0x3855,'dskread'),(0x3863,'dskread'),(0x386e,'harderrrw')]),
       ('dskread',0,0x38b5,114,[(0x38c0,'setread'),(0x38e9,'setwrite'),(0x38f4,'deviocall2'),(0x3923,'harderr')]),
       ('deviocall',0,0x47df,603,[(0x47e2,'ecritdevice'),(0x485a,'lcritdevice')]),
       ('ecritdisk',0,0x1356,128,[])]
if args.lock:
    cases.append(('$lockoper',0,0x74a6,178,[(0x74ab,'sffromhandle'),
        (0x751d,'idle'),(0x753e,'harderr')]))
if args.openclose:
    cases.append(('dev_open_sft',0,0x475e,129,[(0x475f,'save_user_world'),
        (0x4767,'save_user_world'),(0x47b6,'deviocall2'),
        (0x47cf,'charhard'),(0x47da,'restore_user_world')]))
if 'fatread_cds' in syms:
    cases.append(('iseof',0,0x56ce,984,[
        (0x572e,'fatal'),(0x5779,'inc_dirty_count'),(0x57ad,'getbuffrb'),
        (0x57bd,'inc_dirty_count'),(0x5823,'getbuffrb'),(0x5859,'getbuffrb'),
        (0x5892,'gotdpb'),(0x58a6,'gotdpb'),(0x5904,'fatal1'),
        (0x5938,'deviocall2'),(0x5997,'harderr'),(0x59ab,'getcurhead'),
        (0x59d0,'getcurhead'),(0x59e3,'scanplace'),(0x5a29,'getcurhead'),
        (0x5a2c,'bufwrite'),(0x5a6c,'deviocall2'),(0x5a88,'$setdpb')]))
    listing=(stage/'misc.lst').read_text(errors='replace')
    bounds=[re.search(r'^\s*([0-9A-F]{4})\s+.*\$GET_DEFAULT_DPB\s+'+kind,listing,re.M|re.I) for kind in ('PROC','ENDP')]
    size=int(bounds[1][1],16)-int(bounds[0][1],16)
    cases.append(('$get_default_dpb',0,0xf94,size,[
        (0xf9a,'getthisdrv'),(0xfaa,'ecritdisk'),(0xfad,'fatread_cds'),
        (0xfb0,'lcritdisk'),(0xfb5,'get_user_stack')]))
if 'dirread' in syms:
    cases.extend([
        ('search',0,0x3ec0,433,[(0x3ec0,'startsrch'),(0x3f58,'matchattributes'),
            (0x3f9f,'iseof'),(0x3fd3,'firstcluster'),(0x3ff8,'dirread'),
            (0x4025,'unpack'),(0x4038,'figrec')]),
        ('dirread',-1,0x37c4,115,[(0x3805,'unpack'),(0x380c,'iseof'),
            (0x381b,'figrec'),(0x3825,'getbuffr')]),
        ('figrec',0,0x4f8b,44,[]),('startsrch',0,0x431c,20,[])])
if 'date16' in syms:
    cases.extend([
        ('$get_date',0,0xa5c,483,[(0xa68,'get_user_stack'),(0xa9e,'get_user_stack'),
            (0xacf,'setread'),(0xad7,'deviocall2'),(0xadc,'setwrite'),(0xaeb,'deviocall2'),
            (0xb2d,'setread'),(0xb35,'deviocall2'),(0xc03,'setread'),(0xc0b,'deviocall2'),
            (0xc10,'setwrite'),(0xc1c,'deviocall2')]),
        ('getpath',0,0x4071,858,[(0x413c,'setdirsrch'),(0x4153,'getlet'),
            (0x415a,'pathchrcmp'),(0x4177,'setrootsrch'),(0x422a,'lookuppath'),
            (0x422f,'findentry'),(0x4288,'setdirsrch'),(0x42a4,'setdirsrch'),
            (0x42b5,'getbuffr'),(0x42c3,'set_buf_as_dir'),(0x42cf,'insertpath'),
            (0x42db,'pathchrcmp'),(0x4307,'insertpath'),(0x43af,'date16')]),
        ('lookuppath',0,0x44ce,296,[(0x451b,'matchattributes')])])
if 'dos_chdir' in syms:
    cases.extend([
        ('$current_dir',0,0x21cc,121,[(0x21cc,'ecritdisk'),(0x21d1,'getvisdrv'),
            (0x21d6,'lcritdisk'),(0x2207,'validatecds'),(0x223f,'lcritdisk')]),
        ('validatecds',0,0x43cb,190,[(0x43df,'ecritdisk'),(0x43f5,'fstrcpy'),
            (0x43fd,'splice'),(0x440b,'fatread_cds'),(0x442f,'fstrcpy'),
            (0x4439,'dos_chdir'),(0x447f,'lcritdisk')]),
        ('dos_chdir',0,0x32f6,69,[(0x32f6,'testnet'),(0x3301,'ecritdisk'),
            (0x3321,'getpath'),(0x3337,'lcritdisk')]),
        ('nodeaccerrj',0,0x3201,8,[(0x3205,'lcritdisk')])])
if args.devicepath:
    listing=(stage/'macro2.lst').read_text(errors='replace')
    def local_device(name,kind):
        m=re.search(r'^\s*([0-9A-F]{4})\s+.*\b'+name+r'\s*'+kind,listing,re.M|re.I)
        assert m,name
        return int(m[1],16)
    base=syms['transpath']-local_device('TransPath','PROC')
    syms['checkdevice']=base+local_device('CheckDevice',':')
    assert base+local_device('DoFile',':')-syms['checkdevice']==0x2f
    cases.extend([
        ('checkthisdevice',0,0x4489,69,[(0x448f,'pathchrcmp'),(0x44a6,'pathchrcmp'),
            (0x44ad,'nametrans'),(0x44be,'devname')]),
        ('checkdevice',0,0x6e0b,69,[(0x6e17,'checkthisdevice'),(0x6e24,'getthisdrv'),
            (0x6e2d,'textfromdrive'),(0x6e33,'strcpy'),(0x6e3a,'getvisdrv'),(0x6e45,'validatecds')])])
if args.chdir:
    listing=(stage/'path.lst').read_text(errors='replace')
    def path_local(name,kind):
        m=re.search(r'^\s*([0-9A-F]{4})\s+.*'+re.escape(name)+r'\s*'+kind,listing,re.M|re.I)
        assert m,name
        return int(m[1],16)
    base=syms['$current_dir']-path_local('$CURRENT_DIR','PROC')
    syms['check_pathlen']=base+path_local('Check_PathLen','PROC')
    assert path_local('$CHDIR','ENDP')-path_local('$CHDIR','PROC')==123
    syms['chdir_error_transfer']=syms['$current_dir']+0x17
    cases.append(('$chdir',0,0x2281,121,[(0x2286,'transpath'),(0x229f,'dos_chdir'),
        (0x22b3,'get_user_stack'),(0x22c4,'transpathnoset'),(0x22d5,'check_pathlen'),(0x22f5,'fstrcpy')]))
if 'release' in syms:
    cases.append(('release',-1,0x5068,63,[(0x506b,'unpack'),(0x5075,'pack'),
        (0x508f,'iseof'),(0x5095,'unpack'),(0x509d,'iseof')]))
if 'fastopen_delete' in syms:
    cases.append(('fastopen_delete',0,0x27bb,62,[]))
rows=[]
if 'find_dpb' in syms:
    cases.append(('find_dpb',0,0x6bb8,98,[]))
    cases.append(('getthisdrv',0,0x6c8c,123,[(0x6cb7,'initcds')]))
if args.init:
    listing=(stage/'msinit.lst').read_text(errors='replace')
    def local_label(name):
        m=re.search(r'^\s*([0-9A-F]{4})\s+.*\b'+name+r'\s*:',listing,re.M|re.I)
        assert m,name
        return int(m[1],16)
    unit_base=syms['dosinit']-local_label('DosInit')
    for name in ('perdrv','continit','charinit'):
        syms[name]=unit_base+local_label(name)
    assert syms['continit']-syms['perdrv']==0x82
    m=re.search(r'^\s*([0-9A-F]{4})\s+.*check_XMM\s+proc',listing,re.M|re.I)
    assert int(m[1],16)-local_label('charinit')==40
    cases.append(('perdrv',0,0x7ac3,146,[(0x7aca,'charinit'),(0x7b00,'$setdpb')]))
    cases.append(('charinit',0,0x7c94,40,[(0x7cb5,'deviocall2')]))
for name,delta,start,size,calls in cases:
    actual_start=syms[name]+delta
    actual=b[actual_start:actual_start+size];expected=bytearray(t[start:start+size]);edges=[]
    for site,callee in calls:
        offset=site-start;loc=actual_start+offset
        assert actual[offset]==expected[offset]==0xe8
        destination=(loc+3+int.from_bytes(actual[offset+1:offset+3],'little',signed=True))&65535
        assert destination==syms[callee],(name,callee,destination,syms[callee])
        expected[offset+1:offset+3]=((syms[callee]-loc-3)&65535).to_bytes(2,'little')
        edges.append(dict(site=loc,callee=callee,destination=destination))
    code_data=[]
    if name in ('$get_date','$current_dir','$lockoper'):
        for site in ((0xaf4,0xb9e) if name=='$get_date' else ((0x754f,) if name=='$lockoper' else (0x21dd,0x21eb,0x21fc))):
            i=site-start
            assert actual[i-3:i]==expected[i-3:i]==bytes.fromhex('2e8e1e')
            assert int.from_bytes(expected[i:i+2],'little')==0x3dd7
            assert syms['dosdseg']==7
            assert int.from_bytes(actual[i:i+2],'little')==origin+7
            expected[i:i+2]=(origin+7).to_bytes(2,'little')
            code_data.append(dict(site=actual_start+i,symbol='DosDseg',value=origin+7))
    branches=[]
    jump_sites=[]
    if name=='$lockoper':
        jump_sites=[(0x74b3,'sys_ret_err',0xe9,0x61d),(0x74f8,'sys_ret_ok',0xe9,0x614)]
    if name=='$current_dir':
        jump_sites=[(0x21e3,'sys_ret_err',0xe9,0x61d),(0x2242,'sys_ret_ok',0xe9,0x614)]
    if name=='$chdir':
        jump_sites=[(0x228d,'chdir_error_transfer',0xeb,0x2277)]
    if name=='dos_chdir':
        jump_sites=[(0x3330,'notdirpath',0x75,0x336d)]
    for site,callee,opcode,target_dest in jump_sites:
        i=site-start;loc=actual_start+i;width=1 if opcode in (0x75,0xeb) else 2
        assert actual[i]==expected[i]==opcode
        assert (site+1+width+int.from_bytes(expected[i+1:i+1+width],'little',signed=True))&65535==target_dest
        assert (loc+1+width+int.from_bytes(actual[i+1:i+1+width],'little',signed=True))&65535==syms[callee]
        disp=syms[callee]-loc-1-width
        expected[i+1:i+1+width]=(disp&((1<<(width*8))-1)).to_bytes(width,'little')
        branches.append(dict(site=loc,callee=callee,destination=syms[callee]))
    diffs=[i for i,(a,c) in enumerate(zip(actual,expected)) if a!=c]
    rows.append(dict(name=name,bytes=size,candidate_start=actual_start,target_start=start,
                     raw_exact=actual==t[start:start+size],relocation_correspondence=not diffs,
                     remaining_difference_offsets=diffs,verified_calls=edges,verified_code_data_references=code_data,verified_branches=branches))
if args.setdpb:
    listing=(stage/'misc.lst').read_text(errors='replace')
    bounds=[re.search(r'^\s*([0-9A-F]{4})\s+.*\$SETDPB\s+'+kind,listing,re.M|re.I) for kind in ('PROC','ENDP')]
    assert int(bounds[1][1],16)-int(bounds[0][1],16)==200
    start=syms['$setdpb']-2;actual=b[start:start+202]
    expected=bytearray(t[0xff7:0x10c1])
    assert actual[:2]==expected[:2]==b'\x03\x00'
    # DIV CS:[word3], the sole relocated code-data reference in this slice.
    off=0x10a4-0xff7
    assert actual[off:off+3]==expected[off:off+3]==bytes.fromhex('2ef736')
    assert int.from_bytes(expected[off+3:off+5],'little')==0x3dd0+0xff7
    assert int.from_bytes(actual[off+3:off+5],'little')==origin+start
    expected[off+3:off+5]=(origin+start).to_bytes(2,'little')
    diffs=[i for i,(a,c) in enumerate(zip(actual,expected)) if a!=c]
    rows.append(dict(name='$setdpb_and_word3',bytes=202,candidate_start=start,target_start=0xff7,
                     raw_exact=actual==t[0xff7:0x10c1],relocation_correspondence=not diffs,
                     remaining_difference_offsets=diffs,verified_calls=[],
                     verified_code_data_references=[dict(symbol='word3',operand=start+off+3,value=origin+start)]))
layout_variations=[]
if 'dos_chdir' in syms:
    # Partial module places the shared error nearer; MASM selects short JMP.
    loc=syms['notdirpath'];actual=b[loc:loc+2]
    assert t[0x336d]==0xe9 and 0x3370+int.from_bytes(t[0x336e:0x3370],'little',signed=True)==0x3201
    assert actual[0]==0xeb
    assert loc+2+int.from_bytes(actual[1:2],'little',signed=True)==syms['nodeaccerrj']
    layout_variations.append(dict(symbol='NOTDIRPATH',target_site=0x336d,target_bytes=3,
        candidate_site=loc,candidate_bytes=2,raw_exact=False,
        verified_destination='NODEACCERRJ',reason='Bounded dircall module; restore full shared-tail placement later'))
if args.chdir:
    # Target error path chains through RMDIR; current bounded ordering skips it.
    def jump_destination(data,loc):
        op=data[loc];assert op in (0xeb,0xe9)
        width=1 if op==0xeb else 2
        return loc+1+width+int.from_bytes(data[loc+1:loc+1+width],'little',signed=True)
    assert jump_destination(t,0x2277)==0x2257
    assert jump_destination(t,0x2257)==0x21e3
    assert jump_destination(t,0x21e3)==0x61d
    assert jump_destination(b,syms['chdir_error_transfer'])==syms['sys_ret_err']
    tail=syms['$chdir']+121
    assert b[tail]==0xeb and t[0x22fa]==0xe9
    assert jump_destination(t,0x22fa)==0x614
    intermediate=jump_destination(b,tail)
    assert intermediate==syms['$current_dir']+0x76
    assert jump_destination(b,intermediate)==syms['sys_ret_ok']
    layout_variations.append(dict(symbol='$CHDIR return routing',target_site=0x22fa,
        target_bytes=3,candidate_site=tail,candidate_bytes=2,raw_exact=False,
        verified_destination='SYS_RET_OK; error branch chain terminates at SYS_RET_ERR',
        reason='Shared transfer macros differ until full original path.asm ordering is restored'))
out=dict(build_report=args.build,slices=rows,layout_variations=layout_variations,
         all_correspond=all(x['relocation_correspondence'] for x in rows),
         scope='Integrated code slices and explicitly named call edges. External-call displacements differ from target layout. No whole-file identity or runtime claim.')
(e/args.report).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2));assert out['all_correspond']
