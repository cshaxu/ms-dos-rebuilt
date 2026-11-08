"""Compare current build inputs with the latest verified component snapshots."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
digest = lambda data: hashlib.sha256(data).hexdigest()
integrated = json.loads((EVIDENCE / 'm6-fresh-integrated-source-audit.json').read_text())
workspace = Path(integrated['workspace']).resolve()
if workspace.is_relative_to(ROOT / 'build'):
    workspace = ROOT / 'extras' / workspace.relative_to(ROOT)
if not workspace.is_relative_to((ROOT / 'extras/build').resolve()):
    raise ValueError('Build workspace outside project build directory')
manifest_bytes = (workspace / 'SOURCE-MANIFEST.json').read_bytes()
if digest(manifest_bytes) != integrated['manifest_sha256']:
    raise ValueError('Integrated build manifest changed')
manifest = json.loads(manifest_bytes)['files']
kernel = json.loads((EVIDENCE / 'm6-kernel-integrated-source-ze2xg22l.json').read_text())
command = json.loads((EVIDENCE / 'm6-command-integrated-source-besftgsc.json').read_text())
command_audit = json.loads((EVIDENCE / 'm6-command-no-research-snapshot-audit.json').read_text())
script_audit = json.loads((EVIDENCE / 'm6-clean-include-path-audit.json').read_text())
bios_audit = json.loads((EVIDENCE / 'm6-bios-explicit-config-audit.json').read_text())
bios_style = json.loads((EVIDENCE / 'm6-bios-single-config-style-audit.json').read_text())
bios_constants = json.loads((EVIDENCE / 'm6-bios-config-constants-clean-audit.json').read_text())
bios_segments = json.loads((EVIDENCE / 'm6-bios-segment-style-audit.json').read_text())
cross_style = json.loads((EVIDENCE / 'm6-cross-component-alignment-audit.json').read_text())
shared_audit = json.loads((EVIDENCE / 'm6-common-includes-integrated-audit.json').read_text())
layout_audit = json.loads((EVIDENCE / 'm6-root-dos-layout-integrated-audit.json').read_text())
dedup_audit = json.loads((EVIDENCE / 'm6-deduplicated-includes-integrated-audit.json').read_text())
expected = {}
for item in manifest:
    rel = Path(item['path'])
    if rel.is_absolute() or rel.drive or '..' in rel.parts:
        raise ValueError(f'Invalid manifest path: {rel}')
    baseline = (workspace / rel).read_bytes()
    if len(baseline) != item['bytes'] or digest(baseline) != item['sha256']:
        raise ValueError(f'Integrated build input changed: {rel}')
    expected[rel.as_posix().lower()] = item['sha256']
removed = {f'kernel-source/inc/ntvdm/{n}.inc' for n in
           ('bop', 'cmdsvc', 'dbgsvc', 'dossvc', 'doswow', 'vint')}
removed.update(('kernel-source/inc/kernel/cputype.inc',
                'kernel-source/inc/kernel/curdir.inc',
                'kernel-source/inc/kernel/const2.asm',
                'kernel-source/inc/kernel/cpmfcb.inc',
                'kernel-source/inc/kernel/sf.inc',
                'kernel-source/inc/ntvdm/curdir.inc'))
for path in removed:
    if expected.pop(path, None) is None or (ROOT / path).exists():
        raise ValueError(f'Unexpected removed header: {path}')
for name in kernel['shared_include_snapshot']:
    old_path = (Path('kernel-source/inc') / Path(name)).as_posix().lower()
    expected.pop(old_path, None)
    if (ROOT / old_path).exists():
        raise ValueError(f'Duplicate kernel include remains: {old_path}')
for name in list(expected):
    if name.startswith('kernel-source/dos/'):
        expected.pop(name)
for name, sha in kernel['source_snapshot'].items():
    expected[Path(name).as_posix().lower()] = sha
for name, sha in command['source_snapshot'].items():
    expected[Path(name).as_posix().lower()] = sha
expected['extras/tools/build_reconstructed_kernel.py'] = script_audit['new_script_sha256']
expected['extras/tools/build_command.py'] = command_audit['build_script_sha256']
expected['extras/tools/command_source_snapshot.py'] = command_audit['snapshot_script_sha256']
for name, sha in bios_audit['changed_inputs'].items():
    expected[Path(name).as_posix().lower()] = sha
for name, sha in bios_style['source_hashes'].items():
    expected[Path(name).as_posix().lower()] = sha
expected['bios/config.inc'] = bios_constants['bios_config_sha256']
for name, sha in bios_segments['source_hashes'].items():
    expected[Path(name).as_posix().lower()] = sha
for name, sha in cross_style['source_hashes'].items():
    path = Path(name).as_posix().lower()
    if path.startswith('kernel-source/dos/'):
        path = path.removeprefix('kernel-source/')
    expected[path] = sha
for name, sha in shared_audit['script_hashes'].items():
    expected[Path(name).as_posix().lower()] = sha
expected['extras/tools/build_reconstructed_kernel.py'] = layout_audit['kernel_build_script_sha256']
expected['extras/tools/kernel_includes.txt'] = dedup_audit['kernel_include_manifest_sha256']
port_audit = json.loads((EVIDENCE / 'm6-nt-port-comment-integrated-audit.json').read_text(encoding='utf-8'))
for name, change in port_audit['changes'].items():
    path = Path(name).as_posix().lower()
    if path.startswith('bios/'):
        expected[path] = change['after']
bios_shared = json.loads((EVIDENCE / 'm6-bios-shared-includes-integrated-audit.json').read_text())
for name, sha in bios_shared['shared'].items():
    expected.pop((Path('bios/inc') / name).as_posix().lower(), None)
    if (ROOT / 'bios/inc' / name).exists():
        raise ValueError(f'Duplicate BIOS include remains: {name}')
    expected[(Path('inc') / name).as_posix().lower()] = sha
for name, sha in bios_shared['script_hashes'].items():
    expected[Path(name).as_posix().lower()] = sha
for name, sha in kernel['shared_include_snapshot'].items():
    expected[(Path('inc') / Path(name)).as_posix().lower()] = sha
research = json.loads((EVIDENCE / 'm6-research-include-move-integrated-audit.json').read_text())
for name, sha in research['moved'].items():
    expected.pop((Path('inc') / name).as_posix().lower(), None)
    if (ROOT / 'inc' / name).exists() or digest((ROOT / 'extras/research/inc' / name).read_bytes()) != sha:
        raise ValueError(f'Research include migration mismatch: {name}')
baseline_audit = json.loads((EVIDENCE / 'm6-retained-three-file-baseline-audit.json').read_text())
for name, sha in baseline_audit['script_hashes'].items():
    expected[Path(name).as_posix().lower()] = sha
class3_audit = json.loads((EVIDENCE / 'm6-bios-class3-direct-source-audit.json').read_text())
expected[class3_audit['script']] = class3_audit['script_sha256']
message_audit = json.loads((EVIDENCE / 'm6-bios-message-skeleton-integrated-audit.json').read_text())
expected[message_audit['script']] = message_audit['script_sha256']
expected[message_audit['source']['source']] = message_audit['source']['after_sha256']
msload_messages = json.loads((EVIDENCE / 'm6-msload-generated-messages-audit.json').read_text())
expected[msload_messages['script']] = msload_messages['script_sha256']
shared_messages = json.loads((EVIDENCE / 'm6-shared-dos-messages-integrated-audit.json').read_text())
for item in shared_messages['moved']:
    expected.pop(Path(item['original']).as_posix().lower(), None)
    if (ROOT / item['original']).exists() or digest((ROOT / 'extras' / item['archive']).read_bytes()) != item['sha256']:
        raise ValueError(f'Message migration mismatch: {item["original"]}')
for name, sha in {**shared_messages['shared_messages'], **shared_messages['script_hashes']}.items():
    expected[Path(name).as_posix().lower()] = sha
power_message = json.loads((EVIDENCE / 'm6-power-message-reconstruction-audit.json').read_text())
expected['messages/usa-ms-dos.msg'] = power_message['message_sha256']
expected['messages/usa-ms-dos.idx'] = power_message['index_sha256']
index_audit = json.loads((EVIDENCE / 'm6-kernel-generated-message-index-audit.json').read_text())
expected[index_audit['script']] = index_audit['script_sha256']
expected.pop('messages/usa-ms-dos.idx', None)
if (ROOT / 'messages/usa-ms-dos.idx').exists() or digest((ROOT / 'extras' / index_audit['archived_index']).read_bytes()) != index_audit['archived_index_sha256']:
    raise ValueError('Archived DOS message index mismatch')
command_index = json.loads((EVIDENCE / 'm6-command-generated-message-index-audit.json').read_text())
for name, sha in command_index['script_hashes'].items():
    expected[name] = sha
expected.pop('messages/usa-ms.idx', None)
if (ROOT / 'messages/usa-ms.idx').exists() or digest((ROOT / 'extras' / command_index['archived_index']).read_bytes()) != command_index['archived_index_sha256']:
    raise ValueError('Archived COMMAND message index mismatch')
dblspace = json.loads((EVIDENCE / 'm6-bios-remove-dblspace-module-audit.json').read_text())
expected.pop('bios/syspre.asm', None)
if (ROOT / 'bios/syspre.asm').exists() or digest((ROOT / 'extras' / dblspace['removed']['archive']).read_bytes()) != dblspace['removed']['source_sha256']:
    raise ValueError('DBLSPACE reference migration mismatch')
expected['bios/msbio.lnk'] = dblspace['removed']['new_link_sha256']
for name, sha in dblspace['script_hashes'].items():
    expected[name] = sha
hooks = json.loads((EVIDENCE / 'm6-bios-dblspace-hooks-audit.json').read_text())
for name, info in hooks['files_changed'].items():
    expected[name] = info['after']
for name, info in hooks['archived_headers'].items():
    expected.pop(name, None)
    if (ROOT / name).exists() or digest((ROOT / 'extras' / info['archive']).read_bytes()) != info['sha256']:
        raise ValueError(f'DBLSPACE header archive mismatch: {name}')
copycds = json.loads((EVIDENCE / 'm6-bios-copycds-cleanup-audit.json').read_text())
for name, info in copycds['files_changed'].items():
    expected[name] = info['after']
highload = json.loads((EVIDENCE / 'm6-bios-highload-archive-audit.json').read_text())
for item in highload['moved']:
    expected.pop(item['original'], None)
    if (ROOT / item['original']).exists() or digest((ROOT / 'extras' / item['archive']).read_bytes()) != item['sha256']:
        raise ValueError(f'High-memory reference archive mismatch: {item["original"]}')
kernel_post5 = json.loads((EVIDENCE / 'm6-kernel-post5-restricted-audit.json').read_text())
for name, info in kernel_post5['files_changed'].items():
    expected[name] = info['after']
post5_comments = json.loads((EVIDENCE / 'm6-sysinit-post5-comments-audit.json').read_text())
expected[post5_comments['change']['source']] = post5_comments['change']['after_sha256']
pause_entry = json.loads((EVIDENCE / 'm6-command-pause-entry-audit.json').read_text())
expected[pause_entry['change']['source']] = pause_entry['change']['after_sha256']
nt_research = json.loads((EVIDENCE / 'm6-nt-research-includes-audit.json').read_text())
for item in nt_research['moved']:
    expected.pop(item['original'].lower(), None)
    if (ROOT / item['original']).exists() or digest((ROOT / 'extras' / item['archive']).read_bytes()) != item['sha256']:
        raise ValueError(f'NT research include archive mismatch: {item["original"]}')
for name, sha in nt_research['script_hashes'].items():
    if name in expected:
        expected[name] = sha
mstable_style = json.loads((EVIDENCE / 'm6-mstable-nt-comment-style-audit.json').read_text())
expected[mstable_style['change']['source']] = mstable_style['change']['after_sha256']
command_contract = json.loads((EVIDENCE / 'm6-command-message-contract-style-audit.json').read_text())
for change in command_contract['changes']:
    expected[change['source']] = change['after_sha256']
exec_error = json.loads((EVIDENCE / 'm6-command-exec-error-register-audit.json').read_text())
expected[exec_error['change']['source']] = exec_error['change']['after_sha256']
bios_orphans = json.loads((EVIDENCE / 'm6-bios-orphan-comments-source-audit.json').read_text())
for name, change in bios_orphans['files_changed'].items():
    expected[name] = change['after']
procedure_titles = json.loads((EVIDENCE / 'm6-kernel-procedure-title-source-audit.json').read_text())
for name, change in procedure_titles['changes'].items():
    expected[name] = change['after']
origin_formula = json.loads((EVIDENCE / 'm6-origin-formula-source-audit.json').read_text())
for name, change in origin_formula['changes'].items():
    expected[name] = change['after']
origin_build = json.loads((EVIDENCE / 'm6-origin-formula-integrated-audit.json').read_text())
expected['extras/tools/build_integrated_source.py'] = origin_build['integrated_script_sha256']
build_paths = json.loads((EVIDENCE / 'm6-configurable-build-tools-source-audit.json').read_text())
for name, change in build_paths['changes'].items():
    if name in expected:
        expected[name] = change['after']
ioctl_recovery = json.loads((EVIDENCE / 'm6-ioctl-structure-recovery-source-audit.json').read_text())
for name, change in ioctl_recovery['changes'].items():
    expected[name] = change['after']
mstable_dispatch = json.loads((EVIDENCE / 'm6-mstable-dos4-dispatch-audit.json').read_text())
expected['extras/tools/audit_linked_module_references.py'] = mstable_dispatch['reference_ledger_script_sha256']
dos4_mapping = json.loads((EVIDENCE / 'm6-dos4-inc-module-mapping-audit.json').read_text())
expected['extras/tools/audit_linked_module_references.py'] = dos4_mapping['ledger_script_sha256']
sft_critical = json.loads((EVIDENCE / 'm6-sft-critical-name-source-audit.json').read_text())
for name, change in sft_critical['changes'].items():
    expected[name] = change['after']
sft_mknode = json.loads((EVIDENCE / 'm6-sft-mknode-source-audit.json').read_text())
for name, change in sft_mknode['changes'].items():
    expected[name] = change['after']
msinit_indent = json.loads((EVIDENCE / 'm6-msinit-indent-followup-source-audit.json').read_text())
expected[msinit_indent['source']] = msinit_indent['after_sha256']
segcheck_debug = json.loads((EVIDENCE / 'm6-segcheck-debug-source-audit.json').read_text())
expected[segcheck_debug['source']] = segcheck_debug['after_sha256']
debug_recovery = json.loads((EVIDENCE / 'm6-debug-kernel-source-audit.json').read_text())
for name, change in debug_recovery['changes'].items():
    expected[name] = change['after']
debug_build = json.loads((EVIDENCE / 'm6-debug-kernel-integrated-audit.json').read_text())
expected['extras/tools/build_debug_kernel.py'] = debug_build['debug_script_sha256']
debug_closure = json.loads((EVIDENCE / 'm6-debug-source-closure-audit.json').read_text())
expected['extras/tools/build_debug_kernel.py'] = debug_closure['debug_script_sha256']
debug_longjump = json.loads((EVIDENCE / 'm6-debug-longjump-macro-source-audit.json').read_text())
for name, change in debug_longjump['changes'].items():
    expected[name] = change['after']
bios_lineage = json.loads((EVIDENCE / 'm6-dos4-bios-partial-mapping-audit.json').read_text())
expected['extras/tools/audit_linked_module_references.py'] = bios_lineage['tool_sha256']
command_unused = json.loads((EVIDENCE / 'm6-command-unused-nt-declarations-source-audit.json').read_text())
for name, change in command_unused['changes'].items():
    expected[name] = change['after']
revision_history = json.loads((EVIDENCE / 'm6-dev-fcb-revision-history-source-audit.json').read_text())
for name, change in revision_history['changes'].items():
    expected[name] = change['after']
tcode_format = json.loads((EVIDENCE / 'm6-tcode-format-source-audit.json').read_text())
expected[tcode_format['source']] = tcode_format['after_sha256']
loadhi_comments = json.loads((EVIDENCE / 'm6-loadhi-parameter-comments-source-audit.json').read_text())
expected[loadhi_comments['source']] = loadhi_comments['after_sha256']
integrated_preflight = json.loads((EVIDENCE / 'm6-integrated-preflight-source-audit.json').read_text())
expected[integrated_preflight['source']] = integrated_preflight['after_sha256']
kernel_nt_unused = json.loads((EVIDENCE / 'm6-kernel-unused-nt-declarations-source-audit.json').read_text())
for name, change in kernel_nt_unused['changes'].items():
    expected[name] = change['after']
buf_review = json.loads((EVIDENCE / 'file-review-053-buf-source-change.json').read_text())
expected[buf_review['file']] = buf_review['after_sha256']
dos6_crit_format = json.loads((EVIDENCE / 'file-review-dos6-crit-format-source.json').read_text())
for name, change in dos6_crit_format['changes'].items():
    expected[name] = change['after']
sysconf_format = json.loads((EVIDENCE / 'file-review-047-dos6-format-source.json').read_text())
expected[sysconf_format['file']] = sysconf_format['after_sha256']
sysinit2_format = json.loads((EVIDENCE / 'file-review-050-dos6-format-source.json').read_text())
expected[sysinit2_format['file']] = sysinit2_format['after_sha256']
retired_slice = json.loads((EVIDENCE / 'file-review-068-diskread-archive-source.json').read_text())
retired_name = retired_slice['source']
if digest((ROOT / 'extras' / retired_slice['archive']).read_bytes()) != retired_slice['sha256']:
    raise ValueError('retired research slice changed')
expected.pop(retired_name, None)
macro2_format = json.loads((EVIDENCE / 'file-review-088-macro2-format-source.json').read_text())
expected[macro2_format['file']] = macro2_format['after_sha256']
misc_format = json.loads((EVIDENCE / 'file-review-089-misc-format-source.json').read_text())
expected[misc_format['file']] = misc_format['after_sha256']
msinit_format = json.loads((EVIDENCE / 'file-review-098-msinit-format-source.json').read_text())
expected[msinit_format['file']] = msinit_format['after_sha256']
msinit_dpb_format = json.loads((EVIDENCE / 'file-review-098-msinit-dpb-format-source.json').read_text())
expected[msinit_dpb_format['file']] = msinit_dpb_format['after_sha256']
msproc_format = json.loads((EVIDENCE / 'file-review-099-msproc-format-source.json').read_text())
expected[msproc_format['file']] = msproc_format['after_sha256']
command_init_format = json.loads((EVIDENCE / 'file-review-129-init-format-source.json').read_text())
expected[command_init_format['file']] = command_init_format['after_sha256']
command_init_nt_macros = json.loads((EVIDENCE / 'file-review-129-init-unused-nt-macros.json').read_text())
expected[command_init_nt_macros['file']] = command_init_nt_macros['after_sha256']
tcode_single_format = json.loads((EVIDENCE / 'file-review-145-tcode-format-source.json').read_text())
expected[tcode_single_format['file']] = tcode_single_format['after_sha256']
uinit_format = json.loads((EVIDENCE / 'file-review-158-uinit-format-source.json').read_text())
expected[uinit_format['file']] = uinit_format['after_sha256']
mult_round2 = json.loads((EVIDENCE / 'round2-to-round1-021-mult.json').read_text())
expected[mult_round2['file']] = mult_round2['after_sha256']
expected['extras/tools/build_integrated_source.py'] = mult_round2['verification']['integrated_build_script_sha256']
msend_round2 = json.loads((EVIDENCE / 'round2-to-round1-038-msend.json').read_text())
expected[msend_round2['file']] = msend_round2['after_sha256']
create_round2 = json.loads((EVIDENCE / 'round2-to-round1-057-create.json').read_text())
expected[create_round2['file']] = create_round2['after_sha256']
crit_round2 = json.loads((EVIDENCE / 'round2-to-round1-058-crit.json').read_text())
expected[crit_round2['file']] = crit_round2['after_sha256']
dev_round2 = json.loads((EVIDENCE / 'round2-to-round1-060-dev.json').read_text())
expected[dev_round2['file']] = dev_round2['after_sha256']
dir2_round2 = json.loads((EVIDENCE / 'round2-to-round1-063-dir2.json').read_text())
expected[dir2_round2['file']] = dir2_round2['after_sha256']
disk2_round2 = json.loads((EVIDENCE / 'round2-to-round1-066-disk2.json').read_text())
expected[disk2_round2['file']] = disk2_round2['after_sha256']
dostab_round2 = json.loads((EVIDENCE / 'round2-to-round1-072-dostab.json').read_text())
expected[dostab_round2['file']] = dostab_round2['after_sha256']
fcb_round2 = json.loads((EVIDENCE / 'round2-to-round1-076-fcb.json').read_text())
expected[fcb_round2['file']] = fcb_round2['after_sha256']
msconst_round2 = json.loads((EVIDENCE / 'round2-to-round1-093-msconst.json').read_text())
expected[msconst_round2['file']] = msconst_round2['after_sha256']
expected['extras/tools/build_integrated_source.py'] = msconst_round2['verification']['integrated_build_script_sha256']
msctrlc_round2 = json.loads((EVIDENCE / 'round2-to-round1-094-msctrlc.json').read_text())
expected[msctrlc_round2['file']] = msctrlc_round2['after_sha256']
open_round2 = json.loads((EVIDENCE / 'round2-to-round1-102-open.json').read_text())
expected[open_round2['file']] = open_round2['after_sha256']
segcheck_round2 = json.loads((EVIDENCE / 'round2-to-round1-110-segcheck.json').read_text())
expected[segcheck_round2['file']] = segcheck_round2['after_sha256']
command1_round2 = json.loads((EVIDENCE / 'round2-to-round1-117-command1.json').read_text())
expected[command1_round2['file']] = command1_round2['after_sha256']
envdata_round2 = json.loads((EVIDENCE / 'round2-to-round1-126-envdata.json').read_text())
expected[envdata_round2['file']] = envdata_round2['after_sha256']
path1_round2 = json.loads((EVIDENCE / 'round2-to-round1-133-path1.json').read_text())
expected[path1_round2['file']] = path1_round2['after_sha256']
tcmd1b_round2 = json.loads((EVIDENCE / 'round2-to-round1-142-tcmd1b.json').read_text())
expected[tcmd1b_round2['file']] = tcmd1b_round2['after_sha256']
tcmd2a_round2 = json.loads((EVIDENCE / 'round2-to-round1-143-tcmd2a.json').read_text())
expected[tcmd2a_round2['file']] = tcmd2a_round2['after_sha256']
tcmd2b_round2 = json.loads((EVIDENCE / 'round2-to-round1-144-tcmd2b.json').read_text())
expected[tcmd2b_round2['file']] = tcmd2b_round2['after_sha256']
tenv_round2 = json.loads((EVIDENCE / 'round2-to-round1-147-tenv.json').read_text())
expected[tenv_round2['file']] = tenv_round2['after_sha256']
const2_round2 = json.loads((EVIDENCE / 'round2-to-round1-165-const2.json').read_text())
expected[const2_round2['file']] = const2_round2['after_sha256']
ioctl_round2 = json.loads((EVIDENCE / 'round2-to-round1-187-ioctl.json').read_text())
expected[ioctl_round2['file']] = ioctl_round2['after_sha256']
msdos_lnk_resource = json.loads((EVIDENCE / 'resource-review-004-msdos-lnk.json').read_text())
expected[msdos_lnk_resource['file']] = msdos_lnk_resource['after_sha256']
migration = json.loads((EVIDENCE / 'extras-path-migration.json').read_text(encoding='utf-8'))
for name in list(expected):
    if name.startswith(('tools/', 'docs/', 'research/', 'tests/')):
        expected['extras/' + name] = expected.pop(name)
for name, sha in migration['changed_files'].items():
    if name in expected:
        expected[name] = sha
for name, sha in expected.items():
    path = ROOT / name
    if not path.is_file() or digest(path.read_bytes()) != sha:
        raise ValueError(f'Current input differs from latest verified source: {name}')
actual_kernel = {p.relative_to(ROOT).as_posix().lower()
                 for p in (ROOT / 'dos').rglob('*') if p.is_file()}
recorded_kernel = {Path(p).as_posix().lower() for p in kernel['source_snapshot']}
recorded_kernel.discard(retired_name.lower())
if actual_kernel != recorded_kernel:
    raise ValueError('Kernel source tree has unrecorded or missing files')
print(json.dumps({'checked_files': len(expected), 'removed_inputs': sorted(removed),
                  'kernel_output_sha256': kernel['output_sha256'],
                  'command_output_sha256': command['output_sha256'],
                  'scope': 'Current files against integrated BIOS inputs and latest component source snapshots; no new build.'}, indent=2))
