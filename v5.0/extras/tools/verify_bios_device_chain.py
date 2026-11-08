"""Compare a DOS 6 BIOS device-chain candidate with the pinned DOS 5 target."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import struct
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent.parent
dos6 = root.parent/'v6.0'
stage = Path(tempfile.mkdtemp(prefix='bios-device-chain-', dir=root/'extras/build'))
shutil.copytree(dos6/'inc', stage/'inc')
shutil.copytree(dos6/'bios', stage/'refbios')
shutil.copyfile(root/'inc/versiona.inc', stage/'inc/versiona.inc')
shutil.copyfile(root/'bios/msbio1.asm', stage/'msbio1.asm')
masm = Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
cmd = [str(masm),'-Mx','-t','-W1','-I.','-Iinc','-Irefbios',
       'msbio1.asm,msbio1.obj,msbio1.lst;']
run = subprocess.run(cmd,cwd=stage,capture_output=True,timeout=30)
(stage/'masm.log').write_bytes(run.stdout+run.stderr)
assert run.returncode == 0, f'assembly failed; inspect {stage}'
listing = (stage/'msbio1.lst').read_text(errors='replace')
def symbol(name):
    hits = re.findall(r'(?im)^'+re.escape(name)+r'\s+(?:\.\s*)+\s*[^\r\n]*?\b([0-9A-F]{4})\s+BIOS_DATA\b',listing)
    assert len(hits)==1,(name,hits)
    return int(hits[0],16)

devices = [('res_dev_list','auxdev2','con_entry'),('auxdev2','prndev2','aux0_entry'),
           ('prndev2','timdev','prn0_entry'),('timdev','dskdev','tim_entry'),
           ('dskdev','com1dev','dsk_entry'),('com1dev','lpt1dev','aux0_entry'),
           ('lpt1dev','lpt2dev','prn1_entry'),('lpt2dev','lpt3dev','prn2_entry'),
           ('lpt3dev','com2dev','prn3_entry'),('com2dev','com3dev','aux1_entry'),
           ('com3dev','com4dev','aux2_entry'),('com4dev',None,'aux3_entry')]
names = {x for triplet in devices for x in triplet if x}
names.update(['strategy','orig13','RomVectors','ptrsav','cdev_entry',
              'inHMA','dosdatasg','cdev','EnsureA20On','outchr'])
symbols = {name:symbol(name) for name in sorted(names)}
raw = (stage/'msbio1.obj').read_bytes()
image = bytearray(65536); covered = set(); pos = 0
def expand_block(data, pos):
    repeat, blocks = struct.unpack_from('<HH',data,pos); pos += 4
    if blocks:
        parts = []
        for _ in range(blocks):
            part,pos = expand_block(data,pos)
            parts.append(part)
        unit = b''.join(parts)
    else:
        length = data[pos]; pos += 1
        unit = data[pos:pos+length]; pos += length
        assert len(unit) == length
    assert len(unit)*repeat <= 65536
    return unit*repeat,pos

while pos < len(raw):
    size = int.from_bytes(raw[pos+1:pos+3],'little')
    record = raw[pos:pos+3+size]; pos += 3+size
    assert sum(record)%256 == 0
    if record[0] not in (0xa0,0xa2):
        continue
    data = record[3:-1]
    assert data[0] < 0x80
    if data[0] != 1:
        continue
    offset = int.from_bytes(data[1:3],'little')
    if record[0] == 0xa0:
        payload = data[3:]
    else:
        payload = b''; cursor = 3
        while cursor < len(data):
            part,cursor = expand_block(data,cursor)
            payload += part
    image[offset:offset+len(payload)] = payload
    covered.update(range(offset,offset+len(payload)))

# Resolve the known device-header fixups using assembler symbols and the
# BIOS load segment 0070h. This is a bounded comparison harness, not a linker.
fixups = []
for name, next_name, entry in devices:
    off = symbols[name]
    for where,value,meaning in [(off, symbols[next_name] if next_name else 0xffff, 'next offset'),
                                (off+2,0x70,'BIOS segment'),
                                (off+6,symbols['strategy'],'strategy'),
                                (off+8,symbols[entry],'entry')]:
        struct.pack_into('<H',image,where,value)
        fixups.append({'offset':where,'value':value,'meaning':meaning,'device':name})
start,end = symbols['res_dev_list'],symbols['RomVectors']
assert (start,end,symbols['orig13']) == (0x23,0x100,0xb4)
missing = sorted(set(range(start,end)) - covered)
assert missing == [0xb1,0xb2,0xb3]  # uninitialized alignment before Orig13
target = (root/'extras/build/target-io-inspect.bin').read_bytes()
assert hashlib.sha256(target).hexdigest() == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
target_offset = 0x5a6 + start
expected = target[target_offset:0x5a6+end]
actual = bytes(image[start:end])
diffs = [start+i for i,(a,b) in enumerate(zip(actual,expected))
         if start+i in covered and a!=b]
sha = lambda p:hashlib.sha256(p.read_bytes()).hexdigest()

# Assemble the two subsequent BIOS_CODE contributors in DOS 6 link order.
# Their WORD-aligned section sizes determine the external table placements.
tables = {}
module_lengths = {}
module_objects = {}
def listing_value(text, name, segment):
    hits = re.findall(r'(?im)^'+re.escape(name)+r'\s+(?:\.\s*)+\s*[^\r\n]*?\b([0-9A-F]{4})\s+'+segment+r'\b',text)
    assert len(hits)==1,(name,hits)
    return int(hits[0],16)
def segment_length(text):
    hits = re.findall(r"(?im)^BIOS_CODE\s+(?:\.\s*)+\s*([0-9A-F]{4})\s+WORD\s+PUBLIC",text)
    assert len(hits)==1,hits
    return int(hits[0],16)

module_lengths['msbio1'] = segment_length(listing)
for name in ('mschar','msdisk'):
    shutil.copyfile(stage/'refbios'/f'{name}.asm',stage/f'{name}.asm')
    module_cmd = [str(masm),'-Mx','-t','-W1','-I.','-Iinc','-Irefbios',
                  f'{name}.asm,{name}.obj,{name}.lst;']
    result = subprocess.run(module_cmd,cwd=stage,capture_output=True,timeout=30)
    (stage/f'{name}.log').write_bytes(result.stdout+result.stderr)
    assert result.returncode==0,name
    module_listing = (stage/f'{name}.lst').read_text(errors='replace')
    module_lengths[name] = segment_length(module_listing)
    module_objects[name] = sha(stage/f'{name}.obj')
    for label in (('con_table','prn_table','aux_table','tim_table') if name=='mschar' else ('dsktbl',)):
        tables[label] = listing_value(module_listing,label,'BIOS_CODE')
word_align = lambda value:(value+1)&~1
char_base = word_align(module_lengths['msbio1'])
disk_base = word_align(char_base+module_lengths['mschar'])
tables = {name:offset+(disk_base if name=='dsktbl' else char_base) for name,offset in tables.items()}
code = bytearray(image)
code_fixups = []
for where,value,meaning in [(symbols['strategy']+3,symbols['ptrsav'],'ptrsav'),
                            (symbols['strategy']+8,symbols['ptrsav']+2,'ptrsav+2')]:
    struct.pack_into('<H',code,where,value)
    code_fixups.append({'offset':where,'value':value,'meaning':meaning})
entries = [('con_entry','con_table'),('prn0_entry','prn_table'),('prn1_entry','prn_table'),
           ('prn2_entry','prn_table'),('prn3_entry','prn_table'),('aux0_entry','aux_table'),
           ('aux1_entry','aux_table'),('aux2_entry','aux_table'),('aux3_entry','aux_table'),
           ('tim_entry','tim_table'),('dsk_entry','dsktbl')]
for entry,table in entries:
    at = symbols[entry]
    assert code[at] == 0xe8
    displacement = (symbols['cdev_entry']-(at+3)) & 0xffff
    struct.pack_into('<H',code,at+1,displacement)
    struct.pack_into('<H',code,at+3,tables[table])
    code_fixups += [{'offset':at+1,'value':displacement,'meaning':entry+' call cdev_entry'},
                    {'offset':at+3,'value':tables[table],'meaning':table}]
common = symbols['cdev_entry']
for where,value,meaning in [(common+3,symbols['inHMA'],'inHMA'),
                            (common+11,symbols['dosdatasg'],'dosdatasg'),
                            (common+16,symbols['ptrsav']+2,'ptrsav+2'),
                            (common+24,symbols['cdev'],'cdev'),
                            (common+27,(symbols['EnsureA20On']-(common+29))&0xffff,'call EnsureA20On')]:
    struct.pack_into('<H',code,where,value)
    code_fixups.append({'offset':where,'value':value,'meaning':meaning})
code_start,code_end = symbols['strategy'],symbols['outchr']
assert set(range(code_start,code_end)) <= covered
code_diff = [p for p in range(code_start,code_end) if code[p] != target[0x5a6+p]]
entry_report = {'bios_start':code_start,'bios_end':code_end,'compared_bytes':code_end-code_start,
                'differences':code_diff,'fixups':code_fixups,'module_lengths':module_lengths,
                'module_objects':module_objects,'mschar_base':char_base,'msdisk_base':disk_base,
                'linked_tables':tables,'equal':not code_diff}
report = {'stage':str(stage),'source_sha256':sha(root/'bios/msbio1.asm'),
          'reference_sha256':sha(dos6/'bios/msbio1.asm'),'tool_sha256':sha(masm),
          'command':cmd,'object_sha256':sha(stage/'msbio1.obj'),
          'listing_sha256':sha(stage/'msbio1.lst'),
          'include_snapshot':{str(p.relative_to(stage)):sha(p) for d in ('inc','refbios')
                              for p in sorted((stage/d).rglob('*')) if p.is_file()},
          'bios_offset_start':start,'bios_offset_end':end,'target_file_offset':target_offset,
          'symbols':symbols,'fixups':fixups,'uninitialized_gaps':missing,
          'compared_bytes':end-start-len(missing),'differences':diffs,'equal':not diffs,
          'device_entry_comparison':entry_report,
          'scope':'Covered device-chain and device-entry bytes only; uninitialized padding excluded. Fixups are comparison assumptions, not a complete link or execution proof.'}
(root/'extras/docs/etc/evidence/m5-bios-device-chain.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k not in ('include_snapshot','fixups')},indent=2))
assert report['equal']
assert entry_report['equal']
