# M6 T25 S1 P33: file 124

124. tbatch2.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Restore IFEXISTS/IFTRUE instruction layout and identical inherited lines with
their applicable argument-index/pointer comments. Split added EXTRN groups to
match surrounding declarations. Restore parsing/output terminator comments at
the dynamic buffer writes. No instruction tokens, layout or control flow change.

Keep the simplified EOF initiation (BatchEOF = 4), subsequent shared 4/2/1/0
state machine and delayed cleanup. Do not restore obsolete LF-buffer inspection
or its inaccurate original explanatory paragraph. Preserve IF's target-specific
absence of early pipe deletion; CALL still has its own existing pipe cleanup.
IF and CALL use dynamic command pointers and WORD lengths rather than PSP
byte-buffer offsets. IFEXISTS keeps quoted path scanning, UNC directory
attributes and shared SelectPathInterface/PathFindFirst/ClosePathFind; flags
are saved across handle closure to preserve the search result. No parallel
legacy search implementation is introduced. Batch open retains deny-write
sharing mode and required public entry labels.

Verification: file124-build.txt; extras/build/t25-tbatch2-15502-1181.
Original COMMAND build passes. Messages and linked executables remain exact.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match, and
all 293 source inputs match the stage.

Prefix 124/293: modified 54, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 125 tcmd1b.asm.
Final full automatic build remains pending. P33 is delivered separately.
