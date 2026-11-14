# T21 file 155: dos/msproc.asm

Full DOS6 diff reviewed. Restored ja Exec_Chk_Mem and its exact DOS6/OpenNT
format instead of DLJA. DLJA emits the same JA with the actual DEBUG=FALSE
configuration; the previous macro spelling was unnecessary (see file 119).
Restored OpenNT's exact CMP AX,100h line, retaining the DOS5 value and comment.

Other DOS6 differences are required: no July 1992 RESTRICTED_BUILD guest-list
implementation, table/include or call sites; no Rational386PatchPtr declaration
and call; COM allocation minimum remains 100h rather than DOS6's later 200h
PSP-and-stack check. OpenNT msproc.asm:1004 directly corroborates the 100h check.
These would otherwise change execution policy, target bytes or linked layout.
The remaining code and structure match DOS6; no NT host dependency is restored.

Final verified stage extras/build/t21-dos-30458-13322, parent
t21-dos-30304-32435 (first JA-only edit), itself parented by t21-dos-29948-7739.
Both edits were compiled before acceptance. Final build recompiled all 55 DOS
objects and relinked MSDOS.SYS: every object and output byte matched parent.
All three artifacts match frozen targets; IO/COMMAND were inherited, not
rebuilt. All 243 source/stage checks pass before/after. Stage result.txt,
dos/AUDIT.LOG, audit-object-compare.log, audit-*-compare.log and
audit-inputs-*.log retain proof. No new production tool/script was introduced.

Prefix 155/243: 16 modified (one metadata), 117 exact, 22 necessary differences.
Next: 156 dos/mssw.asm.
