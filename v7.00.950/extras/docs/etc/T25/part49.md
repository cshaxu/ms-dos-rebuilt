# M6 T25 S1 P49: file 140

140. tucode.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Remove six unused externals left after replacement of FCB deletion and old
ON_OFF parsing: BWDBUF, DEST, destdir, dirchar, PARSE1_CODE, extend_setup.
Split added declaration lists and align added instruction layout with surrounding
code. Reuse UNLINK, the two STD_CON_INPUT_FLUSH service expressions and
util_msg_class. Correct ON_OFF input documentation to parsed arg/control blocks
and its actual nonzero rejected-input indicator. Preserve unchanged code.

Retain shared erase enumeration, separate all-files versus per-file confirmation,
dynamic command argument parsing, LFNFOR control and common ON/OFF matcher.
These replace the old FCB/PSP interfaces; adding the reference routines alongside
them would duplicate command processing. Preserve the target's wildcard/prompt,
delete count/error and branch behavior. No new module or runtime path introduced.

Owner-authorized XP semantic reference: demlfn.c:5441 passes DS:DX filename,
CH required attributes, CL search attributes and SI wildcard selection to
demLFNDeleteFile; implementation at :4905 branches on fUseWildCard at :4949.
TUCODE's direct wildcard deletion sets SI=1/CX=0; its enumerated single-file
deletion sets SI=0. These roles agree. Its PathFindNext consumer tests carry
and uses its own DeleteError rather than depending on the overwritten AX noted
in P48. This verifies these specific contracts, not all deletion edge cases.

Verification: file140-build.txt; extras/build/t25-tucode-23741-28320.
Original COMMAND build passes; messages and linked executables unchanged.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 current source inputs match the verified stage.

Prefix 140/293: modified 69, exact 21, necessary unchanged 14, no same-name
reference unchanged 36. Tool modification one. Next: 141 uinit.asm.
Final full automatic build and completion audit remain pending.
