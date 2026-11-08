"""Verify retained isolated-product probe evidence and on-disk guest results."""
from pathlib import Path
import hashlib
import json
from fat12_guest_file import read_root_file
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
evidence = root/'extras/docs/etc/evidence'
media = json.loads((evidence/'m3-t4-prepared.json').read_text())
stage = Path(media['stage'])
sha = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()
log = stage/'isolated-start.log'
text = log.read_text(encoding='utf-8-sig')
required = ['BEGIN-DOS5-SMOKE', 'MS-DOS Version 5.00', 'ENV-PASS', 'PATH=A:\\',
            'FOR-ONE', 'FOR-TWO', 'FOR-THREE', 'FILE-CONTENT', 'FILE-PASS',
            'CHILD-PASS', 'SMOKE-PASS']
guest = {name: read_root_file(stage/'boot.img', name)
         for name in ('RESULTS.TXT', 'DONE.TXT', 'COPY.TXT', 'INPUT.TXT')}
results = guest['RESULTS.TXT'] or b''
original = Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
checks = {
    'markers': all(x.encode() in results for x in required) and b'SMOKE-FAIL' not in results,
    'completed': guest['DONE.TXT'] == b'FINISHED\r\n',
    'copy': guest['COPY.TXT'] == b'FILE-CONTENT\r\n',
    'delete': guest['INPUT.TXT'] is None,
    'original_unchanged': sha(original) == media['original_sha256'],
    'system_files_unchanged': inspect(stage/'boot.img')['files'] == inspect(original)['files'],
    'supplied_product': sha(stage/'softpc64.exe') == media['softpc_sha256'] == sha(r'O:\DOS\softpc64.exe'),
    'owned_start': 'owned-console-start=1' in text,
    'running_window': 'title=Insignia SoftPC (Running)' in text,
    'isolated_desktop': 'input-desktop=Default isolated-desktop=DOS5Probe_' in text,
    'cleanup_recorded': 'budget-end: terminate owned process' in text and 'product-exit=0' in text,
    'input_desktop_unchanged': 'input-desktop-after=Default' in text,
}
out = {'stage': str(stage), 'checks': checks, 'passed': all(checks.values()),
       'product_sha256': sha(stage/'softpc64.exe'), 'config_sha256': sha(stage/'softpc.ini'),
       'probe_log_sha256': sha(log), 'tested_probe_sha256': sha(root/'extras/build/isolated-softpc-probe.exe'),
       'guest_files': {n: v.decode('ascii') if v is not None else None for n,v in guest.items()},
       'limitations': ['Product termination was forced after the bounded test, not a graceful shutdown.',
                      'Only COMMAND is source-built; IO.SYS and MSDOS.SYS are target fixtures.',
                      'Missing original media tail is zero-padded only in disposable test media.',
                      'Desktop checks establish the probe boundary; no screenshots or Computer Use were used.']}
(evidence/'m3-t4-product-runtime.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps(out,indent=2))
assert out['passed'], 'Product probe evidence incomplete'
