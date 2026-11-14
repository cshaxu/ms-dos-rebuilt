# M6 T25 S1 P55: file 151

151. dos/dev.asm -- accepted_modified. Full effective-reference diff reviewed.
RW_SC, IN_SC, INVALIDATE_SC, VIRREAD and SC2BUF are implemented in devcache.asm;
do not duplicate them in DEV. Remove their obsolete module-content list and
five now-unused declarations: SC_CACHE_COUNT, SC_CACHE_PTR, TEMP_VAR, TEMP_VAR2,
DDMOVE. Keep HIGH_SECTOR and CALLNEWSC, still used by block request handling.

Split added EXTRN/PUBLIC groups into individual declarations and restore added
instruction columns while preserving matching inherited lines. Replace the
device selectors' two 8000h constants with DevTyp and two console masks of 3
with ISCIN+ISCOUT, as defined in the existing devsym.inc.

Retain resident cache-data layout, pipe status service, null-driver guard,
device-call depth, separate console/disk critical-section selection and cache
retry path. No new module or second implementation is introduced; raw target
encodings stay unchanged. Moving cache routines/data back would change linked
layout and is not a necessary style repair within the preserved structure.

Original NMAKE/MASM/LINK freshly builds the kernel byte-identical to the prior
accepted kernel. IO.SYS freshly repacked from that kernel is target-exact;
the two unaffected inherited images are exact. All 293 current inputs match.
Stage extras/build/t25-dev-28535-12804; file151-build.txt, file151-make.txt.

Prefix 151/293: modified 75, exact 21, necessary unchanged 19, no same-name
reference unchanged 36. Separate modified tool one. Next: 152 dos/devcache.asm.
Final full build and completion audit remain pending.
