"""Independently audit a retained fresh three-component source build."""
from pathlib import Path
import hashlib
import json
import re
import sys
from fat12_guest_file import read_root_file
from command_build_provenance import retained_inputs

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
stage = Path(sys.argv[1]).resolve()
workspace = stage.parent.parent
assert stage.name.startswith('integrated-source-') and stage.parent.name == 'build'
assert workspace.is_relative_to((ROOT/'extras/build').resolve())
provision = json.loads((workspace/'extras/build/workspace-inputs.json').read_text())
assert Path(provision['workspace']).resolve() == workspace
sha = lambda data: hashlib.sha256(data).hexdigest()
manifest_bytes = (workspace/'SOURCE-MANIFEST.json').read_bytes()
assert sha(manifest_bytes) == provision['manifest_sha256']
manifest = json.loads(manifest_bytes)
for item in manifest['files']:
    rel = Path(item['path'])
    assert not rel.is_absolute() and not rel.drive and '..' not in rel.parts
    data = (workspace/rel).read_bytes()
    assert len(data) == item['bytes'] and sha(data) == item['sha256'], rel
reports = {name: json.loads((stage/(name+'-report.json')).read_text()) for name in ('msload','bios','kernel','command')}
assert reports['msload']['local_source'] and all(reports['bios'][x] for x in ('local_source','candidate','oembase','singleconfig'))
command_provenance = retained_inputs(reports['command'])
assert command_provenance['mode'] == 'build-stage-source-snapshot'
old = {'bios': json.loads((EVIDENCE/'m5-bios-singleconfig-probe.json').read_text()),
       'kernel': json.loads((EVIDENCE/'m4-t5-consolidated-kernel-build.json').read_text()),
       'command': json.loads((EVIDENCE/'m2-t3-command-repeat-build.json').read_text())}
def objects(name, report):
    if name == 'bios': return {x['name']: x['object_sha256'] for x in report['units']}
    if name == 'command': return {x['name']: x['sha256'] for x in report['objects']}
    return report['objects']
counts = {}
for name, expected_count in [('bios',15),('kernel',55),('command',34)]:
    a, b = objects(name, old[name]), objects(name, reports[name])
    assert a == b and len(a) == expected_count
    objstage = Path(reports[name]['stage'])
    for module, expected in b.items(): assert sha((objstage/(module+'.obj')).read_bytes()) == expected
    counts[name] = len(b)
logs = []
for name, expected_logs in [('msload',1),('bios',2),('kernel',2),('command',2)]:
    component = Path(reports[name]['stage'])
    host_logs = sorted(component.glob('*-host.log'))
    assert len(host_logs) == expected_logs
    for path in host_logs:
        data = path.read_bytes()
        assert re.search(rb'private-desktop=DOS5Build_\d+_\d+ owned-pid=\d+', data)
        assert b'child-exit=0 timeout=0' in data
        logs.append({'component': name, 'name': path.name, 'sha256': sha(data)})
media = workspace/'extras/build/command-vm-5e3s_yo_/boot.img'
assert sha(media.read_bytes()) == '30f75d94c68e94eeebee002a20197fd7633d5ee31dfadc1eb58f70beb26e15f9'
targets = {'IO.SYS':(33430,'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'),
           'MSDOS.SYS':(37394,'4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'),
           'COMMAND.COM':(47845,'74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89')}
files = []
for name, (length, expected) in targets.items():
    data = (stage/name).read_bytes()
    assert len(data) == length and sha(data) == expected and data == read_root_file(media,name)
    files.append({'name': name, 'bytes': length, 'sha256': expected, 'byte_equal': True})
assert (stage/'IO.SYS').read_bytes() == (Path(reports['msload']['stage'])/'msload.com').read_bytes() + (Path(reports['bios']['stage'])/'msbio.bin').read_bytes()
assert (stage/'MSDOS.SYS').read_bytes() == (Path(reports['kernel']['stage'])/'msdos.sys').read_bytes()
assert (stage/'COMMAND.COM').read_bytes() == (Path(reports['command']['stage'])/'command.com').read_bytes()
report = {'stage': str(stage), 'workspace': str(workspace), 'manifest_sha256': sha(manifest_bytes),
          'source_files_verified': len(manifest['files']), 'command_snapshot_files': len(command_provenance['files']),
          'objects_equal_to_prior_exact_build': counts, 'private_desktop_logs': logs, 'files': files,
          'media_sha256': sha(media.read_bytes()),
          'scope': 'Fresh source snapshot build and direct comparison against pinned retained media; original image, supplied product runtime, rights and deployment remain separate.'}
(EVIDENCE/'m6-fresh-integrated-source-audit.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k != 'private_desktop_logs'}, indent=2))
