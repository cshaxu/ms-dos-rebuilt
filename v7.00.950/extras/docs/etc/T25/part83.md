# M6 T25 S1 P83, files 202–203

202 dos/msinit.asm, accepted_modified. Reviewed the complete effective
v6.22 diff. Returned the original patch_misc_segments contract to the
procedure it documents. Updated stale DPUBLIC names to the existing saved
vector loop and vector-offset loops. Preserved the 950 device initialization,
data relocation, instance tables and interrupt-vector code. The regular
kernel configuration was built. DPUBLIC is conditional on DEBUG.

Original NMAKE via the P72 probe reassembled MSINIT and relinked the kernel.
All 293 source inputs matched stage extras/build/t25-msinit-9313-32714.
Fresh IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched the frozen
950 targets byte for byte. See file202-build.txt and file202-make.txt.

203 dos/msioctl.asm, accepted_exact. FC /B with effective v6.22 supplier
v6.2/dos/msioctl.asm reported no differences.

Prefix 203/293. Modified 106, exact 32, necessary unchanged 28, no same-name
reference unchanged 37. Next 204 dos/msproc.asm.
