"""Compare the current tree with the inputs of the retained integrated build."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
audit = json.loads((ROOT / 'extras/docs/etc/evidence/m6-fresh-integrated-source-audit.json').read_text())
workspace = Path(audit['workspace']).resolve()
if not workspace.is_relative_to((ROOT / 'extras/build').resolve()):
    raise ValueError('Build workspace is outside the project build directory')
manifest_bytes = (workspace / 'SOURCE-MANIFEST.json').read_bytes()
sha = lambda data: hashlib.sha256(data).hexdigest()
if sha(manifest_bytes) != audit['manifest_sha256']:
    raise ValueError('Build input manifest does not match the recorded audit')
manifest = json.loads(manifest_bytes)
failures = []
seen = set()
for item in manifest['files']:
    rel = Path(item['path'])
    if rel.is_absolute() or rel.drive or '..' in rel.parts or str(rel).lower() in seen:
        raise ValueError(f'Invalid or duplicate manifest path: {rel}')
    seen.add(str(rel).lower())
    try:
        current = (ROOT / rel).read_bytes()
        snapshot = (workspace / rel).read_bytes()
    except FileNotFoundError:
        failures.append({'path': str(rel), 'reason': 'missing'})
        continue
    if len(snapshot) != item['bytes'] or sha(snapshot) != item['sha256']:
        failures.append({'path': str(rel), 'reason': 'snapshot differs from manifest'})
    elif current != snapshot:
        failures.append({'path': str(rel), 'reason': 'current file differs from snapshot'})
result = {'manifest_sha256': sha(manifest_bytes), 'files_checked': len(seen),
          'equal': not failures, 'failures': failures,
          'scope': 'Listed inputs only; does not prove unlisted dependencies or rebuild outputs.'}
print(json.dumps(result, indent=2))
if failures:
    raise SystemExit(1)
