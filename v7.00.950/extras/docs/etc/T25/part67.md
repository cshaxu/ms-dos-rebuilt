# M6 T25 S1 P67: file 169

169 dos/exepatch.asm: accepted_modified. Full source read and comparison with
effective v6.22 supplier v6.2/dos/exepatch.asm. The entire exepatch_start
through EOF substring compares exactly, including patch byte patterns,
ExePatch/ExePackPatch, checksum helpers, RationalPatch and IsCopyProt.
The removed reference routines are located in EXECHOT, accepted in P66;
the two external helper calls continue to use that shared implementation.

Removed six unused external declarations: fixexepatch, Rational386PatchPtr,
Special_Version, DosHasHMA, A20OFF_PSP and DOS_FLAG. Normalized added DOSCODE,
ASSUME and helper EXTRN formatting. Preserved all inherited comments and
conditional/patch data. No instruction or data change.

Affected EXEPATCH compiled and kernel freshly linked unchanged against the
previous verified stage. Freshly packed IO.SYS target-exact; unaffected
MSDOS.SYS and COMMAND.COM inherited and also compared target-exact. All 293
inputs match stage extras/build/t25-exepatch-1335-21525. Evidence:
file169-build.txt and file169-make.txt.

Prefix 169/293: modified 87, exact 25, necessary unchanged 21, no same-name
reference unchanged 36. Separate tool change 1. Next 170 dos/fat.asm.
Full clean build and completion audit remain pending.
