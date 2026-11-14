# M6 T25 S1 P47: file 139 and owner LFN authority amendment

139. tspc.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Remove duplicate DirAttributeText and DirDateTimeBuffer exports. Normalize
added PUBLIC declarations to inherited single-symbol/tabbed form; keep exact
inherited declarations untouched. Replace COPY prompt_sublist size 13 with
existing parm_block_size. Correct the zero-valued message format byte comment
without changing its value. All storage order, widths, reserved words and
aliases remain intact.

Keep required dynamic command/parser state, long paths/search buffers, stack
guard, DIR counts/date workspace and updated compression bookkeeping. The
48-byte DIR date workspace has three 16-byte template consumers; shared output
storage and aliases are not duplicate implementations. No new storage added.

Verification: file139-build.txt; extras/build/t25-tspc-22428-68.
Original COMMAND build passes; messages and linked executables unchanged.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 source inputs match the verified stage.

Owner now requires XP NTDOS as authoritative for LFN interface/semantics.
CURRENT records the precise scope and Microsoft guest/DEM source locations.
This part does not claim completed XP semantic validation or change LFN code.
Earlier accepted LFN files require a focused semantic completion cross-check;
general quality baseline and sequential inventory remain effective v6.22.

Prefix 139/293: modified 68, exact 21, necessary unchanged 14, no same-name
reference unchanged 36. Separate tool modification one. Next: 140 tucode.asm.
Final full automatic build and completion audit remain pending.
