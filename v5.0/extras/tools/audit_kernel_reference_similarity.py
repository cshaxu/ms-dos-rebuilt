"""Compare linked kernel source files with available reference files."""
from pathlib import Path
import difflib
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
REFERENCES = {
    'opennt': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos'),
    'dos6': ROOT.parent / 'v6.0/dos',
}
link = ROOT / 'dos/msdos.lnk'
names = re.findall(r'(\w+)\.obj', link.read_text(), re.I)
if len(names) != 55 or len(set(n.lower() for n in names)) != len(names):
    raise ValueError('Unexpected kernel link list')
digest = lambda data: hashlib.sha256(data).hexdigest()
modules = []
for name in names:
    data = (ROOT / 'dos' / (name + '.asm')).read_bytes()
    record = {'module': name, 'source_sha256': digest(data), 'references': {}}
    for label, directory in REFERENCES.items():
        path = directory / (name + '.asm')
        if not path.is_file():
            record['references'][label] = {'available': False}
            continue
        reference = path.read_bytes()
        similarity = difflib.SequenceMatcher(None, data.splitlines(),
                                             reference.splitlines(), autojunk=False).ratio()
        record['references'][label] = {'available': True, 'sha256': digest(reference),
                                      'exact': data == reference,
                                      'line_similarity': round(similarity, 4)}
    modules.append(record)
summary = {label: {'available': sum(m['references'][label]['available'] for m in modules),
                   'exact': sum(m['references'][label].get('exact', False) for m in modules)}
           for label in REFERENCES}
print(json.dumps({'link_sha256': digest(link.read_bytes()), 'summary': summary,
                  'modules': modules,
                  'scope': 'Literal file comparison only; similarity does not establish provenance, target correspondence, or historical authorship.'}, indent=2))
