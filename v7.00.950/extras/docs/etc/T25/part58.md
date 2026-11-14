# M6 T25 S1 P58: files 155-156

155. dos/dir2.asm -- accepted_necessary. Full effective-reference diff reviewed.
Retain CheckCDSDrive adaptation and getdseg support, restoration of DI from Temp
after the check, and explicit short-immediate CMP encoding. The removed initial
CURR_DIR_END load/test at CrackIt would only branch to the immediately following
LOOK_SING label; that path loads SI from CURR_DIR_END again. Do not reintroduce
the removed setup instructions. Existing differences are necessary target form;
no edit or redundant build.

156. dos/dircall.asm -- accepted_modified. Full diff reviewed. Restore inherited
declaration and instruction columns in added LFN save/delete paragraphs and
restore the existing buffer-read error comment. Explain that the increment of
saved LFN chain length includes the short directory entry. Retain the shared
LfnSaveState/LfnDeleteEntries calls, FastOpen cleanup and DeferredFlush policy,
short-immediate encoding and long error branch. The short-only deletion path
and chain deletion path serve different inputs; do not remove either as a
duplicate implementation. No executable operation or value changed.

Original NMAKE/MASM/LINK freshly builds the affected kernel byte-identical.
Freshly repacked IO.SYS matches the frozen target; the two inherited unaffected
outputs are exact. All 293 source inputs match the stage. Evidence:
file156-build.txt, file156-make.txt; stage named in the build record.

Prefix 156/293: modified 78, exact 22, necessary unchanged 20, no same-name
reference unchanged 36. Separate modified tool one. Next: 157 dos/dircmp.asm.
Final full build and completion audit remain pending.
