# M6 T25 S1 P50: file 141 with required build dependency

141. uinit.asm -- accepted_modified. Reviewed full effective-v6.22 diff.
Restore original COMND1_OUTPUT/NO_VAL/positional-counter comments; expand /L
and /U value-range records using the inherited field layout. Split added export
lists. Replace eleven DOS service literals with symbols from syscall.inc and
use the inherited INT 21h syntax. Include syscall.inc explicitly.

Retain fourteen switches, numeric limits, environment minimum, Windows command
path, resource-file search and shared class reader, initialization pointer fixup
and resident relocation additions. INIT's two class loads call the same reader;
the fallback path reuses ReadMessageHeader rather than introducing a second
implementation. Resource loading at initialization cannot be removed in favor
of the old inline message organization without changing the accepted output.

Build dependency correction: add syscall.inc to the existing uinit.obj list in
COMMAND makefile (file 114, already counted modified). This is the necessary
dependency introduced by this file's edit, not a new sequential acceptance or
a broad re-audit. No other dependency or build command changed.

Initial attempt failed because UINIT did not include service constants.
Evidence: file141-failed-build.txt and file141-failed-make.txt;
extras/build/t25-uinit-24296-20541. No acceptance at that point.
After explicit include, original build and all comparisons pass:
file141-build.txt; extras/build/t25-uinit-24561-6426.
After the dependency edit, original build and comparisons pass again:
file141-dependency-build.txt; extras/build/t25-uinit-dep-24731-8287.
Messages and linked executables unchanged; fresh COMMAND.COM target-exact,
inherited IO.SYS/MSDOS.SYS target-exact; all 293 source inputs match latest stage.

Prefix 141/293: modified 70, exact 21, necessary unchanged 14, no same-name
reference unchanged 36. Separate tool modification one. Next: 142 dos/abort.asm.
Full final automatic build and completion audit remain pending.
