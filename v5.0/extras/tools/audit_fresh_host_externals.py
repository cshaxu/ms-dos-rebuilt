"""Inventory selected NT-host names in fresh 16-bit OMF EXTDEF records."""
from pathlib import Path
import argparse
import hashlib
import json
import re
from omf_emitted import omf_index

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
sha = lambda data: hashlib.sha256(data).hexdigest()
reports = {name: json.loads((stage/(name+'-report.json')).read_text()) for name in ('msload','bios','kernel','command')}
objects = []
for item in reports['bios']['units']:
    objects.append(('bios', item['name'], Path(reports['bios']['stage'])/(item['name']+'.obj'), item['object_sha256']))
for name, expected in reports['kernel']['objects'].items():
    objects.append(('kernel', name, Path(reports['kernel']['stage'])/(name+'.obj'), expected))
for item in reports['command']['objects']:
    objects.append(('command', item['name'], Path(reports['command']['stage'])/(item['name']+'.obj'), item['sha256']))
loader_stage = Path(reports['msload']['stage'])
assert sha((loader_stage/'msload.com').read_bytes()) == reports['msload']['output']['sha256']
assert (stage/'IO.SYS').read_bytes().startswith((loader_stage/'msload.com').read_bytes())
objects.append(('msload', 'msload', loader_stage/'msload.obj', None))
assert len(reports['bios']['units']) in (14, 15)
assert len(objects) == 1 + len(reports['bios']['units']) + len(reports['kernel']['objects']) + len(reports['command']['objects'])
pattern = re.compile(r'^dem|ntvdm|wow|^svc_|^spc|bop', re.I)
matches = []
counts = {}
object_rows = []
for group, module, path, expected in objects:
    data = path.read_bytes()
    if expected is not None: assert sha(data) == expected
    pos = 0; count = 0
    while pos < len(data):
        assert pos + 3 <= len(data)
        length = int.from_bytes(data[pos+1:pos+3], 'little')
        record = data[pos:pos+3+length]
        assert length > 0 and len(record) == 3+length and sum(record) % 256 == 0
        assert record[0] in {0x80,0x88,0x8a,0x8c,0x90,0x96,0x98,0x9a,0x9c,0xa0,0xa2}
        pos += len(record)
        if record[0] != 0x8c: continue
        body = record[3:-1]; i = 0
        while i < len(body):
            size = body[i]; i += 1
            assert size and i+size <= len(body)
            name = body[i:i+size].decode('latin1'); i += size
            _, i = omf_index(body, i)
            assert i <= len(body)
            count += 1
            if pattern.search(name): matches.append({'group': group, 'module': module, 'name': name})
    assert pos == len(data)
    counts[group] = counts.get(group, 0) + count
    object_rows.append({'group': group, 'module': module, 'sha256': sha(data), 'external_count': count})
report = {'stage': str(stage), 'name_pattern': pattern.pattern, 'object_count': len(objects),
          'external_counts': counts, 'matches': matches, 'objects': object_rows,
          'scope': 'Only EXTDEF names matching the documented regex in the listed fresh OMF objects; no claim about other names, fixup reachability, opcodes, indirect host calls, or runtime behavior.'}
report_path.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps({key: report[key] for key in ('object_count','external_counts','matches','scope')}, indent=2))
