# M6 T25 S1 P41: file 132

132. tfor.asm -- accepted_modified. Reviewed complete effective-v6.22 diff,
including Save_Args against its inherited implementation in reference PATH2.
Restore separate externals, find-first/next comments, matching Save_Args line
formatting and procedure separator. Correct its obsolete caller-size note:
allocation now derives from for_info and three command-buffer lengths.
No runtime instruction or layout changed.

Retain LFNFOR-controlled interface selection, FOR-owned search handle transfer,
returned filename pointer preservation and dynamic command buffer/WORD length.
Save_Args is a single implementation, moved from PATH2 to its FOR consumer;
its inherited register preservation, allocation, pointer-fixup and error tails
remain, while header/string copying follows the current FOR layout. Replacing
that copy with the old fixed arg_unit would lose dynamic strings. Do not add
another legacy Save_Args or independent file-search body. Required search and
buffer changes stay within existing FOR processing; no new module is needed.

Verification: file132-build.txt; extras/build/t25-tfor-19274-29286.
Original COMMAND build passes. Messages and linked executables remain exact.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 source inputs match the verified stage.

Prefix 132/293: modified 62, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: file 133.
Final full automatic build remains pending. P41 is delivered separately.
