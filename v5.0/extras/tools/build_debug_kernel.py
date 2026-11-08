"""Assemble and link the diagnostic kernel in a fresh, isolated build stage."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
RUNNER_SHA256 = 'ae195ddf68aedff2fab5130e1368cb5c585e5264b84d142d4f79dc9f973f85b9'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    if Path(args.report).name != args.report:
        parser.error('report must be a filename')
    report_path = EVIDENCE / args.report
    if report_path.exists():
        raise FileExistsError(report_path)
    stage = Path(tempfile.mkdtemp(prefix='kernel-debug-', dir=ROOT / 'extras/build'))
    source = ROOT / 'dos'
    snapshot = {p.relative_to(ROOT).as_posix(): sha(p)
                for p in source.rglob('*') if p.is_file()}
    (stage / 'src').mkdir()
    shutil.copytree(source, stage / 'src/dos')
    manifest = ROOT / 'extras/tools/kernel_includes.txt'
    manifest_sha256 = sha(manifest)
    names = manifest.read_text(encoding='ascii').splitlines()
    if len(names) != 46 or len({n.lower() for n in names}) != 46:
        raise ValueError('invalid include manifest')
    (stage / 'src/inc').mkdir()
    includes = {}
    for name in names:
        if not name or Path(name).name != name:
            raise ValueError('invalid include name')
        includes[name] = sha(ROOT / 'inc' / name)
        shutil.copyfile(ROOT / 'inc' / name, stage / 'src/inc' / name)
    tool16 = Path(os.environ.get('DOS5_TOOLS16_ROOT', r'O:\repos.hobby\ntvdm64\tools\opennt\tools16'))
    dos6 = Path(os.environ.get('DOS5_DOS6_ROOT', r'O:\repos.hobby\ms-dos-archaeology\v6.0'))
    tools = {'masm.exe': tool16 / 'masm.exe', 'buildidx.exe': tool16 / 'buildidx.exe',
             'nosrvbld.exe': tool16 / 'nosrvbld.exe',
             'link.exe': dos6 / 'c6ers/tools6/bin/link.exe'}
    for name, path in tools.items():
        shutil.copyfile(path, stage / name)
    shutil.copyfile(stage / 'src/dos/msdos.skl', stage / 'msdos.skl')
    shutil.copyfile(stage / 'src/dos/msdos-debug.lnk', stage / 'msdos.lnk')
    message = ROOT / 'messages/usa-ms-dos.msg'
    message_sha256 = sha(message)
    shutil.copyfile(message, stage / 'usa-ms.msg')
    runner = ROOT / 'extras/build/isolated-tool-runner.exe'
    dosbox = Path(os.environ.get('DOS5_DOSBOX_PATH', r'C:\Program Files (x86)\DOSBox-0.74-3\DOSBox.exe'))
    if sha(runner) != RUNNER_SHA256:
        raise ValueError('unverified isolated launcher')

    def phase(name, commands):
        batch = '@echo off\r\n' + ''.join(c + '\r\nif errorlevel 1 goto fail\r\n' for c in commands)
        batch += f'echo PASS > {name}.ok\r\ngoto done\r\n:fail\r\necho FAIL > {name}.ok\r\n:done\r\nexit\r\n'
        (stage / f'{name}.bat').write_bytes(batch.encode('ascii'))
        conf = stage / f'{name}.conf'
        conf.write_text('[sdl]\nfullscreen=false\n[dosbox]\nmemsize=16\n[cpu]\ncycles=max\n'
                        '[autoexec]\nmount c "' + str(stage) + '"\nc:\n' + name + '.bat\n', encoding='ascii')
        command = subprocess.list2cmdline([str(dosbox), '-noconsole', '-conf', str(conf)])
        result = subprocess.run([str(runner), str(dosbox), str(stage), command],
                                capture_output=True, timeout=75)
        (stage / f'{name}-host.log').write_bytes(result.stdout + result.stderr)
        marker = stage / f'{name}.ok'
        if result.returncode or not marker.exists() or marker.read_text().strip() != 'PASS':
            raise RuntimeError(f'{name} failed; inspect {stage}')

    phase('messages', ['buildidx usa-ms.msg > idx.log', 'nosrvbld msdos.skl usa-ms.msg > msg.log'])
    modules = re.findall(r'(\w+)\.obj', (stage / 'msdos.lnk').read_text(), re.I)
    if len(modules) != 56 or len({x.lower() for x in modules}) != 56:
        raise ValueError('unexpected DEBUG link order')
    objects = {}
    for name in modules:
        shutil.copyfile(stage / 'src/dos' / f'{name}.asm', stage / f'{name}.asm')
        command = [str(stage / 'masm.exe'), '-Mx', '-t', '-W1', '-DDEBUG=1',
                   '-I.', '-Isrc/dos', '-Isrc/inc', '-Isrc/dos/messages',
                   f'{name}.asm,{name}.obj,{name}.lst;']
        run = subprocess.run(command, cwd=stage, capture_output=True, timeout=45)
        (stage / f'{name}.log').write_bytes(run.stdout + run.stderr)
        if run.returncode:
            raise RuntimeError(f'{name} failed; inspect {stage}')
        objects[name] = sha(stage / f'{name}.obj')
    phase('dlink', ['link /MAP @msdos.lnk > dlink.log'])
    current = {p.relative_to(ROOT).as_posix(): sha(p) for p in source.rglob('*') if p.is_file()}
    if current != snapshot:
        raise ValueError('kernel source changed during build')
    staged = {(Path('dos') / p.relative_to(stage / 'src/dos')).as_posix(): sha(p)
              for p in (stage / 'src/dos').rglob('*') if p.is_file()}
    if staged != snapshot:
        raise ValueError('staged kernel source differs from snapshot')
    if (includes != {name: sha(ROOT / 'inc' / name) for name in names}
            or includes != {name: sha(stage / 'src/inc' / name) for name in names}
            or sha(message) != message_sha256 or sha(manifest) != manifest_sha256):
        raise ValueError('shared inputs changed during build')
    output = {'stage': str(stage), 'source_snapshot': snapshot, 'include_snapshot': includes,
              'include_manifest_sha256': manifest_sha256, 'message_sha256': message_sha256,
              'generated_index_sha256': sha(stage / 'usa-ms.idx'),
              'generated_messages': {f'msdos.cl{i}': sha(stage / f'msdos.cl{i}') for i in range(1, 5)},
              'link_order': modules, 'objects': objects,
              'tool_hashes': {name: sha(path) for name, path in tools.items()},
              'dosbox_sha256': sha(dosbox), 'launcher_sha256': sha(runner),
              'exe_sha256': sha(stage / 'MSDOS.EXE'),
              'map_sha256': sha(stage / 'MSDOS.MAP'),
              'scope': 'DEBUG kernel assembly and link only; no boot, runtime or target identity claim.'}
    report_path.write_text(json.dumps(output, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'stage': str(stage), 'objects': len(objects),
                      'exe_sha256': output['exe_sha256'], 'scope': output['scope']}, indent=2))


if __name__ == '__main__':
    main()
