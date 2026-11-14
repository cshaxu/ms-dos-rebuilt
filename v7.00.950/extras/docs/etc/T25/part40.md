# M6 T25 S1 P40: file 131

131. tenv2.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Restore original invalid-directory explanation, filename-copy comments,
FCB conversion contract and string comparison notes. Match inherited TAB
instruction layout in rewritten CHDIR, shared MKDIR/RMDIR setup and string
helpers. Use existing RMDIR/MKDIR service symbols for two legacy API selectors.
No instruction sequence or layout changed.

Keep shared ParseArgument/count checking and selected long/short path APIs.
SETRMMK remains one common setup for MKDIR/RMDIR. Preserve explicit return
sharing, transient buffer pointers, message class and FCB conversion's tracking
of the final nonblank name/extension position. Restoring the old per-character
space omission would change target behavior. STRCOMP and DELIM already reuse
existing return tails, so no further artificial factoring is needed.

PATHCRUNCH's network-path checks, attribute fallback, caller flags and delimiter
restoration differ necessarily from the reference. All three change-directory
sites share pcrunch_chdir; attribute lookups share pcrunch_attrib. Preserve their
flag contracts and restoration state rather than duplicating the old inline
DOS calls. Existing inherited path scanning and conditional structure remain.

Verification: file131-build.txt; extras/build/t25-tenv2-18843-19521.
Original COMMAND build passes. Messages and linked executables remain exact.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 source inputs match the verified stage.

Prefix 131/293: modified 61, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 132 tfor.asm.
Final full automatic build remains pending. P40 is delivered separately.
