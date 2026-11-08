r"""Create owned FAT12 test media; original image and O:\DOS stay read-only."""
from pathlib import Path
import hashlib
import json
import shutil
import struct
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
source = Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
baseline = inspect(source)
assert baseline['image']['sha256'] == '168bd67f0d0feaca7f47c0677e64aab51666460c116dd8bbaf8343e83364948c'
report = json.loads((root/'extras/docs/etc/evidence/m2-t3-command-repeat-build.json').read_text())
command = (Path(report['stage'])/'command.com').read_bytes()
assert hashlib.sha256(command).hexdigest() == baseline['files']['COMMAND.COM']['sha256']
stage = Path(tempfile.mkdtemp(prefix='command-vm-', dir=root/'extras/build'))
b = bytearray(source.read_bytes())
b.extend(bytes(baseline['image']['bpb_bytes']-len(b)))
bs = baseline['image']['bytes_per_sector']; spf = baseline['image']['fat_sectors']
reserved = baseline['image']['reserved_sectors']; spc = baseline['image']['sectors_per_cluster']
assert bs == 512 and spc == 1
fat_offset = reserved*bs
root_offset = (reserved+2*spf)*bs
data_offset = baseline['image']['data_offset']
def get_fat(cluster):
    n = fat_offset+cluster+cluster//2
    word = int.from_bytes(b[n:n+2], 'little')
    return (word >> 4) if cluster & 1 else word & 0xfff
def set_fat(cluster, value):
    for f in range(2):
        n = fat_offset+f*spf*bs+cluster+cluster//2
        word = int.from_bytes(b[n:n+2], 'little')
        word = ((word & 15) | (value << 4)) if cluster & 1 else ((word & 0xf000) | value)
        b[n:n+2] = word.to_bytes(2, 'little')
def entry(name):
    stem, ext = name.split('.')
    return stem.ljust(8).encode()+ext.ljust(3).encode()
def add_file(name, payload):
    assert not any(b[p:p+11] == entry(name) for p in range(root_offset, data_offset, 32))
    slot = next(p for p in range(root_offset, data_offset, 32) if b[p] in (0, 0xe5))
    needed = (len(payload)+bs-1)//bs
    available = [c for c in range(2, (len(b)-data_offset)//bs+2) if get_fat(c) == 0][:needed]
    assert len(available) == needed
    for i,c in enumerate(available):
        set_fat(c, available[i+1] if i+1 < needed else 0xfff)
        off = data_offset+(c-2)*bs
        b[off:off+bs] = payload[i*bs:(i+1)*bs].ljust(bs, b'\0')
    e = bytearray(32); e[:11] = entry(name); e[11] = 0x20
    struct.pack_into('<H', e, 26, available[0]); struct.pack_into('<I', e, 28, len(payload))
    b[slot:slot+32] = e
# Explicitly put source-built COMMAND into the existing chain; identity does
# not excuse treating the original target file as the reconstruction output.
slot = next(p for p in range(root_offset, data_offset, 32) if b[p:p+11] == entry('COMMAND.COM'))
c = struct.unpack_from('<H', b, slot+26)[0]; position = 0
while c < 0xff8:
    off = data_offset+(c-2)*bs; chunk = command[position:position+bs]
    b[off:off+len(chunk)] = chunk; position += len(chunk); c = get_fat(c)
assert position == len(command)
auto = '@echo off\r\ncall A:\\SMOKE.BAT\r\necho FINISHED>A:\\DONE.TXT\r\n'
smoke = r'''@echo off
echo BEGIN-DOS5-SMOKE>A:\RESULTS.TXT
ver >> A:\RESULTS.TXT
set TESTVAR=DOS5VALUE
if not "%TESTVAR%"=="DOS5VALUE" goto fail
echo ENV-PASS>>A:\RESULTS.TXT
path A:\
path >> A:\RESULTS.TXT
for %%i in (ONE TWO THREE) do echo FOR-%%i>>A:\RESULTS.TXT
echo FILE-CONTENT>A:\INPUT.TXT
copy A:\INPUT.TXT A:\COPY.TXT > nul
if errorlevel 1 goto fail
if not exist A:\COPY.TXT goto fail
type A:\COPY.TXT >> A:\RESULTS.TXT
del A:\INPUT.TXT
if exist A:\INPUT.TXT goto fail
echo FILE-PASS>>A:\RESULTS.TXT
A:\COMMAND.COM /C echo CHILD-PASS>>A:\RESULTS.TXT
if errorlevel 1 goto fail
goto passed
:fail
echo SMOKE-FAIL>>A:\RESULTS.TXT
goto end
:passed
echo SMOKE-PASS>>A:\RESULTS.TXT
:end
'''
add_file('AUTOEXEC.BAT', auto.encode('ascii'))
add_file('SMOKE.BAT', smoke.replace('\n', '\r\n').encode('ascii'))
image = stage/'boot.img'; image.write_bytes(b)
assert inspect(image)['files'] == baseline['files']
shutil.copyfile(r'O:\DOS\softpc64.exe', stage/'softpc64.exe')
(stage/'softpc.ini').write_text('floppy=boot.img\nfloppy_mode=direct\nhard_disk=\nmemory_mb=16\ndisplay=window\nconsole_control=0\nserial_output=serial.log\n', encoding='ascii')
(stage/'SMOKE.BAT').write_bytes(smoke.replace('\n', '\r\n').encode('ascii'))
out = {'stage': str(stage), 'original_sha256': baseline['image']['sha256'],
       'test_image_sha256': hashlib.sha256(b).hexdigest(),
       'softpc_sha256': hashlib.sha256((stage/'softpc64.exe').read_bytes()).hexdigest(),
       'source_build_report': 'm2-t3-command-repeat-build.json',
       'assumption': 'Missing media tail zero-padded only in disposable test copy.',
       'fixture_components': ['IO.SYS', 'MSDOS.SYS'], 'source_built_components': ['COMMAND.COM'],
       'status': 'prepared; guest execution not yet verified'}
(root/'extras/docs/etc/evidence/m3-t4-prepared.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
