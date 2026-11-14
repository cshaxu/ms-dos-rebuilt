# M6 T25 S1 P28: file 117

117. cmd/command/path2.asm -- accepted_modified.
Read complete effective-reference diff and current module. Remove the unused
fordata.asm include and ten unused added external declarations left after
Save_Args moved to TFOR. Retain inherited declarations to minimize unrelated
reference differences. Restore matching search/type/copy instruction formatting
and original comments. Correct the Save_Args location and Search_Ftype input
contract (DS:SI filename rather than a fixed DTA location).

Keep SelectPathInterface and shared PathFindFirst/Next/ClosePathFind operations,
long/short result-buffer selection, returned short-name preference, word-sized
best-type state and extension folding. These adapt the original Search and
Search_Ftype flows to 950 file APIs; they are not a second search engine.
Save_Args remains solely in TFOR, with the dynamic layout required by FORDATA.
The existing makefile's conservative fordata dependency is harmless; no build
rule or already-accepted source was changed in this P.

Verification: file117-build.txt; extras/build/t25-path2-12746-6262.
Original COMMAND build passes. All messages and linked executables unchanged;
fresh COMMAND.COM matches its target. Inherited IO.SYS/MSDOS.SYS also match.
All 293 current sources match the stage, including the removed empty include.

Prefix 117/293: modified 50, exact 20, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 118 rdata.asm.
Full automatic final build remains pending. P28 is committed/pushed separately.
