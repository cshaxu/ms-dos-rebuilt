# M6 T25 S1 P68: files 170-171

170 dos/fat.asm: accepted_modified. Complete effective v6.22 diff reviewed.
Retain 950 EOF threshold handling, CS-resident buffer/cache/FAT-zero state,
CDS validation with DOS data segment, null DPB failure path, corrected DS
assumption, and HMA low-memory BPB buffer handling. These are actual behavior
and addressing differences; no parallel algorithm added by this audit.
Normalize three new external declarations to the inherited style.

Tested restoration of the reference RETZ macro at PACK. The macro can reuse
earlier returns (dosmac.inc condret), unlike the explicit JNZ/RET sequence.
Actual rebuilt kernel differed, so restoration was rejected and reverted.
Evidence: file170-retz-rejected.txt. No rejected code remains in source.

Final FAT recompiled, kernel linked unchanged against preceding verified
stage and IO.SYS freshly packed target-exact. Unaffected MSDOS.SYS and
COMMAND.COM inherited and compared target-exact; 293 inputs checked.
Evidence: file170-build.txt and file170-make.txt.

171 dos/fcb.asm: accepted_exact. FC /B against effective v6.22 supplier
v6.2/dos/fcb.asm reports no differences. No redundant rebuild.

Prefix 171/293: modified 88, exact 26, necessary unchanged 21, no same-name
reference unchanged 36. Tool change 1 separately. Next 172 dos/fcbio.asm.
Final clean build and full completion audit pending.
