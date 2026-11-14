# M6 T25 S1 P75, files 184–185

184 dos/lockio.asm, accepted_modified. The full region containing both
procedure contracts and bodies matches effective v6.22 dos/lock.asm
byte for byte. Corrected the copied module title and contents list.
Removed the unused THISSFT, EXTERR, fShare, EXTERR_LOCUS, Lock_Buffer and
Temp_Var declarations. Preserved procedure contracts and conditional paths.
Original NMAKE ran through the P72 diagnostic probe. Reassembled LOCKIO,
linked the kernel, verified all 293 source inputs, and packed IO.SYS.
Fresh IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched the frozen
targets with FC /B at extras/build/t25-lockio-5907-28782.
See file184-build.txt and file184-make.txt.

185 dos/macro.asm, accepted_necessary. The full effective v6.22 diff covers
the CMP-based user operation dispatch, the shared UserError jump, and the
explicit conditional return sequence in GetVisDrv. These affect the
target instruction stream. No formatting-only differences remain.

Prefix 185/293. Modified 96, exact 27, necessary unchanged 26, no same-name
reference unchanged 36. Next 186 dos/macro2.asm.
