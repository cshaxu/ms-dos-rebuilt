"""Compare selected complete include expansions in a retained MASM listing."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
build = json.loads((EVIDENCE / 'm2-t3-command-repeat-build.json').read_text())
package = Path(json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())['stage'])
stage = Path(build['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
output = (stage / 'command.com').read_bytes()
assert len(output) == build['output_bytes'] and digest(output) == build['output_sha256'] and build['target_match']
search = [ROOT / 'cmd/command', ROOT / 'inc', ROOT / 'extras/research/inc/ntvdm', ROOT / 'messages']
selected = [('command1', 'envdata.asm'), ('stub', 'comseg.asm'), ('tcode', 'pdb.inc'),
            ('tcode', 'arena.inc'), ('tcode', 'mshalo.asm'), ('tdata', 'error.inc'),
            ('tfor', 'fordata.asm'), ('uinit', 'resmsg.equ')]
objects = {item['name'].lower(): item['sha256'] for item in build['objects']}
records = []
for unit, name in selected:
    assert digest((stage / (unit + '.obj')).read_bytes()) == objects[unit]
    candidates = [directory / name for directory in search if (directory / name).is_file()]
    assert candidates
    source = candidates[0]
    relative = source.relative_to(ROOT)
    source_data = source.read_bytes()
    assert source_data == (package / relative).read_bytes()
    listing = (stage / (unit + '.lst')).read_bytes()
    lines = listing.decode('latin1').splitlines()
    pattern = re.compile(r'\\\s*include\s+' + re.escape(name) + r'(?:\s|$)', re.I)
    starts = [i for i, line in enumerate(lines) if pattern.search(line)]
    assert len(starts) == 1, (unit, name)
    expanded = []
    for line in lines[starts[0] + 1:]:
        match = re.search(r'C\\\s*(.*)$', line)
        if match:
            text = ' '.join(match[1].split())
            if text: expanded.append(text)
        elif re.search(r'^\s*\\', line):
            break
    else:
        raise ValueError('listing expansion end not found: ' + name)
    expected = [' '.join(line.split()) for line in source_data.decode('latin1').replace('\x1a', '').splitlines() if line.strip()]
    assert expected and expanded == expected, (unit, name)
    records.append({'unit': unit, 'include': relative.as_posix(), 'nonblank_lines': len(expected),
                    'source_sha256': digest(source_data), 'listing_sha256': digest(listing),
                    'object_sha256': objects[unit]})
report = {'stage': str(stage), 'package': str(package), 'command_sha256': digest(output), 'includes': records,
          'scope': 'Selected complete listing expansions only, compared after whitespace normalization; no claim about other includes, byte-for-byte source identity, listing provenance beyond the retained stage, or a fresh build.'}
(EVIDENCE / 'm6-command-listing-include-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'includes': len(records), 'nonblank_lines': sum(item['nonblank_lines'] for item in records), 'scope': report['scope']}, indent=2))
