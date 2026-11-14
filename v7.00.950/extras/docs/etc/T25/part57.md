# M6 T25 S1 P57: file 154

154. dos/dir.asm -- accepted_modified. Full effective-reference diff reviewed.
MetaCompare's sole implementation resides in dircmp.asm; remove its orphan
contract from DIR while preserving the external call. Normalize added LFN
search and SFT helper declarations/instructions to inherited column conventions.
Replace two literal table capacities with LENGTH DirSftIds and derive the
two-word position table capacity from the same array. Replace the zero-offset
SFT reference-count store with the existing sf_ref_count field symbol.
Remove reconstruction provenance from the runtime explanation and describe the
SaveDirSft/ClearDirSft input and register-preservation contracts.

Retain LFN search state initialization, skipping and result bookkeeping;
DirSftCluster updates for directory/root searches; the shared SFT association
table and all lookup/save/clear behavior. Existing callers in file/fcb/abort/close
and the internal dispatch entry use this one implementation. Preserve required
instruction encoding, .286/.8086 boundaries and table order. No machine-code
operation or value changes; no source tree restructuring.

Original NMAKE/MASM/LINK freshly rebuilds the kernel byte-identical. Fresh
IO.SYS repack matches the frozen 950 target. Unaffected inherited MSDOS.SYS
and COMMAND.COM are also target-exact; all 293 source inputs match the stage.
Evidence: file154-build.txt, file154-make.txt; stage named in the build record.

Prefix 154/293: modified 77, exact 22, necessary unchanged 19, no same-name
reference unchanged 36. Separate modified tool one. Next: 155 dos/dir2.asm.
Final full build and completion audit remain pending.
