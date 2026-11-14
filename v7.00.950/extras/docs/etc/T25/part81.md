# M6 T25 S1 P81, files 194–195

194 dos/msctrlc.asm, accepted_modified. Reviewed the complete effective
v6.22 diff. Moved the inherited DSKSTATCHK heading and comment back to the
procedure following SPOOLINT. Aligned three procedure declarations with
the enclosing module. Preserved the 950 console status and Ctrl+C paths,
divide-error vector, DOS call depth, abort and deferred flush handling.
Original NMAKE via the P72 probe rebuilt MSCTRLC and linked the kernel.
Fresh IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched frozen targets.
All 293 inputs were checked at extras/build/t25-msctrlc-8581-17135.
See file194-build.txt and file194-make.txt.

195 dos/msdata.asm, accepted_necessary. The complete effective v6.22 diff
omits the wpatch.inc include. That file emits old Windows patch signature
tables in DOSDATA. Restoring it would change the 950 data layout. Kept
the current source and include order.

Prefix 195/293. Modified 104, exact 28, necessary unchanged 27, no same-name
reference unchanged 36. Next 196 dos/msdisp.asm.
