# T21 file 25: bios/sysconf.asm

Modified and verified. Only this source file was edited at this position.

## Changes

Seven command-byte comparisons now use the existing DOS6 CONFIG_DOS,
CONFIG_INSTALL (twice), CONFIG_COMMENT, CONFIG_UNKNOWN, CONFIG_REM and
CONFIG_DEVICEHIGH definitions, in the reference's instruction spelling and
layout. File 4 already defines them as exactly H/I/Y/Z/0/U. This removes
unnecessary bare command values without changing an instruction byte.

Removed the orphan CheckProtmanArena comment header: this procedure and its
call are absent from the selected DOS5 implementation. Leaving a procedure
contract above a different routine is misleading. No empty original conditional
branches were removed and no replacement helper/path was introduced.

## Disposition of the remaining DOS6 difference groups

| Group / affected blocks | Decision and source evidence |
| --- | --- |
| MULTI_CONFIG definition/state/workspace, command line-number rewriting, query_user calls, SET/NUMLOCK and INSTALLHIGH dispatch | Later multi-configuration behavior; retain omission. Keep DOS5's three SWITCHES entries K/T/W and its original pass/branch sequence. |
| MagicDrv include/externs, syspre exports, driver_units, MagicHomeFlag, CheckDoubleSpace and temporary sysi_numio/ncds swap | DoubleSpace integration; retain omission consistent with files 8 and 9. Do not add inactive later-version code merely to resemble DOS6. |
| COPYCDS blocks and doconf allocation | DOS5 uses confbot and moves temporary CDS storage before reading CONFIG. Retain existing confbot/tempcds operations instead of DOS6's alloclim and multi-config work area. |
| DEVICEHIGH ParseSize/save positions and delimiter scan | Retain DOS5 parsing/control flow. OpenNT preserves the earlier SIZE-only ParseSize body at lines 3366-3392; do not restore DOS6 ParseVar /L handling. |
| UmbTest, ConvLoad, highvar/highload/highexit, HideUMBs/FreezeUM/RetFromUM | DOS6 explicit UMB-selection machinery. Keep the existing DOS5 InitForConv path rather than parallel implementations. DOS6 itself labels this path DOS5-style. |
| LoadDevice DS setup, error branches, short jump forms and device init bookkeeping | These emit different instructions/register effects or change branch widths. Preserve the exact target sequence. OpenNT BadFile lines 1118-1124 corroborate the CR check instead of DOS6's broader space comparison. |
| CheckProtmanArena body and call | Later allocator workaround absent from the target. Omission retained; only its stale surviving header was removed. |
| DRIVPARM carry check after diddleback | Preserve target JC. OpenNT retains the earlier sequence in its commented DRIVPARM code, lines 1639-1646. DOS6 comments out the check; that would change DOS5 bytes/behavior. This audit is not an unsolicited bug fix. |
| SHELL name/argument handling and COMMENT/REM placement | OpenNT lines 1779-1823 preserve the earlier shell loop (apart from its commented NT service). Retain DOS5 loop, limits, branch order and comment dispatch position; do not insert the DOS6 bounded-copy/command-length rewrite. No NT service imported. |
| PrepareMark versus inline arena setup in GetUMBForDev | OpenNT's retained pre-NT branch, lines 2925-2961, corroborates the inline DOS5 arena marking. Its NT best-fit alternative begins at 2962 and is excluded. A DOS6 helper call would change target bytes and register/order details. |
| SizeDevice save/restore and minimum SIZE selection | Keep DOS5 DS behavior and DevSizeOption comparison; DOS6's advanced loading path differs. |
| Anonymous labels, local trampolines and retained comments | Preserve existing forms already corroborated by older OpenNT code or required by the target branch layout. No cosmetic relabeling that obscures provenance. |

DOS4 provides older ancestry but not the DOS5 UMB feature set; it is not a
replacement for the required device-loading blocks. Full DOS6 diff was read,
including retained data definitions, all dispatch deletion hunks, device-load
changes, shell handling and the later helper procedures. No whole-word
BOP/NTVDM/VDM/NTIO/dossvc hits occur in the current file.

## Verification

Clean build cmd-19587-14534 returned zero; before/after source snapshots match.
IO.SYS, MSDOS.SYS and COMMAND.COM all passed full FC /B against the frozen
targets and were published to extras/assets. Direct comparison with accepted
cmd-6108-11594 passed for all 15 BIOS object files (including sysconf.obj),
msload.com, msbio.bin and IO.SYS. See T21-025-object-compare.log.

Initial SHA256 remains frozen in T21-file-ledger.csv. Post-edit SHA256 is in
T21-025-proof.csv and the build input snapshots. Prefix 25/243: 3 modified,
18 reference-identical, 4 unchanged necessary differences. Next 26 sysimes.asm.
