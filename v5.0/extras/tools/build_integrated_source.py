"""Build a fresh three-file candidate; requires approved private-desktop execution."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
import tempfile

from target_files import BASELINE, TARGETS, read_target
from preflight_source_build import checks as prerequisite_checks, inspect as inspect_prerequisite

ROOT = Path(__file__).resolve().parent.parent.parent
digest = lambda data: hashlib.sha256(data).hexdigest()


def load_report(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def verify_payloads(payloads, references, targets):
    """Require exact named-file and byte identity before retaining candidates."""
    if set(payloads) != set(targets) or set(references) != set(targets):
        raise ValueError('incomplete candidate or target set')
    entries = []
    for name, (length, expected) in targets.items():
        data = payloads[name]
        if len(data) != length or digest(data) != expected:
            raise ValueError(f'{name}: candidate size/hash mismatch')
        if data != references[name] or digest(references[name]) != expected:
            raise ValueError(f'{name}: target comparison failed')
        entries.append({'name': name, 'bytes': len(data), 'sha256': digest(data), 'byte_equal': True})
    return entries


def verify_segment_sizes(bios_map, kernel_map, size_source):
    """Check the DOS GETSIZE inputs against the freshly linked segments."""
    values = {}
    for constant, segment, data in (
        ('BIODATASIZ', 'BIOS_DATA', bios_map),
        ('BIOCODESIZ', 'BIOS_CODE', bios_map),
        ('DOSDATASIZ', 'DOSDATA', kernel_map),
    ):
        pattern = r'^\s*[0-9A-F]+H\s+[0-9A-F]+H\s+([0-9A-F]+)H\s+' + segment + r'\s'
        matches = re.findall(pattern, data, re.IGNORECASE | re.MULTILINE)
        declarations = re.findall(r'^\s*' + constant + r'\s+EQU\s+([0-9A-F]+)H\s*$',
                                  size_source, re.IGNORECASE | re.MULTILINE)
        if len(matches) != 1 or len(declarations) != 1:
            raise ValueError(f'{constant}: missing or ambiguous segment size')
        values[constant] = int(matches[0], 16)
        if values[constant] != int(declarations[0], 16):
            raise ValueError(f'{constant}: bdsize.inc differs from linked map')
    return values


def verify_prerequisites():
    results = [inspect_prerequisite(*item) for item in prerequisite_checks]
    failures = [item for item in results if item['status'] != 'match']
    if failures:
        details = ', '.join(f"{item['name']} ({item['status']})" for item in failures)
        raise ValueError(f'build prerequisite check failed: {details}')
    return results


def verify_sysinit_layout(kernel_map):
    """Check the historical SYSINITVAR size using linked public symbols."""
    symbols = {}
    for name in ('SYSINITVAR', 'START_ARENA'):
        matches = re.findall(r'^\s*([0-9A-F]+):([0-9A-F]+)\s+' + name + r'\s*$',
                             kernel_map, re.IGNORECASE | re.MULTILINE)
        unique = {(int(segment, 16), int(offset, 16)) for segment, offset in matches}
        if len(unique) != 1:
            raise ValueError(f'{name}: missing or ambiguous linked symbol')
        symbols[name] = unique.pop()
    start, end = symbols['SYSINITVAR'], symbols['START_ARENA']
    if start[0] != end[0] or end[1] + 2 - start[1] != 0x6a:
        raise ValueError('SYSINITVAR layout differs from the 6Ah-byte requirement')
    return {'sysinitvar': start[1], 'start_arena': end[1], 'size': 0x6a}


def observe_dosbox_adjacent_dlls():
    """Observe adjacent imports, without asserting Windows loaded those files."""
    dosbox = next(path for name, path, _ in prerequisite_checks if name == 'dosbox')
    observations = []
    for name in ('SDL.dll', 'SDL_net.dll'):
        path = dosbox.parent / name
        try:
            data = path.read_bytes()
        except FileNotFoundError:
            observations.append({'name': name, 'path': str(path), 'status': 'absent'})
        else:
            observations.append({'name': name, 'path': str(path), 'status': 'present',
                                 'bytes': len(data), 'sha256': digest(data)})
    return observations


def main():
    prerequisites = verify_prerequisites()
    dosbox_dlls = observe_dosbox_adjacent_dlls()
    evidence = ROOT / 'extras/docs/etc/evidence'
    targets = {name: read_target(name) for name in TARGETS}
    stage = Path(tempfile.mkdtemp(prefix='integrated-source-', dir=ROOT / 'extras/build'))
    jobs = [
        ('msload', 'build_msload_candidate.py', ['--local-source']),
        ('bios', 'build_bios_comparison.py', ['--candidate', '--oembase', '--singleconfig', '--local-source']),
        ('kernel', 'build_reconstructed_kernel.py', []),
        ('command', 'build_command.py', []),
    ]
    reports = {}
    for label, script, args in jobs:
        report_name = f'm6-{label}-{stage.name}.json'
        report_path = evidence / report_name
        if report_path.exists():
            raise FileExistsError(f'refusing to overwrite {report_path}')
        command = [sys.executable, str(ROOT / 'extras/tools' / script), *args, '--report', report_name]
        try:
            run = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=300)
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(f'{label} timed out; inspect owned stage {stage}') from exc
        (stage / (label + '.log')).write_bytes(run.stdout + run.stderr)
        if run.returncode != 0 or not report_path.exists():
            raise RuntimeError(f'{label} failed; inspect owned stage {stage}')
        report = load_report(report_path)
        (stage / (label + '-report.json')).write_bytes(report_path.read_bytes())
        reports[label] = report
    if not reports['msload'].get('local_source') or not reports['bios'].get('local_source'):
        raise ValueError('BIOS or MSLOAD did not use local source')
    if not all(reports['bios'].get(flag) for flag in ('candidate', 'oembase', 'singleconfig')):
        raise ValueError('incorrect BIOS build configuration')
    size_path = ROOT / 'inc/bdsize.inc'
    if digest(size_path.read_bytes()) != reports['kernel']['shared_include_snapshot']['bdsize.inc']:
        raise ValueError('bdsize.inc changed since the kernel build')
    kernel_map = (Path(reports['kernel']['stage']) / 'MSDOS.MAP').read_text(errors='strict')
    segment_sizes = verify_segment_sizes(
        (Path(reports['bios']['stage']) / 'msbio.map').read_text(errors='strict'),
        kernel_map,
        size_path.read_text(encoding='ascii'))
    sysinit_layout = verify_sysinit_layout(kernel_map)
    loader = (Path(reports['msload']['stage']) / 'msload.com').read_bytes()
    bios = (Path(reports['bios']['stage']) / 'msbio.bin').read_bytes()
    if len(loader) != 0x5a6 or digest(loader) != reports['msload']['output']['sha256']:
        raise ValueError('MSLOAD report or size mismatch')
    if digest(bios) != reports['bios']['output']['sha256']:
        raise ValueError('BIOS report mismatch')
    kernel = (Path(reports['kernel']['stage']) / 'MSDOS.SYS').read_bytes()
    command = (Path(reports['command']['stage']) / 'COMMAND.COM').read_bytes()
    if digest(kernel) != reports['kernel']['output_sha256'] or digest(command) != reports['command']['output_sha256']:
        raise ValueError('kernel or command report mismatch')
    payloads = {'IO.SYS': loader + bios, 'MSDOS.SYS': kernel, 'COMMAND.COM': command}
    entries = verify_payloads(payloads, targets, TARGETS)
    if any(read_target(name) != data for name, data in targets.items()):
        raise ValueError('retained baseline changed during build')
    if observe_dosbox_adjacent_dlls() != dosbox_dlls:
        raise ValueError('DOSBox adjacent DLL observations changed during build')
    for name, data in payloads.items():
        (stage / name).write_bytes(data)
        if (stage / name).read_bytes() != data:
            raise IOError(f'{name}: staged write failed')
    result = {'stage': str(stage), 'files': entries, 'baseline': str(BASELINE),
              'prerequisites': prerequisites,
              'dosbox_adjacent_dll_observations': dosbox_dlls,
              'segment_sizes': segment_sizes,
              'sysinit_layout': sysinit_layout,
              'component_stages': {key: value['stage'] for key, value in reports.items()},
              'scope': 'Fresh source build versus hash-pinned retained system files; source provenance remains separate.'}
    (evidence / f'm6-integrated-{stage.name}.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()
