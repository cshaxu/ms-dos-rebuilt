# M6 T25 S1 P84, files 204–205

204 dos/msproc.asm, accepted_modified. Reviewed the full effective v6.22
diff. Named CDS field offsets and flags in ExecSaveState and ExecCheckState
using curdir.inc. Aligned the added data declarations. Preserved EXEC
dispatch, overlay/version behavior, read failure paths, state notification,
and target-specific encodings and state layout. Original NMAKE via the
P72 probe rebuilt MSPROC and relinked the kernel. Fresh IO.SYS and inherited
MSDOS.SYS and COMMAND.COM matched the frozen targets, with 293 inputs
verified at extras/build/t25-msproc-9672-2623. See file204-build.txt and
file204-make.txt.

205 dos/mssw.asm, accepted_exact. FC /B with effective v6.22 supplier
v6.2/dos/mssw.asm reported no differences.

Prefix 205/293. Modified 107, exact 33, necessary unchanged 28, no same-name
reference unchanged 37. Next 206 dos/mstable.asm.
