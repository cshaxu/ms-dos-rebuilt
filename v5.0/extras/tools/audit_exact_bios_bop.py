"""Audit BOP byte signatures in exact BIOS comparison build objects."""
from pathlib import Path
import hashlib
import json

from omf_emitted import emitted_segments

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
build = json.loads((evidence / 'm5-bios-singleconfig-probe.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
assert build['candidate'] and build['oembase'] and build['singleconfig']
assert build['output']['equal'] and len(build['units']) == 15
bios = (stage / 'msbio.bin').read_bytes()
target = (root / 'extras/build/target-io-inspect.bin').read_bytes()
assert sha(target) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
assert sha(bios) == build['output']['sha256'] and bios == target[0x5a6:]
hits = []
counts = {'ledata': 0, 'lidata': 0, 'emitted_bytes': 0}
objects = []
for unit in build['units']:
    name = unit['name']
    assert unit['exit'] == 0
    data = (stage / (name + '.obj')).read_bytes()
    assert sha(data) == unit['object_sha256'], name
    objects.append({'module': name, 'sha256': sha(data)})
    segments, record_counts = emitted_segments(data)
    counts['ledata'] += record_counts['ledata']
    counts['lidata'] += record_counts['lidata']
    for seg, emitted in segments.items():
        counts['emitted_bytes'] += len(emitted)
        for offset in sorted(emitted):
            if emitted[offset] == 0xc4 and emitted.get(offset + 1) == 0xc4:
                hits.append({'module': name, 'segment_index': seg, 'offset': offset,
                             'following_byte': emitted.get(offset + 2)})
loader_build = json.loads((evidence / 'm5-msload-candidate-build.json').read_text())
loader_stage = Path(loader_build['stage'])
loader = (loader_stage / 'msload.com').read_bytes()
assert loader == target[:0x5a6] and sha(loader) == loader_build['output']['sha256']
assert sha((root / 'bios/msload.asm').read_bytes()) == loader_build['inputs']['msload.asm']
loader_object = (loader_stage / 'msload.obj').read_bytes()
assert sha(loader_object) == '47487917af41e2ad50fad41b73849a33e93ca28f5cd8ba8b220b78f5026ba9d0'
loader_segments, loader_counts = emitted_segments(loader_object)
loader_hits = [{'segment_index': seg, 'offset': offset, 'following_byte': emitted.get(offset + 2)}
               for seg, emitted in loader_segments.items() for offset in sorted(emitted)
               if emitted[offset] == 0xc4 and emitted.get(offset + 1) == 0xc4]
loader_audit = {'stage': str(loader_stage), 'object_sha256': sha(loader_object),
                'record_counts': loader_counts, 'emitted_bytes': sum(map(len, loader_segments.values())),
                'hits': loader_hits, 'hit_count': len(loader_hits)}
report = {'stage': str(stage), 'bios_sha256': sha(bios), 'objects': objects,
          'record_counts': counts, 'hits': hits, 'hit_count': len(hits), 'msload': loader_audit,
          'scope': 'C4 C4 byte patterns in emitted LEDATA and expanded LIDATA of 15 hash-checked exact-build BIOS objects. Not a complete audit of other host interfaces, fixup effects or runtime behavior. MSLOAD object hash is independently recorded by this audit, not the original build report.'}
(evidence / 'm5-bios-exact-bop-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'objects': len(objects), **counts, 'hit_count': len(hits), 'hits': hits, 'msload_hits': len(loader_hits)}, indent=2))
