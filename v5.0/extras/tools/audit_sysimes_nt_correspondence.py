"""Compare SYSIMES statements for the retained single-config BIOS build."""
from pathlib import Path
import hashlib
import json
from sysimes_source import active_lines

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\bios\sysimes.asm')
build = json.loads((EVIDENCE / 'm5-bios-singleconfig-probe.json').read_text())
messages = json.loads((EVIDENCE / 'm5-bios-message-source-verification.json').read_text())
stage = Path(build['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
current = (ROOT/'bios/sysimes.asm').read_bytes()
configured = (stage/'src/sysimes.asm').read_bytes()
assert digest(configured) == build['inputs']['src\\sysimes.asm']
nt_data = NT.read_bytes()
assert current == nt_data
nt_lines = active_lines(nt_data)
assert nt_lines == active_lines(configured) and len(nt_lines) == 13
unit = next(item for item in build['units'] if item['name'] == 'sysimes')
assert digest((stage/'sysimes.obj').read_bytes()) == unit['object_sha256']
cl3 = (ROOT/'bios/msbio.cl3').read_bytes()
assert cl3 == (stage/'msbio.cl3').read_bytes() and digest(cl3) == messages['source_sha256']
bios = (stage/'msbio.bin').read_bytes()
target = (ROOT/'extras/build/target-io-inspect.bin').read_bytes()
assert digest(bios) == messages['bios_sha256'] and digest(target) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
offset, size = messages['target_offset'], messages['length']
assert size == 472 and bios[offset:offset+size] == target[0x5a6+offset:0x5a6+offset+size]
report = {'nt_sha256': digest(nt_data), 'candidate_sha256': digest(current),
          'configured_sha256': digest(configured), 'object_sha256': unit['object_sha256'],
          'active_statements': nt_lines, 'message_source_sha256': digest(cl3),
          'message_length': size, 'message_io_offset': 0x5a6+offset,
          'scope': 'Current source equals NTIO; literal single-config statements match the retained build source. The retained object and target message interval are checked. No fresh assembly or complete object equivalence claim.'}
(EVIDENCE/'m6-sysimes-nt-correspondence.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'active_statements': len(nt_lines), 'message_bytes': size, 'message_io_offset': 0x5a6+offset, 'scope': report['scope']}, indent=2))
