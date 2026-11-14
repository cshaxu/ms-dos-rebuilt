# M6 T25 S1 P63: file 161

161. dos/diskio.asm -- accepted_modified (no same-name effective reference).
Review against corresponding effective-v6.22 close.asm and disk.asm paragraphs.
Full DirFromSFT and FATSecRd/DREAD procedure text comparisons pass. DirRead
retains the target's shared carry-return branches in place of inline conditional
returns. Preserve all executable code, procedure order and inherited comments.

Remove fifteen unused copied DOSDATA declarations: CONSft, CONSWAP, IDLEINT,
THISSFT, DMAADD, DEVCALL, CALLSCNT, CALLXAD, CONTPOS, NEXTADD, CONBUF, ClusFac,
JShare, DOS34_FLAG, IsWin386; remove five unused procedure externals CharHard,
DevIoCall, DevIoCall2, Outt and Setup. Correct copied module identity/contents,
remove the orphan Win386 variable note, and restore the exact inherited
DirFromSFT and DirRead contracts at their definitions. This completes the
documentation moves from CLOSE and DISK without reintroducing duplicate code.
Normalize segment/end forms; keep the existing module and linked layout.

Original NMAKE/MASM/LINK rebuilds the affected kernel byte-identical. Fresh
IO.SYS repack equals the frozen target; both unaffected inherited images also
compare exact. All 293 current source inputs match the stage. Evidence:
file161-build.txt and file161-make.txt; stage named in the build record.

Prefix 161/293: modified 83, exact 22, necessary unchanged 20, no same-name
reference unchanged 36. Separate modified tool one. Next: 162 dos/diskset.asm.
Final full build and completion audit remain pending.
