# M6 T25 S1 P59: file 157

157. dos/dircmp.asm -- accepted_modified (no same-name effective reference).
Direct full-procedure text comparison against MetaCompare in effective v6.22
dos/dir.asm passes, including the DBCS conditional branch. Preserve that entire
procedure unchanged. Restore its exact inherited input/output/register contract
at the definition, completing the removal of the orphan copy from DIR in P57.

Correct the copied module description and contents list, remove unused
fastopen.inc and dpb.inc includes, normalize segment/ASSUME/END forms and remove
the reconstruction-location comment from the source. Keep the separate module
and accepted link order: it provides one shared comparison implementation at the
target's required position, not another competing comparison path.

Original NMAKE/MASM/LINK rebuilds the kernel byte-identical. Fresh IO.SYS repack
matches the frozen target; both unaffected inherited images also compare exact.
All 293 current inputs match. Evidence: file157-build.txt, file157-make.txt;
stage recorded in the build evidence. Binary validation covers the USA target;
the DBCS source comparison does not claim a separate DBCS binary build.

Prefix 157/293: modified 79, exact 22, necessary unchanged 20, no same-name
reference unchanged 36. Separate modified tool one. Next: 158 dos/disk.asm.
Final full build and completion audit remain pending.
