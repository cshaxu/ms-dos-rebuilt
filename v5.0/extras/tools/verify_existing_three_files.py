"""Collect existing source-built files and compare them to retained FAT12 media."""
from pathlib import Path
import hashlib
import json
import tempfile

from fat12_guest_file import read_root_file

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
digest = lambda data: hashlib.sha256(data).hexdigest()
reports = {
    'IO.SYS': ('m5-io-combined-verification.json', 'IO.SYS', 33430,
               'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'),
    'MSDOS.SYS': ('m4-t5-consolidated-kernel-build.json', 'MSDOS.SYS', 37394,
                  '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'),
    'COMMAND.COM': ('m2-t3-command-repeat-build.json', 'COMMAND.COM', 47845,
                    '74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'),
}
media = [
    (root / 'extras/build/command-vm-5e3s_yo_/boot.img', '30f75d94c68e94eeebee002a20197fd7633d5ee31dfadc1eb58f70beb26e15f9'),
    (root / 'extras/build/command-vm-h0vnbc95/boot.img', '524d75d8ca40106bb77a515b4885b17e5a2d96ba0ccd38c9b91084b0fc269167'),
]
for image, expected in media:
    assert digest(image.read_bytes()) == expected, image

payloads = {}
entries = []
for name, (report_name, filename, size, expected) in reports.items():
    report = json.loads((evidence / report_name).read_text())
    source = Path(report['stage']) / filename
    data = source.read_bytes()
    assert len(data) == size and digest(data) == expected, name
    for image, _ in media:
        assert read_root_file(image, name) == data, (name, image)
    payloads[name] = data
    entries.append({'name': name, 'source_report': report_name, 'source': str(source),
                    'bytes': size, 'sha256': expected, 'equal_to_both_media': True})

stage = Path(tempfile.mkdtemp(prefix='three-file-candidate-', dir=root / 'extras/build'))
for name, data in payloads.items():
    (stage / name).write_bytes(data)
    assert (stage / name).read_bytes() == data
report = {'stage': str(stage), 'files': entries,
          'media': [{'path': str(path), 'sha256': sha} for path, sha in media],
          'scope': 'Collection of existing source-built candidates; two retained media copies share the original baseline. Not a new integrated build, original-image revalidation, boot test or deployment.'}
(evidence / 'm6-three-file-existing-candidate.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps(report, indent=2))
