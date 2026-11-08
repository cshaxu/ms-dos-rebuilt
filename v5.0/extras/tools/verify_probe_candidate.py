"""Compare a complete linked probe module with its target-proven OMF candidate."""
from pathlib import Path
import argparse,hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
parser=argparse.ArgumentParser();parser.add_argument('--module',choices=('macro2-full','util-full','srvcall-full','alloc-full','macro-full','cpmio-full','msdisp-full','cpmio2-full','msctrlc-full','mscode-full','misc-full','dinfo-full','getset-full','ioctl-full','path-full','search-full','lock-full','dev-iofunc','dev-openclose','dev-io','disk-full','disk2-full','disk3-full','rom-full','mknode','dircall','share','create-full','delete-full','close-full','finfo-full','rename-full','open-full','isearch-full','abort-full','handle-full','file-full','fcbio2-full','fcbio-full'),required=True);args=parser.parse_args()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
c=json.loads((e/f'm4-t5-{args.module}-verification.json').read_text());assert c['exact']
assert sha(Path(c['source']))==c['source_sha256']
r=json.loads((e/'m4-t5-physical-sft-link-probe.json').read_text());assert r['marker']=='PASS'
stage=Path(r['stage'])
for name,h in r['outputs'].items():assert sha(stage/name)==h
module='dev' if args.module.startswith('dev-') else args.module.removesuffix('-full')
assert sha(stage/f'{module}.asm')==r['inputs'][f'{module}.asm']
if module=='dev':
    # Freeze the same composite source assembled by the physical probe.
    dev=(root/'dos/dev.asm').read_text();io=(root/'dos/dev.iofunc.recovery.asm').read_text()
    a=dev.index('Public DEV001S');z=dev.index(';**\tDev_Open_SFT')
    u=io.index('Public DEV001S');v=io.index('DOSCODE ENDS')
    assert (stage/'dev.asm').read_text()==dev[:a]+io[u:v]+dev[z:]
else:
    assert sha(stage/f'{module}.asm')==c['source_sha256']

def symbols(text):
    return {m[3].lower():(int(m[1],16),int(m[2],16)) for m in re.finditer(r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',text,re.M)}
syms=symbols((stage/'probe.map').read_text())
old=json.loads((e/'m4-t5-cds-harderr-build.json').read_text());mp=Path(old['stage'])/'ntdos.map';assert sha(mp)==c['map_sha256'];oldsyms=symbols(mp.read_text())
raw=(stage/'probe.exe').read_bytes();assert raw[:2]==b'MZ';load=raw[int.from_bytes(raw[8:10],'little')*16:]
# Derive module start independently from every native OMF code PUBLIC.
def index(b,i):
    if b[i]&128:return ((b[i]&127)*256+b[i+1],i+2)
    return b[i],i+1
obj=Path(c['stage'])/'buf.obj';assert sha(obj)==c['object_sha256']
data=obj.read_bytes();pos=0;anchors=[]
while pos<len(data):
    kind=data[pos];n=int.from_bytes(data[pos+1:pos+3],'little');record=data[pos:pos+3+n];pos+=3+n
    assert sum(record)%256==0
    if kind!=0x90:continue
    b=record[3:-1];group,i=index(b,0);seg,i=index(b,i)
    if seg==0:i+=2
    while i<len(b):
        n=b[i];i+=1;name=b[i:i+n].decode().lower();i+=n
        offset=int.from_bytes(b[i:i+2],'little');i+=2;_,i=index(b,i)
        if seg!=1:continue
        assert syms[name][0]==0
        anchors.append({'symbol':name,'object_offset':offset,'linked_offset':syms[name][1]})
starts={a['linked_offset']-a['object_offset'] for a in anchors};assert len(starts)==1
start=starts.pop()
expected=bytearray((Path(c['stage'])/'buf.resolved.bin').read_bytes());assert hashlib.sha256(expected).hexdigest()==c['target_slice_sha256']
oldbase=0x3dd0+c['target_start'];fixups=[]
for reloc in c['relocations']:
    key=reloc['symbol'];i=reloc['offset'];value=reloc['value']
    if reloc.get('kind')=='byte_constant':
        assert expected[i]==value and load[start+i]==value
        fixups.append({'offset':i,'symbol':key,'relative':False,'target_symbol':value,'linked_symbol':value,'kind':'byte_constant'})
        continue
    assert int.from_bytes(expected[i:i+2],'little')==value
    if reloc.get('kind')=='far_pointer':
        assert key.lower()=='bios_i2f' and expected[i:i+4]==bytes.fromhex('05007000')
        assert load[start+i:start+i+4]==expected[i:i+4]
        fixups.append({'offset':i,'symbol':key,'relative':False,'target_symbol':5,'linked_symbol':5,'segment':0x70})
        continue
    if key.lower()=='vxdmeslen':oldvalue=newvalue=0x63
    elif key=='DOSCODE':oldvalue=oldbase;newvalue=start
    elif key.lower()=='dosdseg':
        assert syms['dosdseg'][0]==0
        oldvalue=0x3dd0+7;newvalue=syms['dosdseg'][1]
    elif key.upper() in c['external_code_target_attributions']:
        oldvalue=0x3dd0+c['external_code_target_attributions'][key.upper()][1]
        assert syms[key.lower()][0]==0
        newvalue=syms[key.lower()][1]
    else:
        assert key.lower() in oldsyms and key.lower() in syms
        oldvalue=oldsyms[key.lower()][1];newvalue=syms[key.lower()][1]
        for d in c['data_layout_differences']:
            if d['symbol'].lower()==key.lower():oldvalue=d['target']
    value+=newvalue-oldvalue
    if reloc['relative']:value-=start-oldbase
    expected[i:i+2]=(value&65535).to_bytes(2,'little')
    fixups.append({'offset':i,'symbol':key,'relative':reloc['relative'],'target_symbol':oldvalue,'linked_symbol':newvalue})
actual=load[start:start+c['bytes']];diffs=[i for i,(a,b) in enumerate(zip(actual,expected)) if a!=b];assert len(actual)==len(expected)
out={'module':args.module,'stage':str(stage),'candidate_proof_sha256':sha(e/f'm4-t5-{args.module}-verification.json'),'link_report_sha256':sha(e/'m4-t5-physical-sft-link-probe.json'),'linked_start':start,'public_anchors':anchors,'bytes':len(expected),'named_fixups':fixups,'remaining_differences':diffs,'correspondence':not diffs,'scope':('Bounded composite DEV slice,' if module=='dev' else 'Complete linked MZ module,')+' only candidate OMF named relocations adjusted; physical data placement can differ. Not runtime or whole-kernel identity.'}
(e/f'm4-t5-{args.module}-probe-linked-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'module':args.module,'bytes':len(expected),'named_fixups':len(fixups),'remaining_differences':diffs},indent=2));assert not diffs
