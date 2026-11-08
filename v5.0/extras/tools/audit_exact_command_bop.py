"""Audit BOP byte signatures in retained exact COMMAND build objects."""
from pathlib import Path
import hashlib
import json

from fat12_guest_file import read_root_file
from omf_emitted import emitted_segments

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm2-t3-command-repeat-build.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
command = (stage / 'COMMAND.COM').read_bytes()
assert build['target_match'] and sha(command) == build['output_sha256']
assert command == read_root_file(root / 'extras/build/command-vm-h0vnbc95/boot.img', 'COMMAND.COM')
hits = []
counts = {'ledata': 0, 'lidata': 0, 'emitted_bytes': 0, 'conflicting_overwrites': 0}
objects = []
for unit in build['objects']:
    name = unit['name']
    data = (stage / (name + '.obj')).read_bytes()
    assert sha(data) == unit['sha256'], name
    objects.append({'module': name, 'sha256': sha(data)})
    segments, record_counts = emitted_segments(data, allow_overlaps=True)
    for key in ('ledata', 'lidata', 'conflicting_overwrites'):
        counts[key] += record_counts[key]
    for seg, emitted in segments.items():
        counts['emitted_bytes'] += len(emitted)
        for offset in sorted(emitted):
            if emitted[offset] == 0xc4 and emitted.get(offset + 1) == 0xc4:
                hits.append({'module': name, 'segment_index': seg, 'offset': offset,
                             'following_byte': emitted.get(offset + 2)})
report = {'stage': str(stage), 'command_sha256': sha(command), 'objects': objects,
          'record_counts': counts, 'hits': hits, 'hit_count': len(hits),
          'scope': 'C4 C4 byte patterns in LEDATA and expanded LIDATA of retained COMMAND objects, with record-order overwrites. Not a complete host-interface, fixup, source provenance or runtime audit.'}
(evidence / 'm3-command-exact-bop-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'objects': len(objects), **counts, 'hit_count': len(hits), 'hits': hits}, indent=2))
