"""Check linked HardErr prefix and the corrected CDS/data-layout consequences."""
from pathlib import Path
import hashlib,json,re
from fat12_guest_file import read_root_file
root=Path(__file__).resolve().parent.parent.parent;e=root/'extras/docs/etc/evidence'
r=json.loads((e/'m4-t5-cds-harderr-build.json').read_text());stage=Path(r['stage'])
b=(stage/'ntdos.sys').read_bytes();assert hashlib.sha256(b).hexdigest()==r['output_sha256']
mp=stage/'ntdos.map';assert hashlib.sha256(mp.read_bytes()).hexdigest()==r['map_sha256']
mapping=mp.read_text();origin=int.from_bytes(b[3:5],'little')
t=read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'),'MSDOS.SYS')
assert hashlib.sha256(t).hexdigest()=='4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
symbols={m[3].lower():int(m[2],16) for m in re.finditer(r'^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+(\S+)',mapping,re.M)}
listing=(stage/'msctrlc.lst').read_text(errors='replace')
start=re.search(r'^\s*([0-9A-F]{4})\s+.*HardErr\s+PROC',listing,re.M|re.I)
end=re.search(r'^\s*([0-9A-F]{4})\s+.*FATALC:',listing,re.M|re.I)
size=int(end[1],16)-int(start[1],16);assert size==0x62
offset=symbols['harderr']-origin
assert b[offset:offset+size]==t[0x54aa:0x550c]
assert t[0x6cf3:0x6cf7]==bytes.fromhex('b358f6e3')
assert t[0x6ca9:0x6cb0]==bytes.fromhex('36c706a205f304')
assert t[0x3868:0x386e]==bytes.fromhex('36c606750500')
expected={'dummycds':0x4f3,'readop':0x575,'trans':0x574,'thisdrv':0x576,'user_sp':0x584,'thisdpb':0x58a}
assert all(symbols[n]==v for n,v in expected.items())
assert 'vhedev' not in symbols
# Check source snapshots, including the already exact COMMAND inputs.
assert all(hashlib.sha256((root/p).read_bytes()).hexdigest()==h for p,h in r['source_snapshot'].items())
command=json.loads((e/'m2-t3-command-exact-verification.json').read_text())
changed=[p for p,h in command['source_snapshot'].items() if hashlib.sha256((root/p).read_bytes()).hexdigest()!=h]
assert not changed,changed
out={'build_report':'m4-t5-cds-harderr-build.json','harderr_prefix_bytes':size,
     'candidate_offset':offset,'target_offset':0x54aa,'prefix_exact':True,
     'data_symbols':expected,'target_cds_stride':0x58,'virtual_device_removed':True,
     'command_snapshot_unchanged':True,
     'scope':'Linked HardErr prefix only; full INT24 handler and NT path flags still require recovery.'}
(e/'m4-t5-cds-harderr-verification.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
