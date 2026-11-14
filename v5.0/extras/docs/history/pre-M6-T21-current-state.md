# Current state: DOS 5 quality audit

## M6 T8 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; T8 follows the thread's closed DOS 6.20 T7
Admission And Approval | Owner requested the same source/tool audit for v5.0, removal of other script languages, and publication to v5.0/extras/assets
Objective | Maximize original DOS6/DOS4/OpenNT source form appropriate to standalone DOS5; simplify autonomous code/tools; preserve exact three-core output; pure CMD build
Non-goals | No other DOS versions, no O:/DOS deployment, no image mounting, no VM smoke test, no archive or Git commit
Reference Baseline | Original msdos500_boot.img and historical target hashes; DOS6/DOS4 and OpenNT; completed v5 file/resource reviews
Candidate Proposal | Freeze the full universe, reuse unchanged evidence, process remaining files in order, migrate the actual build to original-form DOS rules and CMD, retire other scripts, then verify and publish
Files And ABI Surface | 592 initial nonmetadata files: 249 core-tree files, 184 research/test/native-tool files, 159 non-CMD scripts; ignored script copies also included in final removal
Applicable Rules | All project rules plus current owner overrides below; no PowerShell or Computer Use; no D:/temp or D:/tempu
Verification | Hash correspondence for reused reviews; byte-identical references; effective-content comparison for formatting; rebuild after meaningful build/code changes; compare all three full outputs
Expected Markers | No unreviewed in-scope file; no non-CMD script retained; original-form makefiles; extras/build.cmd; three exact published files
Asset Needs | Frozen extras/baselines/targets, historical tools and native isolated-desktop runner; extras/assets is reserved for built verified outputs
Reporting Requirements | Current sequence/count, modified count, reference-identical count, retained/retired counts, concrete next file or dependency unit
Stop Conditions | Unexpected target/input change or binary mismatch; retain evidence and fix before publication
Exit Criteria | Entire source/tool scope audited, pure CMD build proven, all other scripts removed including ignored backups, three compiled outputs exact and published
Original Owner Request | Apply the completed 6.20 quality audit and CMD-only tooling standard to v5.0, with extras/assets as output directory
Similar-Issue Sweep | Include old Python wrapper makefiles, BIOS/private headers, optional sources, resources, research variants, native probes, compiled artifacts in source folders and ignored script copies

S1 and T8 are closed after implementation, verification and separate task audit.
No active S remains. Completion audit: ../history/M6-T8-completion-audit.md.
The pre-admission state is preserved in ../history/pre-M6-T8-current-state.md.

## Verified delivery

Run extras/build.cmd. The pure CMD host and original-form DOS makefiles build
all three components from source, compare each full file with the fixed target,
and publish only verified outputs to extras/assets. Accepted run:
extras/build/cmd-6108-11594. IO.SYS is 33430 bytes, MSDOS.SYS 37394 bytes,
and COMMAND.COM 47845 bytes; all three match the original image extracts.

The finite ledger ../etc/quality-audit-queue.json has 602 disposed entries:
221 reference-identical, 44 unchanged with prior reviewed evidence, 4 modified
existing build/resource files, 9 added build files, 1 updated existing status
document, 2 retained metadata/native-tool files, and 321 retired entries.
There are no pending entries or unregistered nonmetadata source/tool files.
No assembly instructions changed. Original empty conditional branches and
DOS5-specific values, including the UINIT switch count 7, are preserved.

The 321 retired entries include 159 maintained non-CMD scripts. Across the
whole extras tree including ignored work, 477 script/cache files were deleted
(314 Python, 162 bytecode, 1 PowerShell), plus an obsolete archive containing
scripts. Final sweep finds no non-CMD script residue. Completed experimental
sources/probes have hash-recorded ignored backups; they are not production
inputs. Their retirement does not claim equivalent runtime test coverage.

See ../etc/evidence/quality-final-audit.json for the final proof and links.
The full build was not repeated for documentation changes or removal of unused
debug/editor inputs: the other 251 accepted inputs remain hash-identical.
CMD mismatch rejection and rollback tests passed in a separate scratch tree;
the native isolated-desktop launcher also rebuilt to its pinned hash.
Build and target-baseline directories are ignored and have no tracked files.

No mounting, SoftPC smoke test, candidate archive, O:/DOS deployment or Git
commit was performed for this delivery. Exact output is demonstrated for the
selected three-core configuration; exact historical source provenance and
unselected optional configurations are not implied.

## Build progress update: M5 T10 S1

Visible progress added across all four versions. See
../etc/build-progress-acceptance.json. This addendum supersedes earlier current
launcher/build-helper hash claims; the original DOS build evidence remains
valid because source and effective compiler commands are unchanged. Four
tooling files changed per version; no DOS source change or rebuild.

## Current build entry location

The only build.cmd is extras/build.cmd. The former root wrapper and tools
helper have been merged into it. Progress, pause, exit status and lock behavior
are preserved. See ../etc/build-entry-location.json. Historical manifests
retain old paths as evidence; this relocation addendum owns current paths.
