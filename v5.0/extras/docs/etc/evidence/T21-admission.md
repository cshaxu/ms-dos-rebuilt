# M6 T21 S1 admission and first ordered decisions

Date: 2026-11-13. The owner requested a new audit, not a repetition of old
approval claims. The previous no-revisit restriction does not apply to this
explicitly authorized new pass.

## Fixed scope and order

Executed CMD `dir /a /b /s` with v5.0 as working directory, without /o or
subsequent sorting. Retained file entries below bios, cmd, dos, inc, messages
in that exact enumeration order; excluded directory entries, root README and
.gitignore, and the extras metadata/tools/generated-input/output tree.
The queue records the original raw enumeration line and initial SHA256.
243 files are in scope, including build recipes and message resources.
No renumbering on later runs; additions/deletions require an explicit ledger
amendment. Raw enumeration and native inventory utility are retained under
extras/build/t21-admission. The utility does not modify source files.

Same-name reference candidates were hashed from DOS6 bios/dos/inc/cmd/command,
DOS4 src, and OpenNT base/mvdm/dos/v86. Same-name candidates are search leads,
not necessarily corresponding modules (especially makefile). Nonidentical
files require semantic/hunk review and renamed counterparts where relevant.
Initial classification: 193 exact reference matches and 50 differing files.
Do not count the classification sweep as a completed 243-file audit.

## Accepted prefix

| Sequence | File | Decision |
| ---: | --- | --- |
| 1 | bios/apmequ.inc | Entire file matches DOS6 bios/apmequ.inc; preserve. |
| 2 | bios/biosseg.inc | Entire file matches DOS6 bios/biosseg.inc; preserve. |
| 3 | bios/biostruc.inc | Entire file matches DOS6 bios/biostruc.inc; preserve. |
| 4 | bios/config.inc | Retain necessary deletion-only difference described below. |
| 5 | bios/copyrigh.inc | Entire file matches OpenNT v86/inc/copyrigh.inc; preserve. |
| 6 | bios/devmark.inc | Entire file matches DOS6 bios/devmark.inc; preserve. |

The config.inc comparison has only nine deleted definitions: BEGIN, INCLUDE,
INSTALLHIGH, MENUCOLOR, MENUDEFAULT, MENUITEM, NUMLOCK, SET and SUBMENU.
The retained definitions have identical layout, spelling and values to DOS6.
The DOS5 sysconf.asm command handling corroborates the retained DOS5 command
set; restoring later menu/multiple-configuration definitions only to obtain
textual identity is not justified. No file change was needed. No other
same-name CONFIG.INC exists in the frozen DOS4/OpenNT candidate inventory.

## Validation rule

For every edited file, compile the affected object(s) before advancing.
Includes require rebuilding every affected consumer; recipes require running
their affected target(s). Compare emitted code/data and the linked affected
component with the accepted baseline, and compare the target component.
Object metadata changes such as line numbers are not machine-code changes;
record them explicitly rather than concealing or ignoring mismatches.
If an optional/unlinked file changes, the main three binaries alone are
insufficient: assemble its relevant configuration and compare its result.
Finish integration checkpoints with all three exact target comparisons.
Even comment/format-only edits must compile under the new owner instruction.

No source changed in this admission batch, so no fresh compilation is claimed.
Existing assets passed direct FC /B against all three frozen targets:

| File | Bytes | Frozen SHA256 |
| --- | ---: | --- |
| IO.SYS | 33430 | dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0 |
| MSDOS.SYS | 37394 | 4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2 |
| COMMAND.COM | 47845 | 74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89 |

Current position is 7/243, bios/makefile. Modification count 0, exact-reference
accepted count 5, retained-necessary-difference count 1. Remaining 237.
