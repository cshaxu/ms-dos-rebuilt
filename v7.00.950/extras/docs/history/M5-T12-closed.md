# DOS 7.0a source quality audit

## M5 T12 S1 Packet

Status: **closed**. All 66 files resolved; completion audit: [source-quality-completion.json](../etc/source-quality-completion.json).

Field | Required record
--- | ---
Identifier Mode | New; T11 is closed
Admission And Approval | Owner explicitly requested the 29 modified and 37 added source files be audited against DOS 6 style and structure
Objective | Audit all 66 files in fixed dependency order; remove unnecessary duplication and second implementations; justify or merge every new file; preserve exact three-core outputs
Non-goals | No Python/PowerShell/JS toolchain, Computer Use, VM boot tests, commits, or unrequested expansion to the unchanged source set
Reference Baseline | T11 completed queue and three-core acceptance; original v6.0 tree; actual version directory is now v7.0
Candidate Proposal | Freeze 66 entries and dependency order; compare each with original Microsoft source or original host-module pattern; implement changes and record necessity/merge decisions
Files And ABI Surface | source-quality-queue.json; public names, segment layout, byte values and call conventions must remain compatible
Applicable Rules | CODING.md and EXECUTION.md; latest owner instructions prevail
Verification | No rebuild for unchanged assembler statements and formatting/comments alone; relevant binary comparison after effective assembly/link changes
Expected Markers | 66 resolved dispositions, per-file DOS6 comparison evidence, explicit necessity decisions for all 37 new entries, no pending transfers on closure
Asset Needs | Existing fixed Win95 A targets and original pinned toolchain; assets remain verified until a justified rebuild replaces them
Reporting Requirements | Show ordinal and completed/remaining files, changed versus unchanged in this audit, and exact DOS6 count separately
Stop Conditions | Unknown provenance, concurrent source drift or binary mismatch; do not approve an unresolved file
Exit Criteria | All 66 reviewed, changes verified at affected scope, new-file decisions closed, separate task completion audit
Original Owner Request | Match DOS6 structure/style, remove unnecessary duplication and second paths, assess merging new files; do not rebuild when instructions did not change
Similar-Issue Sweep | Repeated segment providers, fragment-only ASM units, duplicate data/headers, generated compilation-unit prose, redundant branches and build paths

The fixed order is [source-quality-queue.json](../etc/source-quality-queue.json).
Previous completed state is archived in history/pre-T12-current.md.

P1 verified ordinals 1-3: one comment/format-only modification, two retained
without edits, zero whole-file DOS6 identities. Necessary compiler/alignment
differences are enumerated in source-quality-P1.json. No assembler statement
changed and no build was run. Next is ordinal 4, bios/biosmt.inc; its
single-consumer necessity/merge decision remains open. Remaining: 63 files.

P2 dependency unit: audit ordinal 4 and inline its seven-line trailer in its
sole consumer, ordinal 9 (biosmsg.asm). This is a source INCLUDE expansion,
not an object merger. Ordinal 9 receives a recorded collateral edit only;
its complete module/placement review remains at ordinal 9. No link input,
segment, symbol or resource byte changes. Resume ordinal 5 after verifying
the expanded assembler stream. Object-merger candidates such as bcend.asm
remain subject to their own ordered review and affected binary validation.

P2 verified ordinals 4-6. Cumulative: 6/66 resolved; 4 modified (including one
retired include), 2 unchanged, 0 whole-file DOS6 identities. Ordinal 9 has a
collateral include-inlining edit, not a completed audit. All selected emitted
statements remain unchanged; no rebuild. Next: ordinal 7, backdata.asm.

P3 dependency unit, admitted before edits: ordinal 7 backdata.asm is an
eleven-line extraction from DOS6 sysinit1.asm immediately preceding movstart
in the link order. Fold it into the beginning of movstart.asm (ordinal 30).
Ordinal 8 bcend.asm is the original DOS6 paragraph boundary marker immediately
preceding biosmsg; fold it into that module (ordinal 9). Update the two removed
object inputs in msbio.lnk and makefile (ordinals 59/60). Consumer/build edits
are collateral; their complete reviews retain their frozen ordinal positions.
Reassemble only the two affected modules, relink BIOS and compare the final
IO.SYS against the accepted target. COMMAND and kernel have no emitted change.

P3 verified ordinals 7-9. Cumulative: 9/66 resolved; 7 modified (including
3 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Full reviews
of collateral edits to ordinals 30, 59 and 60 remain pending. Two modules
reassembled, BIOS relinked and IO.SYS repacked; direct byte comparisons match
the accepted BIOS and IO.SYS. Other two outputs retain T11 acceptance without
rebuilding. Next is ordinal 10, bios/biostail.asm; remaining 57 files.

P4 dependency unit: ordinal 10 retains the boot-log and CONFIG$ service
module; normalize declaration/PROC formatting and remove assembler-version
commentary from source, without changing any effective statement. Ordinal 11
bootdata.asm is an unnecessary standalone state fragment. Append its data to
the immediately preceding ststate.asm (ordinal 53), preserving declaration
order and byte alignment. The ststate full review remains at ordinal 53.
Remove bootdata from link/make inputs (59/60), then reassemble ststate and
compare the linked BIOS and packed IO.SYS. No other component rebuild.

P4 verified ordinals 10-13. Cumulative: 13/66 resolved; 11 modified (including
4 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. The complete
effective statement streams of biostail, cfgline and cfgmain are unchanged.
Only ststate was reassembled for the bootdata merge; linked BIOS and packed
IO.SYS compare byte-for-byte with the accepted originals. No other rebuild.
Collateral full-file reviews retain ordinals 53, 59 and 60. Next is ordinal 14,
bios/cfgmem.asm; remaining 53 files. See source-quality-P4.json for evidence.

P5 verified ordinal 14, cfgmem.asm: shared memory-service module retained;
formatting and provenance commentary cleaned up, all 145 assembler statements
unchanged, no rebuild. Cumulative: 14/66 resolved; 12 modified (including
4 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Next is
ordinal 15, bios/cfgmenu.asm; remaining 52 files. Evidence: source-quality-P5.json.

P6 dependency unit: review 15/16 in order, normalize cfgmenu procedure comments
and cfgseg segment-order header without changing effective statements. Retire
ordinal 17 clockbr.asm by appending its two clock procedures to the preceding
original mschar module (ordinal 33), replacing its external int6c_update with
the local definition. Link/make (59/60) lose clockbr.obj. The complete mschar
review remains at ordinal 33. Reassemble mschar only, relink BIOS and compare
packed IO.SYS. Ordinal 18 confhook follows after that module decision.

P6 ordinal 18 decision: merge confhook into its original configuration owner,
sysconf.asm (ordinal 54). Its state and pathname callback already live there;
only the install/remove/check procedures were in the adjacent fragment.
Append procedures in the same SysInitSeg order, remove the external declarations
replaced by definitions, and remove confhook.obj from 59/60. Reassemble sysconf
and relink against the verified merged mschar object. Full sysconf review stays
at ordinal 54; this is a documented dependency edit, not an out-of-order audit.

P6 verified ordinals 15-18. Cumulative: 18/66 resolved; 16 modified (including
6 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. cfgmenu/cfgseg
effective statements unchanged; no rebuild for those changes. Merged mschar
and sysconf assembled with original tools, and linked BIOS plus final IO.SYS
compare byte-for-byte with T11 accepted outputs. Full host-module reviews keep
ordinals 33/54; link/make keep 59/60. Next: ordinal 19, bios/cpath.asm; 48 remain.

P7 dependency unit: ordinal 19 retains the configuration path service with
format/comment cleanup only. Ordinal 20 devparm.asm contains just one device
parameter structure, originally declared in DOS6 sysinit2.asm. Merge it into
the adjacent request-packet storage module reqpkt.asm (ordinal 46), preserving
byte alignment and data order. Remove devparm.obj from 59/60; reassemble only
reqpkt and compare linked BIOS plus packed IO.SYS. Full reqpkt review stays 46.

P7 verified ordinals 19-21. Cumulative: 21/66 resolved; 19 modified (including
7 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. cpath and
drivechk effective assembler statements unchanged (the latter after expanding
its single-use macro); no rebuild for those edits. Reassembled reqpkt, linked
BIOS and packed IO.SYS match accepted bytes. Next: ordinal 22, bios/initclk.asm;
45 remain. Full collateral reviews retain 46/59/60. Evidence: source-quality-P7.json.

P8: specialize ordinal 22 initclk to the formal DOS7_CONFIG build, removing
unselected DOS6 implementation branches while retaining original POWER/ROMDOS
conditionals. All 419 effective statements match; no rebuild for this edit.
Ordinal 23 instdata is adjacent to ststate in the link order: merge its INSTALL
and configuration-command state into ststate (53), preserving EXEC structures,
field order and byte alignment. Remove instdata input/rule (59/60), add exe.inc
dependency, reassemble ststate and compare BIOS/IO.SYS. Full host review stays 53.

P8 verified ordinals 22-23. Cumulative: 23/66 resolved; 21 modified (including
8 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Removed 308 lines
of unselected initclk branches, retaining all 419 effective statements and
original POWER/ROMDOS conditionals; no clock rebuild. Merged INSTALL state,
reassembled ststate and verified linked BIOS plus complete IO.SYS byte-for-byte.
Next: ordinal 24, bios/logocode.asm; 43 remain. Evidence: source-quality-P8.json.

P9 dependency unit: normalize 24/25 without changing effective statements.
For 26, the BDS structure already exists in original msbio1 with identical
fields; move the instances into its final SysInitSeg and remove the duplicate
structure/module. Ordinal 27's sole SI_start jump follows those instances;
merge it there with EVEN to preserve the previous word-aligned contribution.
Host msbio1 full review retains ordinal 31. Remove mbbds/mbentry object inputs
and rules (59/60); reassemble msbio1, relink and compare complete IO.SYS.

P9 verified ordinals 24-27. Cumulative: 27/66 resolved; 25 modified (including
10 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Logo/log effective
statement sequences unchanged after macro expansion and redundant CPU directive
removal; no rebuild for those edits. BDS instances and SI_start returned to
original msbio1, duplicate BDS schema eliminated; original-tool BIOS and complete
IO.SYS compare byte-for-byte. Next: ordinal 28, bios/mblate.asm; 39 remain.

P10 dependency unit: ordinal 28's system EXEC routine is one fall-through flow;
only boot_exec_system has external consumers. Replace seven intermediate PROC
interfaces with same-named near labels, retain all instructions and assumptions,
and close the one procedure at its final return. Remove orphan drive-check
heading. Ordinal 29 memstate is adjacent to ststate; merge its memory-allocation
state there (53), removing duplicate boot_mode PUBLIC and stale packet comments.
Remove memstate object/rule (59/60); validate the changed procedure organization
and object merge by assembling mblate/ststate, linking BIOS and comparing IO.SYS.

P10 verified ordinals 28-29. Cumulative: 29/66 resolved; 27 modified (including
11 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. EXEC flow is
one real procedure with internal labels; duplicate declarations and orphan
comments removed. Memory state merged into ststate. Original-tool BIOS and
complete IO.SYS compare byte-for-byte; post-build EXTRN deduplication verified
without recompilation. Next: ordinal 30, bios/movstart.asm; 37 remain.

P11 dependency unit: move ordinal 30 back into original owner sysinit1 (56),
including previously absorbed backdoor data. The old fragment begins at odd
offset 0FFBh and ends at SYSIN 1080h. Define BYTE_SYSINIT before biosseg in the
host so its new combined contribution begins at the same byte boundary; do
not add local EVEN. Insert the relocation prelude before old sysinit$ and
remove external declarations replaced by local definitions. Other existing
declarations and original conditional branches stay. Remove movstart object
input/rule (59/60). Reassemble sysinit1 and validate map addresses plus BIOS
and complete IO.SYS. Full sysinit1 audit remains at ordinal 56.

P11 verified ordinal 30. Cumulative: 30/66 resolved; 28 modified (including
12 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Relocation
prelude and backdoor state returned to original sysinit1, with all four checked
entry addresses unchanged. Original-tool linked BIOS and complete IO.SYS match
accepted bytes. Backdata's final owner is tracked through this second merge.
Next: ordinal 31, bios/msbio1.asm; 36 remain. Evidence: source-quality-P11.json.

P12 verified ordinal 31, including its P9 collateral merge. Original procedure
comments now accompany their bodies; orphan headings and eight redundant PUBLIC
declarations removed. Ordered effective non-PUBLIC statements and exported symbol
set are unchanged, so no rebuild. Target-specific BIOS behavior and original
conditional branches retained. Cumulative: 31/66 resolved; 29 modified (including
12 retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 32,
bios/msbio2.asm; 35 remain. Evidence: source-quality-P12.json.

P13 verified ordinal 32. Select the formal DOS7_CONFIG path, remove 34 selectors
and inactive DOS6 alternatives, and correct displaced/stale comments. Net 195
lines removed; all 776 effective statements unchanged. AT/COMPAQ ROM patch remains
DOS6 text-identical apart from EOF newline. No rebuild. Cumulative: 32/66 resolved;
30 modified (including 12 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 33, bios/mschar.asm; 34 remain. See source-quality-P13.json.

P14 verified ordinal 33, including its P6 clock merger. Remove 23 project-added
DOS7_CONFIG selectors and inactive alternatives; retain original COMMENTEDOUT
and locale branches. Correct displaced conversion and rollover comments. All
694 effective statements unchanged; no rebuild. Cumulative: 33/66 resolved;
31 modified (including 12 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 34, bios/msdioctl.asm; 33 remain. See source-quality-P14.json.

P15 verified ordinal 34. Remove 99 project DOS7_CONFIG selectors and unselected
DOS6 alternatives; document the two extended disk operations and their existing
shared check within the original IOCTL module. Correct BootIo buffer/register
comments. Historical M060 retry body remains verbatim and non-emitting. Net 482
lines removed; all 1007 effective statements unchanged, no rebuild. Cumulative:
34/66 resolved; 32 modified (including 12 retired by merge), 2 unchanged,
0 whole-file DOS6 identities. Next: ordinal 35, bios/msdisk.asm; 32 remain.
Evidence: source-quality-P15.json.

P16 verified ordinal 35. Remove 139 project DOS7_CONFIG selectors and inactive
DOS6 alternatives. Correct displaced SetDrive header and stale buffer/owner
comments; document extended disk interfaces within the original module. CHS and
extended transfers are distinct required capabilities; the short retry copies
remain to preserve emitted layout. Net 715 lines removed; all 1252 effective
statements unchanged, no rebuild. Cumulative: 35/66 resolved; 33 modified
(including 12 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 36, bios/msend.asm; 31 remain. Evidence: source-quality-P16.json.

P17 verified ordinal 36. Retain the original data/initialization end-marker
module; BCode_end already resides in biosmsg at its required earlier link
position. Correct the header and leftover blank lines only. All 13 effective
statements unchanged, no rebuild. Cumulative: 36/66 resolved; 34 modified
(including 12 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 37, bios/msinit.asm; 30 remain. Evidence: source-quality-P17.json.

P18 verified ordinal 37. Remove 243 project DOS7_CONFIG selectors and inactive
alternatives, one duplicate outchr external, and stale moved-code/interface
comments. Initialization-only extended reads remain in their original owner,
separate from resident disk services by lifetime and interface. Net 2656 lines
removed. All ordered non-EXTRN statements and the external declaration set are
unchanged; original empty conditional structures retained, no rebuild.
Cumulative: 37/66 resolved; 35 modified (including 12 retired by merge),
2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 38, bios/msint13.asm;
29 remain. Evidence: source-quality-P18.json.

P19 verified ordinal 38. Remove 43 project DOS7_CONFIG selectors and inactive
alternatives, obsolete HMAPtr header and stale buffer comments. Return displaced
INT 2F/move_sector headers to their procedures and normalize PUBLIC indentation.
Windows/HMA and extended-read recovery services remain in the original interrupt
module; they are necessary distinct interfaces, not replacement copies. Net 271
lines removed; all 1092 effective statements unchanged, no rebuild. Cumulative:
38/66 resolved; 36 modified (including 12 retired by merge), 2 unchanged,
0 whole-file DOS6 identities. Next: ordinal 39, bios/pathsrc.asm; 28 remain.
Evidence: source-quality-P19.json.

P20 verified ordinal 39. Retain the cohesive PATH helper module corresponding
to original DOS6 inc/path.asm; neighbouring log/EXEC modules are different owners.
Normalize tabs and add accurate procedure entry/exit comments; provenance lives
in the evidence. All 166 effective statements unchanged, no rebuild. Cumulative:
39/66 resolved; 37 modified (including 12 retired by merge), 2 unchanged,
0 whole-file DOS6 identities. Next: ordinal 40, bios/rapiopen.asm; 27 remain.
Evidence: source-quality-P20.json.

P21 verified ordinal 40. Registry API module has no DOS6 homolog; retain its
existing consolidation of fifteen related entries. Replace fifteen orphan
source/verification headers with one module contract and accurate per-procedure
stack-argument comments. Normalize indentation. Windows-provider/local dispatch
is a required runtime distinction; existing shared providers remain. All 1877
effective statements unchanged, no rebuild. Cumulative: 40/66 resolved;
38 modified (including 12 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 41, bios/regfind.asm; 26 remain. See source-quality-P21.json.

P22 verified ordinal 41. Consolidate stale fragment headers and document the
fourteen handle/file procedures at their definitions; normalize indentation.
Keep existing InvalidateRoot macro sharing and distinct key/file/HV ownership
operations within the one REGHANDLE unit. All 815 effective statements, macro
body and invocations unchanged; no rebuild. Cumulative: 41/66 resolved;
39 modified (including 12 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 42, bios/reginit.asm; 25 remain. See source-quality-P22.json.

P23 verified ordinal 42. Replace stale fragment headers with the REGINIT module
contract and all nine procedure interfaces; normalize indentation. Block, mount
and export operations already share one module and existing providers. Preserve
all 858 effective assembler statements, including cleanup paths and layout; no
rebuild. Cumulative: 42/66 resolved; 40 modified (including 12 retired by merge),
2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 43, bios/regopen.asm;
24 remain. Evidence: source-quality-P23.json.

P24 verified ordinal 43. Consolidate the REGKEYS module header, remove repeated
empty-data comments and document all twenty-one procedure interfaces. Correct
recursion-depth and additional-size descriptions. Shared search/allocation/cache
providers already avoid second implementations; overlap-safe moves and staged
record growth remain distinct required cases. All 3743 effective assembler
statements unchanged, no rebuild. Cumulative: 43/66 resolved; 41 modified
(including 12 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 44, bios/regread.asm; 23 remain. See source-quality-P24.json.

P25 verified ordinal 44. Replace fragment headers and repeated empty-data prose
with a module contract and twenty-eight procedure interfaces. Correct pathname
argument order and distinguish key-signature validation from header/data checksum
policy. Existing file/block ownership, cache retry and variable-size allocation
paths are distinct; shared writers, indexers and validators already consolidate
common work. All 3633 effective assembler statements unchanged, no rebuild.
Cumulative: 44/66 resolved; 42 modified (including 12 retired by merge),
2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 45, bios/regstart.asm;
22 remain. Evidence: source-quality-P25.json.

P26 verified ordinal 45. Consolidate root-lifetime headers and document nine
procedure contracts. Correct the no-argument ReloadSystem interface and Boolean
FlushAll return; distinguish reusable file buffers from descriptor/mount teardown.
System/user recovery and provider selection have required differences. All 1265
effective assembler statements unchanged, no rebuild. Cumulative: 45/66 resolved;
43 modified (including 12 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 46, bios/reqpkt.asm; 21 remain. See source-quality-P26.json.

P27 dependency unit admitted before edits: merge ordinal 46 reqpkt into the
end of stkinit (52), its immediately preceding SYSINITSEG contribution. Both
are SYSINIT storage/code derived from the original initialization owner; keep
the packet fields contiguous and deviceparameters after them. Existing BPB and
IOCTL includes in stkinit supply the structure. Remove its now-local external
and the reqpkt object/rules (59/60). Reassemble stkinit with original MASM,
link/relocate BIOS and compare full IO.SYS. Full stkinit review remains at 52.

P27 verified ordinal 46 including the P7 deviceparameters transfer. Retire the
small reqpkt object and append its contiguous storage to stkinit. Original MASM,
LINK and RELOC pass; linked BIOS and complete IO.SYS compare byte-for-byte.
No COMMAND.COM/MSDOS.SYS changes. Cumulative: 46/66 resolved; 44 modified
(including 13 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 47, bios/rqvalue.asm; 20 remain. See source-quality-P27.json.

P28 verified ordinal 47. Consolidate wrapper headers and document five entry
contracts; normalize indentation. Windows-provider argument ordering and local
core adaptation are distinct required paths within one shared wrapper module.
All 201 effective assembler statements unchanged, no rebuild. Cumulative:
47/66 resolved; 45 modified (including 13 retired by merge), 2 unchanged,
0 whole-file DOS6 identities. Next: ordinal 48, bios/config.lnk; 19 remain.
Evidence: source-quality-P28.json.

P29 verified ordinal 48. Retain the sole original-tool CONFIG link response:
87 unique objects, 44 local source/rule providers and 43 extracted CRT members.
Before edit it matched the accepted T11 input byte-for-byte. Normalize only its
90 line endings to DOS CRLF; ordered link tokens unchanged, no rebuild.
Cumulative: 48/66 resolved; 46 modified (including 13 retired by merge),
2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 49, bios/config.mak;
18 remain. Evidence: source-quality-P29.json.

P30 verified ordinal 49. Retain the sole native NMAKE CONFIG assembly rules;
44 unique targets match local link objects. Shared-source conditional variants
avoid duplicate implementations and emit distinct required contributions.
Normalize original-style heading, assignments, continuation indentation and CRLF.
All effective build records unchanged; no rebuild. Cumulative: 49/66 resolved;
47 modified (including 13 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 50, bios/si1tail.asm; 17 remain. See source-quality-P30.json.

P31 verified ordinal 50. Retain the late SYSINIT contribution because si2front
emits intervening CONFIG code between it and its original sysinit1 owner. Correct
orphan/obsolete buffer, communication-block and stack-default comments; normalize
added-code indentation. Original empty/locale branches remain. All 1828 effective
assembler statements unchanged; ParaRound and Taiwan OEM bodies also match DOS6
canonically. No rebuild. Cumulative: 50/66 resolved; 48 modified (including 13
retired by merge), 2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 51,
bios/si2front.asm; 16 remain. Evidence: source-quality-P31.json.

P32 verified ordinal 51. Retain the early CONFIG/menu/country contribution; its
original sysinit2 owner is separated by emitted contributions in the link order.
Remove one redundant external and two single-use encoding macros; repair moved
headers and changed-interface comments. Ordered effective non-EXTRN statements
and scoped external availability remain identical; four original helper bodies
match DOS6 canonically. No rebuild. Cumulative: 51/66 resolved; 49 modified
(including 13 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 52, bios/stkinit.asm; 15 remain. See source-quality-P32.json.

P33 verified ordinal 52, including its P27 storage merger. Keep the early stack
handler contribution; its common dispatcher and IRP already share the interrupt
logic. Remove 77 unused EXTRN lines and the unused partner of bios_flags, plus
unrelated copied revision history. All 291 non-EXTRN statements remain identical;
original conditional scaffolding retained. No rebuild. Cumulative: 52/66 resolved;
50 modified (including 13 retired by merge), 2 unchanged, 0 whole-file DOS6
identities. Next: ordinal 53, bios/ststate.asm; 14 remain. See source-quality-P33.json.

P34 verified ordinal 53, closing its P4/P8/P10 collateral reviews. Keep consolidated
early SYSINIT state; aliases intentionally share storage, and the original owner
is separated by tailstat bytes. Correct obsolete relocation/CDS/pass comments and
normalize indentation. All 193 statements and original empty STACKSW branch remain
unchanged; no rebuild. Cumulative: 53/66 resolved; 51 modified (including 13 retired
by merge), 2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 54, bios/sysconf.asm;
13 remain. Evidence: source-quality-P34.json.

P35 verified ordinal 54, closing its P6 CONFIG$ hook transfer. Keep device load,
configuration parsing and recording in their original sysconf owner. Shared parse
labels, allocation markers and record providers avoid second implementations;
target-required dispatch instructions remain. Correct misplaced/orphan headers,
obsolete pass/workspace/SWITCHES comments and document added interfaces. All 3875
effective statements unchanged; no rebuild. Cumulative: 54/66 resolved; 52 modified
(including 13 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 55, bios/sysimes.asm; 12 remain. See source-quality-P35.json.

P36 verified ordinal 55. Remove the unselected DOS6 message alternative and
DOS7_CONFIG wrapper; keep indexed SYSINIT resources in the original message
module with its language include. All effective selected statements unchanged;
no rebuild. Cumulative: 55/66 resolved; 53 modified (including 13 retired by merge),
2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 56, bios/sysinit1.asm;
11 remain. Evidence: source-quality-P36.json.

P37 verified ordinal 56, closing the P11 relocation transfer. Keep initialization,
DOS/BIOS relocation and DRIVPARM in the original owner. Expand one single-use
encoding macro; correct orphan headers and changed interfaces, normalize added
indentation. All 2232 effective statements unchanged after expansion; three original
HMA/VDISK helpers match DOS6 canonically. No rebuild. Cumulative: 56/66 resolved;
54 modified (including 13 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 57, bios/sysinit2.asm; 10 remain. See source-quality-P37.json.

P38 verified ordinal 57. Keep startup options, default-driver dispatch and shell
selection in sysinit2, reusing the shared CONFIG/menu/environment providers.
Remove 85 unused external names, a single-use encoding macro and displaced headers;
correct interface comments and normalize indentation. All 2469 non-EXTRN effective
statements remain identical after expansion; no rebuild. Cumulative: 57/66 resolved;
55 modified (including 13 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 58, bios/tailstat.asm; 9 remain. See source-quality-P38.json.
P39 dependency unit admitted at ordinal 58: append tailstat's five state fields
to the adjacent preceding ststate SYSINIT contribution. Both contributions use
byte alignment; all field order and names remain. This is a bounded collateral
addition to the already reviewed state owner, not a second full-file audit.
Remove tailstat from msbio.lnk/makefile (59/60), reassemble ststate only, relink
BIOS and compare complete IO.SYS. Record the final state-owner hash and close
the transfer after binary verification. Full link/make reviews remain 59/60.

P39 verified ordinals 58-59. Retire tailstat into adjacent ststate; its five fields
retain byte order/alignment. Original MASM, LINK and RELOC pass; linked BIOS and
complete IO.SYS compare byte-for-byte with accepted outputs. Other two cores
unchanged. Full msbio.lnk review closes all link-input transfers; its native response
contains 27 unique source-backed objects. Cumulative: 59/66 resolved; 57 modified
(including 14 retired by merge), 2 unchanged, 0 whole-file DOS6 identities.
Next: ordinal 60, bios/makefile; 7 remain. Evidence: source-quality-P39.json.

P40 verified ordinal 60, closing all pending makefile transfers. Restore DOS6-style
per-object dependency lists from recursive INCLUDE closure, track language resources
and generated message classes, and remove generic/duplicate dependency lines.
Recipes, flags and link order unchanged. Original NMAKE /N all passes without
compiling. Cumulative: 60/66 resolved; 58 modified (including 14 retired by merge),
2 unchanged, 0 whole-file DOS6 identities. Next: ordinal 61, cmd/command/buildmsg.c;
6 remain. Evidence: source-quality-P40.json.

P41 verified ordinals 61-63. Retain buildmsg unchanged: its only DOS6 deviations
are the valid C comment header and required DOS7 message-class encoding. Keep two
minimal resource entries sharing language INCLUDEs; each needs an independent
resource origin/map. Normalize their directive indentation and CRLF only; no
rebuild. Cumulative: 63/66 resolved; 60 modified (including 14 retired by merge),
3 unchanged, 0 whole-file DOS6 identities. Next: ordinal 64, cmd/command/makefile;
3 remain. Evidence: source-quality-P41.json.


### T12 S1 P42 — ordinal 64

COMMAND makefile uses DOS6-style formatting and complete source dependencies; commands, flags and object order unchanged. Native NMAKE /N passed; no compilation. Progress: 64/66, modified 61, unchanged 3, DOS6 whole-file exact 0, retired by merge 14. Next: 65 dos/makefile.


### T12 S1 P43 — ordinals 65–66

Kernel makefile: normalized eight added dependency rules; original commands and conditional branches retained. Native NMAKE /N msdos.sys passed. MSDOS configuration text retained unchanged and FC /B equals published MSDOS.SYS. No instruction changes or rebuild. Progress: 66/66, modified 62, unchanged 4, DOS6 whole-file exact 0, retired by merge 14. Separate completion audit remains.


### T12 completion audit

Closed against the fixed 66-file universe: modified 62, unchanged 4, DOS6 whole-file exact 0; 14 of 37 added files merged away, 23 retained with recorded reasons. All 52 retained file hashes match the ledger, all 14 retired paths are absent, all 43 evidence records parse, and no collateral full-file reviews remain pending. Native makefile dry runs and scoped git diff checks pass. Direct FC /B confirms all three published outputs and latest P39 IO.SYS equal fixed targets. Final edits do not change instructions or recipes, so no additional rebuild. Frozen dependency lists are historical admission data, not live build inputs. The earlier ststate/tailstat separation rationale is superseded: retained consolidated state ownership is an organizational decision, not a byte-layout impossibility. No open transfers or active S remain.
