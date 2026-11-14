# M6 T25 S1 P27: file 116

116. cmd/command/path1.asm -- accepted_modified.
Complete diff retains the original Path_Search/Path_Crunch structure. Normalize
the three added LFN/UNC branch pairs to the surrounding Microsoft instruction
style, explain why those branches bypass legacy prefix expansion, and split
the added external declarations to match the existing declaration form.

Necessary differences retained: EXECPATH length 260; PathFindMode bypasses short
path expansion at initial and found-result handling; UNC names are not prefixed
with a drive; scratch references use the actual dynamic token buffer; public
exit entries and the target BH load position remain intact. The two mode tests
handle different inputs/stages and are not duplicate search implementations.
No second path-search engine or source module introduced.

Verification: file116-build.txt; extras/build/t25-path1-12286-30833.
Original COMMAND build passes. Regenerated messages and linked executables are
unchanged. Fresh COMMAND.COM matches own target; inherited IO.SYS/MSDOS.SYS also
match. All 293 source inputs match the verified stage.

Prefix 116/293: modified 49, exact 20, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 117 path2.asm.
Final full automatic build remains pending. P27 is committed/pushed separately.
