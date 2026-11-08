"""Record selected physical-versus-NTIO MSCHAR source differences."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
nt_path = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\bios\mschar.asm')
source_path = ROOT/'bios/mschar.asm'
build = json.loads((EVIDENCE/'m5-bios-singleconfig-probe.json').read_text())
package = Path(json.loads((EVIDENCE/'m6-source-package-candidate.json').read_text())['stage'])
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
nt, candidate = nt_path.read_bytes(), source_path.read_bytes()
assert candidate == (package/'bios/mschar.asm').read_bytes() == (stage/'src/mschar.asm').read_bytes()
assert sha(candidate) == build['inputs']['src\\mschar.asm']
unit = next(x for x in build['units'] if x['name'] == 'mschar')
assert sha((stage/'mschar.obj').read_bytes()) == unit['object_sha256']
bios = (stage/'msbio.bin').read_bytes(); target = (ROOT/'extras/build/target-io-inspect.bin').read_bytes()
assert sha(bios) == build['output']['sha256'] and build['output']['equal']
assert sha(target) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
assert bios == target[0x5a6:]

def lines(data, pattern):
    return [index for index, line in enumerate(data.decode('latin1').splitlines(), 1)
            if re.search(pattern, line, re.I)]

checks = [
    ('printer_host_bop', r'^\s*bop\s+%BIOS_PRINTER_IO\b', r'^\s*bop\s+%BIOS_PRINTER_IO\b', 2, 0),
    ('host_video_fast_path', r'^\s*mov\s+bx,word ptr \[int29Perf\]', r'^\s*mov\s+bx,word ptr \[int29Perf\]', 1, 0),
    ('physical_keyboard_wait', r'^\s*int\s+15h\b', r'^\s*int\s+15h\b', 0, 1),
    ('clock_read_procedure', r'^\s*tim_read\s+proc\b', r'^\s*tim_read\s+proc\b', 0, 1),
    ('clock_write_procedure', r'^\s*tim_writ\s+proc\b', r'^\s*tim_writ\s+proc\b', 0, 1),
]
seams = []
for name, nt_pattern, candidate_pattern, nt_count, candidate_count in checks:
    nt_lines, candidate_lines = lines(nt, nt_pattern), lines(candidate, candidate_pattern)
    assert len(nt_lines) == nt_count and len(candidate_lines) == candidate_count, name
    seams.append({'name': name, 'opennt_lines': nt_lines, 'candidate_lines': candidate_lines})
report = {'opennt_source_sha256': sha(nt), 'candidate_source_sha256': sha(candidate),
          'retained_object_sha256': unit['object_sha256'], 'bios_sha256': sha(bios),
          'seams': seams,
          'scope': 'Selected lexical source differences plus identity of retained MSCHAR object and full BIOS target comparison; not a complete host-seam inventory, per-instruction mapping, or runtime validation.'}
(EVIDENCE/'m6-mschar-nt-seam-audit.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
