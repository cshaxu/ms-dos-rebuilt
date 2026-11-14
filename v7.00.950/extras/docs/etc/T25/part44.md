# M6 T25 S1 P44: files 135-136

135. tparse.asm -- accepted_necessary. The entire effective-v6.22 diff is
PARSE_STRING_LENGTH equ 104h before the inherited psdata.inc include. That
include allocates $P_STRING_BUF using the configured length, otherwise 128
(or 104h for SYSINIT_PARSE_LARGE). COMMAND requires the 260-byte pathname
operand buffer. Keep the narrow configuration at the original include boundary;
no duplicate parser implementation. No source edit or redundant rebuild.

136. tpipe.asm -- accepted_modified. Reviewed the complete effective-reference
diff. Remove unused COMBUF and INTERNATVARS externals left after dynamic input
and DATINIT removal. Split new parser externals. Restore inherited date-display,
date-field loading and error-output formatting/comments, including disabled
historical reset comments. Move three pipe delimiter comments back to their
comparison instructions. Correct date/time input contracts to identify ComBufPtr
and TranSpaceEnd storage instead of the removed static COMBUF.

Retain far allocated pipe storage, segment-preserving reads, quoted pipe-text
copy, WORD command lengths, deny-write input opens and matching deallocation.
Keep target temporary-file initialization and branch reach forms. DATE uses
the shared parsed-argument interface; TIME keeps its SYSPARSE route with GETARG
and temporary interactive input. These have distinct return/control contracts;
do not force the reference's PSP-based parser or DATINIT back into the target.
No new module, copy implementation or alternate runtime path added.

Verification: file136-build.txt; extras/build/t25-tpipe-20518-3707.
Original COMMAND build passed; messages and linked executables remain exact.
Fresh COMMAND.COM equals its frozen target. Inherited IO.SYS and MSDOS.SYS
also compare exact; all 293 current source inputs match the verified stage.

Prefix 136/293: modified 65, exact 21, necessary unchanged 14, no same-name
reference unchanged 36. Separate tool modification one. Next: 137 tprintf.asm.
Final full automatic build remains pending.
