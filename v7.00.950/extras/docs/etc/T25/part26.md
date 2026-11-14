# M6 T25 S1 P26: file 115

115. cmd/command/parse2.asm -- accepted_modified.
Reviewed the complete effective-reference diff, original parse loop and actual
command-specific consumers of ParseArgument. Restore the inherited token loop,
switch/error comments and success/error exit formatting. Preserve both explicit
SHORT branches and all target instructions. Update the old interface description
for ComBufPtr, dynamic buffer length, preserved AX/BX and argument-string storage.

Keep shared ParseCommandLine for initial parsing and cmd_copy reparsing; retain
dynamic storage bounds and original-command copies required by FOR. NewArg and
Arg_Switch still share argv bookkeeping. Command-specific consumers use the
common typed-argument dispatcher and date/number helpers. ReadDecimal stops at
a separator and advances SI; ParseNumberArg requires a null-terminated argument,
preserves SI and returns parser error/result state. They have different contracts
and target bodies, rather than interchangeable duplicate paths. No module added.

Verification: file115-build.txt; extras/build/t25-parse2-11809-1661.
Original COMMAND build passes. Regenerated messages and linked executables
are unchanged. Fresh COMMAND.COM equals its 950 target; inherited IO.SYS and
MSDOS.SYS also equal. All 293 current sources match the verified stage.

Prefix 115/293: modified 48, exact 20, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 116 path1.asm.
Final full automatic build remains pending. This verified P is committed and
pushed independently under the owner's standing Git authorization.
