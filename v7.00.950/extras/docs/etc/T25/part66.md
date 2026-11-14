# M6 T25 S1 P66: file 168

168 dos/exechot.asm: accepted_modified. No same-name reference, but the full
ExecReady-through-VVDigit body was extracted and compared with effective
v6.22 dos/exepatch.asm. Differences are two calls (ExecSaveState/ExecNotify),
five explicit arithmetic encodings, and a corrected cross-file comment.
The Rational search/replacement patterns and algorithm are inherited, not
a second implementation. Retain existing module partition and layout.

Removed 14 unused PATCH/CHKSUM equates copied from the other module and
three unused externs UNPACK_OFFSET, RatBugCode and RationalPatchPtr.
Corrected module name/contents description, located the RationalPatch
cross-reference in EXEPATCH.ASM, and normalized added wrapper declarations.
Preserved inherited commented-out declarations, historical notes, patch
byte arrays, instruction bytes and target copyright strings.

Affected EXECHOT compiled, kernel linked and compared unchanged against
the previous verified stage. Fresh IO.SYS packed and target-exact; unaffected
MSDOS.SYS and COMMAND.COM inherited and also target-exact. All 293 current
source inputs match stage extras/build/t25-exechot-963-8623. Evidence:
file168-build.txt and file168-make.txt.

Prefix 168/293: modified 86, exact 25, necessary unchanged 21, no same-name
reference unchanged 36. Separate tool change 1. Next 169 dos/exepatch.asm.
Full clean build and completion audit pending.
