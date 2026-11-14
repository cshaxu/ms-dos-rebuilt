# M6 T25 S1 P69: files 172-174

172 dos/fcbio.asm: accepted_necessary. Complete effective v6.22 diff reviewed.
Three explicit target encodings, SaveDirSft after regeneration and ClearDirSft
before clearing the SFT, followed by target immediate ref-count clear/order.
Uses existing shared directory tracking helpers; no second implementation.
Retain target behavior and bytes. No rebuild for unchanged source.

173 dos/fcbio2.asm: accepted_necessary. Three explicit target encodings and
SaveDirSft after reference-count increments in FCBOK2/OpenFound. Required
companion tracking to FCBIO; inherited structure retained. No rebuild.

174 dos/file.asm: accepted_modified. Complete reference diff reviewed.
Retain SaveDirSft on successful open, removed IFS error exception, shared
success/error jumps, temporary-name retry based on extended error plus
attribute query, and target CMP encoding. Corrected obsolete open-failure
comment that still claimed to check the removed extended-open hook.
Normalized new temporary-file block indentation and two JMP declarations.
Instruction text/operands and data unchanged.

FILE rebuilt, kernel freshly linked unchanged and IO.SYS freshly packed
target-exact. Unaffected MSDOS.SYS/COMMAND.COM inherited and also compared
target-exact; 293 current inputs match build stage. Evidence file174-build.txt
and file174-make.txt.

Prefix 174/293: modified 89, exact 26, necessary unchanged 23, no same-name
reference unchanged 36; separate tool change 1. Next 175 dos/finfo.asm.
Final full clean build and completion audit pending.
