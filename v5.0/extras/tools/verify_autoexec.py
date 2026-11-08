"""Bounded DOS 5 AUTOEXEC reconstruction checks; no runtime claim."""
from pathlib import Path
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
stage = Path(json.loads((root / 'extras/docs/etc/evidence/m2-t3-autoexec-build.json').read_text())['stage'])
symbols = {}
for line in (stage / 'command.map').read_text(encoding='latin1').splitlines():
    m = re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$', line)
    if m:
        symbols[m[3].lower()] = int(m[1], 16)*16 + int(m[2], 16)-256
with tempfile.TemporaryDirectory(prefix='dos5-autoexec-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
listing = (stage/'init.lst').read_text(encoding='latin1').splitlines()
mask = set()
labels = {}
for line in listing:
    m = re.match(r' ([0-9A-F]{4})  (.*?)\\(.*)', line)
    if not m:
        continue
    pos = int(m[1], 16)
    for label in ['DoDate', 'OpenErr', 'Drv0']:
        if re.match(r'\s*'+label+r':', m[3], re.I):
            labels[label] = pos
    previous = []
    for token in m[2].split():
        token = token.rstrip(':')
        if token in ('E', 'R'):
            mask.update(previous)
        elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}', token):
            previous = list(range(pos, pos+len(token)//2))
            pos += len(token)//2
start = symbols['conproc'] + labels['DoDate']
length = labels['OpenErr']-labels['DoDate']
differences = [i for i in range(length) if candidate[start+i] != target[0x197d+i] and labels['DoDate']+i not in mask]
# Both exits reach Drv0 outside this slice. The shorter current downstream
# path lets MASM relax the first jump to EB + NOP; do not hide this mismatch.
assert differences == [86, 87, 88, 150], differences
assert candidate[start+86] == 0xeb and candidate[start+88] == 0x90
assert start+88+int.from_bytes(candidate[start+87:start+88], 'little', signed=True) == symbols['conproc']+labels['Drv0']
assert candidate[start+149] == target[0x197d+149] == 0xeb
assert start+151+int.from_bytes(candidate[start+150:start+151], 'little', signed=True) == symbols['conproc']+labels['Drv0']
assert target[0x197d+86] == 0xe9
target_exit = 0x197d+89+int.from_bytes(target[0x197d+87:0x197d+89], 'little', signed=True)
assert target_exit == 0x197d+151+int.from_bytes(target[0x197d+150:0x197d+151], 'little', signed=True)
for name, offset, text in [('autobat', 0x1d6d, b'\0:\\AUTOEXEC.BAT\0\r'), ('kautobat', 0x1d7e, b'\0:\\KAUTOEXE.BAT\0\r')]:
    assert candidate[symbols[name]:symbols[name]+len(text)] == target[offset:offset+len(text)] == text
# RDATA begins immediately after the 256-byte PSP placeholder; MAP/listing bias
# is independently established by the existing reference-build record.
assert candidate[0x250:0x257] == target[0x250:0x257] == bytes.fromhex('bb0400b448cd21')
assert candidate[0x264:0x26a] == target[0x264:0x26a] == bytes.fromhex('b9210083c110')
assert candidate[symbols['conproc']+0x49e:symbols['conproc']+0x4a5] == target[0x18fe:0x1905] == bytes.fromhex('bb0400b448cd21')
out = {'candidate_start': start, 'target_start': 0x197d, 'length': length, 'unmasked_differences': differences,
       'exit_branch_semantics_verified': True, 'target_exit': target_exit,
       'masked_offsets': sorted(i-labels['DoDate'] for i in mask if labels['DoDate'] <= i < labels['OpenErr']),
       'filename_bytes_exact': True, 'allocation_and_copy_operands_exact': True,
       'limitation': 'Annotated address operands masked in initialization region; full layout and runtime remain unverified.'}
(root/'extras/docs/etc/evidence/m2-t3-autoexec-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
