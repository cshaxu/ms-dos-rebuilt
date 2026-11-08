"""Compare retained application-compatibility data with reference sources."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
DOS6 = ROOT.parent / 'v6.0'
OPENNT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos')
digest = lambda data: hashlib.sha256(data).hexdigest()
cases = [
    ('Sidekick and PortOfEntry', ROOT/'dos/dostab.asm',
     DOS6/'dos/dostab.asm', b'; Patch for Sidekick', b';*** New FCB Implementation'),
    ('Windows patch data', ROOT/'inc/wpatch.inc',
     DOS6/'inc/wpatch.inc', b'DOSDATA\tSegment', None),
    ('EXEPATCH module', ROOT/'dos/exepatch.asm',
     OPENNT/'exepatch.asm', None, None),
]
result = []
for label, source, reference, first, last in cases:
    a, b = source.read_bytes(), reference.read_bytes()
    if first is not None:
        a, b = a[a.index(first):], b[b.index(first):]
    if last is not None:
        a, b = a[:a.index(last)], b[:b.index(last)]
    if a != b:
        raise ValueError(f'{label}: reference bytes differ')
    result.append({'name': label, 'source': str(source.relative_to(ROOT)),
                   'reference': str(reference), 'compared_bytes': len(a),
                   'sha256': digest(a), 'identical': True})
print(json.dumps({'comparisons': result,
                  'scope': 'Source correspondence only; not proof of original DOS 5 authorship.'}, indent=2))
