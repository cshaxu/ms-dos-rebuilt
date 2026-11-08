"""Run one owned SoftPC process with a 45-second guest-completion budget."""
from pathlib import Path
import hashlib
import json
import struct
import subprocess
import time
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
raise SystemExit('Disabled by permanent owner constraint: this legacy hidden-window runner does not isolate the desktop. Use a verified isolated-desktop runner or machine probe instead.')
prepared = json.loads((root/'extras/docs/etc/evidence/m3-t4-prepared.json').read_text())
stage = Path(prepared['stage'])
image = stage/'boot.img'
assert hashlib.sha256(image.read_bytes()).hexdigest() == prepared['test_image_sha256']
def read_file(name):
    b = image.read_bytes()
    bs = struct.unpack_from('<H', b, 11)[0]
    spf = struct.unpack_from('<H', b, 22)[0]
    reserved = struct.unpack_from('<H', b, 14)[0]
    entries = struct.unpack_from('<H', b, 17)[0]
    ro = (reserved+2*spf)*bs; data = ro+((entries*32+bs-1)//bs)*bs
    stem, ext = name.split('.'); wanted = (stem.ljust(8)+ext.ljust(3)).encode()
    for p in range(ro, ro+entries*32, 32):
        if b[p] == 0: return None
        if b[p:p+11] != wanted: continue
        size = struct.unpack_from('<I', b, p+28)[0]
        c = struct.unpack_from('<H', b, p+26)[0]; out = bytearray(); seen = set()
        while 2 <= c < 0xff0:
            if c in seen: raise ValueError('cyclic guest chain')
            seen.add(c); off = data+(c-2)*bs; out.extend(b[off:off+bs])
            n = reserved*bs+c+c//2; w = int.from_bytes(b[n:n+2], 'little')
            c = w >> 4 if c & 1 else w & 0xfff
        return bytes(out[:size])
    return None

si = subprocess.STARTUPINFO(); si.dwFlags |= subprocess.STARTF_USESHOWWINDOW; si.wShowWindow = 0
started = time.monotonic()
with (stage/'host.log').open('wb') as log:
    p = subprocess.Popen([str(stage/'softpc64.exe')], cwd=stage, stdout=log, stderr=log, startupinfo=si)
    done = None
    try:
        while time.monotonic()-started < 45 and p.poll() is None:
            done = read_file('DONE.TXT')
            if done and b'FINISHED' in done: break
            time.sleep(0.5)
    finally:
        running = p.poll() is None
        if running: p.terminate()
        code = p.wait(timeout=10)
results = read_file('RESULTS.TXT') or b''
(stage/'results.txt').write_bytes(results)
required = [b'BEGIN-DOS5-SMOKE', b'MS-DOS Version 5.00', b'ENV-PASS', b'PATH=A:\\',
            b'FOR-ONE', b'FOR-TWO', b'FOR-THREE', b'FILE-CONTENT', b'FILE-PASS', b'CHILD-PASS', b'SMOKE-PASS']
missing = [x.decode() for x in required if x not in results]
source = Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
assert hashlib.sha256(source.read_bytes()).hexdigest() == prepared['original_sha256']
assert inspect(image)['files']['COMMAND.COM']['sha256'] == '74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'
out = {'stage': str(stage), 'pid': p.pid, 'elapsed_seconds': round(time.monotonic()-started, 2),
       'completion_marker': bool(done and b'FINISHED' in done), 'owned_process_terminated': running,
       'host_exit_code': code, 'missing_markers': missing,
       'guest_results': results.decode('ascii', 'replace'),
       'passed': bool(done and not missing and b'SMOKE-FAIL' not in results),
       'scope': 'SoftPC shell smoke using reconstructed COMMAND and original IO.SYS/MSDOS.SYS fixtures.'}
(root/'extras/docs/etc/evidence/m3-t4-runtime.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
if not out['passed']: raise SystemExit('Guest checks incomplete/failed; inspect evidence and owned stage.')
