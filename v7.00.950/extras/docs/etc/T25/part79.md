# M6 T25 S1 P79, files 190–191

190 dos/mknode.asm, accepted_modified. Reviewed the full effective v6.22
diff. Aligned data declarations, immediate encoding notation and the
flush comment. Preserved the target directory access-date initialization,
save failure branch, deferred flush and exact compare encoding. Original
NMAKE reassembled MKNODE and linked the kernel via the P72 diagnostic probe.
Freshly packed IO.SYS and inherited MSDOS.SYS and COMMAND.COM compared
exactly to the frozen 950 targets. The verification stage
extras/build/t25-mknode-7504-9105 matched all 293 current inputs.
See file190-build.txt and file190-make.txt.

191 dos/mpatch.asm, accepted_exact. FC /B with effective v6.22 supplier
v6.2/dos/mpatch.asm reported no differences.

Prefix 191/293. Modified 101, exact 28, necessary unchanged 26, no same-name
reference unchanged 36. Next 192 dos/mscode.asm.
