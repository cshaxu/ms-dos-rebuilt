# M6 T25 S1 P90, files 257–263

257 inc/lmstub.asm, accepted_modified. Reviewed the full effective v6.22
diff. Aligned new data declarations and documented the BIOS A20 error
call. Retained low-memory interrupt handling, call-depth counters, the
BIOS error delegation, and the 950 locale and response data layout.
Reassembled MSDATA, which includes LMSTUB, via original NMAKE and the P72
probe. Fresh kernel and IO.SYS passed byte checks. Inherited MSDOS.SYS and
COMMAND.COM matched their targets. All 293 inputs matched stage
t25-msdata-11879-26817. See file257-build.txt and file257-make.txt.

258 inc/lock.inc, 259 inc/magicdrv.inc, 260 inc/mi.inc, 261 inc/msbdata.inc,
and 262 inc/msbds.inc, accepted_exact. FC /B against effective suppliers
in v6.2/inc reported no differences.

263 inc/msgdcl.inc, accepted_necessary. The complete diff guards the
class declaration expansion and the two message service checks with
IF NOT COMT. Preserved the 950 transient COMMAND message configuration.

Prefix 263/293. Modified 115, exact 74, necessary unchanged 37, no same-name
reference unchanged 37. Next 264 inc/msgserv.asm.
