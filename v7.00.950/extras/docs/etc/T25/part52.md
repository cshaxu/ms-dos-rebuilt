# M6 T25 S1 P52: file 145

145. dos/close.asm -- accepted_modified. Full effective-v6.22 diff reviewed.
Remove unused Attrib, ALLOWED, EXTERR_LOCUS and HIGH_SECTOR declarations after
removal of the old local DirFromSFT and FCB attribute path. DirFromSFT has its
single current definition in diskio.asm; remove its orphan contract from CLOSE.
Normalize the added helper and replacement paragraphs to inherited instruction
columns, preserving unchanged original include/macro formatting. Restore the
archive-bit comment and correct the DOS_CLOSE directory-access/DS-return notes.

Retain clean-file access-date updates, per-drive policy, shared DirFromSFT,
DeferredFlush and ClearDirSft, error handling and target branch placement.
No executable operation, operand, conditional or data value changed.

Initial original-assembler build succeeded, but object-byte equality failed:
deleting external declarations changes OMF symbol records and indices. Do not
misclassify that result as an executable regression or accept on compilation
alone. Retain file145-object-check.txt and stage t25-close-26817-28007.

Stronger verification: recompile CLOSE and link dos/msdos.sys with original
NMAKE/MASM/LINK; the linked kernel is byte-identical to the accepted kernel.
Repack IO.SYS from that new kernel and verify it against the frozen 950 target.
The other two inherited outputs also compare exact. All 293 current source
inputs match the new stage. Evidence: file145-build.txt and file145-make.txt;
extras/build/t25-close-26984-19119. This is a fresh affected kernel link and IO
repack, not the final clean full automatic project build.

Prefix 145/293: modified 72, exact 21, necessary unchanged 16, no same-name
reference unchanged 36. Separate modified tool one. Next: 146 dos/cpmio.asm.
Full final build and completion audit remain pending.
