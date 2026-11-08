"""Prepare disposable FAT12 media containing the existing three-file candidate."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import struct
import tempfile

from fat12_guest_file import read_root_file
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
parser = argparse.ArgumentParser()
parser.add_argument('--candidate-report', type=Path, default=evidence/'m6-three-file-existing-candidate.json')
parser.add_argument('--report', default='m6-integrated-vm-prepared.json')
args = parser.parse_args()
if Path(args.report).name != args.report: parser.error('--report must be a filename')
base = root / 'extras/build/command-vm-h0vnbc95/boot.img'
base_sha = '524d75d8ca40106bb77a515b4885b17e5a2d96ba0ccd38c9b91084b0fc269167'
product = Path(r'O:\DOS\softpc64.exe')
product_sha = '9f1212f8b26a5e98bb06b5fec601a6ff7cf6c499f16991dd68d62fb81ab75c3e'
sha = lambda data: hashlib.sha256(data).hexdigest()
assert sha(base.read_bytes()) == base_sha
assert sha(product.read_bytes()) == product_sha
candidate = json.loads(args.candidate_report.read_text())
source_dir = Path(candidate['stage'])
payloads = {}
for entry in candidate['files']:
    data = (source_dir / entry['name']).read_bytes()
    assert len(data) == entry['bytes'] and sha(data) == entry['sha256']
    assert read_root_file(base, entry['name']) == data
    payloads[entry['name']] = data
assert set(payloads) == {'IO.SYS', 'MSDOS.SYS', 'COMMAND.COM'}
for name in ('RESULTS.TXT', 'DONE.TXT', 'COPY.TXT', 'INPUT.TXT'):
    assert read_root_file(base, name) is None, name

auto = b'@echo off\r\ncall A:\\SMOKE.BAT\r\necho FINISHED>A:\\DONE.TXT\r\n'
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
'''.replace('\n', '\r\n').encode('ascii')

image = bytearray(base.read_bytes())
sector = struct.unpack_from('<H', image, 11)[0]
cluster_sectors = image[13]
reserved = struct.unpack_from('<H', image, 14)[0]
fats = image[16]
fat_sectors = struct.unpack_from('<H', image, 22)[0]
root_entries = struct.unpack_from('<H', image, 17)[0]
assert sector == 512 and cluster_sectors == 1 and fats == 2
root_offset = (reserved + fats * fat_sectors) * sector
data_offset = root_offset + ((root_entries * 32 + sector - 1) // sector) * sector
fat_offset = reserved * sector

def replace_file(name, data):
    stem, ext = name.split('.')
    wanted = (stem.ljust(8) + ext.ljust(3)).encode('ascii')
    slots = [p for p in range(root_offset, root_offset + root_entries * 32, 32)
             if image[p:p + 11] == wanted]
    assert len(slots) == 1, name
    slot = slots[0]
    cluster = struct.unpack_from('<H', image, slot + 26)[0]
    chain, seen = [], set()
    while 2 <= cluster < 0xff0:
        assert cluster not in seen
        seen.add(cluster)
        chain.append(cluster)
        position = fat_offset + cluster + cluster // 2
        word = int.from_bytes(image[position:position + 2], 'little')
        cluster = word >> 4 if cluster & 1 else word & 0xfff
    assert cluster >= 0xff8 and len(data) <= len(chain) * sector, name
    assert len(data) > (len(chain) - 1) * sector, name
    for index, cluster in enumerate(chain):
        start = data_offset + (cluster - 2) * sector
        chunk = data[index * sector:(index + 1) * sector]
        image[start:start + sector] = chunk.ljust(sector, b'\0')
    struct.pack_into('<I', image, slot + 28, len(data))

for name, data in payloads.items():
    replace_file(name, data)
replace_file('AUTOEXEC.BAT', auto)
replace_file('SMOKE.BAT', smoke)
stage = Path(tempfile.mkdtemp(prefix='integrated-vm-', dir=root / 'extras/build'))
path = stage / 'boot.img'
path.write_bytes(image)
for name, data in {**payloads, 'AUTOEXEC.BAT': auto, 'SMOKE.BAT': smoke}.items():
    assert read_root_file(path, name) == data, name
for name in ('RESULTS.TXT', 'DONE.TXT', 'COPY.TXT', 'INPUT.TXT'):
    assert read_root_file(path, name) is None, name
assert inspect(path)['image']['fat_copies_equal']
shutil.copyfile(product, stage / 'softpc64.exe')
assert sha((stage / 'softpc64.exe').read_bytes()) == product_sha
(stage / 'softpc.ini').write_text('floppy=boot.img\nfloppy_mode=direct\nhard_disk=\nmemory_mb=16\ndisplay=window\nconsole_control=0\nserial_output=serial.log\n', encoding='ascii')
report = {'stage': str(stage), 'base_image': str(base), 'base_sha256': base_sha,
          'test_image_sha256': sha(image), 'product_sha256': product_sha,
          'candidate_report': str(args.candidate_report),
          'system_files': {name: sha(data) for name, data in payloads.items()},
          'status': 'prepared; not executed',
          'scope': 'Disposable media using the named source-built candidate report and retained padded media. This is not original-image revalidation.'}
(evidence / args.report).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
