"""Inventory two historical NT directory flags in the fresh kernel inputs."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
fresh = json.loads((EVIDENCE/'m6-fresh-integrated-source-audit.json').read_text())
stage = Path(fresh['stage'])
build = json.loads((stage/'kernel-report.json').read_text())
source = ROOT/'kernel-source'
sha = lambda data: hashlib.sha256(data).hexdigest()
recorded = {key.replace('\\', '/').lower(): value for key, value in build['source_snapshot'].items()}
files = [p for p in source.rglob('*') if p.is_file()]
assert len(files) == len(recorded)
for path in files:
    assert sha(path.read_bytes()) == recorded[path.relative_to(source).as_posix().lower()]
pattern = re.compile(r'\b(?:CURDIR_TOSYNC|CURDIR_NT_FIX)\b', re.I)
source_hits = []
for path in files:
    for line, text in enumerate(path.read_text(encoding='latin1').splitlines(), 1):
        if pattern.search(text):
            source_hits.append({'path': path.relative_to(source).as_posix(), 'line': line, 'text': text.strip()})
assert len(source_hits) == 4
assert all(re.match(r'^CURDIR_(?:TOSYNC|NT_FIX)\s+EQU\s+', item['text'], re.I) for item in source_hits)
assert {x['path'].lower() for x in source_hits} == {'inc/kernel/curdir.inc', 'inc/ntvdm/curdir.inc'}
object_stage = Path(build['stage']); listing_hits = []
assert len(build['objects']) == 55
for name, expected in build['objects'].items():
    assert sha((object_stage/(name+'.obj')).read_bytes()) == expected
    body = (object_stage/(name+'.lst')).read_text(encoding='latin1').split('Symbols:', 1)[0]
    for line, text in enumerate(body.splitlines(), 1):
        if pattern.search(text): listing_hits.append({'module': name, 'line': line, 'text': text.strip()})
assert not listing_hits
report = {'source_snapshot_files': len(files), 'objects_and_listings': len(build['objects']),
          'source_hits': source_hits, 'listing_body_hits': listing_hits,
          'scope': 'Literal-name inventory only, including comments and inactive source; does not evaluate generated names, all macro expansion, or prove a source edit preserves the build. Definitions remain unchanged.'}
(EVIDENCE/'m6-curdir-nt-flag-inventory.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
