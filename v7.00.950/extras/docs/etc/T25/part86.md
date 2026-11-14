# M6 T25 S1 P86, files 210–212

210 dos/path.asm, accepted_modified. Reviewed the full effective v6.22 diff.
Removed the unused GetDst label after CurrentValidate lost the old branch.
Corrected the NoSetDir segment comment and shared error jump comment.
Preserved validation, redirection checks and the target error return chain.
Stage t25-path-10456-26336.

211 dos/rename.asm, accepted_modified. Reviewed the full effective v6.22 diff.
Aligned the IoState3 declaration and explicit comparison notation. Preserved
the 950 LFN state save and deletion, deferred flushing and branch layout.
Stage t25-rename-10531-11406.

Both files were reassembled separately with original NMAKE through the P72
probe. Each fresh kernel and IO.SYS passed byte checks. Inherited MSDOS.SYS
and COMMAND.COM matched frozen targets. All 293 inputs matched both stages.
See file210-build.txt and file211-build.txt and their make logs.

212 dos/restrict.inc, accepted_exact. FC /B against the effective supplier
v6.2/dos/restrict.inc reported no differences.

Prefix 212/293. Modified 111, exact 36, necessary unchanged 28, no same-name
reference unchanged 37. Next 213 dos/rom.asm.
