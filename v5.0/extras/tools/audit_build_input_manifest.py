"""Verify recorded staged inputs of a fresh three-file source build."""
from pathlib import Path
import argparse
import hashlib
import json
import re
from target_files import TARGETS, read_target

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True)
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    if Path(args.stage).name != args.stage or not args.stage.startswith('integrated-source-'):
        parser.error('invalid stage')
    if Path(args.report).name != args.report:
        parser.error('invalid report name')
    output = EVIDENCE / args.report
    if output.exists():
        raise FileExistsError(output)
    stage = ROOT / 'extras/build' / args.stage
    reports = {n: json.loads((stage / f'{n}-report.json').read_text())
               for n in ('msload', 'bios', 'kernel', 'command')}
    work = {n: Path(r['stage']).resolve() for n, r in reports.items()}
    if any(not p.is_relative_to((ROOT / 'extras/build').resolve()) for p in work.values()):
        raise ValueError('component stage outside build')
    verified = []

    def check(component, category, path, expected):
        if sha(path) != expected:
            raise ValueError(f'{component} {category} differs: {path}')
        verified.append({'component': component, 'category': category,
                         'path': str(path), 'sha256': expected})

    # The loader and BIOS append the same BOOT message to a staged copy before
    # generating indexes. Verify both the recorded input and that transformation.
    raw_ms = ROOT / 'messages/usa-ms-dos.msg'
    raw_ibm = ROOT / 'messages/usa-ibm.msg'
    ibm_data = raw_ibm.read_bytes()
    boot = re.search(rb'(?im)^BOOT\s+[^\r\n]*\r?\n0001[^\r\n]*\r?\n[^\r\n]*\r?\n', ibm_data)
    if not boot:
        raise ValueError('BOOT message not found')
    raw_data = raw_ms.read_bytes()
    count_line, separator, remainder = raw_data.partition(b'\r\n')
    if not separator or not re.fullmatch(rb'[0-9A-Fa-f]{4}', count_line):
        raise ValueError('unexpected message count header')
    updated_count = f'{int(count_line, 16) + 1:04X}'.encode('ascii')
    boot_data, replacements = re.subn(
        rb'(?im)^(BOOT\s+)\S+(\s+0001\r?\n)',
        lambda m: m.group(1) + f'{len(raw_data):08x}'.encode('ascii') + m.group(2),
        boot.group(), count=1)
    if replacements != 1:
        raise ValueError('unexpected BOOT record header')
    # BUILDIDX increments the count, removes the appended blank line and
    # replaces the BOOT offset with its position in the rewritten file.
    combined = updated_count + separator + remainder + boot_data
    for component in ('msload', 'bios'):
        r, w = reports[component], work[component]
        for name, expected in r['inputs'].items():
            if name.lower() == 'usa-ms.msg':
                check(component, 'original message', raw_ms, expected)
                if (w / name).read_bytes() != combined:
                    raise ValueError(f'{component}: staged message transformation mismatch')
                verified.append({'component': component, 'category': 'combined message',
                                 'path': str(w / name), 'sha256': sha(w / name)})
            else:
                check(component, 'staged input', w / name, expected)
        if component == 'msload':
            for name, expected in r['includes'].items():
                check(component, 'staged include', w / 'inc' / name, expected)
        for name, expected in r['messages'].items():
            check(component, 'generated message', w / name, expected)
    kernel, kw = reports['kernel'], work['kernel']
    for name, expected in kernel['source_snapshot'].items():
        relative = Path(name)
        check('kernel', 'staged source', kw / 'src' / relative, expected)
    for name, expected in kernel['shared_include_snapshot'].items():
        check('kernel', 'staged include', kw / 'src/inc' / name, expected)
    for name, expected in kernel['shared_message_snapshot'].items():
        check('kernel', 'original message source', raw_ms, expected)
        check('kernel', 'BUILDIDX working message', kw / name, kernel['working_message_sha256'])
    for name, expected in kernel['tools'].items():
        check('kernel', 'staged tool', kw / name, expected)
    for name, expected in kernel['messages'].items():
        check('kernel', 'generated message', kw / name, expected)
    command, cw = reports['command'], work['command']
    for name, expected in command['source_snapshot'].items():
        check('command', 'staged source', cw / 'src' / Path(name), expected)
    # COMMAND runs the external tools directly; these hashes were captured in
    # the build report, but copies of those tools are not present in its stage.
    for name, expected in command['messages'].items():
        check('command', 'generated message', cw / name, expected)
    targets = []
    for name in TARGETS:
        target = read_target(name)
        if (stage / name).read_bytes() != target:
            raise ValueError(f'{name}: retained target mismatch')
        targets.append({'name': name, 'sha256': hashlib.sha256(target).hexdigest(),
                        'bytes': len(target), 'byte_equal': True})
    result = {'stage': str(stage), 'verified': verified,
              'command_external_tool_hashes_recorded_at_build': command['tool_hashes'],
              'command_dosbox_sha256_recorded_at_build': command['dosbox_sha256'],
              'targets': targets,
              'scope': 'Verifies recorded staged files and the documented BOOT-message transformation. '
                       'Snapshots include some files that may not be referenced by assembly. '
                       'Does not prove full OS/tool dependency closure, distribution rights, '
                       'or absence of opaque code/data outside these checks.'}
    output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'verified_files': len(verified), 'targets': len(targets),
                      'report': str(output)}, indent=2))


if __name__ == '__main__':
    main()
