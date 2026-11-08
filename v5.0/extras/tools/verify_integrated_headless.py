"""Verify guest artifacts from the bounded headless integrated candidate probe."""
from pathlib import Path
import argparse
import hashlib
import json

from fat12_guest_file import read_root_file
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
parser = argparse.ArgumentParser()
parser.add_argument('--prepared', default='m6-integrated-vm-prepared.json')
parser.add_argument('--output', default='m6-integrated-headless-runtime.json')
args = parser.parse_args()
if any(Path(name).name != name for name in (args.prepared, args.output)):
    parser.error('prepared and output must be filenames')
prepared = json.loads((evidence / args.prepared).read_text())
stage = Path(prepared['stage'])
image = stage / 'boot.img'
probe = root / 'extras/build/softpc-probe-56iubdoq/probe.exe'
sha = lambda data: hashlib.sha256(data).hexdigest()
assert sha(probe.read_bytes()) == 'b5b718d3f27e09242ae859b48756d80b83ba1d56843f7234962e7b3f17aa7aaa'
assert sha(Path(prepared['base_image']).read_bytes()) == prepared['base_sha256']
log = (stage / 'headless-probe.log').read_bytes()
for marker in (b'create=0', b'started state=1', b'state-before-stop=2', b'video-read=0'):
    assert marker in log, marker
files = {name: read_root_file(image, name) for name in ('RESULTS.TXT', 'DONE.TXT', 'COPY.TXT', 'INPUT.TXT')}
results = files['RESULTS.TXT'] or b''
markers = ['BEGIN-DOS5-SMOKE', 'MS-DOS Version 5.00', 'ENV-PASS', 'PATH=A:\\',
           'FOR-ONE', 'FOR-TWO', 'FOR-THREE', 'FILE-CONTENT', 'FILE-PASS', 'CHILD-PASS', 'SMOKE-PASS']
assert all(marker.encode('ascii') in results for marker in markers)
assert b'SMOKE-FAIL' not in results
assert files['DONE.TXT'] == b'FINISHED\r\n'
assert files['COPY.TXT'] == b'FILE-CONTENT\r\n'
assert files['INPUT.TXT'] is None
for name, expected in prepared['system_files'].items():
    assert sha(read_root_file(image, name)) == expected, name
assert inspect(image)['image']['fat_copies_equal']
report = {'stage': str(stage), 'probe_sha256': sha(probe.read_bytes()),
          'probe_log_sha256': sha(log), 'test_image_before_sha256': prepared['test_image_sha256'],
          'test_image_after_sha256': sha(image.read_bytes()), 'system_files': prepared['system_files'],
          'markers': markers, 'guest_files': {k: v.decode('ascii') if v is not None else None for k, v in files.items()},
          'passed': True,
          'candidate_report': prepared['candidate_report'],
          'scope': 'Bounded headless SoftPC core probe using the named three-file candidate on disposable media. This is not the O:\\DOS product executable or original-image revalidation.'}
(evidence / args.output).write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
