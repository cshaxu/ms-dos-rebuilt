# M6 T25 S1 P85, files 206–209

206 dos/mstable.asm, accepted_modified. Reviewed the complete effective
v6.22 diff. Aligned the LFN, extended call and SFT entries with adjacent
table formatting. Retained error mapping, dispatch padding, ROM placeholders,
70h–73h handlers, FindDirSft and target placement of copyright data.
Stage t25-mstable-10041-4777.

207 dos/open.asm, accepted_modified. Reviewed the complete effective v6.22
diff. Aligned access-bit comments. Retained the CDS redirect and register
restore path, low-two-bit masks and separate bit 3 rejection. The shared
access_mask is 0Fh and would not be equivalent here.
Stage t25-open-10083-13434.

Each edit was assembled separately by original NMAKE through the P72 probe.
Each kernel relink and fresh IO.SYS passed byte comparisons. MSDOS.SYS and
COMMAND.COM were inherited and compared with their frozen targets. Both
stages matched all 293 source inputs. See file206-build.txt and
file207-build.txt and their make logs.

208 dos/origin.asm and 209 dos/parse.asm, accepted_exact. FC /B against the
effective v6.22 suppliers in v6.2/dos reported no differences.

Prefix 209/293. Modified 109, exact 35, necessary unchanged 28, no same-name
reference unchanged 37. Next 210 dos/path.asm.
