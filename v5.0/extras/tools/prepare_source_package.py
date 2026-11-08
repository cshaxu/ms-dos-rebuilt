"""Create a local, source-only snapshot of the three-file reconstruction."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import tempfile

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
sha = lambda data: hashlib.sha256(data).hexdigest()
entries = []

def add_tree(relative, allowed=None):
    origin = root / relative
    for path in sorted(origin.rglob('*')):
        if not path.is_file():
            continue
        if path.is_symlink():
            raise ValueError(f'symlink is not a source input: {path}')
        if allowed is not None and path.suffix.lower() not in allowed and path.name.lower() not in {'makefile', 'makefil0'}:
            continue
        entries.append((path, path.relative_to(root)))

add_tree('bios')
add_tree('kernel-source/dos')
add_tree('kernel-source/inc')
add_tree('cmd/command', {'.asm', '.inc', '.equ', '.h', '.c', '.skl', '.lnk', '.md', '.txt'})
add_tree('inc')
for name in ('usa-ms.msg', 'usa-ms.idx', 'usa-ibm.msg', 'comimsg.inc', 'comrmsg.inc'):
    path = root / 'messages' / name
    assert path.is_file()
    entries.append((path, path.relative_to(root)))
for name in ('build_integrated_source.py', 'build_bios_comparison.py', 'build_msload_candidate.py',
             'build_reconstructed_kernel.py', 'build_command.py', 'target_kernel.py',
             'fat12_guest_file.py', 'isolated_tool_runner.c', 'preflight_source_build.py', 'command_source_snapshot.py',
             'command_output_check.py', 'command_style_changes.py', 'msend_recovery.py', 'prepare_build_workspace.py'):
    path = root / 'extras/tools' / name
    assert path.is_file()
    entries.append((path, path.relative_to(root)))
path = root / 'extras/docs/etc/command-style-adjustment.md'
assert path.is_file()
entries.append((path, path.relative_to(root)))
assert len({str(rel).lower() for _, rel in entries}) == len(entries)
assert not any(rel.suffix.lower() in {'.sys', '.com', '.exe', '.exc', '.obj', '.map'} for _, rel in entries)

# Ensure the source files named by the three component link lists are present.
def linked(path):
    return re.findall(r'(?i)\b(\w+)\.obj\b', path.read_text(errors='replace'))
for directory, link in [('kernel-source/dos', 'msdos.lnk'), ('cmd/command', 'command.lnk')]:
    names = linked(root / directory / link)
    assert names and all((root / directory / (name + '.asm')).is_file() for name in names)
bios_names = re.findall(r'[A-Za-z_][A-Za-z_0-9]*', (root / 'bios/msbio.lnk').read_text().split(',')[0])
assert len(bios_names) == 15 and all((root / 'bios' / (name + '.asm')).is_file() for name in bios_names)

stage = Path(tempfile.mkdtemp(prefix='source-package-candidate-', dir=root / 'extras/build'))
manifest = []
for source, relative in entries:
    destination = stage / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    data = source.read_bytes()
    destination.write_bytes(data)
    assert destination.read_bytes() == data
    manifest.append({'path': relative.as_posix(), 'bytes': len(data), 'sha256': sha(data)})
readme = '''# MS-DOS 5.00 reconstruction source candidate

This local research snapshot is a reconstruction, not an original Microsoft
source release. It contains source and build inputs only, not target system
binaries. Reference provenance and distribution rights must be reviewed before
redistribution.

`bios/` contains IO.SYS candidates and BIOS-scoped includes. `kernel-source/`
contains the consolidated MSDOS.SYS candidate. `cmd/command/`, `inc/`, and
`messages/` contain the COMMAND candidate and shared inputs. The additional
`kernel-source/` and `bios/inc/` levels preserve incompatible include versions.

The recipes in `tools/` retain external historical assembler, linker, resource
tool, DOSBox and private-desktop-runner dependencies. They also require the
owner's pinned target extracts and retained test media under `build/`; none are
included. `DOS5_DOS6_ROOT` can override the external DOS 6 reference/tool root;
its default is `O:\\repos.hobby\\ms-dos-archaeology\\v6.0`, independent of the
snapshot location. Runtime validation and DOSBox builds must use a verified
isolated desktop or a machine probe, never the user's desktop. Consult the
repository evidence for the verification status of this exact snapshot.

`python tools/preflight_source_build.py` only inventories external prerequisites
and their pinned hashes. It does not run or authorize a build, and conservatively
requires a kernel extract even where the original image could be used.
`python tools/prepare_build_workspace.py --help` describes creating a separate
local workspace from verified inputs without running the build. The original
source snapshot stays source-only.

COMMAND source has had comment-only style edits; BIOS SYSIMES uses NTIO source,
and MSEND is derived from NTIO with physical segment endings. See
`docs/etc/command-style-adjustment.md` for the COMMAND changes. The original
image, supplied SoftPC product, and complete runtime behavior require separate
verification; see the repository's current evidence before making claims.
See the main repository documentation and evidence for provenance and limits.
'''
(stage / 'README.md').write_text(readme, encoding='utf-8')
(stage / 'build').mkdir()
(stage / 'extras/docs/etc/evidence').mkdir(parents=True)
manifest.sort(key=lambda item: item['path'].lower())
report = {'stage': str(stage), 'files': manifest,
          'scope': 'Local source-only review snapshot, copied from current workspace; no fresh build, target media, tool binaries, runtime or distribution-rights claim.'}
(stage / 'SOURCE-MANIFEST.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
(evidence / 'm6-source-package-candidate.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'stage': str(stage), 'files': len(manifest), 'source_bytes': sum(x['bytes'] for x in manifest),
                  'scope': report['scope']}, indent=2))
