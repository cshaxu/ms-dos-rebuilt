"""Check NTIO-derived MSEND against retained physical BIOS build evidence."""
from pathlib import Path
import hashlib
import json
from msend_recovery import recover
from sysimes_source import active_lines

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\bios\msend.asm')
build = json.loads((EVIDENCE/'m5-bios-singleconfig-probe.json').read_text())
stage = Path(build['stage'])
package = Path(json.loads((EVIDENCE/'m6-source-package-candidate.json').read_text())['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
nt = NT.read_bytes(); source = (ROOT/'bios/msend.asm').read_bytes()
assert source == recover(nt) == (package/'bios/msend.asm').read_bytes()
retained = (stage/'src/msend.asm').read_bytes()
assert sha(retained) == build['inputs']['src\\msend.asm']
statements = active_lines(source)
assert len(statements) == 19 and statements == active_lines(retained)
unit = next(item for item in build['units'] if item['name'] == 'msend')
assert sha((stage/'msend.obj').read_bytes()) == unit['object_sha256']
assert sha((stage/'msbio.bin').read_bytes()) == build['output']['sha256'] and build['output']['equal']
report = {'nt_sha256': sha(nt), 'source_sha256': sha(source), 'retained_source_sha256': sha(retained),
          'retained_object_sha256': unit['object_sha256'], 'active_statements': statements,
          'transformation': 'Remove NT SoftPC keyboard, mouse, and EMM segments; place SI_end at the end of sysinitseg.',
          'scope': 'NT-derived source and literal active statements compared to retained physical-build source. Historical object and BIOS checked; no fresh assembly or object equivalence claim.'}
(EVIDENCE/'m6-msend-nt-recovery.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k != 'active_statements'}, indent=2))
