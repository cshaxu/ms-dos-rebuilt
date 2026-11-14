# M6 T25 S1 P87, files 213–217

213 dos/rom.asm, accepted_modified. Reviewed the complete effective v6.22
diff. Restored a concise next-sector comment and documented the saved byte
count and sector start used by the zero-fill path. Preserved the 950
preread and zero-fill instructions, allocation error branches and deferred
flush. Original NMAKE through the P72 probe rebuilt ROM and relinked the
kernel. Fresh IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched the
frozen targets. Stage t25-rom-10851-16173 matched all 293 source inputs.
See file213-build.txt and file213-make.txt.

214 dos/romfind.asm, 215 dos/scnam.inc, 216 dos/search.asm and
217 dos/segcheck.asm, accepted_exact. FC /B against each corresponding
effective v6.22 supplier in v6.2/dos reported no differences.

Prefix 217/293. Modified 112, exact 40, necessary unchanged 28, no same-name
reference unchanged 37. Next 218 dos/share.asm.
