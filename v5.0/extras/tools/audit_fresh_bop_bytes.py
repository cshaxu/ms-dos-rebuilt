"""Scan complete fresh/deployed output bytes for the NT BOP signature."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
parser = argparse.ArgumentParser()
parser.add_argument('--stage', required=True, help='integrated-source directory name under build/')
parser.add_argument('--report', required=True, help='new evidence filename')
args = parser.parse_args()
if Path(args.stage).name != args.stage or not args.stage.startswith('integrated-source-'):
    parser.error('--stage must be an integrated-source directory name')
if Path(args.report).name != args.report:
    parser.error('--report must be a filename')
stage = (ROOT/'extras/build'/args.stage).resolve()
if not stage.is_relative_to((ROOT/'extras/build').resolve()):
    raise ValueError('stage outside build directory')
report_path = EVIDENCE/args.report
if report_path.exists():
    raise FileExistsError(report_path)
build = json.loads((EVIDENCE/f'm6-integrated-{args.stage}.json').read_text())
if Path(build['stage']).resolve() != stage:
    raise ValueError('integrated report stage mismatch')
sha = lambda data: hashlib.sha256(data).hexdigest()
rows = []
for item in build['files']:
    name = item['name']
    data = (stage/name).read_bytes()
    deployed = (Path(r'O:\DOS')/name).read_bytes()
    assert len(data) == item['bytes'] and sha(data) == item['sha256'] and deployed == data
    offsets = []
    start = 0
    while True:
        pos = data.find(b'\xc4\xc4', start)
        if pos < 0: break
        offsets.append(pos)
        start = pos + 1
    rows.append({'name': name, 'bytes': len(data), 'sha256': sha(data), 'offsets': offsets})
report = {'stage': str(stage), 'signature_hex': 'c4c4', 'files': rows,
          'scope': 'Raw byte scan of entire fresh and deployed files after linking; absence of this exact signature does not rule out other host interfaces, altered encodings, or runtime dependencies.'}
report_path.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
