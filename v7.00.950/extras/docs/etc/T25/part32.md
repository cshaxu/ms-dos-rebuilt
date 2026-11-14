# M6 T25 S1 P32: file 123

123. tbatch.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Restore six inherited explanatory paragraphs for EOF cleanup, label detection,
label skipping, echo decision, overflow and argument termination. Restore
seek/argument comments and the original LSEEK expression. Match surrounding
one-symbol EXTRN declarations and TAB-based allocation instructions.

Retain dynamic ComBufPtr/WORD length, separate raw-read and expansion phases,
DBCS capacity handling, environment case mode and FOR matching. TCODE and
ReadBat share ExpandCommandLine; restoring the old inline parameter parser or
StrCpy would reintroduce a second path. ExpandPercent already shares its exit,
context and variable-match helpers. Keep quoted argument scanning, command
state notification, canonical path storage, dynamic allocation/overlap bounds
and temporary TPA reservation, all of which affect required target behavior.
No runtime instruction sequence or layout was removed or added.

Verification: file123-build.txt; extras/build/t25-tbatch-15022-26797.
Original COMMAND build passes. Message files and linked executables remain
byte-identical. Fresh COMMAND.COM matches the frozen target; inherited IO.SYS
and MSDOS.SYS also match. All 293 source inputs match the verified stage.

Prefix 123/293: modified 53, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 124 tbatch2.asm.
Final full automatic build remains pending. P32 is delivered separately.
