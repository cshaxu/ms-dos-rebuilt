"""Bounded headless-core shell test; no desktop APIs or product-window launch."""
from pathlib import Path
import hashlib
import json
import subprocess
from target_fat12 import inspect
from fat12_guest_file import read_root_file

root = Path(__file__).resolve().parent.parent.parent
evidence = root/'extras/docs/etc/evidence'
probe = json.loads((evidence/'m3-t4-probe-build.json').read_text())
media = json.loads((evidence/'m3-t4-prepared.json').read_text())
stage = Path(media['stage'])
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
assert sha(stage/'boot.img') == media['test_image_sha256'], 'Prepare fresh test media first'
assert sha(probe['executable']) == probe['executable_sha256']
si = subprocess.STARTUPINFO(); si.dwFlags |= subprocess.STARTF_USESHOWWINDOW; si.wShowWindow = 0
try:
    run = subprocess.run([probe['executable'], str(stage/'boot.img')], cwd=stage,
                         startupinfo=si, capture_output=True, timeout=35)
except subprocess.TimeoutExpired as error:
    (stage/'probe.log').write_bytes((error.stdout or b'')+(error.stderr or b''))
    raise SystemExit('Headless probe timed out; subprocess.run killed and reaped its child; inconclusive.')
output = run.stdout+run.stderr
(stage/'probe.log').write_bytes(output)
required = ['BEGIN-DOS5-SMOKE', 'MS-DOS Version 5.00', 'ENV-PASS', 'PATH=A:\\',
            'FOR-ONE', 'FOR-TWO', 'FOR-THREE', 'FILE-CONTENT', 'FILE-PASS', 'CHILD-PASS', 'SMOKE-PASS']
guest_output = read_root_file(stage/'boot.img', 'RESULTS.TXT') or b''
missing = [x for x in required if x.encode() not in guest_output]
original = Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
assert sha(original) == media['original_sha256']
system_files = inspect(stage/'boot.img')['files']
assert system_files == inspect(original)['files']
out = {'stage': str(stage), 'probe_build': 'm3-t4-probe-build.json',
       'probe_log_sha256': sha(stage/'probe.log'), 'host_exit_code': run.returncode,
       'screen_markers': required, 'missing_markers': missing,
       'guest_system_files_unchanged': True,
       'guest_results': guest_output.decode('ascii',errors='replace'),
       'passed': run.returncode == 0 and not missing and b'SMOKE-FAIL' not in guest_output,
       'scope': 'Headless SoftPC core using existing neighboring build objects; supplied O:\\DOS product executable is not exercised.'}
(evidence/'m3-t4-headless-runtime.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
if not out['passed']: raise SystemExit('Headless guest checks failed or incomplete')
