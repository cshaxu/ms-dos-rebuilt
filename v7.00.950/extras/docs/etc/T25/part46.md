# M6 T25 S1 P46: file 138

138. tranmsg.asm -- accepted_modified. Reviewed the complete effective-v6.22
diff. Expand thirteen added substitution records (trace, root heading, LFNFOR,
three date/time templates, attributes, two continuation paths, count, allocation
and two disk-usage substitutions) into the inherited field-by-field form.
Use parm_block_size, existing format/alignment constants and blank in place of
raw bytes. Declare widths as WORD fields matching the current ABI. Split four
combined public declarations. Every value, relocation and record order remains.

Retain expanded widths, message IDs, long-path widths and zero/unlimited-width
semantics, extra trace/LOCK/UNC/LFNFOR messages, length-prefixed environment
names and conditional locale/compression records. Message state removed from
this file is defined in TSPC, not missing. DIR root/current continuation records
contain distinct pointers; date/time templates are copied into workspace and
cannot be merged without changing target data and consumer contracts. Keep the
inherited unused version substitution fields to preserve target layout.

Verification: file138-build.txt; extras/build/t25-tranmsg-21717-16212.
Original COMMAND build passes; generated messages and linked executables match
the prior verified stage. Fresh COMMAND.COM equals its frozen target; inherited
IO.SYS/MSDOS.SYS also compare exact. All 293 current inputs match the stage.

Prefix 138/293: modified 67, exact 21, necessary unchanged 14, no same-name
reference unchanged 36. Separate tool modification one. Next: 139 tspc.asm.
Final full automatic build remains pending.
