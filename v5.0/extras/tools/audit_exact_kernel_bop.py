"""Audit emitted C4 C4 host-call signatures in the exact kernel objects."""
from pathlib import Path
import hashlib
import json

from omf_emitted import emitted_segments

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm4-t5-consolidated-kernel-build.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
assert build['exact'] and len(build['objects']) == 55
source_root = root / 'kernel-source'
current_sources = {str(path.relative_to(source_root)): sha(path.read_bytes())
                   for path in source_root.rglob('*') if path.is_file()}
assert current_sources == build['source_snapshot'], 'current source differs from exact build'
kernel = (stage / 'MSDOS.SYS').read_bytes()
assert sha(kernel) == build['output_sha256'] == build['target_sha256']
assert kernel == (root / 'extras/build/target-kernel-inspect.bin').read_bytes()

hits = []
counts = {'ledata': 0, 'lidata': 0, 'emitted_bytes': 0}
objects = []
for name, expected_hash in build['objects'].items():
    data = (stage / (name + '.obj')).read_bytes()
    assert sha(data) == expected_hash, name
    objects.append({'module': name, 'sha256': expected_hash})
    segments, record_counts = emitted_segments(data)
    counts['ledata'] += record_counts['ledata']
    counts['lidata'] += record_counts['lidata']
    for seg, emitted in segments.items():
        counts['emitted_bytes'] += len(emitted)
        for offset in sorted(emitted):
            if emitted[offset] == 0xc4 and emitted.get(offset + 1) == 0xc4:
                hits.append({'module': name, 'segment_index': seg, 'offset': offset,
                             'following_byte': emitted.get(offset + 2)})
report = {'stage': str(stage), 'kernel_sha256': sha(kernel), 'objects': objects,
          'source_files_verified': len(current_sources), 'record_counts': counts, 'hits': hits, 'hit_count': len(hits),
          'scope': 'C4 C4 byte patterns in emitted LEDATA and expanded LIDATA of 55 hash-checked exact-build objects. This is not a complete audit of other host interfaces, fixup effects or runtime behavior.'}
(evidence / 'm4-t5-exact-kernel-bop-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'objects': len(objects), 'source_files': len(current_sources), **counts, 'hit_count': len(hits), 'hits': hits}, indent=2))
