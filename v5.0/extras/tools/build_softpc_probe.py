"""Link a local diagnostic probe against existing SoftPC test objects, read-only."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parent.parent.parent
softpc = Path(r'O:\repos.hobby\softpc')
build = softpc/'extras/build/.ninja/gcc-x64-release'
stage = Path(tempfile.mkdtemp(prefix='softpc-probe-', dir=root/'extras/build'))
ninja = (build/'build.ninja').read_text()
link_line = next(line for line in ninja.splitlines() if line.startswith('build softpc-runtime-smoke.exe: '))
objects = link_line.split(': ',1)[1].split(' |',1)[0].split()[1:]
block = ninja[ninja.index(link_line):]
libraries = re.search(r'^  LINK_LIBRARIES = (.*)$', block, re.M)[1].split()
compiler = shutil.which('gcc'); assert compiler
obj = stage/'probe.obj'; exe = stage/'probe.exe'
compile_args = [compiler, '-std=c17', '-O2', '-DSOFTPC_STANDALONE=1',
    '-I'+str(softpc/'src'), '-I'+str(softpc/'src/app-softpc'),
    '-I'+str(softpc/'test/app-softpc/integration'),
    '-c', str(root/'extras/tools/softpc_command_probe.c'), '-o', str(obj)]
p = subprocess.run(compile_args, capture_output=True, timeout=30)
(stage/'compile.log').write_bytes(p.stdout+p.stderr)
assert p.returncode == 0, p.stderr.decode(errors='replace')
replaced = [str(obj) if x.endswith('/runtime_smoke.c.obj') else str(build/x) for x in objects]
assert replaced.count(str(obj)) == 1
libs = [x if x.startswith('-') else str(build/x) for x in libraries]
args = [compiler, '-static', '-static-libgcc', *replaced, *libs, '-o', str(exe)]
p = subprocess.run(args, capture_output=True, timeout=45)
(stage/'link.log').write_bytes(p.stdout+p.stderr)
assert p.returncode == 0, p.stderr.decode(errors='replace')
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
inputs = {p: sha(p) for p in replaced+libs if not p.startswith('-')}
out = {'stage': str(stage), 'executable': str(exe), 'executable_sha256': sha(exe),
       'compiler': compiler, 'compiler_sha256': sha(compiler), 'inputs': inputs,
       'source_sha256': sha(root/'extras/tools/softpc_command_probe.c'),
       'scope': 'Headless probe using existing SoftPC build; not the O:\\DOS product binary.'}
(root/'extras/docs/etc/evidence/m3-t4-probe-build.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(str(exe))
