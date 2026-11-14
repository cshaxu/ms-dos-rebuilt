# M6 T25 S1 P34: file 125

125. tcmd1b.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Remove unused added DirSearchPos external. Split added external groups to match
surrounding declarations. Restore ERASE/SetupMissingArgument instruction layout
and inherited switch/error comments. Move the VOLUME listing heading and its
description from above TYPE's parser to VOLUME itself. Preserve inherited
space-indented declarations instead of normalizing reference-exact lines.

Retain shared ParseArgument and directory argument/error helpers, LFN/UNC
selection, wildcard preparation and common NOTEST2 erase path. Rename's
enumeration, long/short filename offsets, wildcard target generation and error
mapping replace the old FCB operation and reuse PathFindFirst/Next and
CopyMakeTargetName. Restoring FCB rename would lose required behavior. TYPE
keeps its one-argument helper and selected open API; its 40h sharing mode is
not the reference read_open_mode (zero), so preserve it. Shared missing-argument
setup is used by TYPE and rename. VOLUME retains generic IOCTL media-ID access
and the additional extended-error entry. No new implementation is introduced.

Verification: file125-build.txt; extras/build/t25-tcmd1b-15992-7810.
Original COMMAND build passes. Messages and linked executables are unchanged.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 source inputs match the verified stage.

Prefix 125/293: modified 55, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 126 tcmd2a.asm.
Final full automatic build remains pending. P34 is delivered separately.
