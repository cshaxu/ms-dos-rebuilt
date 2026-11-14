# M6 T25 S1 P80, files 192–193

192 dos/mscode.asm, accepted_modified. Reviewed the complete effective v6.22
diff. Removed seven unused declarations left after the Winoldap, VxD, UMB
restore and secondary-cache changes. Aligned CURSC_DRIVE's external
declaration and corrected the enhanced-mode exit label comment. Retained
absolute I/O checks, call-depth tracking, DPB error handling, selected
instruction encodings and target Windows dispatch. Stage t25-mscode-7846-23576.

193 dos/msconst.asm, accepted_modified. Reviewed the complete effective
v6.22 diff. Aligned the deferred-write flag and NLS pointer declarations
and removed obsolete EMS comments from their storage. Retained data order,
initializers and the reserved byte. MSDATA includes this file and was
reassembled. Stage t25-msdata-8196-26775.

Each build ran original NMAKE via the P72 diagnostic probe, relinked the
kernel, checked all 293 inputs and packed fresh IO.SYS. All three frozen
target comparisons passed. MSDOS.SYS and COMMAND.COM were inherited.
See file192-build.txt and file193-build.txt and their make logs.

Prefix 193/293. Modified 103, exact 28, necessary unchanged 26, no same-name
reference unchanged 36. Next 194 dos/msctrlc.asm.
