# M6 T25 S1 P45: file 137

137. tprintf.asm -- accepted_modified. Reviewed complete effective-v6.22 diff
and the SYSMSG/MSGSERV macro consumers. Split the new combined external,
restore the inherited TRANSPACE declaration marker and equate formatting,
remove an extra blank line and correct the obsolete data-allocation comment.
The module declares shared message data rather than expanding MSGDATA here.

Retain utility message class 3, initialized message-data segment placement,
JCXZ substitution test, extended-error-number reset, shared SYSLOADMSG entry
and staged message-service expansion. PrimaryMsgDirectory, DirOutputPtr and
DirOutputActive are used by the expanded message macros, so they are not dead
externals. DOS7_DEFER_COMMON governs emission order inside MSGSERV; merging
the original macro invocation or restoring the old wrapper changes target
layout/code. No additional loader, wrapper or duplicate service body added.

Verification: file137-build.txt; extras/build/t25-tprintf-20962-23698.
Original COMMAND build passes; messages and linked executables are unchanged.
Fresh COMMAND.COM equals its frozen target; inherited IO.SYS/MSDOS.SYS also
compare exact. All 293 current source inputs match the verified stage.

Prefix 137/293: modified 66, exact 21, necessary unchanged 14, no same-name
reference unchanged 36. Separate tool modification one. Next: 138 tranmsg.asm.
Final full automatic build remains pending.
