# M6 T25 S1 P39: file 130

130. tenv.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Restore original formatting of TPA allocation calls and SETBLOCK, and original
32K-limit/paragraph-conversion comments in ResizeEnvironment. Match surrounding
instruction layout in PrepareLongCommand. Move the SET heading to its entry
and correct the obsolete DS:SI/carry-return contract: input comes from parsed
argv and errors go through CERROR. No emitted instruction or data changed.

SetEnvironmentValue is already shared by SET, PROMPT, PATH and long-command
preservation. PrepareEnvironmentChange accounts for replaced values, command
reservation and growth before writing; restoring STORE_CHAR's per-character
growth would duplicate and change that flow. Keep shared FIND/deletion/name
copy, selectable case comparison, DBCS handling, double-null termination and
COMSPEC filename tracking. SET PATH delegates to PathFromSet rather than
maintaining another path parser. Dynamic GETARG, longer SCASBX bound and selected
directory restore API are required. ResizeEnvironment's allocation placement
and failure cleanup differ materially from the old inline grow path; retain
the target sequence and common error exit.

Verification: file130-build.txt; extras/build/t25-tenv-18412-9755.
Original COMMAND build passes. Regenerated messages and linked executables
are unchanged. Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS
also match, and all 293 source inputs match the verified stage.

Prefix 130/293: modified 60, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: file 131.
Final full automatic build remains pending. P39 is delivered separately.
