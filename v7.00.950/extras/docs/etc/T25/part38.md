# M6 T25 S1 P38: file 129

129. tdata.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Restore separate external declarations and consistent labels. Correct the
COMTAB description: it stores flags/handler/help entries, with names in a
separate ordered table. Remove orphan FILE_OPTIONAL/MRDIR/CTTY/LOADHIGH table
descriptions and put CHCP's header beside its actual compact control. Correct
ParseResultValue/ParseResultType and VER /R notes; describe DIR's remaining
synonyms without claiming removed PARSE1_OUTPUT-based tables still exist.
Keep valid inherited comments, original conditional branches and empty blocks.

The separate name and command tables, LOCK/UNLOCK/LFNFOR entries, changed
command flags, switch masks, access-date ordering and new help IDs are required
target data. Compact controls use the shared ParseArgument dispatcher, while
TIME retains its legacy table and target terminator byte. Reinstating deleted
legacy control tables would change layout and duplicate obsolete parsing.
Keep resource indirection, message macro invocation and TRANDATAEND checksum
boundary unchanged. No DB/DW/DD values, emitted order or section changed.

Verification: file129-build.txt; extras/build/t25-tdata-17988-21486.
Original COMMAND build passes. Regenerated messages and linked executables
are unchanged. Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS
also match, and all 293 source inputs match the verified stage.

Prefix 129/293: modified 59, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 130 tenv.asm.
Final full automatic build remains pending. P38 is delivered separately.
