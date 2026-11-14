# T21 file 142: dos/makefile

Restored DOS6's MS-DOS banner, dependency heading, link_opts=/MAP variable,
and LINK/RELOC/STRIPZ recipe spelling/indentation. Replaced 49 of the 55 object
dependency blocks with their exact DOS6 text after case/slash-normalized set
comparison. The other six use the same reference text minus dependencies not
present in DOS5: msdata omits mpatch.asm; mstable/rom/handle/file omit EA.inc;
msproc omits EA.inc and restrict.inc. No original empty conditional or repeated
dependency was newly deleted. DOS6's repeated dosmac dependency is retained.
Before/after comparison confirms all 55 dependency sets unchanged.

Added makefile to MSDOS.BIN prerequisites as in DOS6, so recipe changes trigger
relinking. Kept current 55-object order and msdos.lnk, which controls actual
link order. There are no source/output-specific patch commands. Core-only
all: $(dest) deliberately excludes reference Build.IO, Copy.EM, compression,
distribution copies and BASE/SOFT_ICE variants; host build owns the three-core
sequence and target-gated publication. The fixed COUNTRY=DOS, -W1 and include
path retain the verified native target configuration, without introducing DOS6
restricted-build, EA or ROM-find units. NOSRVBLD still generates the four DOS5
message classes from the native skeleton/message inputs; it is not a binary
substitution. These recipe/configuration differences are required by the
existing core-only DOS5 build boundary. No script language was introduced.

Verification: extras/build/t21-dos-29103-9182, parent t21-dos-28339-17191.
Original NMAKE/MASM rebuilt all 55 DOS objects; every raw object matched the
parent. Relinked MSDOS.SYS matches both parent and frozen target. Inherited
IO.SYS/COMMAND.COM also match their frozen targets (not rebuilt). All 243
source/stage checks passed before/after. Logs are audit-object-compare.log,
audit-*-compare.log, audit-inputs-*.log, dos/AUDIT.LOG, result.txt in the stage.
T21-142-blocks.log identifies the reference blocks and omitted dependencies;
T21-142-dependency-check.log compares candidate with old dependency sets
(its generic 'DOS6' labels mean the supplied candidate in that second run).

Prefix 142/243: 14 modified (one metadata), 109 exact, 19 necessary differences.
Next: 143 dos/misc.asm.
