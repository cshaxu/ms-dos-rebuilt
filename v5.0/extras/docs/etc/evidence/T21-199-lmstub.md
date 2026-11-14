# T21 file 199: inc/lmstub.asm

Complete DOS6 diff and whitespace-insensitive OpenNT diff reviewed. Moved the
original Win 2.x instance-table explanation from the unrelated XMM message
include back before OldInstanceJunk, matching DOS6. Restored DOS6's M032
history entry for the already-present 34-byte EXEC block length and restored
34 reference whitespace lines. No instructions, emitted data or conditions
changed. This is a correction of comment ownership, not a second table.

Required native differences from OpenNT: EnsureA20ON is the single DOS6
flags-preserving routine, with no December 1992 WEnsureA20ON wrapper split;
native CLI/STI/IRET replace DOCLI/DOSTI/DOIRET/SVC hooks. NT debugger, SCS,
FAKE_NTDPB, redirected NetCDS and WOW records remain removed. EXEC header data
is not duplicated from OpenNT's relocated copy. The instance table's DOS6
placement/34-byte EXEC entry are retained because they match target layout;
OpenNT's moved table/24-byte entry would not. Against DOS6, the short header
is original OpenNT lineage, the .ERR layout guard is also present in OpenNT,
and optional ROMDOS/POWER count and ROMEXEC exclusion pointer remain absent.
Neither the existing guard nor original active/empty branches are removed.

Only dos/msdata.asm includes this file (other source hits are comments);
the DOS makefile records that dependency. Verified stage
extras/build/t21-dos-31304-11880, parent t21-dos-30775-7342: original isolated
NMAKE/MASM rebuilt all 55 DOS objects and relinked MSDOS.SYS. Every raw object
and MSDOS.SYS matched parent. All three components match frozen targets,
IO/COMMAND inherited rather than recompiled. All 243 source/stage checks pass
before/after. Logs: result.txt, dos/AUDIT.LOG, audit-object-compare.log,
audit-*-compare.log and audit-inputs-*.log in the verified stage.

Prefix 199/243: 18 modified (one metadata), 156 exact, 25 necessary differences.
Next: 200 inc/lock.inc.
