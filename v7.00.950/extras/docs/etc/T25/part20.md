# T25 sequential audit: file 105

105. cmd/command/cratio.asm -- accepted_modified.
Reference is the actual v6.22/cmd/command/cratio.asm overlay. Read complete
current file, compared the retained arithmetic and removed CVF/FAT machinery,
and checked actual DIR callers and compressed-size querying flow.

Restore csecPerCluster declaration/comment, original ASSUME formatting,
Div32 entry comment and the complete inherited 16-bit divisor paragraph.
Correct the return description: whole number is shifted left four bits, rather
than limited to one high nibble. No instruction or arithmetic changed.

Keep shared ComputeRatio multiplication/rounding body. Required differences
are 386 division for wide divisors, packed ratio representation and cluster
rounding helper. DIR's DirQueryCompressedSize uses AX=7143h/BL=2, so reintroducing
6.22's direct CVF open/read, FAT buffers and chain traversal would add an unused
second implementation. DIR calls the existing ratio core for its calculated
sector counts. DBLSPACE_HOOKS selection and source file organization preserved.

Verification: file105-build.txt; extras/build/t25-cratio-7064-14563.
Original COMMAND build passes; messages and linked executables unchanged.
Fresh COMMAND.COM matches own 950 target. IO.SYS/MSDOS.SYS inherited and exact.
All 293 current sources match stage. Full automatic final build pending.

Prefix 105/293: modified 42, exact 18, necessary unchanged 11, no same-name
reference unchanged 34. Tool modification separately one. Next: 106 dir.asm.
