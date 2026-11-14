# T21 file 243: messages/usa-ms.msg

Complete OpenNT diff is exactly COMMAND message 1040: removing '.500' from
'MS-DOS Version %1.%2.500'. The maintained line exactly matches DOS4
src/MESSAGES/USA-MS.MSG:205, including the U/0000 fields and quoted text.
All other source bytes follow OpenNT. This necessary target version difference
does not require a new rewrite or extra resource path.

The on-disk source hash still equals its frozen admission hash. The original
BUILDIDX updates catalog index fields in the staged copy, as expected; this
is separately checked rather than falsely asserting source/stage identity.
The final full build cmd-32179-8869 compiled this input, produced exactly the
target COMMAND.COM and published all three byte-identical files. No file edit
or additional build was needed for this final unchanged source.

All 243 files now have ordered dispositions: 20 modified (19 source/build
plus one metadata relocation), 193 reference-identical, 30 retained necessary
differences. No file is pending. Task completion remains subject to the separate
completion audit and final evidence checks.
