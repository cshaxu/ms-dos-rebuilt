# M4 T23 S2: DOS 6.22 audit

Local order is the frozen DIR order. Original v6.0 is the only source-quality
reference. No other DOS version's binary is used for comparison.

Ordinal | Path | Disposition
--- | --- | ---
1 | bios/syspre.asm | Necessary differences retained
2 | cmd/command/cratio.asm | Original comment restored; verified compilation
3 | inc/copyrigh.inc | Necessary 1994 copyright text retained
4 | inc/versiona.inc | Necessary minor version 22 retained
5 | lang/usa/messages/comimsg.inc | No same-name DOS6 reference; original macro interface retained
6 | lang/usa/messages/usa-ms-dos.msg | No same-name DOS6 reference; original message-tool format retained

SYSPRE retains the original preload/postload procedures. Added DriveSpace and
DoubleSpace filename probes converge on one selected pointer and the existing
load path. The revision probe, saved BX and postload pointer transfer match
target behavior; merging repeated DOS calls into an invented helper would
alter the binary. Preserve original comments, conditionals and declaration
form. The two absent DEVMark operations remain absent as required.

CRATIO retains the original OpenCVF procedure, error path and BPB handling.
The added near-jump bridge is needed by its target branch layout; DriveSpace
open falls back to DoubleSpace and both use one success path. Restore the
original comment 'Now open the Compressed Volume File' immediately before the
existing DriveSpace explanation. No instruction, data, label or control flow
changes. Its overlay pin is updated to the verified new source hash.

COPYRIGH and VERSIONA have only target-required literals differing from DOS6;
original source form is already intact. COMIMSG uses original resmsg.equ msg,
CR/LF and RESGROUP pointer conventions; its 6.22 banner/1994 text is target
data. The complete USA-MS-DOS catalog retains MSBIO/MSDOS/BOOT records, original
message IDs and continuations, and the exact 6.22 menu/OEM border bytes. No
same-name reference text is claimed for either language input.

Tool repair: baseline.lst has exactly four T22 pin updates proven against old
entry hashes and accepted build hashes; overlay.lst updates only CRATIO. No
compiler logic, makefile, target, directory structure or other source changed.

Verification: original-tool compilation in cmd-17372-11632 completed with
BUILD.OK=PASS. The isolated runner timed out waiting for exit at 60 seconds,
so build.cmd returned failure before its post-check/publication phases. Preserve
that failed result; do not call it a successful automatic build run.
Independent completion checks verified all 241 before-snapshot records still
match current sources/tools/manifests, all three compiled outputs match v6.22
frozen targets by FC/B, and existing assets already match those same targets.
CRATIO.OBJ also matches the pre-edit accepted object byte for byte. No redundant
recompilation or asset replacement was needed. See snapshot-check.txt and
final-fc.txt in addition to the retained original build-result.txt/host.log.
225 merged inputs match the build input copies; 219 inherit T22 and 6 are local.
Merged DOS6 classes: 193 exact, 28 differences, 4 no same-name reference.
Local counts: modified 1, exact 0, necessary unchanged 3, no reference 2.
Tooling files modified: 2. The source edit was compiled before accepting later
unchanged local files. See local-inventory.csv, merged-inputs.csv, input-check.txt,
622-pins.txt, cratio-change.txt and build-result.txt.
