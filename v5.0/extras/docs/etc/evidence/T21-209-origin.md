# T21 file 209: inc/origin.inc

Complete DOS6 and OpenNT diffs reviewed. The file follows OpenNT's direct disk
origin structure; its sole semantic difference removes OpenNT's -40h adjustment
from PARASTART. Native DOS6 provides exactly the maintained paragraph-rounding
formula. Restored the final tab so this formula line now also matches DOS6 raw
text. Required size inputs were independently verified against linked segment
maps in file 172. Do not import the ROMDOS zero-origin alternative or restore
the NT displacement merely to reduce textual differences.

Compilation scope: dos/origin.asm and msdata's included mshead.asm consume this
header; no BIOS/COMMAND source includes it. Stage t21-dos-31617-27919, parent
t21-dos-31304-11880, rebuilt all 55 DOS objects using original NMAKE/MASM and
relinked MSDOS.SYS. All raw objects and output match parent byte-for-byte.
All three outputs match frozen targets; IO/COMMAND are inherited, not rebuilt.
All 243 source/stage checks pass before/after. Logs are in the stage's
audit-object-compare.log, audit-*-compare.log, audit-inputs-*.log, dos/AUDIT.LOG,
result.txt. No data or instruction changed.

Prefix 209/243: 19 modified (one metadata), 164 exact, 26 necessary differences.
Next: 210 inc/parse.asm.
