# M6 T25 S1 P60: file 158

158. dos/disk.asm -- accepted_modified. Full effective-reference diff reviewed.
Remove 12 unused declarations left after code movement: DirStart, ClusFac,
SecClusPos, DirSec, ClusNum, NxtClusNum, ReadOp, CURBUF, ALLOWED, HIGH_SECTOR,
JShare and DOS34_FLAG. Retain IsWin386, which still has a real code reference.
Remove the module-list entries for relocated directory/FAT/lock routines and
the orphan DIRREAD heading/contract at the end of the module. Directory/FAT
implementation is in diskio.asm; lock-check implementation is in disk2.asm.
No second implementation is created or removed from actual execution.

Retain both access-mode masks of 3: existing ACCESS_MASK is 0Fh and cannot be
substituted without a semantic and binary change. Preserve input/output AL
initialization for DSKSTATCHK, cooked-write early count termination, and DOS_FLAG
console-output state. These target-specific operations already use inherited
structure. No executable instruction or operand changed in this part.

Original NMAKE/MASM/LINK freshly rebuilds the kernel byte-identical. Fresh
IO.SYS repack equals the frozen 950 target; both unaffected inherited outputs
also compare exact. All 293 source inputs match the stage. Evidence:
file158-build.txt, file158-make.txt; stage named in the build record.

Prefix 158/293: modified 80, exact 22, necessary unchanged 20, no same-name
reference unchanged 36. Separate modified tool one. Next: 159 dos/disk2.asm.
Final full build and completion audit remain pending.
