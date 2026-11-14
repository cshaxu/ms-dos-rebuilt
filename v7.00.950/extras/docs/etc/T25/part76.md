# M6 T25 S1 P76, file 186

186 dos/macro2.asm, accepted_modified. Reviewed the complete diff against
effective v6.22 dos/macro2.asm. Aligned the added DOS_FLAG declaration with
neighboring declarations and restored the intent of the UNC prefix comparison
comment. Retained explicit comparison encodings, the UNC destination bound
check, the DOS_FLAG path restriction, CDS validation and the shared error
returns. These paths are part of the existing 950 instruction stream.

Original NMAKE reassembled MACRO2 and linked the kernel through the P72
diagnostic probe. The new kernel matched the prior stage byte for byte.
Fresh IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched the 950 frozen
targets. All 293 inputs matched the build stage.
See file186-build.txt and file186-make.txt.

Prefix 186/293. Modified 97, exact 27, necessary unchanged 26, no same-name
reference unchanged 36. Next 187 dos/makefile.
