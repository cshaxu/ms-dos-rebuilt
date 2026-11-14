# Manual CMD build and publication complete

## M5 T7 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; verified and closed
Admission And Approval | Owner requested build.cmd, automatic publication to extras/assets, removal of all Python and PowerShell scripts; owner requires CMD only
Objective | A pure CMD build entry with exact three-file validation and publication
Non-goals | No DOS source changes, no Node or other script-language runtime, no commit or unrelated version work
Reference Baseline | Closed T6 source/build audit and original DOS makefiles
Candidate Proposal | CMD host staging and hash checks; existing native isolated runner; original DOS NMAKE; publish only after all comparisons pass
Files And ABI Surface | build.cmd, extras/tools CMD support, script retirement, current build documentation
Applicable Rules | EXECUTION.md and CODING.md; no PowerShell/Computer Use; owned scratch only
Verification | Run actual CMD build once after migration; direct three-file comparison; publication failure checks; script inventory
Expected Markers | Three MATCH lines; assets exact; no Python/PowerShell files
Asset Needs | Pinned historical DOS tools, DOSBox, native runner/GCC and frozen target files
Reporting Requirements | Modified/new/retired counts separately; exact outputs and remaining work
Stop Conditions | Build mismatch, failed tool hash, unexpected input or publication failure
Exit Criteria | Manual entry succeeds without Python/PowerShell/Node and publishes all three verified files; scripts removed
Original Owner Request | Build and publish 6.20 from build.cmd; remove Python and PowerShell from extras
Similar-Issue Sweep | Include ignored script backups and bytecode; replace obsolete live documentation commands

M5 / T7 / S1 and T7 are verified and closed. No active packet remains.

The root build.cmd uses only CMD and native Windows/DOS tools. It builds and
publishes IO.SYS, MSDOS.SYS and COMMAND.COM to extras/assets after all three
pass full byte comparison. The actual run and publication passed; 234 input
hashes cover all 225 unchanged core source files and nine build inputs.
Wrong hashes and wrong output were rejected. A failed second publication
restored all three old assets. The native runner was reproduced exactly by
CMD/GCC without Python. No further DOS rebuild is required for these docs.

Added five CMD build/configuration files; no core source changed. Removed
64 Python script/backup/bytecode files, including ignored scratch. No
PowerShell files remain. Two obsolete JSON configurations were archived as
metadata. Evidence: ../etc/cmd-build-acceptance.json and
../etc/cmd-script-retirement.json. Current instructions: BUILD.md.

Earlier ledgers and commands below describe historical states, not the current
CMD-only tool inventory. Previous quality audit remains historical below.

# Quality audit closed

## M5 T6 S1 Packet

Field | Required record
--- | ---
Identifier Mode | Continuation; existing T6 quality audit now verified and closed
Admission And Approval | Owner authorized the complete 6.20 source/tooling audit
Objective | Preserve DOS 6.00 source form, remove unnecessary reconstruction paths, preserve exact three-core binaries
Non-goals | No deployment, VM smoke test, commit, or unrelated version changes
Reference Baseline | DOS 6.00 tree; frozen DOS 6.20 target files
Candidate Proposal | Close source/tool/research dispositions, then perform final requirement audit
Files And ABI Surface | 225 core-tree files; original 51 tools; added build/listing support; 48 research files
Applicable Rules | EXECUTION.md, CODING.md; no PowerShell or Computer Use; no rebuild for nonsemantic changes
Verification | Recorded hashes, original-reference byte comparisons, original-make production acceptance and runner format-only addendum
Expected Markers | No pending original tools; no unregistered nonmetadata files; no unexplained changes
Asset Needs | Existing reference sources and retained build evidence
Reporting Requirements | Separate changed, unchanged/reference-identical and retired counts
Stop Conditions | Unexpected hash mismatch or unidentified build-input change
Exit Criteria | Complete final requirement-to-evidence audit including added support and research scope
Original Owner Request | Audit all 6.20 assembly, nonassembly and build scripts while retaining exact original binary outputs
Similar-Issue Sweep | Research subtree included; completed COPY experiments retired; original excluded files preserved

Original tooling: 51/51 disposed (5 modified, 4 retained, 42 retired).
Core tree: 190 initially reference-identical plus 5 restored original files;
30 differences reviewed, with 2 comment-restored and 28 retained.
Research scope: 40 reference-identical files retained and 8 completed COPY
experiments retired, with backups under ignored extras/build.
No maintained executable caller referenced those eight experiments.

Current status: quality-current-status.json reports no changed/missing files.
Research evidence: quality-research-queue.json. Scope: quality-scope-check.json.
No core rebuild ran for these retirements or documentation updates.
M5 / T6 / S1 and task T6 are verified and closed. No active quality packet remains.
Final requirement audit: [quality-audit-closure.md](../quality-audit-closure.md).
Complete scope and hashes: ../etc/quality-final-ledger.json.
Current binary correspondence: ../etc/quality-completion-check.json.

All checkpoints below are historical, not the current queue.

# Reference-tool and status audit checkpoint

This batch disposed 12 original tools: 6 completed research entry points
retired, 4 read-only reference/mapping tools retained unchanged, 2 tools modified.
The FAT12 extractor now validates all three payloads before writing and refuses
nonempty output directories. Original-image extraction hashes are unchanged;
missing-file and overwrite negative tests passed.
The status command now checks current quality ledgers and current file hashes,
instead of rerunning the initial-import review.

Evidence: ../etc/quality-reference-tools.json,
../etc/quality-extractor-check.json and ../etc/quality-current-status.json.
Original tooling inventory: 42/51 disposed, 9 remain; current status reports no
changed or missing reviewed files. Source dispositions remain 190 reference
identical, 28 reviewed/retained and 2 comment-restored files.
No DOS rebuild ran; no core source or build recipe changed.

Next: isolated runner/helper and seven specialized verification tools.
Overall quality audit remains active.

Earlier checkpoints below are historical.

# Intermediate verification cleanup

Six obsolete mixed-reference experiments were retired after individual review:
RDATA messages/OMF, STUB listing, TDATA OMF, TRANMSG OMF and TSPC layout.
Their fixed old directories, old generated-message injection and expected
intermediate differences no longer belong in current acceptance tooling.
Historical investigation JSON is retained; these experiments are not claimed
algorithmically equivalent to full-build acceptance.

Current input hashes and all three existing output byte comparisons were
rechecked without rebuilding. Twelve final public symbol addresses confirm
the old resident, message and workspace layout hypotheses directly.
Evidence: ../etc/retired-intermediate-checks.json.

Original tooling inventory: 30/51 disposed; 21 remain. This batch changed no
core source or build rule. Six tools retired, zero retained as current tools.
Core source audit remains 2 modified, 28 retained, 190 initially reference-exact.
Next: remaining specialized checks and leaf research utilities. Goal active.

Earlier checkpoints below are historical.

# Listing checker consolidation verified

Twenty historical listing scripts had identical checking algorithms. They were
replaced by extras/tools/verify_listing.py and listing-regions.json.
All twenty existing listings produced identical old/new coverage, relocation
and branch counts. Empty/unparseable listings, corrupted fixed bytes and wrong
internal branch displacements were rejected. No assembler or core rebuild ran.
Evidence: ../etc/listing-consolidation-check.json.

The new checker requires an explicit existing listing and is read-only.
It does not assume the old copy-merge-stage directory or certify current source.
External relocation fields remain outside this historical partial check;
complete production acceptance remains the original-make three-file comparison.

Original tooling inventory: 24 of 51 entries disposed (1 migrated build entry,
3 retired build recipes, 20 retired duplicate listing checkers); 27 remain.
Added support has its own records: four verified DOS build support files and
the new listing checker plus interval metadata. Specialized checkers with extra
assertions were retained for separate review, not silently folded into the group.
Source dispositions are unchanged: 2 modified, 28 retained, 190 reference exact.

Next: the remaining specialized listing/OMF verifiers and research utilities,
in the recorded dependency order. Overall quality audit remains active.

Earlier checkpoints below are historical.

# Production makefile migration verified

The single build entry stages and runs the original DOS 6.00 makefiles.
All three complete files match the DOS 6.20 targets; inputs stayed unchanged.
Evidence: ../etc/original-make-production-build.json.
Removed build_command_reference.py, build_kernel_reference.py and
build_bios_reference.py after verifying no maintained callers remained.
Python retains staging, pinned-tool checks, isolation and complete comparison.

Tooling: one entry rewritten, three duplicate recipes retired, four new build
support files verified. Source audit: 30/30, with 2 changed and 28 retained,
plus 190 originally identical files. Five restored original build/dependency
files remain byte-identical to the DOS 6.00 reference.

Next: audit remaining tools in dependency order. Listing verifiers repeat a
parser and rely on an old fixed scratch stage; this finding remains open.
The full quality goal is not complete until the tooling audit closes.

Earlier checkpoints below are historical.

# Original build recipe restoration checkpoint

All three original DOS 6.00 makefiles have run successfully against the current
6.20 sources; all three outputs match the frozen targets exactly.
Restored five files byte-identically: bios/makefile, dos/makefile,
cmd/command/makefile, inc/romloc.inc and bios/msbior.lnk.
Evidence: ../etc/original-make-verified.json.

The tool runner now rejects batch names longer than DOS 8.3 allows before
launch; a direct negative check passed. Remaining work: route the production
entry point through these makefiles, retain only necessary generic host
isolation/verification logic, then finish the tooling queue and final audit.
No source-quality or binary-completion claim is made for that remaining work.

# Quality audit current checkpoint

M5 / T6 remains active. The 30 non-identical source files were reviewed:
2 changed (original comments restored), 28 retained. The preceding 190 files
are byte-identical to the DOS 6.00 reference. Four of the 30 are message inputs
absent from the primary DOS 6.00 tree; this reference limitation is explicit.

The source queue and per-file decisions are in quality-audit-queue.json.
Pure comments/formatting do not trigger a rebuild; effective assembly content
must be unchanged. Original empty conditions and repeated structures are kept.
Only reconstruction-introduced unnecessary paths are candidates for removal.

Current implementation: the four production Python build scripts no longer
select reference sources or fallback messages, and BIOS no longer appends BOOT
records to message input. Full binary verification passed for all three files after build
rules changed; see ../etc/quality-build-paths.json. These are not yet accepted as original-form makefile builds.
The remaining scope is the complete tooling queue, original-style build recipe
restoration, and final audit. No PowerShell is allowed.

Earlier checkpoint text below is history.

# Active quality audit: M5 / T6 / S1

Owner admitted a DOS 6.20 quality audit against the original DOS 6.00 source.
All three binaries must remain exactly equal to the original DOS 6.20 targets.
PowerShell execution and retained PowerShell scripts are prohibited.
The full scan includes ignored build directories; no PowerShell script files
were found at admission. BUILD.md command examples now use bat fences.

Queue: ../etc/quality-audit-queue.json. Start with build inputs and their
dependencies; resolve dependency order before modifying source files.
Identical source files may be skipped; non-identical files require ordered
review of structure, comments, formatting, duplication and unnecessary paths.
Build recipes must follow DOS 6.00 forms and must not inject target-specific
source or binary patches. This audit is active, not completed.

Previous delivery records below describe binary reconstruction, not this new
quality audit.

# Current state

Final worktree delivery has been documented after rechecking all 226 input hashes, the 260-entry ledger, ignored build/target directories, and all three complete target comparisons. Historical per-round statuses and original 6.20 attribution remain documented limitations, not reasons to repeat completed file reviews. See [delivery](../history/M4-T5-delivery.md) and [acceptance audit](../etc/acceptance-audit.json).

The 260-entry file ledger has been summarized without a new audit round: 190 DOS 6-identical, 26 modified, four new message inputs and 40 excluded. Separate historical three-round status per entry was not recorded; this is a documentation limit, not a claim that the passes were reconstructed. See [disposition summary](../etc/m2-t3-file-disposition-summary.json).

Owner clarified that historically uncertain reconstructed source data is normal and must not block the project. The three STUB bytes remain explicitly marked as reconstructed with unknown origin; no target binary blob is a build input and no built binary is patched. The earlier blocked/approval interpretation was an error. See [acceptance audit](../etc/acceptance-audit.json).

A fresh full build after the STUB comment clarification records the current 226-file input snapshot and matches all three targets; the owner decision on the three reconstructed tail bytes remains pending. See [build](../etc/three-core-comment-snapshot-build.json).

STUB tail comment now identifies the bytes as reconstructed with unknown origin. Its reassembled object matches the previous target-matching object byte for byte; owner decision on acceptance remains pending.

The unified build now verifies all three baseline file sizes and hashes before starting; a missing-baseline negative probe passed and a fresh build matched all targets. The build guide documents read-only extraction into a new ignored directory. See [build evidence](../etc/three-core-verified-baseline-build.json).

A fresh three-component build now records hashes for 220 source/message files and six build scripts/runner source and verifies that the set stayed unchanged during the build; all three outputs match target. See [snapshot and build](../etc/three-core-input-snapshot-build.json).

Component build scripts now reject missing project message sources instead of silently substituting reference inputs. Negative guard probe passed; a fresh build again matches all three target files. See [build](../etc/three-core-strict-input-build.json).

Six selected link/skeleton build inputs have been appended as indices 255–260: five match DOS 6.0 and the COMMAND skeleton was reconstructed for target messages. All actual files in the core and message directories are now represented in the ledger. See [ledger](../etc/file-review-ledger.json).

The acceptance matrix records direct image/build equality and a complete ordered ledger, and leaves STUB tail provenance and formal MTSP task closure open. See [acceptance audit](../etc/acceptance-audit.json).

A bounded build-input screen found target-file reads in the component scripts after output production for comparison. The four sources containing long hexadecimal tables match DOS 6.0; optional ROM data is not in the selected link. The separate reconstructed STUB tail issue remains open. See [screen](../etc/build-input-bounded-screen.json).

The local 6.20 ZIP contains no STUB source/object/map by member name; both COMMAND copies have the same hash as the target and are not independent source evidence. The adjacent RAR lists installer executables, whose contents were not inspected. See [tail investigation](../etc/stub-tail-origin-investigation.json).

The local DOS 6.00 source archive was inspected read-only; its STUB is byte-identical to the existing 6.0 reference and supplies no new 6.20 tail evidence. See [investigation](../etc/stub-tail-origin-investigation.json).

A bounded text search of the DOS 6.0, Astro, OpenNT and XP MVDM references found no independent whole-word `cox` or matching byte declaration; archives and unavailable 6.20 source are not covered. See [tail investigation](../etc/stub-tail-origin-investigation.json).

OpenNT, Windows XP MVDM and reconstructed v5 STUB references end their data segment after the corresponding Exec_Trap jump and do not explain the target 6.20 tail; their UMB paths differ and they cannot establish original 6.20 source. See [investigation](../etc/stub-tail-origin-investigation.json).

Microsoft public MS-DOS source repository lists versions 1.25, 2.0 and 4.0, not 6.2; it does not resolve STUB tail attribution. This is not a claim that other source does not exist. See [tail investigation](../etc/stub-tail-origin-investigation.json).

STUB tail static check found no linked public symbol in RESGROUP 02C2h–02C4h and no exact numeric references in selected COMMAND/include sources. This cannot rule out indirect references or establish historical meaning. See [reference audit](../etc/stub-tail-reference-audit.json).

Read-only cross-image inspection confirms the `cox` boundary in three distinct COMMAND.COM binaries from DOS 6.20, 6.21 and 6.22, whereas the 6.00 image places resident data immediately after the same jump. The 6.22 media and Chinese-labeled image contain the same COMMAND binary and are not independent source evidence. Historical source meaning remains unproven. See [cross-image audit](../etc/stub-tail-cross-image-audit.json).

An isolated STUB tail probe replaced the three explicit bytes with uninitialized storage. Both available historical linkers emitted zeros, leaving exactly those three target-byte differences. This does not establish the original source; the issue remains open. See [investigation](../etc/stub-tail-origin-investigation.json).

STUB tail investigation: the three target-derived bytes follow an unconditional jump and occur in the linked EXE before RELOC, but their historical origin and any possible indirect entry remain unknown. Reference DOS 6 STUB sources end after the jump. The source-fragment acceptance issue remains open. See [investigation](../etc/stub-tail-origin-investigation.json).

Read-only FAT12 extraction from the user-specified image has been directly compared with both retained baseline files and the latest three full builds; all three match byte for byte. The supplied image is truncated outside the complete core-file chains. See [direct audit](../etc/image-build-direct-audit.json).

Completion remains open: `cmd/command/stub.asm` emits a target-derived three-byte `cox` tail whose historical source ownership and meaning are unproven (review 144). This needs reconciliation with the plan prohibition on using target binary fragments as build material; matching outputs alone do not close that requirement.

The file ledger now appends four required USA message inputs at indices 251–254 without changing the original frozen 250 entries. All 254 entries are reviewed or excluded; the appended files have independent source and target-build evidence. See [ledger](../etc/file-review-ledger.json).

The isolated tool runner is now rebuilt from project-owned source under `extras/tools`, removing the runtime dependency on the v5.0 project directory. A fresh three-component build with that runner matches all target bytes. See [runner provenance](../etc/local-runner-provenance.json) and [comparison](../etc/three-core-local-runner-build.json).

`extras/tools/build_three.py` builds all three components in fresh isolated stages and independently compares complete outputs: all match target. Project message inputs are required; pinned tools and target binaries remain external. See [build guide](BUILD.md) and [comparison](../etc/three-core-clean-build.json).

COMMAND now builds in a fresh stage using project-owned initialization, resident and generated message sources, and equals the 54619-byte target. TDATA exports answer aliases from generated message 1104. Tools remain external pinned dependencies. See [message review](../etc/message-review-004-command.json) and [build](../etc/command-project-messages-clean-build.json).

## Historical progress entries

The entries below record observations at the time they were made; pending statements may have been superseded by the current build status above. The active MTSP packet is retained at the end of this document.

Resident COMMAND message source `lang/usa/messages/comrmsg.inc` is project-owned and byte-identical to Astro; RDATA reassembly and diagnostic link retain complete target equality. Generated transient messages and clean build remain open. See [message review](../etc/message-review-003-comrmsg.json).

Project-owned `lang/usa/messages/usa-ms-dos.msg` contains the selected MSBIO, MSDOS and BOOT message sections. Fresh builds using it match IO.SYS and MSDOS.SYS byte for byte; tool dependencies and COMMAND message closure remain open. See [message review](../etc/message-review-002-system.json).

Initialization message source `lang/usa/messages/comimsg.inc` is now project-owned, matching the previously target-identical diagnostic link; the COMMAND build selects it when present. Other message inputs and clean linking remain open. See [message review](../etc/message-review-001-comimsg.json).

COMMAND.COM diagnostic link now matches all 54619 target bytes after message reconstruction in ignored probe storage and six COPY TRANGROUP offsets. The message inputs are not yet project-owned or reproducibly generated; clean final builds remain open. See [COPY review](../etc/file-review-117-copy.json).

A diagnostic COMMAND link succeeds after placing COPY answer symbols in TRANDATA and adding inferred message records 1103–1105 to a generated probe. Output length is 54056 versus target 54619; the probe message source and full identity remain unresolved. See [review](../etc/file-review-117-copy.json).

TCODE BatchStep now declares ES:RESGROUP using the existing source convention; an isolated link no longer reports its six fix-up overflows and still reports four unresolved answer_* symbols. Target non-relocation bytes and internal branches remain matched. See [review](../etc/file-review-151-tcode.json).

IO.SYS now builds byte-identically to the 40,566-byte target after moving the SYSCONF failure label before CheckDoubleSpace. This build used the temporary reconstructed message probe; final source-owned message inputs and a self-contained production build remain open. See [build](../etc/bios-message-620-branch-verified.json).

IO.SYS message probe updated MSBIO message IDs 18, 23, 34 and 36 in isolated input; rebuilt output has target length 40,566 and only two differing bytes, at 0x6DDB and 0x6E00, both SYSCONF short-branch displacements. The message input remains provisional and build-local; final source ownership and branch control flow are unresolved. See [probe](../etc/bios-message-620-probe2.json).

Fresh full-build baseline using current source and provisional message candidates: MSDOS.SYS builds to 38,138 bytes and is byte-identical to target (SHA-256 1ff320e7fdb3de707370e18d48d52b724b6f40f86ae7b70469bb130d754a904f); this does not establish self-contained final message provenance. IO.SYS builds to 40,550 bytes versus target 40,566 and first differs at offset 8089. COMMAND assembles but linking fails with TRANCODE fix-up overflows and unresolved answer_buffer/answer_yes/answer_no/answer_all. See [kernel](../etc/kernel-current-version-baseline.json), [BIOS](../etc/bios-current-version-baseline.json), and [COMMAND](../etc/command-current-version-baseline.json) reports. These are isolated diagnostic builds, not final distribution artifacts.

Index 250 `inc/yesno.asm` remains identical to DOS 6.0 and astro; it exports generated country yes/no characters. Generated resources and final links remain pending. See [review](../etc/file-review-250-yesno.json).

Index 249 `inc/xmm.inc` remains identical to DOS 6.0 and astro; prior COMMAND and DOS comparisons support selected XMM constants. Final links remain pending. See [review](../etc/file-review-249-xmm.json).

Index 248 `inc/wpatch.inc` remains identical to DOS 6.0 and astro; selected assembled patch data matches its inferred target DOSDATA range. Final links remain pending. See [review](../etc/file-review-248-wpatch.json).

Index 247 `inc/wordout.inc` is excluded from the selected non-debug core build; the diagnostic routines are retained under research. See [review](../etc/file-review-247-wordout.json).

Index 246 `inc/win386.inc` remains identical to DOS 6.0 and astro; prior MSCODE and MSINIT comparisons support selected interface definitions. Final links remain pending. See [review](../etc/file-review-246-win386.json).

Index 245 `inc/versiona.inc` restores minor version 20; isolated BIOS, DOS and COMMAND assemblies emit target version values. Final links remain pending. See [review](../etc/file-review-245-versiona.json).

Index 244 `inc/version.inc` remains identical to DOS 6.0 and astro; it controls assembly options, while numeric version definitions are in index 245. Final links remain pending. See [review](../etc/file-review-244-version.json).

Index 243 `inc/vector.inc` remains identical to DOS 6.0 and astro; prior MSINIT comparison supports selected interrupt-vector definitions. Final links remain pending. See [review](../etc/file-review-243-vector.json).

Index 242 `inc/umb.inc` remains identical to DOS 6.0 and astro; prior SYSCONF comparison supports selected upper-memory definitions. Final links remain pending. See [review](../etc/file-review-242-umb.json).

Index 241 `inc/sysvar.inc` remains identical to DOS 6.0 and astro; prior SYSINIT1 and MSINIT comparisons support selected initialization structure fields. Final links remain pending. See [review](../etc/file-review-241-sysvar.json).

Index 240 `inc/sysmsg.inc` restores two thousands-separator positions; the complete TPRINTF message-service module has no non-relocation byte differences and 66 internal near branches match the inferred target. Final link remains pending. See [review](../etc/file-review-240-sysmsg.json).

Index 239 `inc/syscall.inc` remains identical to DOS 6.0 and astro; prior PATH2 comparison supports a selected system call definition. Final links remain pending. See [review](../etc/file-review-239-syscall.json).

Index 238 `inc/struc.inc` is excluded from the selected core build; the unreferenced structured-assembly macro library is retained under research. See [review](../etc/file-review-238-struc.json).

Index 237 `inc/smifssym.inc` remains identical to DOS 6.0 and astro; retained for the BIOS include-listing auxiliary, outside the selected core dependency inventory. See [review](../etc/file-review-237-smifssym.json).

Index 236 `inc/smdossym.inc` is excluded from the selected core build; its obsolete unreferenced aggregation header is retained under research. See [review](../etc/file-review-236-smdossym.json).

Index 235 `inc/sf.inc` remains identical to DOS 6.0 and astro; prior DISK and CONST2 comparisons support selected system-file-table uses. Final links remain pending. See [review](../etc/file-review-235-sf.json).

Index 234 `inc/romloc.inc` is excluded from the selected disk-based core build; unreferenced ROM locations are retained under research. See [review](../etc/file-review-234-romloc.json).

Index 233 `inc/rombios.inc` remains identical to DOS 6.0 and astro; prior COMMAND DIR comparison supports selected screen-data references. Final links remain pending. See [review](../etc/file-review-233-rombios.json).

Index 232 `inc/redirsym.inc` is excluded from the selected core build; the unreferenced redirector implementation header is retained under research. See [review](../etc/file-review-232-redirsym.json).

Index 231 `inc/psdata.inc` remains identical to DOS 6.0 and astro; the current TPARSE object comparison covers its selected parser configuration. Final links remain pending. See [review](../etc/file-review-231-psdata.json).

Index 230 `inc/postequ.inc` is excluded from the selected core build; unreferenced POST constants are retained under research. See [review](../etc/file-review-230-postequ.json).

Index 229 `inc/pdb.inc` remains identical to DOS 6.0 and astro; prior process-module comparisons support its exercised fields. Final links remain pending. See [review](../etc/file-review-229-pdb.json).

Index 228 `inc/pcinput.inc` is excluded from the selected core build; the unreferenced screen-input implementation is retained under research. See [review](../etc/file-review-228-pcinput.json).

Index 227 `inc/pcgequ.inc` is excluded from the selected core build; unreferenced graphics definitions are retained under research. See [review](../etc/file-review-227-pcgequ.json).

Index 226 `inc/pathmac.inc` is excluded from the selected core build; its unreferenced path-label macro is retained under research. See [review](../etc/file-review-226-pathmac.json).

Index 225 `inc/path.asm` is excluded from the selected core build; the distinct DOS and COMMAND path modules remain. See [review](../etc/file-review-225-path.json).

Index 224 `inc/parse.asm` remains identical to DOS 6.0 and astro; current TPARSE object comparison matches 2412 non-relocation bytes and 70 internal branches. Final links remain pending. See [review](../etc/file-review-224-parse.json).

Index 223 `inc/origin.inc` remains identical to DOS 6.0 and astro; isolated assembly with current size values emits target origin 3DE0h. Full kernel link remains pending. See [review](../etc/file-review-223-origin.json).

Index 222 `inc/oemnum.inc` is excluded from the selected core build; the unreferenced documentary list is retained under research. See [review](../etc/file-review-222-oemnum.json).

Index 221 `inc/oemconf.inc` remains identical to DOS 6.0 and astro; four SYSINIT1 default values match the target in a diagnostic comparison. Final links remain pending. See [review](../etc/file-review-221-oemconf.json).

Index 220 `inc/mult.inc` remains identical to DOS 6.0 and astro; prior DIRCALL and MSLOAD comparisons support exercised multiplex constants. Final links remain pending. See [review](../etc/file-review-220-mult.json).

Index 219 `inc/mstable.asm` is excluded from the selected core build; the distinct selected `dos/mstable.asm` remains. See [review](../etc/file-review-219-mstable.json).

Index 218 `inc/mshead.asm` remains identical to DOS 6.0 and astro; kernel header origin and version dependencies require a fresh final link. See [review](../etc/file-review-218-mshead.json).

Index 217 `inc/mshalo.asm` remains identical to DOS 6.0 and astro; the selected TCODE assembly includes its ROM code. Final COMMAND linking remains pending. See [review](../etc/file-review-217-mshalo.json).

Index 216 `inc/msgserv.asm` restores transient message input and grouped numeric conversion; final linking remains pending; the two formatting constants were restored in index 240. See [review](../etc/file-review-216-msgserv.json).

Index 215 `inc/msghan.inc` is excluded from the selected core build; unreferenced utility message definitions are retained under research. See [review](../etc/file-review-215-msghan.json).

Index 214 `inc/msgdcl.inc` remains identical to DOS 6.0 and astro; message-service implementation and generated inputs remain independently pending. See [review](../etc/file-review-214-msgdcl.json).

Index 213 `inc/msdata2.asm` is excluded from the selected core build; the alternate aggregation unit is retained under research. See [review](../etc/file-review-213-msdata2.json).

Index 212 `inc/msbds.inc` remains identical to DOS 6.0 and astro; prior BIOS disk module comparisons support selected disk descriptor uses. Final links remain pending. See [review](../etc/file-review-212-msbds.json).

Index 211 `inc/msbdata.inc` remains identical to DOS 6.0 and astro; ten fixed BIOS interface bytes match target IO.SYS in a prior build. Final links remain pending. See [review](../etc/file-review-211-msbdata.json).

Index 210 `inc/ms_data.asm` remains identical to DOS 6.0 and astro; 1783 aligned output bytes match, including materialized uninitialized storage. Final kernel layout remains pending. See [review](../etc/file-review-210-ms_data.json).

Index 209 `inc/mi.inc` remains identical to DOS 6.0 and astro; prior MISC and MSDISP comparisons support exercised instruction and flag constants. Final links remain pending. See [review](../etc/file-review-209-mi.json).

Index 208 `inc/mft.inc` is excluded from the selected core build because no retained source includes it; it is retained under research. See [review](../etc/file-review-208-mft.json).

Index 207 `inc/magicdrv.inc` remains identical to DOS 6.0 and astro; prior CRATIO and SYSPRE comparisons support exercised DoubleSpace interface values. Final links remain pending. See [review](../etc/file-review-207-magicdrv.json).

Index 206 `inc/lock.inc` remains identical to DOS 6.0 and astro; prior LOCK module comparison supports its exercised fields. Final linking remains pending. See [review](../etc/file-review-206-lock.json).

Index 205 `inc/lmstub.asm` remains identical to DOS 6.0 and astro; its 769-byte aligned data contribution differs only in ten relocatable pointer bytes. Final kernel linking remains pending. See [review](../etc/file-review-205-lmstub.json).

Index 204 `inc/keybshar.inc` is excluded from the selected core build; the unreferenced KEYB-specific definitions are retained under research. See [review](../etc/file-review-204-keybshar.json).

Index 203 `inc/ioctl.inc` remains identical to DOS 6.0 and astro; prior BIOS MSDIOCTL comparison supports exercised function codes. Final links remain pending. See [review](../etc/file-review-203-ioctl.json).

Index 202 `inc/intnat.inc` remains identical to DOS 6.0 and astro; TSPC uses its international data structure, whose final layout awaits linking. See [review](../etc/file-review-202-intnat.json).

Index 201 `inc/int2a.inc` remains identical to DOS 6.0 and astro; the selected CRIT module matches 128 target bytes. Final links remain pending. See [review](../etc/file-review-201-int2a.json).

Index 200 `inc/highvar.inc` remains identical to DOS 6.0 and astro; high-memory variable layout retains pending final-link verification. See [review](../etc/file-review-200-highvar.json).

Index 199 `inc/highload.inc` remains identical to DOS 6.0 and astro; prior LOADHI and SYSCONF comparisons cover selected expansions. Final links remain pending. See [review](../etc/file-review-199-highload.json).

Index 198 `inc/highexit.inc` remains identical to DOS 6.0 and astro; prior SYSCONF and STUB comparisons cover selected expansions. Final links remain pending. See [review](../etc/file-review-198-highexit.json).

Index 197 `inc/find.inc` remains identical to DOS 6.0 and astro; prior COMMAND DIR and PATH2 comparisons support exercised find-buffer fields. Final links remain pending. See [review](../etc/file-review-197-find.json).

Index 196 `inc/filemode.inc` remains identical to DOS 6.0 and astro; prior DISK and OPEN comparisons support selected access-mode values. Final links remain pending. See [review](../etc/file-review-196-filemode.json).

Index 195 `inc/fastxxxx.inc` remains identical to DOS 6.0 and astro; prior selected DOS module comparisons support exercised flags. Final links remain pending. See [review](../etc/file-review-195-fastxxxx.json).

Index 194 `inc/fastopen.inc` remains identical to DOS 6.0 and astro; prior DIR2 and DIRCALL comparisons support exercised interface constants. Final links remain pending. See [review](../etc/file-review-194-fastopen.json).

Index 193 `inc/exe.inc` remains identical to DOS 6.0 and astro; prior MSPROC and EXEPATCH comparisons support exercised definitions. Final links remain pending. See [review](../etc/file-review-193-exe.json).

Index 192 `inc/error.inc` remains identical to DOS 6.0 and astro; prior DIRCALL comparison supports its exercised error constants. Final links remain pending. See [review](../etc/file-review-192-error.json).

Index 191 `inc/ea.inc` remains identical to DOS 6.0 and astro; retained as a dependency of the BIOS include-listing auxiliary, not evidenced as part of the selected core links. See [review](../etc/file-review-191-ea.json).

Index 190 `inc/dseg.inc` is excluded from the selected core build because it is not included; the reference file is retained under research. See [review](../etc/file-review-190-dseg.json).

Index 189 `inc/ds_vers.inc` restores DoubleSpace internal revision 10; isolated SYSPRE assembly emits the target instruction. Final IO.SYS linking remains pending. See [review](../etc/file-review-189-ds_vers.json).

Index 188 `inc/ds_vers.h` is excluded from the selected core build; the separate assembler version include remains for ordered review. See [review](../etc/file-review-188-ds_vers_h.json).

Index 187 `inc/dpl.asm` remains identical to DOS 6.0 and astro; prior SRVCALL comparison supports its selected-build field offsets. Final linking remains pending. See [review](../etc/file-review-187-dpl.json).

Index 186 `inc/dpb.inc` remains identical to DOS 6.0 and astro; prior FAT and BUF comparisons support its exercised fields. Final links remain pending. See [review](../etc/file-review-186-dpb.json).

Index 185 `inc/dossym.inc` remains identical to DOS 6.0 and astro; its included dependencies remain independently tracked and final links are pending. See [review](../etc/file-review-185-dossym.json).

Index 184 `inc/dosseg.inc` remains identical to DOS 6.0 and astro; complete target segment placement awaits the final kernel link. See [review](../etc/file-review-184-dosseg.json).

Index 183 `inc/dosmac.inc` remains identical to DOS 6.0 and astro; prior BIOS and DOS module comparisons support selected macro expansions. Final links remain pending. See [review](../etc/file-review-183-dosmac.json).

Index 182 `inc/doscntry.inc` remains identical to DOS 6.0 and astro; prior GETSET and TENV comparisons support its selected-build uses. Final links remain pending. See [review](../etc/file-review-182-doscntry.json).

Index 181 `inc/dirent.inc` remains identical to DOS 6.0 and astro; prior DIR2 and FAT comparisons support the selected directory entry definitions. Final links remain pending. See [review](../etc/file-review-181-dirent.json).

Index 180 `inc/devsym.inc` remains identical to DOS 6.0 and astro; prior BIOS and DOS module comparisons support its selected-build device definitions. Final links remain pending. See [review](../etc/file-review-180-devsym.json).

Index 179 `inc/dbcs.sw` remains identical to DOS 6.0 and astro; it only reports an externally defined build switch and emits no object bytes. Final configuration and links remain to be verified. See [review](../etc/file-review-179-dbcs.json).

Index 178 `inc/curdir.inc` remains identical to DOS 6.0 and astro; prior directory module comparisons support its selected-build uses. Final links remain pending. See [review](../etc/file-review-178-curdir.json).

Index 177 `inc/cputype.inc` remains identical to DOS 6.0 and astro; its 36-byte DOS initialization expansion matches target MSDOS.SYS. Final links remain pending. See [review](../etc/file-review-177-cputype.json).

Index 176 `inc/cpmfcb.inc` remains identical to DOS 6.0 and astro; prior FCBIO and FCBIO2 comparisons support its selected-build uses. Final kernel linking remains pending. See [review](../etc/file-review-176-cpmfcb.json).

Index 175 `inc/copyrigh.inc` remains identical to DOS 6.0 and astro; the USA copyright bytes occur in each of the three target files. Final links remain pending. See [review](../etc/file-review-175-copyrigh.json).

Index 174 `inc/const2.asm` remains identical to DOS 6.0 and astro; its 741 labelled data bytes match the target in the prior kernel build. Final kernel linking remains pending. See [review](../etc/file-review-174-const2.json).

Index 173 `inc/cmacros.inc` is excluded from the selected core build because no selected source includes the library; it is retained under research. See [review](../etc/file-review-173-cmacros.json).

Index 172 `inc/chkcpu.inc` is excluded from the selected core build because its macro is unreferenced; the reference file is retained under research. See [review](../etc/file-review-172-chkcpu.json).

Index 171 `inc/bugtyp.inc` remains identical to DOS 6.0 and astro; it supplies DOS debugging definitions. Final kernel linking remains pending. See [review](../etc/file-review-171-bugtyp.json).

Index 170 `inc/buffer.inc` remains identical to DOS 6.0 and astro; existing BUF and FAT comparisons support its selected-build uses. Final MSDOS.SYS linking remains pending. See [review](../etc/file-review-170-buffer.json).

Index 169 `inc/bpb.inc` remains identical to DOS 6.0 and astro; prior selected BIOS, DOS and COMMAND module comparisons support its exercised definitions. Final links remain pending. See [review](../etc/file-review-169-bpb.json).

Index 168 `inc/bootform.inc` remains identical to DOS 6.0 and astro; prior BIOS module comparisons support its selected-build uses. Final IO.SYS linking remains pending. See [review](../etc/file-review-168-bootform.json).

Index 167 `inc/bdsize.inc` adopts astro size equates, producing the target kernel header origin 3DE0h; individual BIOS sizes and final links remain unverified. See [review](../etc/file-review-167-bdsize.json).

Index 166 `inc/arena.inc` remains identical to DOS 6.0 and astro; prior ALLOC and LOADHI comparisons support the definitions exercised there. Final links remain pending. See [review](../etc/file-review-166-arena.json).

Index 165 `inc/_parse.asm` is excluded from the selected core build; COMMAND retains its separate parser. See [review](../etc/file-review-165-_parse.json).

Index 164 `cmd/command/uinit.asm` restores the ninth COMMAND /Y parsing entry. Diagnostic linking confirms the target symbol addresses and 29-byte authored tail; generated initialization messages and final linking remain pending. See [review](../etc/file-review-164-uinit.json).

Index 163 `cmd/command/tucode.asm` remains reference-identical. Its 451 non-relocation bytes and eight internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-163-tucode.json).

Index 162 `cmd/command/tspc.asm` restores 14 COPY state bytes; all 3,924 other aligned reference bytes match the target. COPY answer-character aliases belong to generated message resources and remain unresolved. See [review](../etc/file-review-162-tspc.json).

Index 161 `cmd/command/tranmsg.asm` restores DIR formatting and batch-step message blocks. Combined TDATA emits 1,456 matching non-relocation bytes; message texts and final linking remain pending. See [review](../etc/file-review-161-tranmsg.json).

Index 160 `cmd/command/tprintf.asm` exports SYSDISPMSG for COPY; the authored prefix matches the target outside relocation fields. Target changes inside the generated MSG_SERVICES implementation remain for inc/msgserv.asm. See [review](../etc/file-review-160-tprintf.json).

Index 159 `cmd/command/tpipe.asm` remains reference-identical. Its 689 non-relocation bytes and 18 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-159-tpipe.json).

Index 158 `cmd/command/tparse.asm` remains reference-identical. Its OMF code including parse.asm matches 2,412 non-relocation bytes and 70 internal branch fixups in the inferred target module. Final linking remains pending. See [review](../etc/file-review-158-tparse.json).

Index 157 `cmd/command/tmisc2.asm` remains reference-identical. Its 399 non-relocation bytes and eight internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-157-tmisc2.json).

Index 156 `cmd/command/tmisc1.asm` has switch count 8 restored. Its 684 non-relocation bytes and 12 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-156-tmisc1.json).

Index 155 `cmd/command/tfor.asm` remains reference-identical. Its 552 non-relocation bytes and 13 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-155-tfor.json).

Index 154 `cmd/command/tenv2.asm` remains reference-identical. Its 588 non-relocation bytes and 14 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-154-tenv2.json).

Index 153 `cmd/command/tenv.asm` remains reference-identical. Its 546 non-relocation bytes and 31 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-153-tenv.json).

Index 152 `cmd/command/tdata.asm` has source-level review completed: target COPY data is restored and all direct TRANDATA fixed bytes match after accounting for pending TRANMSG changes. Generated message inputs and final linking remain pending. See [review](../etc/file-review-152-tdata.json).

Index 151 `cmd/command/tcode.asm` has source-level review completed: /Y step confirmation and COPY command-origin logic are restored, with target non-relocation bytes and internal branches matching. The prompt message and final linking remain pending. See [review](../etc/file-review-151-tcode.json).

Index 150 `cmd/command/tcmd2b.asm` remains reference-identical. Its 442 non-relocation bytes and seven internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-150-tcmd2b.json).

Index 149 `cmd/command/tcmd2a.asm` remains reference-identical. Its 538 non-relocation bytes and nine internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-149-tcmd2a.json).

Index 148 `cmd/command/tcmd1b.asm` remains reference-identical. Its 653 non-relocation bytes and eight internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-148-tcmd1b.json).

Index 147 `cmd/command/tcmd1a.asm` is an obsolete predecessor replaced by DIR.ASM and is archived outside the selected core source tree. See [review](../etc/file-review-147-tcmd1a.json).

Index 146 `cmd/command/tbatch2.asm` remains reference-identical. Its 860 non-relocation bytes and 19 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-146-tbatch2.json).

Index 145 `cmd/command/tbatch.asm` remains reference-identical. Its 903 non-relocation bytes and 17 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-145-tbatch.json).

Index 144 `cmd/command/stub.asm` has source-level review completed. A diagnostic link matches the target STUB except its deferred version byte and places both RDATA state words at target offsets. The three reconstructed tail bytes have unproven historical attribution; final link remains pending. See [review](../etc/file-review-144-stub.json).

Index 143 `cmd/command/rucode.asm` remains reference-identical. Its 791 non-relocation bytes and 23 internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-143-rucode.json).

Index 142 `cmd/command/romstub/command.asm` is a separate disk stub for ROM COMMAND, distinct from the floppy build's stub.asm; it is archived outside the floppy core source tree. See [review](../etc/file-review-142-romstub-command.json).

Index 141 `cmd/command/romres.asm` is a ROM resident-image locator and is archived outside the floppy core source tree. See [review](../etc/file-review-141-romres.json).

Index 140 `cmd/command/romldr.asm` is a ROM image loader and is archived outside the floppy core source tree. See [review](../etc/file-review-140-romldr.json).

Index 139 `cmd/command/romhead.asm` is a separate ROM COMMAND header and is archived outside the floppy core source tree. See [review](../etc/file-review-139-romhead.json).

Index 138 `cmd/command/resmsg.equ` remains reference-identical; selected resident substitution and message macro outputs match target subject to relocation. Final linking remains pending. See [review](../etc/file-review-138-resmsg.json).

Index 137 `cmd/command/rdata.asm` has source-level review completed: both state words are restored; pre-message data and message content align subject to relocation and inferred segment base. Final linking and message provenance remain pending. See [review](../etc/file-review-137-rdata.json).

Index 136 `cmd/command/path2.asm` remains reference-identical. Its 353 non-relocation bytes and one internal branch match the inferred target module; final linking remains pending. See [review](../etc/file-review-136-path2.json).

Index 135 `cmd/command/path1.asm` remains reference-identical. Its 396 non-relocation bytes and six internal branches match the inferred target module; final linking remains pending. See [review](../etc/file-review-135-path1.json).

Index 134 `cmd/command/parse2.asm` remains reference-identical. Its 230 non-relocation bytes and five internal branches match the inferred target module. Its unused switch_count definition does not encode the switch-table length. See [review](../etc/file-review-134-parse2.json).

Index 133 `cmd/command/minicmd/romhead.asm` is the separate ROM COMMAND header and is archived outside the floppy core source tree. See [review](../etc/file-review-133-romhead.json).

Index 132 `cmd/command/minicmd/minicmd.inc` contains constants for separate MINICMD.COM and is archived outside the selected core source tree. See [review](../etc/file-review-132-minicmd-inc.json).

Index 131 `cmd/command/minicmd/minicmd.asm` belongs to separate ROM-oriented MINICMD.COM and is archived outside the selected core source tree. See [review](../etc/file-review-131-minicmd.json).

Index 130 `cmd/command/minicmd/dataseg.inc` is a message include for the separate MINICMD.COM utility and is archived outside the selected core source tree. See [review](../etc/file-review-130-dataseg-inc.json).

Index 129 `cmd/command/minicmd/dataseg.asm` belongs to the separate MINICMD.COM utility and is archived outside the selected core source tree. See [review](../etc/file-review-129-dataseg.json).

Index 128 `cmd/command/loadhi.asm` remains reference-identical. Its 1,697 non-relocation bytes and 73 internal branches match the inferred target module, including HIGHLOAD.INC. Final linking remains pending. See [review](../etc/file-review-128-loadhi.json).

Index 127 `cmd/command/iparse.asm` remains reference-identical. Its parser include is commented out and the reference configuration emits an empty INIT segment. See [review](../etc/file-review-127-iparse.json).

Index 126 `cmd/command/init.asm` has the target COMMAND /Y branch restored. 2,026 non-relocation bytes and 51 internal branches match; one version byte, external /Y definitions and final linking remain pending. See [review](../etc/file-review-126-init.json).

Index 125 `cmd/command/ifequ.asm` remains reference-identical. It emits assembler information only and no binary bytes. See [review](../etc/file-review-125-ifequ.json).

Index 124 `cmd/command/fordata.asm` remains reference-identical; target TFOR instructions support selected structure offsets and allocation size. Full TFOR and final linking remain pending. See [review](../etc/file-review-124-fordata.json).

Index 123 `cmd/command/envdata.asm` remains reference-identical. Target INIT instruction constants support the reference environment structure size and COMSPEC limit; full INIT validation remains pending. See [review](../etc/file-review-123-envdata.json).

Index 122 `cmd/command/dir.asm` has 6.20 display-width and directory-padding logic reconstructed. Its 2,114 non-relocation bytes and 78 internal branches match the inferred target module; message data and final linking remain pending. See [review](../etc/file-review-122-dir.json).

Index 121 `cmd/command/cratio.asm` remains reference-identical; 663 non-relocation bytes and 9 internal branches match its inferred target module. Final relocation values and linking remain unverified. See [review](../etc/file-review-121-cratio.json).

Index 120 `cmd/command/cparse.asm` has target switch count 8 restored; 332 non-relocation bytes and 17 internal near branches match the inferred target module. `tdata.asm` switch table, `tmisc1.asm` count, relocation values and final link remain pending. See [review](../etc/file-review-120-cparse.json).

Index 119 `cmd/command/copypr2.asm` has its target ASCII flag operation restored. Its 539 non-relocation bytes and four internal near branches match the inferred target module; final relocation values and linking remain unverified. See [review](../etc/file-review-119-copypr2.json).

Index 117 `cmd/command/copy.asm` has completed source-level review; its non-relocation bytes and internal branches match the target, while external definitions and full linking remain unresolved. See [investigation](../etc/file-review-117-copy-investigation.json).

The current kernel build differs from the target at 425 byte positions, down from 17,037 before `dos/dir.asm` reconstruction. See [review](../etc/file-review-053-dir.json).

Index 40 `bios/sysinit2.asm` has its 6.20 startup paths reconstructed; its remaining aligned differences are assembler-marked relocation fields. Final layout remains unresolved. See [review](../etc/file-review-040-sysinit2.json).

Index 39 `bios/sysinit1.asm` has reconstructed control flow. Its probe uses temporary later-module stubs; the real BIOS link awaits SYSINIT2 interfaces and corrected version and messages. See [review](../etc/file-review-039-sysinit1.json).

Index 37 `bios/sysconf.asm` has its target call restored; all 545 remaining aligned differences fall in relocation fields or two branch displacements. Final values depend on later link layout. See [review](../etc/file-review-037-sysconf.json).

**Scope correction:** DOS 6.0 and Astro are the primary source baselines. NT/BOP cleanup is not a routine review task for those files; evaluate source-specific host dependencies only if OpenNT code is actually introduced. The earlier lexical screen below is historical evidence, not an ongoing requirement.

M0 T1 is [closed](../history/M0-T1-completion.md); M1 T2 S1 is active for build-input and reference closure. The frozen source ledger has 250 entries: indices 1–6, 8–21, 26–32 and 37–128, 134–138, 143–146 and 148–164, 166–171, 174–187, 189, 191–203, 205–207, 209–212, 214, 216–218, 220–221, 223–224, 229, 231, 233, 235, 237 and 239–246, 248–250 reviewed, indices 7, 22–25, 33–36, 129–133, 139–142, 147, 165, 172–173, 188, 190, 204, 208, 213, 215, 219, 222, 225–228, 230, 232, 234, 236, 238 and 247 excluded from the selected core build; no frozen inventory items remain pending; generated resources and complete three-component linking remain open. `bios/msbio1.asm` now initializes BDS2's logical drive to the target value; its only remaining reference-layout segment difference is an external SYSINIT relocation. See [evidence](../etc/file-review-008-msbio1.json). The selected reference build excludes the POWER/PTIME module bodies; optional 6.20 behavior is not established.

The three target files are in Git-ignored `extras/baselines/targets/`; see [baseline evidence](../etc/target-baseline.json). The frozen 250 DOS 6.0 source candidates and six link/skeleton inputs have been imported unmodified. They are a pending baseline, not qualified DOS 6.20 source.

M1 dependency findings: conservative scanning of the DOS 6.0 linked sources found
9 BIOS and 4 DOS generated-message includes, plus COMMAND's `comrmsg.inc`,
`comimsg.inc` and conditionally included `command.loc`; two macro-driven includes
remain dynamic. These are leads, not a validated build closure. Candidate tools
and message sources are pinned in [dependency inventory](../etc/reference-dependency-inventory.json).
The OpenNT/v5 message sources omit 18 numbered COMMAND template definitions;
`:def` defaults may still be used. Target COMMAND directly contains the 6.20
version banner and 1981–1993 copyright; OpenNT and v5 `comimsg.inc` differ
there. See [message analysis](../etc/message-candidate-analysis.json). The source baseline has been imported; no 6.20 target output has been rebuilt. The next action is to establish
message-generation behavior and resolve target-relevant inputs, then perform
the isolated DOS 6.0 reference build.

Message-generation probes now establish a concrete input gap: DOS 6 `BUILDMSG`
rejects the COMMAND template at its 150-message limit; the OpenNT tool completes
but emits empty bodies for the 18 absent entries. Two missing defaults occur
verbatim in target COMMAND. DOS 6 `NOSRVBLD` returns success on the OpenNT
candidate but emits malformed BIOS CL3/CL9 lines. See
[diagnostics](../etc/message-generation-diagnostics.json). Do not use these
probe results as target resources; reconstruct or locate suitable inputs.

Local supplemental tree `O:/repos.external/astro` describes itself as a DOS
6.0.500 beta source tree with reconstructed missing portions; it is not proof
of DOS 6.20 provenance. Its three core message skeletons are byte-identical to
the primary v6.0 reference. Its `messages/usa.msg` supplies 17 of 18 previously
empty COMMAND messages in the diagnostic build; the remaining ID 1200 is still
empty. Several generated message literals occur in the target. The same source
is not a complete BIOS solution: generated CL9 incorrectly assigns a FAT error
message to `PowerSignOn`. See [assessment](../etc/astro-message-assessment.json).

A diagnostic message input assembled from `astro/messages/usa.msg`, the
component-specific `astro/messages/usa/msbio.msg`, and the explicitly inferred
v5 POWER entry now generates all 15 previously missing BIOS declarations and
a PowerSignOn declaration without the raw record defect. This remains a 6.0
reference probe, not 6.20 source. The target status-line text differs from the
reference, proving a target-specific difference to address in ordered review.
See [input provenance](../etc/bios-reference-message-input.json) and
[validation](../etc/bios-reference-message-validation.json).

An isolated COMMAND reference build has assembled all 35 DOS 6.0 linked
modules and linked a 52,925-byte `COMMAND.COM`; the 6.20 target is 54,619
bytes and differs. It uses astro's provisional messages and OpenNT MASM/BUILDMSG,
so it is a comparison baseline, not a verified original DOS 6.0 binary.
LINK reports L4021 (no stack segment). The 35 object hashes and staged reference
inputs are checked in [build record](../etc/command-reference-build.json) and
[input check](../etc/command-reference-input-check.json). No production source
has been imported or edited.

An isolated DOS 6.0 kernel reference build assembled all 57 link-list modules.
Its 38,138-byte output has the target length but differs at 17,037 byte
positions; 653 contiguous difference ranges include relocation effects. See
[kernel build](../etc/kernel-reference-build.json) and
[comparison](../etc/kernel-reference-comparison.json). The message input is
provisional, and no 6.20 kernel identity is claimed.

DOS 6.0 reference builds now exist for all three components. The latest BIOS
reference assembles MSLOAD plus 15 BIOS modules, producing 40,470 bytes versus
the 40,566-byte IO.SYS target. It uses provisional messages and is not 6.20
source; see [build](../etc/bios-reference-build.json) and
[comparison](../etc/bios-reference-comparison.json). Kernel and COMMAND
reference builds likewise differ from the targets. Remaining M1 work is to
resolve the documented message and build-input limits and establish how to
map target changes before ordered source reconstruction.

The three provisional reference binaries have unique 32-byte exact-block
mappings to the targets: IO.SYS 169 runs, MSDOS.SYS 278, COMMAND.COM 232.
For example, one IO.SYS run matches for 7,369 bytes at the same offset;
MSDOS.SYS has many runs shifted by one byte. These are byte anchors, not
proof that corresponding source files or functionality are 6.20-identical.
See [block map](../etc/reference-target-block-map.json).

Reference linker publics were mapped only when their first 16 bytes fall within
an exact matching target block: BIOS 388, kernel 640 and COMMAND 338 symbol
points. These include data, aliases and partial routines; they are not complete
function matches. See [symbol map](../etc/reference-target-public-map.json).

The 250 frozen DOS 6.0 source candidates and six support files have been
imported unchanged; all 250 remain pending 6.20 review. An NT/BOP lexical
screen found no hits, without treating DOS 6 compression as forbidden. The
local imported baseline reproduces all three earlier reference outputs and
all 108 object hashes using provisional messages; none matches the 6.20 target.
See [import](../etc/reference-import.json), [screen](../etc/reference-import-nt-bop-screen.json)
and [local build comparison](../etc/local-baseline-reproduction.json).

## MTSP status

M1 T2 is closed against its reference evidence; M3 T4 is closed for three-component byte equality under the selected configuration. See [T2 audit](../history/M1-T2-completion.md) and [T4 audit](../history/M3-T4-completion.md). Historical source uncertainty remains documented and is not a blocker; workflow and final delivery audits remain.
