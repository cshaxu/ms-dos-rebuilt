# M6 T25 S1 P91, files 264–266

264 inc/msgserv.asm, accepted_modified. Compared against effective v6.22
with end-of-line whitespace ignored to expose the functional changes.
Preserved the 950 message resource tables, transient layout, deferred
common procedures and active output paths. Removed two duplicate COMT
output blocks nested in the ELSE arms of IF COMT. Their outer conditions
prevented assembly in every configuration. The active handle and console
buffer labels each remain in their respective COMT branches.

Forced TPRINTF and TDATA assembly and ran original COMMAND NMAKE and
message tools. Linked COMMAND and message intermediates passed binary
comparison. Fresh COMMAND.COM and inherited IO.SYS and MSDOS.SYS matched
the frozen 950 targets. All 293 inputs matched stage
t25-msgserv-12317-25312. See file264-build.txt and file264-make.txt.

265 inc/mshalo.asm and 266 inc/mshead.asm, accepted_exact. FC /B against
the effective v6.22 suppliers in v6.2/inc reported no differences.

Prefix 266/293. Modified 116, exact 76, necessary unchanged 37, no same-name
reference unchanged 37. Next 267 inc/ms_data.asm.
