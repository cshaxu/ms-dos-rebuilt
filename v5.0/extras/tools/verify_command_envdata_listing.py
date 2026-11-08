"""Compare ENVDATA source text with its retained MASM listing expansion."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
build = json.loads((EVIDENCE / 'm2-t3-command-repeat-build.json').read_text())
candidate = json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())
stage = Path(build['stage'])
package = Path(candidate['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()

unit = next(item for item in build['objects'] if item['name'].lower() == 'command1')
assert digest((stage / 'command1.obj').read_bytes()) == unit['sha256']
output = (stage / 'command.com').read_bytes()
assert len(output) == build['output_bytes'] and digest(output) == build['output_sha256']
assert build['target_match']
source_path = ROOT / 'cmd/command/envdata.asm'
source = source_path.read_bytes()
assert source == (package / 'cmd/command/envdata.asm').read_bytes()
listing = (stage / 'command1.lst').read_bytes()
lines = listing.decode('latin1').splitlines()
starts = [i for i, line in enumerate(lines)
          if re.search(r'\\\s*include\s+envdata\.asm(?:\s|$)', line, re.I)]
assert len(starts) == 1
expanded = []
for line in lines[starts[0] + 1:]:
    match = re.search(r'C\\\s*(.*)$', line)
    if match:
        expanded.append(' '.join(match[1].split()))
    elif re.search(r'^\s*\\', line):
        break
else:
    raise ValueError('end of listing expansion not found')
expected = [' '.join(line.split()) for line in source.decode('latin1').replace('\x1a', '').splitlines() if line.strip()]
actual = [line for line in expanded if line]
assert len(expected) == 18 and actual == expected
report = {
    'stage': str(stage), 'source': 'cmd/command/envdata.asm',
    'source_sha256': digest(source), 'listing': 'command1.lst',
    'listing_sha256': digest(listing), 'command1_obj_sha256': unit['sha256'],
    'command_sha256': digest(output), 'nonblank_lines_compared': len(actual),
    'result': 'All nonblank source lines equal the retained listing expansion after whitespace normalization.',
    'scope': 'Bounded text comparison for one included file in one retained build; does not prove byte identity, other includes, listing provenance beyond the retained stage, or a fresh build.',
}
(EVIDENCE / 'm6-command-envdata-listing-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
