"""Check IOFUNC integration prerequisites against the accepted native build."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parent.parent.parent
e=root/'extras/docs/etc/evidence'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
name='m4-t5-openclose-build.json'
b=json.loads((e/name).read_text());stage=Path(b['stage'])
for rel,digest in b['source_snapshot'].items():
    assert sha(root/rel)==digest,rel
candidate=json.loads((e/'m4-t5-dev-iofunc-verification.json').read_text())
assert candidate['exact'] and candidate['bytes']==360
assert sha(Path(candidate['source']))==candidate['source_sha256']
assert sha(stage/'ntdos.map')==b['map_sha256']
mp=(stage/'ntdos.map').read_text()
syms={m[2].upper():int(m[1],16) for m in re.finditer(r'^\s*0000:([0-9A-F]{4})\s+(\S+)',mp,re.M)}
required=['DOS_READ','DOS_WRITE','DISKREAD','DISKWRITE','SETUP','DOS_COMMIT']
entries={s:{'present_in_map':s in syms,'offset':syms.get(s)} for s in required}
assert entries['DOS_READ']['present_in_map'] and entries['DOS_WRITE']['present_in_map']
assert not any(entries[s]['present_in_map'] for s in ('DISKREAD','DISKWRITE','SETUP'))
listing=(stage/'disk.lst').read_text(errors='replace')
m=re.search(r'^\s*([0-9A-F]{4})\s+B4 06[^\n]*mov\s+ah,6',listing,re.M|re.I)
assert m,'AH=6 must be evidenced in active assembly, not just source text'
following=listing[m.end():].splitlines()[:6]
assert any('CALL    IOFunc' in line for line in following)
source=(root/'dos/disk.asm').read_text()
def body(name):
    return re.search(r'procedure\s+'+name+r',NEAR(.*?)EndProc\s+'+name,source,re.S|re.I)[1]
read=body('DOS_READ');write=body('DOS_WRITE')
active=lambda text:'\n'.join(line.split(';',1)[0] for line in text.splitlines())
assert 'DISKREAD' not in active(read).upper()
assert 'DISKWRITE' not in active(write).upper()
assert re.search(r'JMP\s+WRTDEV',active(write),re.I)
snap={}
for report in (name,'m2-t3-command-exact-verification.json'):
    d=json.loads((e/report).read_text())['source_snapshot']
    bad=[p for p,h in d.items() if sha(root/p)!=h];assert not bad
    snap[report]={'inputs':len(d),'mismatches':bad}
out={'build':name,'candidate':'m4-t5-dev-iofunc-verification.json',
 'range':[0x45f6,0x475e],'bytes':360,'candidate_adaptation':'DOS 6 IOFUNC and tables; local CALL DEVIOCALL becomes invoke only for standalone candidate assembly. Full physical sf.inc confined to comparison stage.',
 'entries':entries,'nt_function6_caller':{'module':'disk.asm','listing_sha256':sha(stage/'disk.lst'),'local_offset':int(m[1],16),'bytes':'B4 06','following_listing':following},
 'prerequisites':[
 {'unit':'dev.asm IOFUNC','state':'target-layout exact candidate','requires':'physical sf_position offset 15h (NT 13h); tables only commands 0..5'},
 {'unit':'disk.asm cooked output','state':'NT command 6 actively assembled','requires':'restore character output loop before removing IOFUNC command 6'},
 {'unit':'disk.asm DOS_READ/DOS_WRITE','state':'names present but physical file paths removed','requires':'restore access checks, SETUP, network/device/file dispatch, critical sections and DOS_COMMIT'},
 {'unit':'disk2.asm','state':'DSKREAD/DSKWRITE sector wrappers only','requires':'restore DISKREAD and SETUP in disk2.asm, DISKWRITE in disk3.asm; sector wrappers are different entry points'},
 {'unit':'kernel sf.inc and SFT users','state':'NT layout still production','requires':'coherent 59-byte physical entry transition with all NT-handle users'}],
 'snapshots':snap,'scope':'Static source, native listing and link-map dependency evidence; not runtime or full-kernel acceptance.'}
(e/'m4-t5-iofunc-transition-audit.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({'bytes':360,'entries':entries,'snapshots':snap},indent=2))
