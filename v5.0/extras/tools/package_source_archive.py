"""Create a local source-only ZIP from the manifest verified by the fresh build."""
from pathlib import Path
import hashlib
import json
import zipfile

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
report = json.loads((EVIDENCE/'m6-source-package-candidate.json').read_text())
fresh = json.loads((EVIDENCE/'m6-fresh-integrated-source-audit.json').read_text())
snapshot = Path(report['stage']).resolve()
assert snapshot.parent == (ROOT/'extras/build').resolve()
original = json.loads((Path(fresh['workspace'])/'SOURCE-MANIFEST.json').read_text())
assert report['files'] == original['files']
sha = lambda data: hashlib.sha256(data).hexdigest()
contents = {}
for entry in report['files']:
    path = Path(entry['path'])
    assert not path.is_absolute() and not path.drive and '..' not in path.parts
    assert path.suffix.lower() not in {'.sys','.com','.exe','.exc','.obj','.map'}
    data = (snapshot/path).read_bytes()
    assert len(data) == entry['bytes'] and sha(data) == entry['sha256']
    contents[path.as_posix()] = data
contents['README.md'] = (snapshot/'README.md').read_bytes()
manifest = (snapshot/'SOURCE-MANIFEST.json').read_bytes()
assert json.loads(manifest) == report
contents['SOURCE-MANIFEST.json'] = manifest
archive = ROOT/'extras/build/msdos-5.00-source-candidate.zip'
with zipfile.ZipFile(archive, 'x', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
    for name, data in sorted(contents.items(), key=lambda item: item[0].lower()):
        info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
        info.compress_type = zipfile.ZIP_DEFLATED
        info.external_attr = 0o100644 << 16
        z.writestr(info, data, compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
with zipfile.ZipFile(archive) as z:
    assert z.testzip() is None
    assert set(z.namelist()) == set(contents) and len(z.namelist()) == len(contents)
    for name, data in contents.items(): assert z.read(name) == data
out = {'archive': str(archive), 'archive_sha256': sha(archive.read_bytes()), 'bytes': archive.stat().st_size,
       'source_files': len(report['files']), 'archive_entries': len(contents),
       'matches_fresh_build_inputs': True, 'source_snapshot': str(snapshot),
       'scope': 'Local research source archive only; contains no tool or target binaries. Original media, supplied-product runtime and redistribution rights remain unverified.'}
(EVIDENCE/'m6-source-archive.json').write_text(json.dumps(out, indent=2)+'\n', encoding='utf-8')
print(json.dumps(out, indent=2))
