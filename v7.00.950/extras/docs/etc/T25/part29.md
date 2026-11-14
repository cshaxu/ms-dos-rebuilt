# M6 T25 S1 P29: files 118-120

118. rdata.asm -- accepted_modified. Reviewed complete effective-reference
diff. Restore BETA3WARN formatting, inherited LoadHigh/message headings and
reverse-copy explanation. Use existing ALLOCOPER expressions for three DOS
services and FALSE for InitFlag. Move the orphan shared-buffer explanation
beside the actual MsgBuffer/SafePathBuffer declarations.

Preserve required resident relocation state, far single-command/pipe pointers,
260-byte shared pathname storage, command/input buffer capacities, checksum and
interrupt state, stack guard and message-resource pointers. EndInit's relocation,
environment resize/allocation fallback and low/top-memory placement are target
requirements. Its environment freeing and vector stub construction already
share FreeInitEnv/CopyInitVector, so no extra implementation is introduced.
No data order, extent, instruction encoding or enabled conditional changed.

Verification: file118-build.txt; extras/build/t25-rdata-13269-22071.
Original COMMAND build passes. Regenerated messages and linked executables
are unchanged. Fresh COMMAND.COM matches its target; inherited IO.SYS/MSDOS.SYS
also match, and all 293 current source inputs match the stage.

119. resclass.asm -- accepted_no_reference. Complete resource-only wrapper
reuses comrmsg.inc. RESOURCE_ONLY suppresses its resident-only portion, while
RDATA selects RESIDENT_MSG_BUFFER. The makefile separately links this resource
and production CMDIMAGE consumes it. Keep the independent resource boundary;
there is no second message implementation. No edit/redundant build.

120. resmsg.equ -- accepted_exact. Direct FC/B against effective reference
passes. No edit/redundant build.

Prefix 120/293: modified 51, exact 21, necessary unchanged 12, no same-name
reference unchanged 36. Separate tool modification one. Next: 121 rucode.asm.
Final full automatic build remains pending. P29 is committed/pushed separately.
