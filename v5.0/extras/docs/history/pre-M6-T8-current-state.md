# Current state

The owner-directed layout migration moved project-added tools, tests, build
outputs, research and governance under `extras/`. The source trees remain in
the DOS 6-style top-level layout. Fresh `extras/build/integrated-source-l6_84v2s`
matched all three retained targets; `../etc/evidence/extras-migration-inputs.json`
records the build-input checks. Historical absolute paths in older evidence
refer to their pre-migration locations.

M4 T5 S2 is [closed](../history/M4-T5-S2-ordered-review-audit.md) for the
owner-directed ordered review and target build checks. T5 is [closed](../history/M4-T5-completion-audit.md);
M4 is [closed](../history/M4-milestone-audit.md); the full project goal remains
open pending its separate audit.
S1 is [closed](../history/M4-T5-S1-baseline-audit.md) with a clean local build.
T4 is closed; see [audit](../history/M3-T4-completion-audit.md).
The full project goal remains active.

Owner-directed second-class conversion review: 48 entries frozen in
`../etc/round2-to-round1-ledger.json`, all forty-eight reviewed: twenty-eight retained in round 2 and twenty converted to round 1;
none pending. Index 209 `inc/VERSIONA.INC` retains DOS 5 version values without
the OpenNT version constant; see `../etc/evidence/round2-to-round1-209-versiona.json`. Index 198 `inc/origin.inc`
retains the target origin formula without OpenNT adjustment or DOS 6 ROMDOS
branch; see `../etc/evidence/round2-to-round1-198-origin.json`. Index 196 `inc/mshead.asm`
retains DOS 5 startup structure without OpenNT port history or DOS 6 ROMDOS
conditionals; see `../etc/evidence/round2-to-round1-196-mshead.json`. Index 188 `inc/lmstub.asm`
retains its layout guard and avoids DOS 6 ROM-specific definitions and OpenNT
host services; see `../etc/evidence/round2-to-round1-188-lmstub.json`. Index 187 `inc/ioctl.inc` now
matches the DOS 6 reference byte for byte; fresh `integrated-source-t61pmujw`
matches all three targets. See `../etc/evidence/round2-to-round1-187-ioctl.json`. Index 4 `bios/config.inc`
cannot use the only same-name DOS 6 reference without adding later menu and
configuration definitions; see `../etc/evidence/round2-to-round1-004-config.json`.
Fresh `integrated-source-6xx55x_4` matched all three targets and recorded
DOSBox adjacent DLL observations before and after the build.
Index 21 `bios/inc/mult.inc` had four later-version comment lines removed;
its 12 code lines are unchanged and its complete references were unsuitable
for exact replacement. Fresh `integrated-source-ter5ziru` matched all three
targets; see `../etc/evidence/round2-to-round1-021-mult.json`.
Index 30 `bios/inc/version.inc` retains DOS 5 build switches; DOS 6 adds
DoubleSpace and OpenNT omits CONFIGPROC. All seven same-name references were
checked; see `../etc/evidence/round2-to-round1-030-version.json`.
Index 33 `bios/msbio2.asm` retains the target install_bds return sequence;
DOS 6 adds EOT-update instructions at that point. See
`../etc/evidence/round2-to-round1-033-msbio2.json`.
Index 38 `bios/msend.asm` now matches DOS 6 byte for byte after restoring its
copyright comment and EOF format; fresh `integrated-source-y4jsf_6e` matches
all three targets. See `../etc/evidence/round2-to-round1-038-msend.json`.
Index 41 `bios/msinit.asm` retains target code without DOS 6 startup-message
and COMPAQ mode-2 additions; the OpenNT BIOS reference includes host-service
headers. See `../etc/evidence/round2-to-round1-041-msinit.json`.
Index 57 `dos/create.asm` now matches DOS 6 byte for byte, including its
original `Sest_EXT_mode` comment typo (actual procedure `Set_EXT_mode`). Fresh
`integrated-source-oyoglh1o` matches the targets; see
`../etc/evidence/round2-to-round1-057-create.json`.
Index 58 `dos/crit.asm` now matches DOS 6 exactly after restoring EOF bytes;
fresh `integrated-source-36swpxl_` matches all targets. See
`../etc/evidence/round2-to-round1-058-crit.json`.
Index 60 `dos/dev.asm` now matches DOS 6, including two unused declarations
and its original comment wording. Its object hash changed, while fresh
`integrated-source-c6u2zvuk` matches all three targets. See
`../etc/evidence/round2-to-round1-060-dev.json`.
Index 63 `dos/dir2.asm` matches DOS 6 including its disabled legacy branch;
fresh `integrated-source-ghfz0jh4` matches all three targets. See
`../etc/evidence/round2-to-round1-063-dir2.json`.
Index 66 `dos/disk2.asm` matches DOS 6 after restoring its original comment
spelling; fresh `integrated-source-ack8p0_u` matches all three targets. See
`../etc/evidence/round2-to-round1-066-disk2.json`.
Index 72 `dos/dostab.asm` matches DOS 6 after restoring comments and
formatting; fresh `integrated-source-7k0a35qi` matches all three targets. See
`../etc/evidence/round2-to-round1-072-dostab.json`.
Index 76 `dos/fcb.asm` matches DOS 6 after restoring copyright and EOF
formatting; fresh `integrated-source-3jwsdhtq` matches all targets. See
`../etc/evidence/round2-to-round1-076-fcb.json`.
Index 88 `dos/macro2.asm` stays in round 2: DOS 6 adds a 1992 CD-ROM scan
workaround in place of the target direct call. See
`../etc/evidence/round2-to-round1-088-macro2.json`.
Index 89 `dos/misc.asm` stays in round 2; DOS 6 adds FAT overflow checks
dated July 1992, and OpenNT uses host services. See
`../etc/evidence/round2-to-round1-089-misc.json`.
Index 93 `dos/msconst.asm` matches DOS 6. Its 6Ah SYSINITVAR layout guard
moved to integrated linked-map validation; fresh `integrated-source-zz1z55_k`
passes that guard and all three target comparisons. See
`../etc/evidence/round2-to-round1-093-msconst.json`.
Index 94 `dos/msctrlc.asm` matches DOS 6 after restoring the reference
comment spelling; fresh `integrated-source-nc6nm5xl` matches the targets.
See `../etc/evidence/round2-to-round1-094-msctrlc.json`.
Index 95 `dos/msdata.asm` remains round 2: DOS 6 includes a 1992/1993
Magicdrv patch module and OpenNT includes BOP support. See
`../etc/evidence/round2-to-round1-095-msdata.json`.
Index 101 `dos/mstable.asm` remains round 2: DOS 6 adds a ROM_EXCLUDE
table entry without a corresponding current implementation. See
`../etc/evidence/round2-to-round1-101-mstable.json`.
Index 102 `dos/open.asm` matches DOS 6 after restoring its procedure heading;
fresh `integrated-source-4hzlmm31` matches all three targets. See
`../etc/evidence/round2-to-round1-102-open.json`.
Index 107 `dos/rom.asm` remains round 2; DOS 6 adds 1992 compression
patches and changes FAT release behavior. See
`../etc/evidence/round2-to-round1-107-rom.json`.
Index 110 `dos/segcheck.asm` matches DOS 6 after copyright and formatting
alignment; fresh `integrated-source-vkbnk0_8` matches all targets. See
`../etc/evidence/round2-to-round1-110-segcheck.json`.
Index 116 `cmd/command/comequ.asm` remains round 2: DOS 6 adds 1993
constants and OpenNT expands a path constant specifically for NTVDM. See
`../etc/evidence/round2-to-round1-116-comequ.json`.
Index 117 `cmd/command/command1.asm` matches DOS 6 after removing an unused
envdata include; INIT retains its include. The envdata header was corrected during its ordered review. Fresh
`integrated-source-jebmrgwo` matches targets; see
`../etc/evidence/round2-to-round1-117-command1.json`.
Index 118 `cmd/command/command2.asm` remains round 2: DOS 6 differs in
environment ownership and ROM loading, while OpenNT adds later handle logic.
See `../etc/evidence/round2-to-round1-118-command2.json`.
Index 126 `cmd/command/envdata.asm` remains round 2; its header now reflects
the INIT include. Fresh `integrated-source-dcbur83p` matches the targets.
See `../etc/evidence/round2-to-round1-126-envdata.json`.
Index 129 `cmd/command/init.asm` remains round 2 due to substantive DOS 6
startup changes and OpenNT host services. See
`../etc/evidence/round2-to-round1-129-init.json`.
Index 131 `cmd/command/loadhi.asm` retains accurate command-tail parameter
comments; OpenNT describes 80h where code copies to 81h. DOS 6 adds /L.
See `../etc/evidence/round2-to-round1-131-loadhi.json`.
Index 133 `cmd/command/path1.asm` matches DOS 6 after EOF alignment; fresh
`integrated-source-p36t4oy1` matches all targets. See
`../etc/evidence/round2-to-round1-133-path1.json`.
Index 135 `cmd/command/rdata.asm` remains round 2; DOS 6 has 1992 data
changes and OpenNT adds host state and services. See
`../etc/evidence/round2-to-round1-135-rdata.json`.
Index 137 `cmd/command/rucode.asm` remains round 2; target state query uses
5500h, whereas OpenNT uses 5501h and DOS 6 adds ROM branches. See
`../etc/evidence/round2-to-round1-137-rucode.json`.
Index 138 `cmd/command/stub.asm` remains round 2: DOS 6 and OpenNT change
EXEC/A20 paths; target EXEC bytes were rechecked. See
`../etc/evidence/round2-to-round1-138-stub.json`.
Index 142 `cmd/command/tcmd1b.asm` matches DOS 6 after EOF alignment; fresh
`integrated-source-bktbemw2` matches all targets. See
`../etc/evidence/round2-to-round1-142-tcmd1b.json`.
Index 143 `cmd/command/tcmd2a.asm` matches DOS 6 after line-ending and EOF
alignment; fresh `integrated-source-k59k6k_5` matches all targets. See
`../etc/evidence/round2-to-round1-143-tcmd2a.json`.
Index 144 `cmd/command/tcmd2b.asm` matches DOS 6 after EOF alignment; fresh
`integrated-source-w89ln5jt` matches all targets. See
`../etc/evidence/round2-to-round1-144-tcmd2b.json`.
Index 145 `cmd/command/tcode.asm` remains round 2: target MOV SI,-1
differs from DOS 6 SEMIPERMCOM and OpenNT adds host services. See
`../etc/evidence/round2-to-round1-145-tcode.json`.
Index 146 `cmd/command/tdata.asm` remains round 2: DOS 6 adds DoubleSpace
tables and OpenNT adds a host-specific command table. See
`../etc/evidence/round2-to-round1-146-tdata.json`.
Index 147 `cmd/command/tenv.asm` matches DOS 6 after removing an unused
public export and aligning EOF; fresh `integrated-source-ye1qp0mo` matches
all targets. See `../etc/evidence/round2-to-round1-147-tenv.json`.
Index 150 `cmd/command/tmisc1.asm` remains round 2: DOS 6 adds ROM paths
and OpenNT adds BOP-provided execution paths. See
`../etc/evidence/round2-to-round1-150-tmisc1.json`.
Index 155 `cmd/command/tranmsg.asm` remains round 2: DOS 6 adds messages
and OpenNT changes version substitution width. See
`../etc/evidence/round2-to-round1-155-tranmsg.json`.
Index 156 `cmd/command/tspc.asm` remains round 2: DOS 6 adds compressed
volume workspace, and OpenNT adds host state and path expansion. See
`../etc/evidence/round2-to-round1-156-tspc.json`.
Index 165 `inc/const2.asm` matches DOS 6 after comment and EOF alignment;
fresh `integrated-source-19x67y0z` matches all targets. See
`../etc/evidence/round2-to-round1-165-const2.json`.
Index 174 `inc/dosmac.INC` remains round 2: DOS 6 changes GETDSEG under
ROMDOS and OpenNT disables critical calls and adds host-service macros. See
`../etc/evidence/round2-to-round1-174-dosmac.json`.

The latest build, retained `O:/DOS` files and historical original-image extraction
hashes were cross-checked without mounting media; the original image path is
currently unavailable, so extraction was not repeated. See
`../etc/evidence/latest-build-historical-image-chain.json`.

Nine active non-code build resources are tracked in
`../etc/resource-review-ledger.json`; all 9 reviewed, no pending entries.
The IBM message source matches OpenNT; its BOOT input and transformation are
verified in `../etc/evidence/resource-review-009-usa-ibm.json`.
The COMMAND message source differs from OpenNT only by removing its `.500`
version suffix; see `../etc/evidence/resource-review-008-usa-ms.json`.
The BIOS/kernel message source matches OpenNT apart from an inferred optional
POWER entry and index adjustments; see `../etc/evidence/resource-review-007-usa-ms-dos.json`.
The COMMAND link file matches OpenNT, with 34 modules in the verified order;
see `../etc/evidence/resource-review-006-command-lnk.json`.
The COMMAND message template matches OpenNT and its five generated classes were
checked; see `../etc/evidence/resource-review-005-command-skl.json`.
The kernel link response now follows DOS 6 formatting with 55 target units
unchanged; `integrated-source-o1gc1cvu` matches all three retained targets. See
`../etc/evidence/resource-review-004-msdos-lnk.json`.
The kernel message skeleton matches DOS 6 and OpenNT, with generated classes
checked; see `../etc/evidence/resource-review-003-msdos-skl.json`.
The BIOS link list retains 14 units in the verified order; see
`../etc/evidence/resource-review-002-msbio-lnk.json`.

A read-only host dependency inventory found DOSBox imports adjacent SDL.dll
and SDL_net.dll. Their current hashes and recursive adjacent PE imports are
recorded in `../etc/evidence/host-build-dependencies-current.json`; historical
build-time DLL hashes, dynamic loads and system dependency closure remain
unproven. Run `python tools/audit_host_build_dependencies.py` to repeat it.

File 214 `messages/comimsg.inc` passed ordered review with the DOS 5
version banner retained. Fourteen message records and the help pointer table
were checked against COMMAND.COM; see `../etc/evidence/file-review-214-comimsg.json`.
The frozen file ledger has no pending entries. Its references and lexical
NT/BOP screen were rechecked in `../etc/evidence/file-review-final-ledger-audit.json`;
364 recorded build inputs and all three targets were verified against stage
`integrated-source-fu7ucnox`. These checks do not prove historical source origin
or exclude every indirect host dependency.

File 161 `inc/bdsize.inc` passed ordered review without source edits. Its
three target-specific sizes match the current link maps and produce PARASTART
3DD0h; the line format matches DOS 6/OpenNT. See
`../etc/evidence/file-review-161-bdsize.json`.

File 158 `cmd/command/uinit.asm` passed ordered review; the owner confirmed
retaining target switch count 7 (DOS 4 has 6; DOS 6 and OpenNT have 8).
The seven target pointers and names were verified. Fresh
`integrated-source-fu7ucnox` matches all three targets and 104 previous
objects. See `../etc/evidence/file-review-158-uinit.json`.

File 145 `cmd/command/tcode.asm` had its single-command sentinel formatted
exactly as DOS 4; all 421 code lines now have reference coverage. Fresh
`integrated-source-w8u1eo8f` matches the three targets and 104 prior objects.
See `../etc/evidence/file-review-145-tcode.json`.

File 137 `cmd/command/rucode.asm` passed ordered review without source edits;
all 669 code lines have reference coverage, and the state-query target
instruction matches COMMAND.COM. It moved to round 2; see
`../etc/evidence/file-review-137-rucode.json`.

File 129 `cmd/command/init.asm` had 48 matching lines formatted as DOS 6 and
three unused NT /Z macros removed. The remaining 1,326 code lines have
reference coverage, including individually checked lines and a shared DOS 6
constant; it moved to round 2. Fresh `integrated-source-supw6_vo` matches all
three targets and all 104 prior object hashes. See
`../etc/evidence/file-review-129-init.json`.

File 99 `dos/msproc.asm` had three critical-section macro arguments aligned
to DOS 6. Fresh `integrated-source-2049f0u1` matches all three targets;
MSPROC.OBJ changed, while 103 others did not. DEBUG assembled and linked.
Target-specific PSP threshold and DEBUG jump are retained; see
`../etc/evidence/file-review-099-msproc.json`.

File 98 `dos/msinit.asm` had 69 whitespace alignments and two equivalent DPB
operand lines aligned to DOS 6. Fresh `integrated-source-03ox03fq` matches
all three targets and 104 prior object hashes; a 56-module DEBUG build also
linked. Remaining DEBUG export differences are recorded in
`../etc/evidence/file-review-098-msinit.json`.

File 89 `dos/misc.asm` had Get-DPB critical-section formatting aligned to
DOS 6; all 347 current code lines now match in order and it moved to automatic
round 2. Fresh `integrated-source-edz4fx2u` matches all three targets; MISC
object hash changed while 103 other object hashes did not. Get-DPB/FAT
call-chain checks were rerun. See `../etc/evidence/file-review-089-misc.json`.

File 88 `dos/macro2.asm` had its direct CheckThisDevice call aligned exactly
to DOS 4/OpenNT formatting. Full code is now covered by reference passages
and it moved to automatic round 2. Fresh `integrated-source-8rcljo6i`
matched the three retained targets and all 104 previous object hashes. See
`../etc/evidence/file-review-088-macro2.json`.

File 68 `dos/diskread.asm` was an unlinked duplicate recovery slice; its two
procedures already reside in `dos/disk.asm`. It was preserved under
`research/dos/diskread.final-slice.asm` and removed from the production tree,
retaining ledger index 68. Fresh `integrated-source-fralw1o7` matches all
three targets and all 104 previous object hashes. See
`../etc/evidence/file-review-068-diskread.json`.

File 67 `dos/disk3.asm` passed ordered review without source edits. DLJC
retains DEBUG compatibility and release target bytes; the DWRITE path has a
DOS 4 reference and differs from DOS 6 compressed-volume code. See
`../etc/evidence/file-review-067-disk3.json`.

File 65 `dos/disk.asm` passed ordered review. Its only uncovered statement is
DLJZ, needed for DEBUG long-branch expansion while matching target release JZ;
see `../etc/evidence/file-review-065-disk.json`.

Owner directed DOS 6/4 formatting alignment for all third-round files and
reclassification when eligible. `dos/close.asm` now matches DOS 6 byte for
byte; `dos/create.asm` initially matched DOS 6 code in order with a corrected
procedure comment; later it was aligned to the full DOS 6 reference. Both
moved to automatic classes with earlier manual evidence retained. `bios/sysconf.asm` and `bios/sysinit2.asm` also had matching lines
aligned; their remaining target-specific code keeps them in manual review.
Build `integrated-source-u2mbtijk` matches all target files and 104 prior
object hashes. The ordered third-round review is complete; whitespace-only candidate counts
were treated as leads, not full coverage.

File 57 `dos/create.asm` passed ordered review without source edits; the
three unmatched statements correspond to DOS 4/6 references, and six target
call destinations were checked. See `../etc/evidence/file-review-057-create.json`.

File 54 `dos/close.asm` passed ordered review without source edits; the
unmatched macro differs from DOS 6 only in case and whitespace, and five
linked commit-path calls were checked in MSDOS.SYS. See
`../etc/evidence/file-review-054-close.json`.

File 53 `dos/buf.asm` was reviewed; comments now describe the target HMA
carry behavior. The HMA path shifts after restoring read flags, unlike DOS 6;
reachability and runtime effects remain unverified. Fresh
`integrated-source-m1_2507r` matches all three retained targets and all 104
preceding object hashes. See `../etc/evidence/file-review-053-buf.json`.

File 50 `bios/sysinit2.asm` passed ordered review and the NT/BOP lexical
screen without source edits. All 15 unmatched code lines were assessed and
nine selected target instruction/data sites checked; see
`../etc/evidence/file-review-050-sysinit2.json`.

Owner clarification: every review round must also screen for NT/NTVDM, BOP
and known post-DOS-5 features, including files matching reference source. The
215-file lexical scan found no listed indicators; see
`../etc/evidence/file-review-nt-bop-scan.json`. The latest three target files
contain no raw C4 C4 sequence; see
`../etc/evidence/m6-bop-refresh-3qm3v2jp.json`. These screens are not proof
that indirect host dependencies or all later-version code are absent.
Qualification and status tools enforce the lexical screen; no file remains
pending in the frozen ledger.

File 49 `bios/sysinit1.asm` passed ordered review without source edits; all
14 code lines left unmatched by the automatic pass were assessed and eight
selected target instructions checked. See
`../etc/evidence/file-review-049-sysinit1.json`.

File 48 `bios/sysimes.asm` passed ordered review without source edits. Its
active statements match OpenNT after whitespace normalization, and all 15
initialization messages match the retained IO.SYS; see
`../etc/evidence/file-review-048-sysimes.json`.

File 47 `bios/sysconf.asm` passed its ordered review without source edits.
Nine previously unmatched lines were individually assessed against the
references and retained IO.SYS; see
`../etc/evidence/file-review-047-sysconf.json`.

Owner-directed file review: of 215 original code/include entries, 14 were manually
reviewed, 171 qualified by byte identity, 29 qualified by complete matching
code passages (including individually verified reference lines), and one
duplicate was archived. None remains pending. See
[ledger](../etc/file-review-ledger.json), [standard](../design/FILE-REVIEW.md),
[automatic evidence](../etc/evidence/file-review-automatic-rounds.json), and
`python tools/file_review_status.py`. Automated textual qualification does not
prove historical origin or all configurations.

DIR2 and MSINIT no longer contain two unused declarations left by removed
OpenNT services or DIR2's unused NT-only range labels. Fresh
`integrated-source-3qm3v2jp` matches all three retained target files; 102 of
104 object hashes match the previous build, with DIR2 and MSINIT objects
changed. See `../etc/evidence/m6-kernel-unused-nt-declarations-integrated-audit.json`.
A separate 56-module DEBUG kernel assembled and linked; see
`../etc/evidence/m6-debug-kernel-3qm3v2jp.json`. Other configurations and
DEBUG runtime are not established.

The integrated build now enforces the existing 12 pinned prerequisite checks
before creating a stage. A missing-tools test failed before stage creation;
`integrated-source-bpcgk0yb` passed the checks and reproduced all three target
files, with all 104 object hashes unchanged. See
`../etc/evidence/m6-integrated-preflight-build-audit.json`. Its 365 recorded
input/resource checks are in
`../etc/evidence/m6-current-build-input-manifest-bpcgk0yb.json`. Standalone
component scripts and changes between check and use are not covered.

The Get-DPB/FAT target audit now checks 16 near-call sites and four
conditional branches in retained MSDOS.SYS, including critical-section,
media-device, buffer and error paths. The checks compare current source to
the build snapshot, inspect MASM listings and link symbols, and decode the
target instructions. This is static evidence only; see
`../etc/evidence/m6-getdpb-callchain-expanded-9y047lqr-v2.json`.

LOADHIGH procedure comments now describe the actual filename error register,
ES requirement, and command-tail data and length offsets. This is an
evidence-based correction, not a claim of original DOS 5 wording. Fresh
`integrated-source-9y047lqr` matches all three retained targets and all 104
object hashes match the preceding build; see
`../etc/evidence/m6-loadhi-parameter-comments-integrated-audit.json`.

TCODE has 19 matching lines aligned to the DOS 6 formatting; target-specific
instructions remain unchanged. Fresh `integrated-source-0du4hovg` matches
all three retained target files and all 104 preceding object hashes. See
`../etc/evidence/m6-tcode-format-integrated-audit.json` and its source audit.
This does not establish exact original DOS 5 formatting.

The DEV and FCB revision-history blocks were restored from DOS 6; their
1988 entries also appear in DOS 4, and the FCB M048 change is reflected in
the retained code. Original DOS 5 comment text remains unproven. Fresh
`integrated-source-vtgj6004` matches all three retained target files and all
104 object hashes match the preceding build; see
`../etc/evidence/m6-dev-fcb-revision-history-integrated-audit.json`.

Latest COMMAND style cleanup: `cmd/command/tcode.asm` no longer carries unused
module-local declarations left by removed OpenNT paths, and `rdata.asm` no
longer contains an orphaned NT-only comment. The removed lines are recorded
in `../etc/evidence/m6-command-unused-nt-declarations-source-audit.json`.
Fresh integrated build `integrated-source-_xw404l3` matches all three retained
`O:\DOS` files byte for byte; 103 of 104 object hashes match the previous
build, while TCODE.OBJ changed. See
`../etc/evidence/m6-command-unused-nt-declarations-integrated-audit.json`.
This confirms the selected build configuration, not every conditional build
or the exact historical DOS 5 source. Module-by-module style review remains
open.

The latest default-build stage has 365 recorded input/resource hash checks,
including the BUILDIDX BOOT-message transformation; scope and limitations are
in `../etc/evidence/m6-current-build-input-manifest-yg_ur1m0.json`.

BIOS disk IOCTL dispatch has 17 linked entries and 11 supported function
codes checked against the retained IO.SYS. See
`../etc/evidence/m6-bios-ioctl-tables-yg_ur1m0.json`.

The four BIOS character-device dispatch tables have 58 entries checked
against the current MASM listing, link map and retained IO.SYS. See
`../etc/evidence/m6-bios-character-tables-yg_ur1m0.json`.

The current linked-module ledger records six partial DOS 4 BIOS references
for three differently split modules; named routine anchors and limits are in
`../etc/evidence/m6-dos4-bios-partial-mapping-audit.json`.

The latest `integrated-source-yg_ur1m0` build uses existing DLJ macros in
three DEBUG-sensitive branches. Both default and DEBUG objects and linked
outputs remain unchanged; see
`../etc/evidence/m6-debug-longjump-macro-integrated-audit.json`.

The DEBUG build now records and checks staged sources, 46 shared includes,
message hashes, tools and link order; a third fresh build matches prior DEBUG
objects. See `../etc/evidence/m6-debug-source-closure-audit.json`.

The latest `integrated-source-ze2xg22l` build retains exact default targets
while a separate DEBUG kernel now assembles and links in two fresh stages.
The DEBUG-only adaptations and DOS 6 DOSPRINT provenance are recorded in
`../etc/evidence/m6-debug-kernel-integrated-audit.json`.

The latest `integrated-source-wkje_tyj` build restores DEBUG-conditional DPB,
SFT and buffer checks in SEGCheck. The DEBUG module assembles independently;
all 104 default-build objects and target files are unchanged. See
`../etc/evidence/m6-segcheck-debug-integrated-audit.json`.

Seven Get-DPB, media-check and FAT-buffer near-call edges are checked against
the retained MSDOS.SYS and the latest linked map. Buffer access is conditional
on the media and device path; this is static evidence only. See
`../etc/evidence/m6-getdpb-target-callchain-ubztdfh5.json`.

The latest `integrated-source-ubztdfh5` build aligns 32 initialization
source lines to DOS 6 indentation; all 104 objects and target files remain
unchanged. See `../etc/evidence/m6-msinit-indent-followup-integrated-audit.json`.

The latest `integrated-source-isk4k52y` build restores DOS 4/6 SFT lock
names in MKNODE; only its object hash changes and all three target files
remain identical. See `../etc/evidence/m6-sft-mknode-integrated-audit.json`.

The latest `integrated-source-l7crcwdj` build restores DOS 4/6 `critSFT`
arguments at three kernel call sites. Three object hashes change as their
external symbol names change, but linked alias addresses and all target files
remain identical; see `../etc/evidence/m6-sft-critical-name-integrated-audit.json`.

The pinned isolated build launcher was reproduced byte-for-byte from source
using GCC 16.1.0 and a fixed PE timestamp, without executing the new binary.
See `../etc/evidence/m6-isolated-launcher-reproducible-audit.json`.

DOS 4 linked data and message wrappers are mapped from `src/INC` to their
current kernel counterparts; link and NAME evidence is recorded in
`../etc/evidence/m6-dos4-inc-module-mapping-audit.json`.

DOS 4 `MS_TABLE.ASM` is now mapped to `dos/mstable.asm`. All 48 target
dispatch addresses match the linked symbols; DOS 4 differs at slot 47 and
DOS 6 has the same 48 names. See
`../etc/evidence/m6-mstable-dos4-dispatch-audit.json` and current triage
`../etc/evidence/m6-module-difference-triage-z7rpjine.json`.

The latest `integrated-source-z7rpjine` build restores two shared IOCTL
structures and removes an unused NT version constant; all 104 objects and
three target files remain unchanged. See
`../etc/evidence/m6-ioctl-structure-recovery-integrated-audit.json`.

The latest `integrated-source-sy8ny4ls` build verifies configurable historical
tool and DOSBox paths, with isolation checks retained. All 104 objects and
three target files remain unchanged; see
`../etc/evidence/m6-configurable-build-tools-integrated-audit.json`.

The latest `integrated-source-w2epwjzh` build derives the DOS code origin
from current BIOS/DOS segment sizes using the DOS 6 formula and checks the
sizes against fresh link maps. Unused NT SFT padding was removed; all 104
objects and three target files remain unchanged. See
`../etc/evidence/m6-origin-formula-integrated-audit.json`.

The latest `integrated-source-wmrq7msr` build corrects seven kernel procedure
comment titles; all 104 objects and three target files remain unchanged. See
`../etc/evidence/m6-kernel-procedure-title-integrated-audit.json`.

The latest `integrated-source-kqk0z_r6` build removes two orphan DOS 6
procedure descriptions and a Chicago-specific BIOS include comment; all
104 objects and three target files remain unchanged. See
`../etc/evidence/m6-bios-orphan-comments-integrated-audit.json`.

The latest `integrated-source-besftgsc` build corrects an EXEC return comment
to match target instructions; 104 objects and all target files remain unchanged.
The apparent AL/error-message issue is a static finding in
`../etc/evidence/m6-command-exec-error-register-audit.json`.

The latest `integrated-source-g9jd3rk3` build verifies the message-retriever
failure register contract and DOS-style COMMAND declarations; all 104 objects
and three target files remain unchanged. See
`../etc/evidence/m6-command-message-contract-style-audit.json`.

Current 104-module reference and line-difference triage is recorded in
`../etc/evidence/m6-module-difference-triage-2tgrct2k-v2.json`; classification
is a review aid and does not establish source origin or completed style review.

The latest `integrated-source-2tgrct2k` build restores the historical parser
listing control and DOS 6 declaration formatting; 104 objects and all target
files remain unchanged. Listing coverage is qualified in
`../etc/evidence/m6-command-parse-listing-style-audit.json`.

The latest `integrated-source-ca8orzet` build verifies removal of a stale NT
dispatch-table comment and DOS 6 formatting in `dos/mstable.asm`; all 104
objects and all three target files remain unchanged. The historical comment
and retained unsupported-slot `NO_OP` are recorded in
`../etc/evidence/m6-mstable-nt-comment-style-audit.json`.

The latest `integrated-source-c492_cis` build verifies DOS 4/6-aligned
formatting at the drive-letter check in `cmd/command/path1.asm`; all 104
objects and all three target files remain unchanged. See
`../etc/evidence/m6-path1-reference-style-audit.json`.


Latest directory and build update: the verified kernel sources are now in
`dos/`, with shared includes in `inc/`; the earlier investigation tree is in
`research/dos/`. The integrated build `integrated-source-ys1fvqqh` matches
the three retained targets and `O:\DOS`, and all 104 component objects match
the preceding build. See `../etc/evidence/m6-root-dos-layout-integrated-audit.json`.
The subsequent `integrated-source-_s02tndz` build verifies the DOS 6-style
`inc/mshead.asm` disk-entry comment restoration; see
`../etc/evidence/m6-mshead-disk-entry-comment-audit.json`.
The latest `integrated-source-ldhe6gv0` build verifies removal of NT porting
comments in six modules; their history and all object comparisons are recorded
in `../etc/evidence/m6-nt-port-comment-integrated-audit.json`.
The latest `integrated-source-dujc14oi` build verifies the replacement of the
NTDOS makefile with a wrapper for the current three-file build; original NT
makefiles are preserved in `research/dos/`. The recipe was executed directly
from `dos/`; NMAKE itself was unavailable. See
`../etc/evidence/m6-kernel-makefile-integrated-audit.json`.
The latest `integrated-source-nb8qxct_` build verifies the COMMAND makefile
wrapper; its OpenNT predecessor is preserved in `research/command/`. The
recipe was run directly from `cmd/command/`, without NMAKE. See
`../etc/evidence/m6-command-makefile-integrated-audit.json`.
The latest `integrated-source-bum5ce2e` build verifies five identical BIOS
headers shared with top-level `inc/`. BIOS and MSLOAD staged inputs are
unchanged; see `../etc/evidence/m6-bios-shared-includes-integrated-audit.json`.
BIOS same-name private headers have been classified in
`../etc/evidence/m6-bios-include-variants.json`: 15 have only notice, blank-line
or EOF differences under the documented comparison, and six have other
differences. These files remain separate; the classification does not prove
runtime equivalence.
The latest `integrated-source-gmjcinx5` build verifies the DOS-style format
and comments in `dos/buf.asm` HMA copy path; instructions and 104 object hashes
are unchanged. See `../etc/evidence/m6-buf-hma-style-integrated-audit.json`.
The target-matching HMA path executes SHR after POPF, unlike DOS 6; this can
change carry before the later conditional branch and is retained as target code.
The latest `integrated-source-gdies2w5` build verifies initialization-entry
formatting and preservation of the OpenNT port note in evidence; see
`../etc/evidence/m6-msinit-entry-style-integrated-audit.json`.
The latest `integrated-source-cutcqvr_` build verifies register comments and
DPB chain-head formatting in `dos/msinit.asm`; see
`../etc/evidence/m6-msinit-dpb-style-integrated-audit.json`.
The latest `integrated-source-bntmlmy2` build verifies migration of three
include research drafts to `research/inc/`; the active include tree no longer
contains those drafts. See `../etc/evidence/m6-research-include-move-integrated-audit.json`.
Latest-build host-interface checks cover 105 object EXTDEF records, 105 MASM
listings, and raw `c4 c4` signatures in all three output files. Results are
in `../etc/evidence/m6-latest-host-externals-bntmlmy2.json`,
`../etc/evidence/m6-latest-host-listing-bntmlmy2.json` and
`../etc/evidence/m6-latest-linked-bop-bntmlmy2.json`. These bounded scans do
not establish the absence of other host interfaces.
The latest `integrated-source-yv1452rt` build verifies 48 DOS 6-aligned
indentation changes in `dos/msinit.asm`; see
`../etc/evidence/m6-msinit-reference-indent-integrated-audit.json`.
The latest `integrated-source-ec4ewo_6` build uses the three hash-pinned
retained `O:\DOS` files directly; current builds no longer depend on the
temporary comparison image or attempt to open E:. The baseline is checked
before and after the build. See
`../etc/evidence/m6-retained-three-file-baseline-audit.json`.
The latest `integrated-source-1rkdarxi` build selects the reconstructed BIOS
class 3 message source directly; staged inputs, messages and all 104 objects
match the prior build. See `../etc/evidence/m6-bios-class3-direct-source-audit.json`.
The latest `integrated-source-54w8syco` build generates BIOS class 3 from the
reconstructed DOS 5 message skeleton; the prior `bios/msbio.cl3` is retained
as a reference. Generated formatting differs, but all 104 objects and three
system files are unchanged. See
`../etc/evidence/m6-bios-message-skeleton-integrated-audit.json`.
The latest `integrated-source-33bqfpb0` build also generates MSLOAD class 1
messages from the BIOS skeleton. Loader and all 104 component objects are
unchanged; see `../etc/evidence/m6-msload-generated-messages-audit.json`.
The latest `integrated-source-tiktv1eh` build shares the BIOS/kernel message
variant under `messages/`, separately from COMMAND. Generated messages, 105
objects and three system files are unchanged; see
`../etc/evidence/m6-shared-dos-messages-integrated-audit.json`.
The latest `integrated-source-5axo8rlo` build includes an inferred optional
POWER message from the existing source comment; POWER remains disabled in the
target configuration. All 105 objects and outputs are unchanged. See
`../etc/evidence/m6-power-message-reconstruction-audit.json`.
The inferred POWER message and the POWER-enabled module were separately
assembled, and the emitted message bytes were located in an OMF data record.
Optional linking and runtime remain unverified; see
`../etc/evidence/m6-power-message-enabled-assembly-audit.json`.
The current compiled source/object universe is inventoried against same-named
OpenNT, DOS 6 and DOS 4 files in
`../etc/evidence/m6-linked-module-reference-ledger-5axo8rlo.json`. The 105
module identities and reference hashes are recorded; differences are review
leads, not conclusions about source ancestry or style completion.
The latest `integrated-source-xbywzx50` build verifies DOS 6-aligned COMMAND
declaration formatting and a restored revision-history line. All 104 component
objects and three files are unchanged; see
`../etc/evidence/m6-command-reference-style-integrated-audit.json`.
The latest `integrated-source-u06amqsd` build generates the kernel message
index in its build stage, keeping source input unchanged. Generated messages,
105 objects and system files match the preceding build; see
`../etc/evidence/m6-kernel-generated-message-index-audit.json`.
The latest `integrated-source-xrublkr3` build generates the COMMAND message
index in its build stage. Six generated files, 105 objects and three outputs
match the preceding build; see
`../etc/evidence/m6-command-generated-message-index-audit.json`.
The latest `integrated-source-n1dujjuk` build removes the 1992 DBLSPACE-only
`syspre` module, which emitted no data in the target configuration. Its source
is retained under `research/bios/`; the remaining 104 objects and all three
system files match. See `../etc/evidence/m6-bios-remove-dblspace-module-audit.json`
and the updated `../etc/evidence/m6-linked-module-reference-ledger-n1dujjuk.json`.
The latest `integrated-source-orzdvz8v` build removes disabled DBLSPACE hooks
and two exclusive headers. SYSConf object symbol records changed, but emitted
code/data and all three system files remain identical; see
`../etc/evidence/m6-bios-dblspace-hooks-audit.json`. Updated 104-module
reference and host-symbol inventories use this build.
The latest `integrated-source-0pv8qok8` build removes disabled COPYCDS and
DBLSPACE-only multiplex markers, preserving the target default path. All 104
objects and three system files are unchanged; see
`../etc/evidence/m6-bios-copycds-cleanup-audit.json`.
The latest `integrated-source-r_1ygt_f` build archives three unreferenced
1992 high-memory headers. Other staged inputs, generated messages, 104 objects
and system files remain unchanged; see
`../etc/evidence/m6-bios-highload-archive-audit.json`.
The latest `integrated-source-v0u7rg93` build removes disabled 1992 restricted
EXEC code and an unused later patch label. All 104 objects and three outputs
remain unchanged; see `../etc/evidence/m6-kernel-post5-restricted-audit.json`.
The latest `integrated-source-jsd769_p` build verifies three post-1991
annotations replaced with descriptions of the retained BIOS code. All 104
objects and outputs are unchanged; see
`../etc/evidence/m6-sysinit-post5-comments-audit.json`.
The latest `integrated-source-lfo06zh6` build restores the PAUSE declaration
ordering shared by DOS 4 and DOS 6. All 104 objects and three files remain
unchanged; see `../etc/evidence/m6-command-pause-entry-audit.json`.
The latest `integrated-source-_wf3nkds` build verifies COMMAND environment
include documentation and DOS 4/6 declaration alignment; all 104 objects and
outputs are unchanged. See `../etc/evidence/m6-command-environment-style-audit.json`.
Historical paths below describe earlier states. Byte identity does not prove
that every statement and comment is the original Microsoft source; style and
NT-derived portions still require evidence-based review.

## M4 T5 S2 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | Continuation (owner-directed ordered file review). |
| Admission And Approval | Continuing the explicit full DOS 5 recovery goal and queued M4 work. |
| Objective | Continue DOS 5 reconstruction using the owner-directed two automatic reference sweeps followed by ordered review of the remaining files, preserving three-file target identity. |
| Non-goals | Do not claim original Microsoft source, complete behavior, or original-image revalidation from a matching retained-media build; COMMAND executable statements remain unchanged. |
| Reference Baseline | Target MSDOS.SYS 37394 bytes, SHA-256 4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2; OpenNT doskrnl/dos primary, DOS 6 and DOS 4 comparative. |
| Candidate Proposal | ROADMAP M4 and QUEUE kernel baseline/build investigation. |
| Files And ABI Surface | One current file at a time from the frozen BIOS, DOS, COMMAND, shared and message-include ledger; review evidence and progress tooling. |
| Applicable Rules | All four project rules; architecture and source layout; permanent Computer Use prohibition. |
| Verification | Clean assembly/link results, source-to-symbol mapping, direct target-byte comparisons; semantic review of host replacements. |
| Expected Markers | Target ORG/entry interpretation; bounded module map and classified differences; verified recovery edits where supported. |
| Asset Needs | Pinned local references, MASM tools, immutable target image; isolated desktops/probes only for runtime tools. |
| Reporting Requirements | Separate lexical candidates from verified host calls and source candidates from target-proven reconstruction. |
| Stop Conditions | Original-input mutation, source overwrite affecting COMMAND, unowned process conflict. |
| Exit Criteria | Every frozen file qualified under the owner-directed reference criteria or reviewed in order, with applicable build identity and limits recorded; broader project milestones remain separately audited. |
| Original Owner Request | 实现 MS-DOS 5.00 源代码考古恢复；以 NTDOS 为基础，接近 DOS 6 目录结构，三文件与目标二进制完全一致。 |
| Similar-Issue Sweep | Kernel linked units, generated messages, shared includes, disk/FAT/device and process host seams. |

## Baseline and limits

Owner decision (2026-11-07): SoftPC and other VM runtime validation are not
acceptance requirements for byte-identical system files. Earlier runtime tests
and historical statements below are evidence of past work, not pending gates.
The permanent prohibition on Computer Use remains in force.

A fresh integrated build from the current project root now produces all three
files byte-identical to the retained targets and to `O:\DOS`. Its [audit](../etc/evidence/m6-current-tree-integrated-audit.json)
checks 15 BIOS, 55 kernel and 34 COMMAND object hashes, current kernel and
COMMAND source snapshots, seven private-desktop logs, and component outputs.
The BIOS input correspondence is covered by `tools/audit_style_cleanup.py`.
A [subsequent full build audit](../etc/evidence/m6-latest-integrated-audit.json)
after the later style and build-input changes reconfirmed all three outputs,
the same 104 object hashes and seven private-desktop logs.
The latest [cross-component alignment audit](../etc/evidence/m6-cross-component-alignment-audit.json)
records a subsequent full build after DOS 6 whitespace alignment in ten source
files; all 104 object hashes and three target outputs remain unchanged.
`DEV.ASM` now uses the DOS 6 local `CALL DEVIOCALL` form and restores the
device-open/close procedure group heading. The [kernel rebuild](../etc/evidence/m6-dev-local-call-style-rebuild.json)
matches the target and all 55 preceding object hashes.
The BIOS sources now express the single-configuration build directly instead
of having three `MULTI_CONFIG` definitions rewritten in the build stage. A
[fresh integrated audit](../etc/evidence/m6-bios-explicit-config-audit.json)
confirmed direct assembly of those sources, unchanged 15 BIOS, 55 kernel and
34 COMMAND objects, and the same three target outputs.
The three initialization files were subsequently reduced to their selected
single-configuration branches, removing 111 DOS 6 multi-configuration blocks
and stale menu descriptions. The [BIOS audit](../etc/evidence/m6-bios-single-config-style-audit.json)
confirms all 15 BIOS object hashes and the complete IO.SYS target remain equal.
Nine unreferenced multiple-configuration constants were then removed from
`bios/config.inc`; the [BIOS audit](../etc/evidence/m6-bios-config-constants-clean-audit.json)
again confirms all 15 objects and full IO.SYS against the retained target.
`msend.asm` segment declarations and `sysimes.asm` public declarations were
aligned with DOS 6 formatting while retaining their NTIO provenance notes.
The [rebuild audit](../etc/evidence/m6-bios-segment-style-audit.json) confirms
all 15 objects and full IO.SYS remain unchanged.

After the recorded integrated build, four recovery-only comment lines were
removed from `kernel-source/dos/msinit.asm`, `cmd/command/tcmd1b.asm` and
`cmd/command/tparse.asm`; the unused final `include bop.inc` was removed from
`kernel-source/dos/msdata.asm`. `python tools/audit_style_cleanup.py` checks
the current inputs against the latest verified component snapshots.
The cleaned kernel was rebuilt on a verified private desktop and matches the
37394-byte target exactly; all 55 object hashes also match the preceding kernel
build. See [kernel build](../etc/evidence/m6-bop-include-kernel-rebuild.json).
COMMAND was subsequently style-cleaned against DOS 4/6 and rebuilt on a
private desktop; all 34 object hashes and the complete output match the prior
verified build and retained target. See
[COMMAND rebuild](../etc/evidence/m6-command-dos-style-rebuild.json).
Four COMMAND modules subsequently dropped six unused NT service and virtual
interrupt header includes. The [COMMAND rebuild](../etc/evidence/m6-command-nt-includes-clean-rebuild.json)
matches the target and retains all 34 preceding object hashes.
COMMAND now uses the full physical DOS `curdir.inc` in the shared include
directory; its build no longer searches `inc/ntvdm`. The [rebuild audit](../etc/evidence/m6-command-physical-curdir-audit.json)
confirms the target output and all 34 object hashes are unchanged.
The remaining public `origin.inc` was aligned with the validated kernel copy;
all 46 files in the physical kernel include directory now have identical
counterparts under the top-level `inc` directory. The [COMMAND rebuild](../etc/evidence/m6-command-shared-origin-rebuild.json)
retains the target output and all 34 object hashes.
BIOS and kernel builds now stage these common top-level includes; the kernel
build checks them against its retained 46-file local list before and after the
build. The [integrated audit](../etc/evidence/m6-common-includes-integrated-audit.json)
confirmed all 104 objects and three output files remained unchanged. The 46
duplicate kernel include files were subsequently removed; the build now stages
them solely from top-level `inc` using `tools/kernel_includes.txt`. A [fresh
integrated audit](../etc/evidence/m6-deduplicated-includes-integrated-audit.json)
again confirmed all 104 objects and three output files.
Unused NT prompt/VDM state constants and a commented VDM error branch were
subsequently removed from COMMAND. The [rebuild](../etc/evidence/m6-command-vdm-constants-clean-rebuild.json)
matches the retained target and all 34 preceding object hashes.
The shared `inc/dosmac.INC` was unified with the physical DOS kernel macro
definitions, restoring the critical-section macros and removing `HRDSVC`.
The [COMMAND rebuild](../etc/evidence/m6-command-shared-dosmac-rebuild.json)
matches the target and all 34 preceding object hashes.
The shared FCB, CPU detection, constant-data and low-memory stub files were
also unified with the verified physical kernel versions. The [COMMAND rebuild](../etc/evidence/m6-command-shared-physical-includes-rebuild.json)
matches the target and all 34 preceding object hashes. Historical `inc/kernel`
and `inc/ntvdm` research inputs remain separate from the current build search.
COMMAND's build snapshot now also excludes those two research directories;
their files remain available for historical work. The [snapshot audit](../etc/evidence/m6-command-no-research-snapshot-audit.json)
records a target-identical rebuild and unchanged hashes for all 34 objects.
`TCODE.ASM` was compared with DOS 4/6 and 357 space-indented source/comment
lines were restored to equivalent tab indentation. The [rebuild](../etc/evidence/m6-tcode-tabs-style-rebuild.json)
matches the target COMMAND.COM and all 34 preceding object hashes; each changed
line was also checked for identical eight-column expansion.
Another 323 `TCODE.ASM` and 22 `INIT.ASM` lines were matched to the DOS 6
reference where source text and eight-column expansion were identical. The
[rebuild](../etc/evidence/m6-command-dos6-alignment-rebuild.json) matches the
COMMAND target and all 34 prior object hashes.
The shared `inc/sf.inc` was also unified with the physical DOS SFT definition
used by the kernel. The [COMMAND rebuild](../etc/evidence/m6-command-shared-sft-rebuild.json)
matches the target and all 34 preceding object hashes.
External dependency closure is outside this check.
The kernel subsequently removed seven `dossvc.inc`, `cmdsvc.inc`, and
`dbgsvc.inc` includes and the unused `HRDSVC` macro. Its [private-desktop
rebuild](../etc/evidence/m6-remove-nt-service-includes-kernel.json) again
matched the retained MSDOS.SYS byte for byte; all 55 object hashes also match
the immediately preceding build. Four then-unreferenced NT service/BOP headers
were removed, retaining identical reference copies in the earlier build
workspace. A further [rebuild](../etc/evidence/m6-remove-nt-service-headers-kernel.json)
matched the target MSDOS.SYS exactly and retained all 55 object hashes.
A DOS 4/6 style pass then removed a recovery-specific data comment and a stale
segment-patching comment; the [new kernel rebuild](../etc/evidence/m6-kernel-dos-style-rebuild.json)
also matched the target and all 55 preceding object hashes.
A further style pass aligned the COMMAND state equate and nearby comments with
the DOS 6 convention and removed an OpenNT-specific override note from the
kernel. The [COMMAND](../etc/evidence/m6-command-equate-style-rebuild.json) and
[kernel](../etc/evidence/m6-kernel-const2-style-rebuild.json) rebuilds both
matched their target files; respectively all 34 and 55 object hashes remained
unchanged from their preceding builds. The current source-input check uses
these latest component snapshots.
In `dir2.asm`, three always-true assembly wrappers around the GetPath,
RootPath and LookupPath/InsertPath sections were removed, restoring the
direct procedure structure used by DOS 6. The [kernel rebuild](../etc/evidence/m6-dir2-structure-style-rebuild.json)
matches the retained target, and all 55 object hashes match the preceding
build. A lexical sweep found no other `IF 1` lines in the active source trees.
The DOS 4/6 `EnterCrit` and `LeaveCrit` macro bodies were restored in
`dosmac.inc`, and 84 equivalent direct critical-section calls across 23 kernel
modules were returned to the historical macro form. The [kernel rebuild](../etc/evidence/m6-critical-macro-style-rebuild.json)
matches the retained target and all 55 immediately preceding object hashes.
`MSINIT.ASM`, `MSTABLE.ASM`, and `BUF.ASM` then had 616 matching source lines
aligned with the DOS 6 reference using equivalent eight-column tab expansion.
The [kernel rebuild](../etc/evidence/m6-kernel-dos6-alignment-rebuild.json)
matches the target and all 55 preceding object hashes.
The Sidekick/PortOfEntry and Windows compatibility data were checked against
DOS 6 source, and `EXEPATCH.ASM` against OpenNT, by
`python tools/audit_compatibility_source.py`; the compared sections are
identical. Outdated comments on the corresponding includes were removed; the
[kernel rebuild](../etc/evidence/m6-kernel-compat-data-style-rebuild.json)
matches the target and all 55 preceding object hashes.
The previously selected physical `Get_CPU_Type` macro was then moved into the
common kernel include location, and the redundant override, unused VINT/WOW
includes and their two headers were removed. The [rebuild](../etc/evidence/m6-physical-cputype-cleanup-rebuild.json)
again matches the target and all 55 preceding object hashes.
The full physical `CURDIR` definition was consolidated into the common
include directory using the DOS 6 reference; the unused NT-only flags and
NTVDM definition were removed. The [CURDIR rebuild](../etc/evidence/m6-curdir-physical-clean-rebuild.json)
matches the target MSDOS.SYS and all 55 preceding object hashes.
The selected physical `const2.asm`, `cpmfcb.inc`, and `sf.inc` were then
consolidated into the common kernel include directory, removing their duplicate
overrides. The [rebuild](../etc/evidence/m6-physical-includes-unified-rebuild.json)
again matches the target MSDOS.SYS and all 55 preceding object hashes. The
empty override directories and obsolete build search paths were then removed;
the [subsequent rebuild](../etc/evidence/m6-clean-include-path-rebuild.json)
and [script audit](../etc/evidence/m6-clean-include-path-audit.json) confirm
the target output and all 55 object hashes remain unchanged.
`python tools/preflight_source_build.py` also verified all 12 currently pinned
tools and comparison inputs. `python tools/audit_retained_build_dependencies.py`
verified the tool copies recorded by each of the four component reports and
14 recorded MSLOAD, BIOS and kernel message files. The COMMAND build report did
not record hashes of its generated messages; their retained current hashes are
observations, not independent proof of their contents at build time. Operating
system and transitive executable dependencies remain outside this check.

The verified kernel build uses `kernel-source/dos/`, not the earlier top-level
`dos/` investigation tree. Of the 55 modules in the verified link list, 14
corresponding top-level files currently match, 32 differ, and 9 are absent.
The two trees must not be interchanged by name. See `dos/README.md`.
The linked-kernel [reference comparison](../etc/evidence/m6-kernel-reference-similarity.json)
records hashes and literal line similarity for all 55 modules: 9 match their
available OpenNT namesakes exactly, and 17 match their DOS 6 namesakes exactly.
OpenNT namesakes were available for 39 modules, DOS 6 for all 55. Similarity
is a lead for further source archaeology, not proof of provenance or of the
original DOS 5 source.

After the owner's approval, a fresh source-snapshot build on private desktops
produced IO.SYS, MSDOS.SYS and COMMAND.COM byte-identical to pinned retained
media. All 104 BIOS, kernel and COMMAND objects match prior exact builds. The
fresh binaries passed a bounded headless core smoke test and were deployed to
O:\DOS with direct byte verification. The original E: image is unavailable;
the supplied SoftPC product probe exited before launch. The owner accepts the
retained three-file baseline without remounting the original image. Source
provenance and rights review remain separate; product runtime is not an
acceptance gate. Evidence: [fresh build](../etc/evidence/m6-fresh-integrated-source-audit.json),
[runtime](../etc/evidence/m6-fresh-integrated-headless-runtime.json),
[deployment](../etc/evidence/m6-fresh-deployment.json), and
[product attempt](../etc/evidence/m6-fresh-integrated-product-attempt.json).
When the original image becomes available, `python tools/verify_original_media.py`
checks its pinned length and hash before directly comparing all three fresh and
deployed files. The retained padded test image is rejected by this gate.
On 2026-11-07, a read-only search of 22 `build/` files with image-like
extensions and at least 258048 bytes found no prefix matching the original
image's pinned SHA-256. This does not rule out a copy elsewhere.
A second product probe created a suspended child on a named private desktop,
but could not read the child's desktop name and terminated it before resuming;
see [thread-desktop attempt](../etc/evidence/m6-fresh-product-thread-attempt.json).
A harmless canary verified its own newly created private desktop after startup.
A subsequent product probe named that desktop at launch but still could not
read the product thread's desktop; it terminated the owned job before console
input or guest boot. See [canary attempt](../etc/evidence/m6-fresh-product-canary-attempt.json).
The console-check probe then confirmed the canary desktop, but the product
exited with code 1 before its console could be verified; no input was sent and
the image remained unchanged. See [console attempt](../etc/evidence/m6-fresh-product-console-attempt.json).
An independent headless probe linked against current local SoftPC objects parsed
the disposable test configuration and created/destroyed the machine, but audio
initialization returned IO_ERROR (5); see
`docs/etc/evidence/m6-softpc-compose-split-probe-result.json`. This is a likely
environmental lead, not direct proof of the supplied product's failing branch.

The consolidated candidate's recovery-specific comments have been moved to
its evidence note where appropriate. A fresh build after this source-style
pass has the same 55 object hashes and exact target-extract output as before;
the historical compatibility byte tables remain intact. This is a bounded
style pass, not a completed source-style or provenance audit.

The [IO.SYS preliminary investigation](../etc/io-reference-investigation.md)
cross-checks two retained test-image copies against the original IO.SYS hash
and records reference link lists and raw correspondence leads. This supports
the kernel/BIOS interface investigation; M5 source recovery is still open.
Two fresh builds of the unmodified NTIO reference now match its shipped binary
exactly, with 12 objects and regenerated messages reproducible. Symbol leads
are recorded in that investigation; they do not establish target code matches.
The comparative MSLOAD candidate now has two builds matching target IO.SYS
offsets [0000h,05A6h) byte for byte, with the boot-message source and DOS 5
version input explicitly recorded there. BIOS proper and runtime remain open.
The DOS 6 comparative MSBIO1 candidate's 218 emitted device-chain bytes match
the corresponding target bytes under documented symbol and load-segment
fixups; three uninitialized alignment bytes are excluded. No full BIOS link or
runtime conclusion follows from that bounded comparison.
The same evidence now covers 109 additional MSBIO1 strategy, device-entry and
common A20-dispatch bytes, using table placements derived from assembled DOS 6
reference module lengths. Called drivers, complete link and runtime remain open.
An actual 15-module DOS 6 comparison BIOS link now independently matches the
first 1760 BIOS bytes, the 109-byte device-entry interval and the following
407-byte interrupt-handler interval. The overall reference BIOS is not equal to
the target and uses explicitly provisional comparison messages.
An MSINIT physical candidate removes two target-absent DOS 6 initialization
blocks. Two repeatable candidate links align BIOS_CODE at 2570h and match
[0000h,08F9h) and [0900h,19C0h) directly; 15667 common-prefix differences
remain. See the IO.SYS investigation for assumptions and evidence.
The MSBIO2 candidate now removes a target-absent `install_bds` EOT update.
Two actual links match the complete 6752-byte BIOS_CODE segment
[2570h,3FD0h); 14594 overall common-prefix differences remain. Several linked
inputs are still provisional DOS 6 comparison sources and messages.
The SYSINIT candidate now incorporates the target-corresponding NTIO hardware
stack-switch sequence. Two builds match the 616-byte SYSINIT prefix
[3FD0h,4238h), preserve full BIOS_CODE identity and leave 14390 whole-BIOS
common-prefix differences. Runtime and later SYSINIT restoration remain open.
SYSINIT1/2 now place the default command-line buffer according to the NTIO
layout; two candidate builds match [423Bh,43D0h), retain previous linked
intervals and leave 14174 common-prefix differences. `top_of_cdss` is held in
temporary candidate storage until its DOS 6-only users are restored.
The packet drive-number symbols now share one byte as a temporary compatibility
seam. Two OEMBASE comparison builds match SYSINIT data [423Bh,4456h) and retain
previous intervals; their 14137 remaining differences and unreviewed condition
selection preclude accepting that configuration as DOS 5. The current default
candidate has 14170 common-prefix differences.
`top_of_cdss` has now been removed: the candidate uses NTIO's
`confbot`/`alloclim` flow with the physical temporary buffer retained. Two
OEMBASE probe builds match [423Bh,44E1h) and a 34-byte displaced TempCDS
allocation slice; 13309 common-prefix differences remain. The refreshed
default candidate has 14141. OEMBASE and runtime acceptance remain open.
A single-configuration staged probe using OEMBASE now links and matches the
continuous 6619-byte BIOS prefix [0000h,19DBh) in two repeatable builds;
12736 common-prefix differences remain. The conditional edits are not yet
promoted into the candidate sources and require further SYSINIT review.
The SYSINIT1 VDISK-header candidate now omits a target-absent DOS 6 machine
workaround; two single-config links match the entire 42-byte routine and retain
the previously verified intervals. The probe has 12464 common-prefix
differences; current OEMBASE/default builds have 13315/14153 respectively.
The SYSINIT candidate now uses NTIO's command-line scan and CR termination;
two single-config builds match the target's 25-byte command preparation block.
Later SYSINIT addresses shifted: BIOS byte 08F9h and four displaced VDISK bytes
now differ and remain to be resolved. Current single-config/OEMBASE/default
common-prefix difference counts are 12874/13309/14158; these include layout
effects and are not acceptance metrics.
The VDISK and BIOS pointer differences are now explained by named relocation
values in a comparison-only verifier. The non-multi EXEC/error path follows
NTIO with a physical target halt; two builds match its 27-byte setup and
50-byte error/continuation intervals. Current single-config probe has 12487
common-prefix differences; link placement and execution remain open.
The physical TempCDS now traverses the DPB chain in target order rather than
re-searching by drive letter. Two builds reproduce the candidate; all 152
linked bytes match after one named, independently checked ParaRound call
normalization. Current single-config/OEMBASE/default common-prefix difference
counts are 12447/13303/14132; runtime and full IO.SYS remain open.
The target-corresponding INSTALL resident-exit check is restored from NTIO;
two displaced linked intervals match directly. TempCDS now matches its full
152 bytes directly at a one-byte displacement, including its call. Current
single-config/OEMBASE/default common-prefix counts are 12497/13296/14159.
Restoring NTIO's target-matching `CLI`/`HLT` fatal path removed the one-byte
SYSINIT displacement. Two single-config builds now directly match the 6619-byte
BIOS prefix, TempCDS and ClrVDISKHeader at their target positions. Current
single-config/OEMBASE/default counts are 10738/13287/14162; full recovery and
runtime remain open.
SYSCONF's non-multi `SWITCHES` table now follows the three-option NTIO layout.
Two builds reproduce it, and 54 linked bytes match after ten documented
one-byte pointer displacements. Current single-config/OEMBASE/default counts
are 10723/13287/14162; full configuration behavior remains unverified.

Original image is 258048 bytes, BPB geometry 1474560. Only disposable test copies
may pad the unknown tail; original media stays immutable. Runtime interaction
uses isolated desktops and probes only; hidden windows are not isolation.

T5 first inventory: docs/etc/evidence/m4-t5-kernel-baseline.json. This records
link order and direct lexical references; it does not establish transitive
include closure, active conditional branches, target correspondence or a build.
Next: resolve include/message dependencies and assemble an untouched OpenNT
kernel baseline in owned scratch before selecting evidence-backed recovery edits.

Initial native assembly probe completed, then expanded to all 38 linked OpenNT
units: every assembler invocation exited 0 and produced a hashed object. See
m4-t5-reference-assembly.json (stage kernel-reference-kzmxwku8). Reference
generated message includes were consumed, not regenerated. This is not a linked
NTDOS or recovered MSDOS.SYS. The frozen
link lists contain OpenNT 38 units, DOS 6 57, DOS 4 55; 19 DOS 6 link units
are absent from OpenNT's link list. Lexical scanning found 86 host-seam
candidates, which still require conditional/semantic analysis.

Reference pipeline now links: NOSRVBLD regenerates all four CL files identically;
LINK 5.10 /MAP, RELOC and STRIPZ yield 27858-byte NTDOS.SYS, SHA-256
957662320654ad5251c3a8b228a5dadec28aa65dddbcba38c3658a6e7f93bc84.
Private-desktop DOSBox exited normally; no Computer Use. See
m4-t5-reference-link.json and m4-t5-reference-comparison.json. Target is 9536
bytes larger and differs at byte 1. Local source recovery and full dependency
closure remain pending; no target equivalence is claimed.

Local baseline now exists: 107 pinned files with zero unresolved literal includes
and zero shared-header conflicts. The import preserved all 110 preexisting
COMMAND-related files. All 38 local objects equal their reference counterparts;
the local-input link also equals the reference NTDOS.SYS and map. Evidence:
m4-t5-kernel-import.json, m4-t5-local-assembly.json, m4-t5-local-link.json.
Next: generation-before-assembly clean pipeline, then target mapping/recovery.

Generation-order gap is now closed: tools/build_kernel.py generated CL files
before all 38 assemblies in fresh stage kernel-clean-fh9v8adc. Output/map match
the reference baseline; source snapshots and tool hashes are recorded in
m4-t5-clean-kernel-build.json. Next action is target mapping/recovery.

Initial unique exact-block anchors total 10356 bytes, not recovered-source
coverage. Target header ORG is 0x3DD0 versus reference 0x2250; entry jump file
destinations are 31145 and 20908 respectively. Nearest public symbols in the
anchor report are context only, especially for data beyond DOSCODE. No code
recovery edits were absent at that stage. See m4-t5-kernel-anchors.json.

First S2 recovery now applied in dos/msinit.asm: native CLI and removal of
the target-absent NT host registration block before BiosDataPtr stores.
Clean build passes; eight entry bytes are exact and the first 88-byte structure
matches apart from 12 explicit word operands. Those operands and the full kernel
remain unmatched. See m4-t5-init-recovery.md and its build/verification JSON.
Target DOSDATA layout inferred from init: file start 0x7EB0, size 0x1362;
sum exactly equals 37394-byte target length. No recovered-kernel boot claim.
ORG follow-up: paragraph rounding constrains the three bdsize constants to a
sum in 0x3701..0x3710; their individual values remain unknown. See evidence.

DOSDATA-only comparison now identifies 21 unique exact candidate blocks totaling
4360 bytes. These are data alignments, not recovered code. Several largest
previous whole-file anchors fall inside DOSDATA; their nearest DOSCODE public
symbols must not be interpreted as function attribution. See
m4-t5-data-anchors.json and m4-t5-init-recovery.md.

Removed the NTVDM-only DosWowDataStart pointer before JShare. Clean build
m4-t5-data-recovery-build.json succeeds: a 587-byte DOSDATA block now starts
at target offset 0xCA, and user_SP moves to target offset 0x584. DOSDATA's
total length remains 5602 bytes versus target 4962; recovery is incomplete.

Current-build data alignment: final 147 bytes match candidate offset 0x154F
to target offset 0x12CF, exactly the 640-byte total size delta. Candidate
intervening declarations mix NT-only fields and EXEC state with live callers;
do not delete them as one inferred block. See m4-t5-data-anchors-current.json.

Selected NT data declarations now have a hashed line-level lexical reference
inventory in m4-t5-nt-data-references.json. It includes inactive branches and
declarations; restore and verify callers before eliminating their data.

Target Get-DPB candidate at file offset 0xF94 returns BP:ES and has three
near calls consistent with DOS 6's FATRead_CDS and critical sections. OpenNT
uses HRDSVC and a fake DPB instead. Callee mapping and real FAT dependencies
must be restored before changing this caller. See m4-t5-init-recovery.md.
The three call destinations are 0x1356, 0x5899 and 0x1376; their entry bytes
support enter/leave critical sections and FATREAD_CDS respectively. Full
function and dependency correspondence is still unverified.

FAT dependency probe now assembles DOS 6 fat.asm against local headers with
one scratch-only full CDS override. Original NT CDS fails six references to
CURDIR_DEVPTR/CURDIR_ID; full CDS resolves them and produces a hashed object.
Its 37 OMF external symbols are recorded in m4-t5-fat-full-cds-probe.json.
This is a comparison build, not yet linked or accepted as DOS 5 production code.

FAT symbol resolution found six missing names: five buf.asm routines and
GOTDPB. Restored GOTDPB from OpenNT's disabled GETBP block without enabling
GETBP. Clean build m4-t5-gotdpb-build.json passes; its complete nine-byte body
equals target file 0x60B exactly (m4-t5-gotdpb-verification.json). FAT and Get-DPB
are not yet integrated; the five buffer routines and semantics remain required.

DOS 6 buf.asm now assembles in scratch against local headers, without a CDS
override. Its 20 EXTDEF names resolve to 17 existing names plus missing
FATSECRD, DREAD and DWRITE (disk.asm/disk2.asm). See
m4-t5-buf-dependency-probe.json and m4-t5-buf-symbol-resolution.json.
Next dependency boundary is the real disk read/write implementation.

Disk probes: DOS 6 disk.asm assembles against local headers. disk2.asm fails
on SF_LSTCLUS/SF_CLUSPOS absent in NT SFT; a scratch-only full DOS 6 sf.inc
override resolves both and assembles successfully. Reports:
m4-t5-disk-dependency-probe.json, m4-t5-disk2-dependency-probe.json,
m4-t5-disk2-full-sft-probe.json. These objects use differing structure baselines
and must not be integrated without a unified target-validated CDS/SFT layout.

Unified storage comparison: fat/buf/disk/disk2/disk3 all assemble under the
same scratch full CDS/SFT headers. OMF checksums and EXTDEF/PUBDEF records
identify 14 still-missing names against the group plus current kernel map.
Definitions occur in DOS 6 rom.asm (10), lock.asm (2), close.asm and delete.asm.
See m4-t5-storage-group-probe.json. This is symbol/dependency evidence only;
the production kernel still uses NT structures and has not linked this group.

Expanded comparison group adds rom/lock/close/delete; all nine modules assemble.
It has 11 overlaps with current kernel public names and 11 unresolved names
(including case variants), so it is not directly linkable. Reports:
m4-t5-storage-expanded-probe.json. GetCurHead's full 18-byte instruction pattern
occurs uniquely in target at file 23206, with three recorded address operands;
see m4-t5-getcurhead-target.json. Field identities still need cross-checks.

GetCurHead now restored as the initial dos/buf.asm slice and linked. Current
BufferQueue/LastBuffer/FIRST_BUFF_ADDR symbols equal the target's three operands;
clean build m4-t5-getcurhead-build.json passes and the entire 18-byte routine
matches exactly (m4-t5-getcurhead-verification.json). Its file position differs;
remaining BUF routines and full FAT call-chain integration are still incomplete.

BUF expanded through ScanPlace, PlaceBuf and PointComp. Clean build
m4-t5-buffer-queue-build.json passes; the complete consecutive 101-byte slice
equals target bytes at file 23206, with no masked addresses/displacements.
verify_buffer_queue.py uses linked start and assembler ENDP for boundaries.
Other buffer operations and full FAT integration remain outstanding.

Added INC_DIRTY_COUNT and DEC_DIRTY_COUNT from the comparative buffer source.
Clean build m4-t5-dirty-count-build.json passes; full six- and fourteen-byte
bodies equal target offsets 0x5D16 and 0x5D1C, including DirtyBufferCount=0x71.
See m4-t5-dirty-count-verification.json. Full buffer read/write still missing.

Latest continuation: SET_RQ_SC_PARMS restored from the comparative DOS 6 BUF
routine, copying DPB sector size and drive number while preserving AX. Its
complete 19 bytes match target 0x5D03. Clean isolated build report is
m4-t5-cache-parms-build.json (27890 bytes; whole kernel still differs).
verify_fat_chain.py rechecks eight complete routines (149 bytes total) and
six static target Get-DPB call edges; all pass without byte masking. Corrected
the earlier FATREAD_CDS-to-GOTDPB call-site transcription: 0x58A6, not 0x5906.
See m4-t5-fat-chain-verification.json. This is static verification, not a
runtime validation of the Get-DPB path.

Current FAT name resolution is 35/37; GETBUFFRB and BUFWRITE remain absent
(m4-t5-fat-current-resolution.json). Existing names do not prove ABI or semantic
compatibility. Next: reconstruct these buffer paths with their FATSECRD/DREAD/
DWRITE dependencies and validate the shared CDS/SFT layouts before integration.

Full BUF candidate now exists at dos/buf.recovery.asm. It is not production
linked. Native MASM plus explicit OMF relocation at the target layout yields
all 644 bytes exactly equal to target [0x5AA6,0x5D2A), including GETBUFFRB,
FlushBuf, CHECKFLUSH and BUFWRITE. Evidence: m4-t5-full-buf-verification.json;
reproduce with tools/verify_full_buf.py. The DOS 6 HMA read-copy sequence was
changed to the target's distinct flag/branch sequence; no target bytes are
substituted into the object. The comparator pins the source, object, tool,
local header inventory and data-symbol map, and records every relocation.
Three disk callees are target-address assumptions verified at their call sites:
FATSECRD=0x3837, DREAD=0x3863, DWRITE=0x38C5 (file offsets). Their bodies and
integrated operation are still required. Next work remains disk recovery and
CDS/SFT validation, followed by replacing the bounded production BUF module.

Disk continuation: dos/disk.read.recovery.asm contains FATSECRD/DREAD plus
their shared preceding RET (72 bytes at [0x3836,0x387E));
dos/disk2.io.recovery.asm contains DSKREAD/DWRITE/DSKWRITE/HARDERRRW
(114 bytes at [0x38B5,0x3927)). Both match exactly under explicit target-layout
relocation. Reports: m4-t5-disk-read-verification.json and
m4-t5-disk2-io-verification.json; common harness verify_storage_candidate.py.
BUF regression remains exact. These candidates are not linked into production.

Integration blocker identified, with progress possible: current ReadOp data
symbol is 0x576, target read/write instructions use 0x575. The harness records
this named target-layout assignment explicitly; original failing comparisons
are retained as *-nt-layout-mismatch.json. No production data layout was
changed. Neighboring target Trans=0x574 and ThisDrv=0x576 also differ from the
current map by one, while later aligned fields agree. Determine the complete
field/structure cause before changing shared data. External SETREAD (0x485E),
SETWRITE (0x4891), DEVIOCALL2 (0x47E2), HARDERR (0x54AA) still need validation
and integration; the recovered wrappers alone do not prove disk I/O behavior.

Resolved the ReadOp layout cause in production: NT const2 adds an 18-byte
vheDev, while NT curdir removes 17 bytes from CDS. Kernel-only overrides in
inc/kernel remove vheDev and restore the 88-byte CDS. HardErr's physical-DPB
prefix replaces its fake-device path so no vheDev reference remains. NT path
flag constants remain transitional; their callers are not yet standalone DOS.
build_kernel.py snapshots the scoped overrides and uses existing kernel-first
include precedence, leaving COMMAND inputs unchanged.

Clean isolated build m4-t5-cds-harderr-build.json succeeds (27954 bytes,
SHA-256 7b41d92eb3fcc7224fa157f411a7e39b26ed83873c7dcb71f08d838013ffe786).
verify_cds_harderr.py verifies all 98 linked HardErr prefix bytes exactly,
DummyCDS=0x4F3, ReadOp=0x575 and retained user_SP/THISDPB offsets. Existing
COMMAND source snapshot matches unchanged. The storage comparison harness
now uses this real data map without any ReadOp override: BUF 644 bytes, disk
read 72 bytes and physical I/O 114 bytes all still match. Whole INT24 handler,
NT path behavior, SFT and storage integration remain incomplete.

Storage production integration now advances that last limitation: full BUF,
FATSECRD/DREAD (temporary diskread.asm), physical I/O wrappers (disk2.asm),
DEVIOCALL through SC2BUF (dev.asm tail), and crit.asm are production linked.
Device-tail candidate matches 603 bytes at target [0x47DF,0x4A3A); CRIT matches
128 bytes at [0x1356,0x13D6). Replaced disabled NT EnterCrit/LeaveCrit expansion
with explicit EcritDevice/LcritDevice calls in the recovered device tail.

Latest clean build: m4-t5-storage-linked-build.json, 29282 bytes, SHA-256
f843203d4b24eca1f8ca45ea094f13405c90d4d9f63f42af2e78dfd26c11b9a2.
verify_linked_storage.py checks five integrated slices (1561 bytes) and all
12 enumerated external call edges. Only named call displacements differ from
target in these slices; no remaining differences after explicit relocation.
Raw whole-kernel equality is not established. Current source snapshot and
existing COMMAND inputs match their recorded hashes.

FAT EXTDEF name resolution is now 37/37, with no missing names; report
m4-t5-fat-linked-resolution.json. FAT itself is still not linked. Next: restore
FAT with the full CDS and audit semantics of its existing kernel callees;
continue SFT, file operations and remaining NT error/path seams. Integrated
disk I/O runtime and final image deployment are still unproved.

FAT/Get-DPB continuation: complete comparative FAT matches target
[0x56CE,0x5AA6), 984 bytes, under explicit target-layout relocation with current
full CDS headers. Imported as dos/fat.asm and linked. Restored misc.asm's
$GET_DEFAULT_DPB/$GET_DPB to EcritDisk -> FATREAD_CDS -> LcritDisk, returning
ES:BP via the user stack; removed the procedure's SVC_DEMGETDPB/fake-DPB path.

Latest clean build m4-t5-fat-getdpb-build.json: 30258 bytes, SHA-256
2a2069afd7cdcabbcd32f390438614fc26ca71dad2c00368835098cf1fcffda3.
Actual linked verification covers 2593 bytes and 35 named external call edges,
including the full 48-byte Get-DPB procedure. All non-relocation bytes match;
external E8 destinations are checked against the actual map, with raw identity
reported separately. Evidence m4-t5-fat-getdpb-verification.json. Source snapshot
and existing COMMAND inputs are unchanged from their recorded hashes.

Next unresolved path: GetThisDrv's InitCDS/GetCDSFromDrv surroundings still
contain NT current-directory synchronization (SVC_CMDGETCURDIR, NT_FIX/TOSYNC).
Full CDS layout alone does not initialize real DPB pointers. Audit and restore
that path and associated startup/CDS construction; SFT/file I/O and remaining
INT24 seams also remain. This build is not yet a standalone boot/runtime proof.

CDS path continuation: macro.asm now restores FIND_DPB and physical InitCDS,
and replaces GetCDSFromDrv's NT sync/host queries with bounded CDS-table lookup.
InitCDS obtains a matching DPB from DPBHead and stores it in curdir_devptr.
Target FIND_DPB+InitCDS [0x6BB8,0x6C1A) is 98 bytes and exactly matches the
actual linked code, including its internal call. GetThisDrv+GetCDSFromDrv is
123 bytes and matches except the explicitly checked external InitCDS call.

Latest isolated build m4-t5-cds-path-build.json: 30178 bytes, SHA-256
710b89a7684e702913a51ea53dec1ee43e50967eb1d3b207ac7c6ca2c2160538.
m4-t5-cds-path-verification.json covers 2814 bytes and 36 external call edges;
all checks pass. Current build input hashes and frozen COMMAND inputs agree.

Next concrete host dependency is DOSINIT's perdrv/continit: it still calls
SVC_DEMGETDPBLIST to construct the DPB chain. Restore block-device initialization
and DPB construction before claiming working physical CDS/DPB operation.
path.asm CurrentValidate also still uses SVC_DEMQUERYCURRENTDIR/NT_FIX; the
restored macro lookup does not remove that separate path. SFT, remaining NT
INT24 paths, exact whole-file layout and runtime acceptance remain outstanding.

Startup DPB continuation: restored DOSINIT perdrv/perunit/continit block-device
initialization from comparative source, replacing SVC_DEMGETDPBLIST. It reads
returned BPBs, invokes $SETDPB per unit, sets drive/unit/device pointers,
updates NUMIO/MAXSEC and terminates the physical DPB chain. No host DPB-list
service remains in msinit.asm.

Latest isolated build m4-t5-dpb-init-build.json: 30290 bytes, SHA-256
1bea04a82fae7cfd663cb7c95578e00f25eadcd451cca3db4ff08f125b08ca8c.
Added actual-link checks for the 146-byte startup block and full 40-byte
charinit, deriving local addresses from listing plus linked DOSINIT. All checks
pass; aggregate 3000 bytes and 39 named external calls. Evidence:
m4-t5-dpb-init-verification.json. Source snapshot and COMMAND inputs are intact.
These are static code checks, not a proof of successful boot or initialized
runtime tables. Continue auditing $SETDPB, startup data/layout, remaining
path.asm validation and NT error/SFT/file seams before runtime acceptance.

$SETDPB continuation: removed its NT SCS-console/handle multiplexer and restored
direct entry into the retained OpenNT BPB conversion body. This preserves the
DOS 5 conversion logic rather than adopting later DOS 6 FAT-size fixes.
The complete 200-byte procedure plus preceding word3 constant corresponds to
target [0x0FF7,0x10C1). Only the explicit CS:word3 address differs by layout;
the verifier checks that it references the actual linked constant, value 3.

Latest isolated build m4-t5-setdpb-build.json: 29970 bytes, SHA-256
a83b0f5a74b58e178676ca016e3f3d4d945c12baf5b667b1164575dd819de554.
m4-t5-setdpb-verification.json passes for 3202 bytes, 39 external call edges
and the code-constant reference. Current source and frozen COMMAND inputs
match their snapshots. Next: remaining startup layout/data and path validation,
NT INT24 and SFT/file operations; full binary identity/runtime still unproved.

Segment reinitialization continuation: removed NT symbol-file host callback
from seg_reinit and restored its direct conditional branch. The first assembly
exposed an oversized CPU macro: NT inserted a BIOS-area NTVDM/MIPS check.
Added kernel-only comparative cputype.inc with native FLAGS CPU detection.
The full seg_reinit is now 137 bytes, matching target instruction structure
with 17 explicitly checked symbolic operands (including six near calls).
DOSINTTABLE and HMA-data offsets still differ; these are recorded, not fixed.

Latest isolated build m4-t5-segreinit-build.json: 29922 bytes, SHA-256
28853145a2f43b0cd9f742d95a2d2ec799f235d433af3a273e6fcefe290db1f5.
verify_segreinit.py and the existing 3202-byte storage/init regression pass.
Source and COMMAND input snapshots are intact. Evidence also localizes a
30-byte excess between patch_misc_segments and patch_offset; inspect that
NT-specific patching path next. Runtime and full binary equality remain open.


Patch-misc continuation: removed the NT-only DosWowDataStart segment patch
block (one pointer load and nine segment stores, 30 code bytes) from msinit.asm.
Clean isolated build m4-t5-patchmisc-build.json yields 29890 bytes, SHA-256
f8431a161a9eb8e5d75be1ea853648f4503d48780fffb897151032dca28b00f8.
The file shrank 32 bytes because of alignment; the removed code is 30 bytes.

verify_segreinit.py --build m4-t5-patchmisc-build.json --report
m4-t5-patchmisc-verification.json --patchmisc verifies the entire 81-byte
patch_misc_segments at target [7DB3h,7E04h): raw byte equality is true,
including all six checked data-symbol operands. The 137-byte seg_reinit
still corresponds with explicitly enumerated symbols; all six near-call
displacements now equal the target. Its DOSDATA/HMA layout differences remain.

verify_linked_storage.py --build m4-t5-patchmisc-build.json --report
m4-t5-patchmisc-storage-regression.json --init --setdpb passes for 3202 bytes,
39 named external calls and the word3 reference. All 111 current kernel inputs
match this build snapshot; all 113 frozen COMMAND inputs remain unchanged.
No runtime or whole-file identity is claimed. Next audit remaining startup
data/layout and physical path validation, then outstanding NT INT24/SFT seams.


Current-directory continuation: recovered the retained OpenNT ValidateCDS
body as dos/validatecds.recovery.asm. Its complete 190 bytes [43CBh,4489h)
match the target with explicit OMF symbol resolution. Reproduce with:
python tools/verify_storage_candidate.py --module validatecds
This is target-layout candidate proof, not integration or runtime proof.

Integration exposed missing DOS_ChDir and then GetPath (excluded by ifdef 0
in dir2.asm). No dummy implementations were accepted. Formal path.asm,
dir2.asm and msdos.lnk were restored to the patchmisc build snapshot; all
111 kernel and 113 frozen COMMAND inputs match. Latest accepted kernel is
still m4-t5-patchmisc-build.json, 29890 bytes. Unaccepted experiments remain
in path.currentdir.recovery.asm and dircall.recovery.asm; the latter has a
temporary adjacent error tail and is not target-layout equivalent.

Evidence: m4-t5-currentdir-dependency-audit.json records source provenance,
failed build stages, candidate hashes and snapshot checks. Next recover the
physical GETPATH/directory-search dependency closure, then integrate the
CurrentValidate/ValidateCDS/DOS_CHDIR chain. Full binary/runtime work remains.


Physical GetPath continuation: dos/getpath.recovery.asm restores retained
OpenNT GETPATH/ROOTPATH/FINDPATH code and its adjacent helper procedures,
including the omitted DATE16 call in Build_device_ent. Full target interval
[4071h,43CBh), 858 bytes, matches after explicit OMF symbol resolution.
fastpath.recovery.asm restores retained LookupPath/InsertPath with dpb.inc;
all 296 bytes at [44CEh,45F6h) match. Commands:
python tools/verify_storage_candidate.py --module getpath
python tools/verify_storage_candidate.py --module fastpath

These add 1154 target-layout candidate bytes, not linked/runtime coverage.
m4-t5-getpath-closure-audit.json records primary source identity and external
symbol inventory. Physical dir.asm is absent from the OpenNT source directory;
comparative DOS 6 dir.asm supplies the next SEARCH/FindEntry/GETENTRY/
SETDIRSRCH/SETROOTSRCH candidate. SET_BUF_AS_DIR and transitive disk helpers
also need restoration. dir2.physical.recovery.asm remains an exploratory
assembly candidate with NT remnants, not a production replacement. All 111
production kernel and 113 frozen COMMAND inputs still match their snapshots.


Directory-search production integration: added full comparative dir.asm
(433 bytes), bounded FIGREC in rom.asm (44 bytes), and DirRead/FIRSTCLUSTER/
SET_BUF_AS_DIR before existing diskread.asm routines. The 115-byte DirRead
proof includes the preceding shared RET and trailing RET shared with the old
FATSecRd/DREAD proof. Initial link exposed STARTSRCH still inside ifdef 0;
moved its retained 20-byte body outside that conditional, matching target.

Clean isolated build m4-t5-directory-build.json: 30498 bytes, SHA-256
3ecfc3d1381f378e619a0d18b2538d79799616b3c27d34b72a14ba5c317f952e.
Actual-link regression m4-t5-directory-verification.json passes: 3813
unique target bytes (3814 summed slice bytes, one overlapping RET),
50 external calls and SETDPB word3 reference. Segment initialization and
patch_misc regression also passes (m4-t5-directory-segreinit-regression.json).
Kernel/COMMAND snapshot checks pass; see m4-t5-directory-integration-audit.json.

Bounded rom.asm and diskread.asm are temporary departures from the final DOS 6
module layout, to merge as surrounding procedures are recovered. GetPath,
FastOpen and ValidateCDS remain proven candidates, not yet integrated; DATE16
and complete DOS_CHDIR/error paths remain next. No standalone boot or whole
binary identity is implied by these static source and link checks.


Time/GetPath production continuation: restored complete comparative time.asm.
Its 483-byte target [0A5Ch,0C3Fh) includes all four date/time APIs, DATE16,
READTIME and calendar conversion. It uses BCLOCK device requests through the
restored SETREAD/SETWRITE/DEVIOCALL2 chain, removing NT date services and NT
BIOS-tick conversions. Full target-layout proof: m4-t5-time-verification.json.
The resolver explicitly checks DosDseg references against DOSCODE header +7.

Enabled retained physical GetPath and FastOpen blocks in dir2.asm, included
dpb.inc and restored DATE16. Existing CurrentValidate/ValidateCDS entry paths
are not yet switched; CheckThisDevice also retains its separate NT seam.
Clean isolated build m4-t5-time-getpath-build.json: 31714 bytes, SHA-256
6f05f0ffe5f9926d1394086c08cbac422892aecbb876a797e0dd7e34c768c60f.
Actual-link regression passes for 5430 unique target bytes
(5451 summed slice bytes with overlaps), 77 external
calls, two time-module DosDseg references and SETDPB word3. Report:
m4-t5-time-getpath-verification.json. Segment/patch-misc regression passes.
All kernel and frozen COMMAND source snapshots match; see
m4-t5-time-getpath-integration-audit.json. Next connect CurrentValidate and
ValidateCDS with DOS_CHDIR/shared error handling; full identity/boot remain open.


Current-directory production chain: restored $CURRENT_DIR from the audited
comparative procedure, replacing SVC_DEMQUERYCURRENTDIR/NT_FIX and the NT-only
UCase calls with physical validation. Restored retained OpenNT ValidateCDS
body by removing its early CLC/RET and conditional exclusion. Added bounded
DOS_CHDIR with shared access-denied return. The linked path now reaches
FATRead_CDS, DOS_CHDIR and the restored GetPath/physical directory machinery.

Clean isolated build m4-t5-currentdir-linked-build.json: 32002 bytes, SHA-256
5cc8c662dba687a49905c61570dacc38f5eeeb324541676fd04cd5392664602e.
Actual-link report m4-t5-currentdir-linked-verification.json checks full
$CURRENT_DIR (121), ValidateCDS (190), DOS_CHDIR (69), shared error body (8),
and previous slices: 5818 unique target bytes, 94 named call edges,
3 named branches, explicit header/constant references. Source snapshots
and segment/patch-misc regressions pass. Audit: m4-t5-currentdir-linked-audit.json.

Explicit exception outside those byte-corresponding slices: NOTDIRPATH's
shared error jump has verified destination NODEACCERRJ but is 2-byte EB in
the bounded module versus target 3-byte E9 at 336Dh. It is not byte-identical;
full dircall layout must restore this encoding naturally. No padding or target
binary substitution was used. The existing bounded dircall source header's
adjacent-tail note denotes temporary placement, not original target layout.
Remaining: CheckThisDevice still invokes the NT path service; full directory
operations, shared layout, SFT/INT24 and standalone runtime remain incomplete.


Device-path continuation: CheckThisDevice now implements the target's device
syntax (including leading backslash-dev-backslash) without SVC_DEMCHECKPATH.
Caller audit found NT DX status checks in macro2.asm; removed them and its
extra GetThisDrv error branch, restored CLC success and the physical
ValidateCDS call in DoFile. Both full 69-byte slices match with named calls.
Verification: m4-t5-devicepath-verification.json --devicepath, covering
5956 unique target bytes and 104 calls; initialization regression passes.

Owner explicitly requires original Microsoft structure, formatting, comments
and parameter conventions. This is now recorded in rules/CODING.md. Restyled
bounded dircall.asm and rom.asm headers/assembly, restored comparative routine
parameter comments, and removed the obsolete NT TransPath warning. Clean
style build m4-t5-devicepath-style-build.json has identical binary and map to
the verified build: 31986 bytes, SHA-256
471c4dc9c1569e2c207e543b5bfb4d84589e3ca09fe619a354a1a97f7d3f1bcb.
Audit m4-t5-devicepath-integration-audit.json confirms current kernel and
COMMAND snapshots. Style changes did not alter machine code.

Next physical directory API gaps: path.asm still invokes DEMSETCURRENTDIR,
DEMCREATEDIR and DEMDELETEDIR. Complete their original shared dircall module
structure rather than retaining bounded layout indefinitely. NOTDIRPATH's
short/near difference, broader NT/SFT/INT24 recovery and whole-file/runtime
acceptance remain outstanding. No full TransPath recovery is claimed.


Physical CHDIR continuation: restored the comparative procedure in path.asm,
retaining Microsoft formatting, comments and register conventions. It calls
DOS_ChDir to check existence, restores joined CDS handling and local cluster
currency, and removes SVC_DEMSETCURRENTDIR. MKDIR/RMDIR still invoke NT services.

Clean isolated build m4-t5-chdir-build.json: 31986 bytes, SHA-256
b632e0c807568f3ecb7d78933e05dc077870c4fa601b1c436d4df4ac34ae45d1.
Verification command adds --chdir to --init --setdpb --devicepath. The actual
123-byte procedure is checked as a 121-byte target-corresponding body plus
its 2-byte shared success transfer. Target has a 3-byte direct success jump;
current transfer goes through $CURRENT_DIR's SYS_RET_OK trampoline. Error
transfer similarly skips target RMDIR's intermediate shared jumps. Both
complete jump chains are decoded and must reach named SYS_RET_OK/SYS_RET_ERR.
These are explicit layout differences, not whole-procedure byte identity.

m4-t5-chdir-verification.json covers 6077 unique target slice bytes and
110 named calls; prior NOTDIRPATH short/near difference remains explicit.
Initialization regression and kernel/COMMAND snapshots pass. Audit:
m4-t5-chdir-integration-audit.json. Next restore physical MKDIR/RMDIR and the
original shared module ordering, then remaining filesystem/INT24 and runtime.


Full dircall module recovery: dos/dircall.full.recovery.asm follows the original
comparative module structure and comments, with critical macros replaced by
explicit restored EcritDisk/LcritDisk invocations. All 521 bytes at target
[31F6h,33FFh) match after enumerated OMF symbol resolution. Reproduce with:
python tools/verify_storage_candidate.py --module dircall
Report m4-t5-dircall-verification.json. Original ordering naturally produces
NOTDIRPATH E9 91 FE at 336Dh, resolving the bounded candidate's encoding issue
in the comparison only; formal dircall.asm is not replaced yet.

Comparison requires complete DOS 6 sf.inc for RenBuf.sf_mft. It is copied
only into the owned comparison stage, with hash in comparison_headers;
production/shared SFT definitions are unchanged. Six external names remain
absent from the accepted link: SET_MKND_ERR (create), MAKENODE/NEWDIR/SETDOTENT
(mknode), RELEASE (rom), FastOpen_Delete (delete). Other named symbols being
linked does not establish full runtime behavior. See
m4-t5-dircall-closure-audit.json for the finite dependency inventory.

Kernel/COMMAND input snapshots remain intact. Next recover these physical
helpers and audit SFT fields before integrating the full module and switching
MKDIR/RMDIR. Latest accepted kernel remains m4-t5-chdir-build.json; full binary
identity and runtime still unproved.


RELEASE/GETEOF continuation: target [5068h,50A7h), 63 bytes including a shared
preceding RET, differs from comparative DOS 6's RELEASE_flush tail. DOS 5
returns on UNPACK/PACK failure, free/end cluster, and final EOF without that
later FLUSHBUF sequence. Restored original retc/retz macro style and retained
procedure/register comments; no synthetic padding. Candidate proof:
m4-t5-release-verification.json. Integrated RELEASE/RELBLKS/GETEOF into rom.asm.

Clean isolated build m4-t5-release-build.json: 32050 bytes, SHA-256
6c5e6502abf995517646f2a205f465500a0b20a511bede5505a552c3cc693b38.
Actual-link regression passes for 6140 unique target slice bytes and
115 named calls; the new slice checks five UNPACK/PACK/IsEOF calls.
Initialization regression and kernel/COMMAND snapshot checks pass. Reports:
m4-t5-release-linked-verification.json, m4-t5-release-segreinit-regression.json,
m4-t5-release-integration-audit.json. Current preceding shared RET belongs to
FIGREC; restore original full rom layout as intervening routines return.

Full dircall now has five missing named helpers: SET_MKND_ERR, MAKENODE,
NEWDIR, SETDOTENT, FastOpen_Delete. SFT recovery, original module layout,
remaining NT operations and runtime acceptance are still outstanding.


Full node-maker candidate: mknode.recovery.asm preserves the comparative
Microsoft module/procedure/comment layout. It restores the EcritDisk and
LcritDisk calls omitted by NT critSFT macros; target 4BFEh and 4C11h call
1356h and 1376h. The entire 941-byte module [4A3Ah,4DE7h), including BUILDDIR,
NEWDIR, SETDOTENT, MAKENODE and its entry/SFT helpers, matches at target layout.
Reproduce: python tools/verify_storage_candidate.py --module mknode
Proof m4-t5-mknode-verification.json. No original OpenNT mknode.asm was found;
DOS 6 is the explicitly recorded comparative source, not assumed original DOS 5.

Integration audit m4-t5-mknode-closure-audit.json identifies four absent names:
ALLOCATE, FastOpen_Update, ShareEnter, ShareEnd. Present symbols are not runtime
proof. SFT audit also shows NT removed sf_firclus and cluster/directory/name/
UID/MFT fields and added sf_NTHandle, changing subsequent offsets. Candidate
uses complete comparative sf.inc only in its owned comparison stage; formal
kernel headers and inputs remain untouched. A coherent physical SFT transition
is required before production integration, not a mixed ABI or dummy fields.

All accepted kernel/COMMAND snapshots still match. Next restore allocation,
FastOpen update and sharing helpers, then integrate the original full modules
with audited SFT users. Latest accepted kernel remains m4-t5-release-build.json;
whole-file identity and standalone runtime remain incomplete.


Allocation/FastOpen continuation: ALLOCATE/RESTFATBYT candidate matches all
179 bytes [4FB6h,5069h), including preceding FIGREC RET. Removed comparative
DOS 6 callmagic/MAGICDRV patch and its helper: target DOS 5 has no compression
allocation hook. Physical sf_firclus/sf_lstclus writes match with comparison-only
full sf.inc. Proof: m4-t5-allocate-verification.json. Integration awaits SFT.

FastOpen_Delete/Rename/Update/Fast_Dispatch tail is 62 bytes [27BBh,27F9h),
exact at target layout and now production-linked in newly created delete.asm.
No previous delete.asm existed; exclusive creation preserved all existing code.
Full delete module remains to restore. Clean isolated m4-t5-fastopen-build.json:
32114 bytes, SHA-256
414022fc709d9a71ceb7e19e1f69f024ba0e41b645f93ea20988b1f8956f93df.
Actual-link and segment initialization regressions pass; kernel/COMMAND input
snapshots match. Evidence: m4-t5-fastopen-linked-verification.json,
m4-t5-fastopen-segreinit-regression.json, m4-t5-allocate-fastopen-audit.json.

Next: sharing helpers, SET_MKND_ERR and coherent physical SFT migration for
full mknode/dircall integration. Existing layout differences and full runtime
acceptance remain open. FastOpen far dispatch is statically matched, not a
proof that a resident cache driver has executed successfully.


Sharing/error-map candidates: complete comparative share.asm is 82 bytes at
[7558h,75AAh), with Share_Check, Share_Violation, ShareEnd and ShareEnter.
All bytes match using full physical sf.inc only in the comparison stage.
HardErr and Idle external targets are explicitly decoded. Proof:
m4-t5-share-verification.json. SET_MKND_ERR plus its eight-byte CRTERRTAB is
15 bytes [2BD9h,2BE8h), exact with the code-relative table operand resolved
from source; m4-t5-create-error-verification.json. Commands use
verify_storage_candidate.py --module share / --module create-error.
These remain candidates until physical SFT integration, not runtime proof.

Reproducible SFT transition inventory: python tools/audit_sft_transition.py.
It freezes m4-t5-fastopen-build inputs and native MASM structure listings.
NT sf_entry is 33 bytes; physical is 59. Field offset changes are enumerated
in m4-t5-sft-transition-audit.json. There are 59 lexical NT-specific field/
flag uses including header definitions across seven .asm modules plus sf.inc;
conditional activity is not inferred from lexical presence. Default sftabl
uses FILLSPACE=5*(59-sizeof sf_entry): NT padding is 130 bytes, physical zero.
Thus its total reserved area can remain stable while entry stride changes.

Next perform a kernel-only physical SFT transition with NT-handle users and
host paths restored coherently, then integrate already proven mknode/dircall/
share/allocation code. Do not append dummy NTHandle fields or reinterpret its
old offset as a physical field. Accepted kernel and COMMAND snapshots remain
intact; latest build remains m4-t5-fastopen-build.json. Whole layout, original
module completion and runtime acceptance remain open.


Device open/close restoration: DEV_OPEN_SFT through DEV_CLOSE_SFT matches
all 129 bytes [475Eh,47DFh) at target layout, using unchanged common SFT
flags/devptr offsets. Restored the OpenNT-removed block-device branch from
comparative DOS 6: fshare > 1 gate, DPB unit/drive and driver address; restored
dpb.inc dependency. Production diff is confined to this include and branch.
Original Microsoft comments and register conventions are retained.

Clean isolated build m4-t5-openclose-build.json: 32130 bytes, SHA-256
171e1d72b0276a36450a0cc00f1db1d8a4d473402068ad5de4bf6d443c347295.
Actual-link regression covers 6331 unique target bytes and 120 named calls,
including five calls in the new slice; initialization regression passes.
Kernel and frozen COMMAND source snapshots match. Proofs and reviewed diff:
m4-t5-dev-openclose-verification.json, m4-t5-openclose-linked-verification.json,
m4-t5-openclose-segreinit-regression.json, m4-t5-openclose-integration-audit.json.

IOFUNC still uses sf_NTHandle and NT read/write/pipe services; CHARHARD's
call destination is checked but its full implementation is not thereby proven.
Next recover IOFUNC and physical file/SFT paths coherently, then integrate
mknode/dircall/allocation/sharing. Whole-file identity and runtime remain open.


IOFUNC reconstruction: complete comparative DOS 6 IOFUNC plus its two tables
matches all 360 bytes [45F6h,475Eh) at the target layout. Candidate
 dos/dev.iofunc.recovery.asm retains original procedure/parameter comments.
Only standalone-assembly adaptation is CALL DEVIOCALL -> invoke DEVIOCALL;
full physical sf.inc is comparison-only. Evidence:
m4-t5-dev-iofunc-verification.json; reproduce with
python tools/verify_storage_candidate.py --module dev-iofunc.

Integration prerequisites are now verified by tools/audit_iofunc_transition.py
and m4-t5-iofunc-transition-audit.json. Active native disk.lst contains B4 06
at module offset 0304h followed by IOFUNC: this NT cooked string output caller
must be restored with the DOS 5 callee's 0..5 command table. DOS_READ/DOS_WRITE
names exist but physical file branches are absent. DISKREAD, DISKWRITE,
SETUP and DOS_COMMIT are all absent from the accepted link map; DSKREAD and
DSKWRITE are sector wrappers, not substitutes for the file transfer entries.
Candidate sf_position is 15h, production NT is 13h. No mixed ABI was installed.

Next restore full disk.asm and disk2.asm file-transfer dependencies alongside
physical SFT users, then integrate IOFUNC and existing node/allocation/sharing
candidates. Latest production build remains m4-t5-openclose-build.json;
kernel and COMMAND snapshots match. Full identity/runtime remain incomplete.


Full file-I/O module candidates: disk.full.recovery.asm covers all 1206 bytes
[33FFh,38B5h); disk2.full.recovery.asm covers all 737 bytes [38B5h,3B96h).
Both match at target layout. disk.asm uses comparative DOS 6 source with
EnterCrit/LeaveCrit critDisk restored as explicit EcritDisk/LcritDisk calls;
disk2.asm is byte-identical source to the pinned comparative DOS 6 module.
Original procedure, register and comment conventions remain intact.

One explicit data-layout departure: disk.asm's polled-console IsWin386 test
at target 347Dh addresses DOSDATA:1030h, versus accepted production 100Eh.
The candidate resolver records this comparison-only symbol placement; no
production header, data layout or address constant was patched. It is not an
actual-link exactness claim. The two candidates require full physical sf.inc
only in their comparison stages. Native retry-count M065 code matches target
without removal. Evidence: m4-t5-disk-full-verification.json,
m4-t5-disk2-full-verification.json; commands verify_storage_candidate.py
--module disk-full / --module disk2-full.

m4-t5-disk-full-closure-audit.json freezes source/proof hashes, current absent
external names and integration order. Correct module ownership: DISKWRITE,
DIV32 and SHR32 belong to disk3.asm; DOS_COMMIT is in close.asm. Next recover
those and rom.asm FNDCLUS/BUFRD/NEXTSEC/OPTIMIZE plus locking, then perform
coherent kernel-only physical SFT migration and whole disk/dev integration.
Do not retain duplicate bounded diskread entries when full disk.asm is linked.
Current production remains m4-t5-openclose-build.json; both production and
COMMAND snapshots match. Full identity and runtime acceptance remain open.


Full disk3/rom recovery: disk3.full.recovery.asm matches 810 bytes
[3B96h,3EC0h), including DISKWRITE, buffer purge, DIV32 and SHR32. DOS 5
calls shared DWRITE at 3D08h; the comparative DOS 6 compressed-volume
DWRITE_LUP/DWRITE_DISK_FULL additions are removed. SET_ACC_ERRW is restored
after the SETCLUS transfer, at 3D58h, as required by all target branches.
The DS/DMAADD and ALLOWED setup is retained. Proof:
m4-t5-disk3-full-verification.json.

rom.full.recovery.asm matches all 704 bytes [4DE7h,50A7h), including FNDCLUS,
SKPCLP, BUFSEC, BUFRD, BUFWRT, NEXTSEC, OPTIMIZE, FIGREC, ALLOCATE,
RESTFATBYT, RELEASE/RELBLKS and GETEOF. Previously evidenced DOS 5 changes
(remove MAGICDRV allocator hook, omit DOS 6 release FLUSHBUF tail) now hold
in original complete module ordering; shared return layout matches naturally.
Proof: m4-t5-rom-full-verification.json. Both use physical SFT only in the
comparison stage, retain Microsoft source/comment/register style, and remain
candidates. Reproduce via verify_storage_candidate.py --module disk3-full /
--module rom-full. No standalone runtime claim.

Reproducible tools/audit_storage_closure.py freezes 12 storage candidates and
123 named code edges, decodes native OMF public offsets and checks each
candidate-to-candidate target address. Only DOS_COMMIT, LOCK_CHECK and
LOCK_VIOLATION lack both a candidate provider and an accepted linked symbol.
Evidence: m4-t5-storage-closure-audit.json. This is a code-name graph, not
proof of existing callees, indirect calls, data ABI or transitive runtime
closure. Next recover those close/locking entries, then migrate physical SFT
users coherently and integrate whole modules, removing duplicated bounded
fragments. IsWin386 production placement also remains to resolve.

Latest production remains m4-t5-openclose-build.json; kernel and COMMAND
snapshots match. Full binary identity, standalone boot and deployment remain
outstanding; M4 T5 S2 and the complete project goal remain active.


Complete locking/close candidates: lock.full.recovery.asm matches 178 bytes
[74A6h,7558h), including $LockOper, LOCK_CHECK, LOCK_VIOLATION and CheckShare.
close.full.recovery.asm matches 428 bytes [304Ah,31F6h), including DOS_CLOSE,
FREE_SFT, DirFromSFT, DOS_COMMIT and SetSFTTimes. Close restores all critDisk
calls, including the double entry in commit. Proofs: m4-t5-lock-full-verification.json
and m4-t5-close-full-verification.json. Close remains physical-SFT candidate.

Full lock.asm is now production-linked: removes NT handle extraction and
SVC_DEMLOCKOPER, restores network INT 2Fh / SHARE dispatch, retry and HardErr
paths. It uses only unchanged SFT flags, so no mixed-layout field access was
introduced. Source equals the pinned comparative Microsoft module; full target
match supports reconstruction, not a claim of original DOS 5 source provenance.

Clean isolated m4-t5-lock-build.json: 32258 bytes, SHA-256
51cf4390b9212bf198bf2430a4d7004644303b7b0ed08a81e51a6aa8e0deab01.
Actual-link regression covers 6509 unique target bytes and 123 named calls;
lock additionally verifies two return jumps and CheckShare's DosDseg operand.
Initialization regression passes. m4-t5-lock-integration-audit.json records
reviewed production diff; only dos/lock.asm changed since openclose build.

Storage graph now has 14 candidates and 141 named code edges; no named code
provider is absent from both candidates and accepted map. Native public offsets
are checked, but map presence is not callee correctness, runtime, indirect-call
coverage or ABI compatibility. Production and COMMAND snapshots pass. Next
perform kernel-only physical SFT migration with remaining NT users restored,
then integrate full disk/dev/rom/close/mknode/dircall/share modules together.
IsWin386 placement, whole binary equality and standalone runtime remain open.


Physical SFT migration probe: tools/probe_physical_sft.py creates an owned
native-only stage from m4-t5-lock-build, combines target-verified full storage
candidates, removes duplicate diskread from its module list and adds full
close/mknode/disk3/share plus the creation error mapper. It overlays comparative
DOS 6 abort/fcbio/fcbio2/handle/file solely as UNVERIFIED investigation inputs,
not accepted reconstructions. No production sources or shared COMMAND headers
are modified. Latest stage: build/physical-sft-probe-w4i4ug52.

All 51 modules now assemble with a 59-byte physical sf_entry. Initial stage
physical-sft-probe-2kdarjfr found three real migration surfaces: zero FILLSPACE
DUP is rejected by native MASM; physical FCB fields require full cpmfcb.inc;
console SFT initialization needs sf_firclus plus name/extension setup. These
are restored only in the probe, with source hashes and classification recorded
in m4-t5-physical-sft-probe.json. Startup changes and five comparative SFT users
still require target-byte evidence. Assembly compatibility is not integration,
link, data-layout or runtime acceptance.

Native OMF declaration audit m4-t5-physical-sft-symbol-audit.json finds duplicate
CHECK_VIRT_OPEN (NT msctrlc and physical mknode) and unprovided declarations:
DOS_DELETE, DOS_RENAME, GET_FILE_INFO, SET_FILE_ATTRIBUTE, SET_EXT_MODE,
OFFSETMAGICPATCH. The last is an unused comparative ROM declaration after
removing the compression hook; distinguish actual fixups before assigning a
link failure. Next resolve those physical pathname dependencies and NT stub
ownership, target-verify the five SFT user modules/startup, then link the probe
and promote only evidence-backed changes. Current production remains
m4-t5-lock-build.json; kernel and COMMAND input snapshots still match.


Pathname dependencies: complete finfo.full.recovery.asm matches 260 bytes
[2A36h,2B3Ah), delete.full.recovery.asm matches 480 bytes [2619h,27F9h),
and rename.full.recovery.asm matches 573 bytes [27F9h,2A36h). Each preserves
comparative Microsoft module structure/comments/register conventions, with
NT-no-op critDisk macros restored to explicit EcritDisk/LcritDisk calls.
Proofs: m4-t5-finfo-full-verification.json, m4-t5-delete-full-verification.json,
m4-t5-rename-full-verification.json. Full delete includes REN_DEL_Check and
FastOpen routines; it replaces, not supplements, the earlier bounded tail.

The physical-SFT probe now assembles 53 modules successfully, including these
three full candidates, at build/physical-sft-probe-aa1_pxwn. Production remains
m4-t5-lock-build.json. Five comparative SFT-user modules and startup changes
are still investigation inputs requiring target evidence, not promoted source.
Snapshot checks preserve kernel and COMMAND. Summary:
m4-t5-pathname-storage-audit.json; reproduce probe_physical_sft.py and
verify_storage_candidate.py --module finfo-full / delete-full / rename-full.

Named-code graph universe expands to 16 candidates/185 edges, replacing
fastopen with full delete. Newly exposed absent providers: DOS_SEARCH_FIRST,
RENAME_NEXT, SET_MEDIA_ID. SET_EXT_MODE remains a separate comparative file
probe import, not yet part of this candidate graph. Next restore full create
and physical internal search dependencies, resolve duplicate CHECK_VIRT_OPEN
ownership, then verify SFT users/startup and actual link. Prior physical-sft
symbol audit refers to its earlier recorded stage; no claim it covers the new
53-module composition. No whole-file identity/runtime acceptance yet.


Create/open/search closure: complete create.full.recovery.asm matches 300 bytes
[2B50h,2C7Ch), open.full.recovery.asm matches 373 bytes [2C7Ch,2DF1h), and
isearch.full.recovery.asm matches 395 bytes [2E52h,2FDDh). Full create supplies
Set_Media_ID/Set_EXT_mode and replaces the bounded error mapper in the probe.
Open supplies SET_SFT_MODE; internal search supplies DOS_SEARCH_FIRST/NEXT and
RENAME_NEXT. Original Microsoft conventions are retained, critDisk calls
restored. Proofs: m4-t5-create-full-verification.json,
m4-t5-open-full-verification.json, m4-t5-isearch-full-verification.json.
Named-code graph now spans 18 candidates/209 edges with no absent providers;
this is not whole-runtime closure.

54-module physical-SFT probe now ASSEMBLES AND LINKS on the private desktop.
Latest owned stage: build/physical-sft-probe-roq3haya. The probe removes NT
msctrlc's duplicate CHECK_VIRT_OPEN, retaining its call to the full mknode owner.
Actual LINK first rejected unused OffsetMagicPatch declaration in rom; remove
that stale i_need after eliminating the compression hook. ROM remains exact
at all 704 target bytes after reassembly. Native OMF declaration presence can
therefore matter even without executable operand use. Prior graph/reference
proof hashes are historical; the refreshed graph uses the new ROM proof.

Reproduce: python tools/probe_physical_sft.py, then
python tools/link_physical_sft_probe.py (private isolated desktop).
Evidence: m4-t5-physical-sft-probe.json and m4-t5-physical-sft-link-probe.json.
Final host exit 0, PASS, no unresolved externals; LINK reports no-stack and
no-start-address warnings expected for this intermediate DOS kernel EXE.
An initial launcher attempt used a non-8.3 BAT filename and timed out with
host exit 124, no link run. Its owned process was terminal before retry with
PROBELNK.BAT; m4-t5-physical-sft-link-launch-failure.json retains that result.
The actual unresolved-symbol attempt is retained separately in
m4-t5-physical-sft-link-unresolved.json.

This is a scratch link, not a promoted MSDOS.SYS: relocation/stripping, target
verification of comparative abort/fcbio/fcbio2/handle/file and SFT startup,
linked-byte regression, physical data placement, and runtime remain required.
Production stays m4-t5-lock-build.json and COMMAND stays unchanged; snapshots
checked by refreshed storage audit. Next target-verify the five SFT users and
startup before promoting the coherent physical migration.


Physical-SFT consumer validation: complete abort.full.recovery.asm matches
109 bytes [2FDDh,304Ah) using physical sf_entry (PID/UID offsets and 59-byte
stride). This is the unchanged pinned comparative Microsoft module. It
replaces NT host-handle close with the target DOS process/FCB reference cleanup
and network/SHARE notifications. Evidence: m4-t5-abort-full-verification.json.

Console SFT initialization candidate msinit.sft.recovery.asm matches all
51 bytes [7A60h,7A93h), including the previously missing sf_firclus zero and
name/extension copy. Procedure body is taken from the comparative initializer,
with historical comments/register usage retained. Evidence:
m4-t5-init-sft-verification.json. This validates only the console SFT block,
not all initialization or data layout.

Actual-link verification: python tools/verify_probe_sft_startup.py verifies
frozen MZ/map/listing hashes and maps native listing offsets into probe.exe's
load image. The 51-byte initializer is RAW EXACT; the full 109-byte DOS_ABORT
matches after two explicitly decoded linked calls to $CLOSE and SFFromSFN.
Evidence: m4-t5-sft-init-abort-linked-verification.json. Existing scratch probe
stage physical-sft-probe-roq3haya was inspected, not rebuilt; its historical
report still describes abort as an investigation input, now superseded by
these specific proofs. Probe recipe uses the byte-identical verified abort
candidate on future runs. No runtime claim.

Storage graph expands to 19 candidates/211 named edges, still no missing
provider. Four comparative consumers remain target-unverified: fcbio, fcbio2,
handle and file. Next validate those and other initialization/data changes,
then perform full linked regressions and promote coherent SFT migration.
Production remains m4-t5-lock-build.json; kernel/COMMAND snapshots pass.
Whole-file equality and standalone runtime remain incomplete.


Handle consumer validation: handle.full.recovery.asm matches complete 640 bytes
[68FBh,6B7Bh), covering close/commit, extended handle table, read/write, seek,
file times, duplicate handles and CheckOwner. Physical sf.inc is comparison-only.
Restore EnterCrit/LeaveCrit critSFT as EcritDisk/LcritDisk (target 6AFFh/6B1Ch).
The earlier unverified DOS 6 probe lost these six bytes through NT macros;
replacing it with this candidate corrects actual emitted code. IsWin386 has
an explicitly recorded target placement 1030h versus production 100Eh at
operand 6B62h, consistent with the disk candidate. Proof:
m4-t5-handle-full-verification.json; --module handle-full.

Physical probe recipe now consumes verified abort/handle sources, leaving
fcbio/fcbio2/file as comparative inputs. All 54 modules reassemble and link in
private isolation: build/physical-sft-probe-xcx0k53o. No production promotion.
Actual entire linked handle module verified by tools/verify_probe_candidate.py
--module handle-full: 640 bytes and 48 OMF-named relocations, zero remaining
differences. Candidate source hash must equal assembled probe source; linked
MZ/map and candidate resolved-byte hashes are checked. Data/code relocations
are explicit, including IsWin386 difference and indirect DOS_READ/DOS_WRITE
addresses. Proof: m4-t5-handle-full-probe-linked-verification.json.

SFT startup/abort linked checks rerun against this new probe and pass: 51-byte
initializer raw exact; 109-byte abort call-adjusted correspondence. Storage
graph now has 20 candidates/226 named edges, no absent provider. Existing
link-probe scope wording about five unverified callers reflects the original
probe template; current count is THREE as established by these later proofs.
Next verify FCB pair and file module, then full linked storage regression,
physical layout and remaining NT runtime seams before coherent promotion.
Current accepted production remains m4-t5-lock-build.json; whole-file target
identity, standalone boot and deployment remain outstanding.


Pathname SFT consumer: file.full.recovery.asm matches complete 969 bytes
[70DDh,74A6h), including open/create, chmod, unlink, rename, temporary/new-file
creation and extended open. Restore critSFT macros to explicit EcritDisk and
LcritDisk at 70E8h/70EEh. Native NT macros had omitted these six bytes in the
previous comparative probe. Preserve Microsoft module/procedure comments and
register conventions. Three MOV CX code-pointer witnesses at 70E4h,71B5h,
72A0h name DOS_OPEN/DOS_CREATE/DOS_CREATE_NEW; the candidate resolver validates
opcode and target address separately from E8/E9 call/jump witnesses.
Evidence: m4-t5-file-full-verification.json; --module file-full.

Probe now uses verified file candidate; only fcbio/fcbio2 remain comparative
unverified consumers. All 54 modules reassemble/link successfully on private
desktop in build/physical-sft-probe-1cdxzp1u. Complete actual-link file proof
checks 969 bytes and 119 OMF named relocations with zero remaining differences:
m4-t5-file-full-probe-linked-verification.json; reproduce via
verify_probe_candidate.py --module file-full. Same run's handle proof passes
640 bytes/48 fixups; initializer remains raw-exact at 51 bytes, abort passes
109-byte call-adjusted proof. Latest linked reports replace prior probe views.

Storage graph has 21 candidates and 249 named edges, no missing providers.
Production remains m4-t5-lock-build.json, COMMAND unchanged; snapshot audit
passes. Next validate complete FCB modules, then actual-linked full storage
regression, physical data layout and remaining host seams before promoting
coherent physical-SFT migration. No whole-file or runtime acceptance yet.


FCB consumer validation: full fcbio (1224 bytes,[1829h,1CF1h)) and fcbio2
(778 bytes,[1CF1h,1FFBh)) candidates match target-layout assembly. Both
.recovery.asm files are byte-identical to their DOS 6 comparative sources,
retaining Microsoft structure, comments and register conventions for physical
implementation recovery in the NTDOS-derived kernel. Physical sf.inc and
cpmfcb.inc remain comparison-only. LocalSFT is explicitly 103Bh in accepted
production versus target 105Dh (11 FCBIO operands and two FCBIO2 operands).
FCBIO's CS-relative DosDseg loads are checked: DS at 1A28h, ES at 1B02h/1CD3h.
No production data-layout adjustment was made.

Reproduce with tools/verify_storage_candidate.py --module fcbio-full or
fcbio2-full, followed by tools/verify_probe_candidate.py with the same
arguments. Actual complete linked modules in physical-sft-probe-1cdxzp1u
pass with 95 and 49 named OMF relocations and zero remaining differences.
Staged source hashes match the candidates; no relink was needed. Future
probe recipe now selects verified candidates. Retained assembly reports
still describe their historical comparative input paths.

Storage graph: 23 candidates, 284 named edges, no missing named providers.
Production (115 inputs) and COMMAND (113 inputs) snapshots pass. M4 T5 S2
remains active; accepted production remains m4-t5-lock-build.json. Next:
full linked storage regression, physical data placement (LocalSFT/IsWin386)
and remaining NT host seams before coherent promotion. Whole-file identity,
standalone runtime and deployment acceptance remain outstanding.


DOSTAB layout investigation resolves the shared 34-byte displacement:
NT moved the 17-word EXEC work area from DOSTAB to LMSTUB (the latter's
comment records that migration). dos/dostab.layout.recovery.asm restores
the comparative DOS 6 declarations verbatim at the historical position and
changes the EXEC instance-table span from 24 to target-proven 34 bytes.
No arbitrary padding or binary substitution is used.

Native assembly proof: tools/verify_dostab_layout.py;
m4-t5-dostab-layout-verification.json. Complete initialized tail
[0FE2h,1061h) is 127 bytes exact after bounded internal DOSDATA OMF fixups.
The preceding 34-byte uninitialized allocation has verified symbol offsets,
not an initialized-byte/linker/runtime claim. EXEC starts 0FC0h, Win386_Info
0FE2h, IsWin386 1030h and LocalSFT 105Dh. The source candidate is the existing
NT-derived DOSTAB plus the reference declaration block and the one span edit.
Scratch-only LMSTUB removes duplicate declarations to permit assembly.

Do not promote this candidate alone: NT MSPROC's GetBinaryType path can
read Exec_Header_Len_NE=62 bytes at Exec_Signature. In restored layout that
would overwrite 36 bytes of Win386 data. The remaining NT extended-header
buffer is deliberately not claimed coherent in the data-only probe. Restore
the DOS 5 EXEC header-loading path before coherent layout integration; full
linked storage regression and other host seams remain open. Accepted kernel
and COMMAND snapshots still pass unchanged. M4 T5 S2 stays active; no runtime,
whole-file identity or deployment acceptance. Earlier delayed sessions have
completed; native assembly exited zero, no live verification job remains.


EXEC header/read chain recovery: dos/msproc.full.recovery.asm is a complete
comparative DOS 6 module with three critical macros changed to explicit
EcritMem/LcritMem invokes because NT macros omit those calls. Preserve the
original structure/comments/register conventions. It is an investigation
candidate, NOT a fully target-verified or promoted MSPROC replacement.

Native proof tools/verify_exec_header.py verifies two complete source-object
slices: header loading/signature classification [5E26h,5E5Ch), 54 bytes;
ExecRead plus exec_dealloc/exec_alloc/ChangeOwners/ChangeOwner
[62BFh,6306h), 71 bytes. All 125 bytes match target with 17 named OMF fixups.
The latter includes actual critical calls at 62D1h/62E2h and $READ at 62C6h.
Proof: m4-t5-exec-header-verification.json, with source/reference/tool/header
hashes, listing labels, OMF relocations and byte hashes. External callee
addresses are not runtime validation. No target bytes are copied to source.

The source-generated header reads 26 bytes at 0FC8h, ending exactly at 0FE2h
(the restored Win386_Info boundary), unlike NT's 62-byte GetBinaryType read.
Thus the bounded DOS 5 read path is established, but NT preclassification,
other EXEC code and host transitions still require coherent replacement.
Next verify the entire MSPROC module and its dependencies before integrating
DOSTAB plus physical SFT. Production remains m4-t5-lock-build.json; accepted
kernel and COMMAND input snapshots pass. M4 T5 S2 stays active, no whole-file,
standalone runtime or deployment acceptance.


Complete MSPROC candidate: [5D2Ah,63F2h), 1736 bytes now matches target
with 156 explicit OMF fixups at pinned symbol placements. Reproduce:
python tools/verify_msproc_full.py. Evidence m4-t5-msproc-full-verification.json
and m4-t5-msproc-target-bindings.json. Source preserves historical style.
Beyond the three restored memory critical calls, remove the DOS 6-only
Rational386PatchPtr indirect call (five bytes absent in target) and restore
COM allocation check CMP AX,100h (target 60B7h); DOS 6 uses 200h, while the
existing NTDOS source independently retains 100h. Whole source remains a
comparative physical implementation candidate for the NT-derived kernel.
The earlier 125-byte header/ownership proof passes with the updated source.

Bindings are explicitly pinned source-name/target-operand attributions, not
independent proof of production ABI. Every use must resolve consistently;
all internal jumps/calls, non-relocation bytes and target length match.
Nineteen data symbols differ from accepted production: fourteen EXEC fields,
DriverLoad/BiosDataPtr, fixexepatch/DosHasHMA and Disa20_Xfer. EXEC and Windows
prefix have independent DOSTAB proof; the later patch/HMA/transfer placement
requires further restoration. External callees are addresses, not runtime
validation. The older 23-candidate storage graph does not yet include MSPROC.

Next integrate MSPROC and DOSTAB together in the disposable physical-SFT
probe, remove the obsolete duplicate LMSTUB EXEC allocation/NT extension,
and verify actual linkage and data layout before any production promotion.
Production and COMMAND snapshots remain unchanged; M4 T5 S2 active. Full
MSDOS.SYS identity, standalone runtime and deployment are not accepted.


MSPROC/DOSTAB physical-probe integration now passes in
build/physical-sft-probe-_e0pgjth: all 54 modules assemble and the private
isolated-desktop DOSBox LINK completes successfully. The probe overlays both
candidates and removes the full obsolete EXEC allocation/NE extension from
staged LMSTUB. Accepted production remains untouched. A first link exposed
an unused Rational386PatchPtr EXTRN; removing that declaration preserves all
candidate bytes and resolves the real linker error. Retained failure:
m4-t5-msproc-link-unused-external.json. Full MSPROC proof rerun passes.

Actual-link proof: tools/verify_probe_exec_layout.py, report
m4-t5-exec-layout-probe-linked-verification.json. Entire MSPROC (1736 bytes,
156 named fixups) corresponds with zero remaining differences; DOSTAB's
127-byte initialized tail is raw exact. EXEC allocation and Windows/LocalSFT
symbol offsets match target. Of the 19 former MSPROC data-placement differences,
only three remain: fixexepatch target1212h/linked11FCh, DosHasHMA target1211h/
linked11FBh, Disa20_Xfer target1115h/linked1117h. Do not hide those offsets
behind the relocation-correspondence result.

Same linked probe regressions pass: FCBIO 1224 bytes/95 fixups, FCBIO2
778/49, handle 640/48, file 969/119; SFT initializer 51 bytes raw exact,
abort 109 bytes with named call adjustments. DOSTAB standalone verifier now
also supports probe input with the NT EXEC allocation already removed.
Production and COMMAND snapshot checks pass unchanged. Next restore remaining
A20/HMA/patch data and runtime seams, broaden linked storage regression, then
promote only a coherent candidate. M4 T5 S2 active; no whole-kernel identity,
standalone runtime or deployment acceptance.


Physical low-memory stub restoration: inc/lmstub.physical.recovery.asm keeps
the NT-derived module and restores comparative physical sections: native
IRET/CLI/STI, removal of SVC_DEMENTRYDOSAPP, unified flag-preserving EnsureA20ON,
and Windows 2.x OldInstanceJunk at its earlier location with 34-byte EXEC span.
No padding is added. The staged probe still removes obsolete NT EXEC storage.
Other NT data after the bounded restored region remains unaccepted.

All 54 modules assemble/link in private isolation at
build/physical-sft-probe-_di49yv4. tools/verify_probe_lmstub.py proves the
entire linked DOSDATA range [108Ah,122Ah), 416 bytes RAW EXACT, including
interrupt stubs, A20 transfers and enable/disable paths, old Windows table,
HMA flag, patch slots, RatBugCode and reserve through Mark3. Proof:
m4-t5-lmstub-probe-linked-verification.json. No relocations are masked.
DOSINTTABLE code pointers preceding the range and the NT tail are excluded.

Disa20_Xfer=1115h, DosHasHMA=1211h and fixexepatch=1212h now match target.
Actual linked MSPROC proof rerun has zero remaining data-placement differences
(all 19 prior ones resolved), still 1736 bytes/156 named relocation checks.
DOSTAB tail remains 127 bytes raw exact. Current linked regressions pass for
FCBIO, FCBIO2, handle, file, 51-byte SFT initialization and 109-byte abort.
Kernel/COMMAND production snapshots remain unchanged. Next broaden actual
linked storage coverage and restore remaining initialization/host seams before
promoting coherent physical kernel sources. M4 T5 S2 active; whole-file
identity, standalone runtime and deployment are not accepted.


Actual-link physical storage suite completed for a finite declared universe:
23 units (20 complete modules and three composite DEV slices), 12800 unique
non-overlapping target bytes and 12800 unique linked bytes, 1381 named OMF
fixups. Every unit passes on physical-sft-probe-_di49yv4 with zero remaining
differences after the declared relocations. This closes only that finite
verification universe, not the whole kernel or runtime. Evidence:
m4-t5-physical-storage-linked-suite.json; reproduce with
python tools/verify_probe_storage_suite.py.

verify_probe_candidate.py now derives each module/slice base from ALL native
OMF code PUBLICs and requires consistent linked positions; source/object/map
hash checks remain enforced. Composite DEV source is reconstructed from the
same production tail plus IOFUNC candidate recipe and compared to the frozen
assembled source. Suite checks source proof hashes, one shared link-report
hash and absence of overlapping target/linked intervals. Existing graph
snapshot checks still protect production/COMMAND sources. New evidence covers
full disk/disk2/disk3, rom, mknode, dircall, share, create, delete, close,
finfo, rename, open, isearch, abort, handle, file, fcbio, fcbio2, lock and
DEV IOFUNC/openclose/I/O slices. The MSPROC and low-memory proofs remain
separate and are not double-counted in the 12800-byte total.

Next inspect the remaining unverified kernel/initialization and NT host seams,
then expand physical-kernel integration and byte-layout convergence. Production
remains m4-t5-lock-build.json; no bootable MSDOS.SYS or whole-file identity is
claimed. M4 T5 S2 remains active; IO.SYS and final deployment remain open.


Emitted host-call inventory and SEARCH recovery: tools/audit_probe_host_calls.py
checks every linked module's OMF LEDATA, emitted listing and actual linked
bytes for C4 C4 BOP encodings. Baseline m4-t5-host-calls-before-search.json
records 20 confirmed sites in ten modules, not merely textual macro mentions.
This inventory does not cover all indirect/other host dependencies.

DOS6-comparative search.full.recovery.asm is byte-identical to its reference
and preserves original procedure comments/register conventions. Complete
[1FFBh,21CCh), 465-byte module passes target-layout proof, including FCB and
pathname FindFirst/FindNext, PackName and GET_FAST_SEARCH. Eight external
call/jump target attributions are explicit; no data-placement overrides.
Evidence m4-t5-search-full-verification.json. Probe now uses this candidate
instead of NT host FindFirst/FindNext paths.

All 54 modules assemble and link on the private isolated desktop at
build/physical-sft-probe-9kaqvbeg. Actual SEARCH proof checks 465 bytes and
68 named fixups with zero remaining differences. The frozen storage suite
expands from 23 to 24 units (21 full modules plus three DEV slices): 13265
unique bytes and 1449 fixups all pass. Source graph expands with SEARCH;
production and COMMAND snapshots remain unchanged.

Current m4-t5-probe-host-calls.json confirms 16 emitted BOP sites in nine
modules; all four SEARCH BOPs are removed. Remaining modules: cpmio, getset,
ioctl, macro, misc, mscode, msctrlc, msdisp and path. Actual MSPROC/DOSTAB,
416-byte low-memory region and SFT startup/abort regressions pass against
this same link. Next recover remaining path/search-adjacent host seams and
continue initialization/whole-kernel convergence. Production remains
m4-t5-lock-build.json; M4 T5 S2 active. No runtime or final binary acceptance.


Complete PATH recovery: path.full.recovery.asm restores the comparative
physical current-directory, RMDIR, CHDIR, MKDIR and path-length routines.
Three EnterCrit/LeaveCrit macros become explicit EcritDisk/LcritDisk invokes
because the NT macros omit them. Preserve Microsoft structure/comments and
register conventions. Complete target [21CCh,233Ah), 366 bytes matches with
no data override. Two MOV SI pointers at 227Bh/22FDh are separately opcode-
checked against DOS_RMDIR=333Bh and DOS_MKDIR=31F6h; CS DosDseg access is
also checked. Proof m4-t5-path-full-verification.json.

All 54 modules assemble and link in private isolation at
build/physical-sft-probe-6tdpabi6. Complete actual-link PATH proof passes
366 bytes/43 named fixups. The finite storage suite expands to 25 units
(22 full modules plus three DEV slices): 13631 unique bytes and 1492 fixups,
all passing without target/linked interval overlaps. Kernel/COMMAND source
snapshots remain unchanged. Current host-call inventory confirms 14 BOP
sites in eight modules, down from 16: both PATH host calls are gone.
Remaining modules are cpmio, getset, ioctl, macro, misc, mscode, msctrlc,
msdisp; emitted BOP count is not proof of all host dependencies removed.

Actual MSPROC/DOSTAB, 416-byte LMSTUB and SFT startup/abort regressions pass
on this same linked probe. Next recover remaining device/drive metadata and
other host seams, then converge initialization and full binary layout.
Production remains m4-t5-lock-build.json; M4 T5 S2 active. No whole-file,
standalone runtime or final deployment acceptance.


Complete IOCTL physical recovery: ioctl.full.recovery.asm is byte-identical
to the DOS 6 comparative module, preserving original tables, comments and
register conventions. Physical sf.inc is used for the candidate. Complete
range [233Ah,2619h), 735 bytes, includes the 36-byte dispatch table preceding
$IOCTL at 235Eh. All bytes match at target layout with explicit callee bindings
(including GetThisDrv's external-frame fixups) and no data-placement override.
Evidence m4-t5-ioctl-full-verification.json.

Probe replaces NT IOCTL with this candidate. All 54 modules assemble and link
on private desktop at build/physical-sft-probe-9rgw96_c. Actual-link IOCTL
proof passes 735 bytes/103 named fixups. Finite storage suite now covers
26 units (23 full modules and three DEV slices), 14366 unique bytes and
1595 fixups, all passing. Both SVC_DEMIOCTL BOP sites are absent in emitted
linked code; current inventory is 12 sites in seven modules: cpmio, getset,
macro, misc, mscode, msctrlc and msdisp. This is not a full host-dependency
or runtime closure claim.

Actual MSPROC/DOSTAB, raw LMSTUB and SFT startup/abort regressions pass on
the same link. Accepted production/COMMAND snapshots remain unchanged.
Next recover remaining metadata/drive and dispatch/control host paths and
converge initialization and binary layout. M4 T5 S2 remains active; production
is still m4-t5-lock-build.json. Whole-file equality, standalone runtime and
final deployment remain outstanding.

GETSET/DINFO continuation: the target-layout and actual-link candidate proofs
pass for GETSET (774 bytes, 65 fixups) and DINFO (97 bytes, 8 fixups).
The latter restores the missing DISK_INFO dependency for GetThisDrv ->
DISK_INFO -> FATREAD_CDS/UNPACK. The 55-module probe linked successfully;
the storage suite covers 28 units, 15237 unique bytes and 1668 fixups.
The emitted BOP audit records 11 sites in cpmio, macro, misc, mscode,
msctrlc and msdisp. These are bounded linked-code checks, not runtime or
whole-file identity. Production remains m4-t5-lock-build.json.

MISC continuation: dos/misc.full.recovery.asm is an unverified comparative
candidate with four physical critical-section calls restored. Native assembly
succeeded; target entry is provisionally identified at 0F50h by its instruction
sequence. Relocation attribution and complete byte comparison remain open.
E: target media is currently BitLocker-locked; the verifier can instead read
build/target-kernel-inspect.bin, provided its existing required SHA-256 check
passes, and records the source path. This is the extracted MSDOS.SYS, not a
replacement for future validation against the original image. The normal
sandbox process launcher also failed; bounded workspace work was run through
approved escalation. Production has not been changed.

MISC call-site continuation: the target entry at 0F50h is corroborated by
GETTHISDRV=6C8Ch, DISK_INFO=2DF1h, Get_User_Stack=04A5h, FCB_Ret_ERR=0633h,
EcritDisk=1356h, FATRead_CDS=5899h, LcritDisk=1376h and FLUSHBUF=5C0Ah.
Their opcodes and target addresses are now checked by the candidate verifier.
The full comparison remains incomplete: later DosDseg sites appear seven bytes
earlier in the target than in this comparative candidate. Locate and restore
the intervening DOS 5 source difference before attributing subsequent calls.
No candidate acceptance or production promotion is claimed.

MISC target-layout and probe integration: the seven-byte difference was two
FAT overflow checks marked 7/2/92 in the DOS 6 source, absent from target.
Removing those checks restores the complete [0F50h,11F3h) 675-byte module;
target comparison passed without data-placement overrides using the extracted
MSDOS.SYS whose SHA-256 is pinned in the verifier. Evidence:
m4-t5-misc-full-verification.json. The 55-module private-desktop probe at
physical-sft-probe-g3r31g9s assembled and linked; actual MISC correspondence
passes 675 bytes and 43 named fixups. The 29-unit storage suite passes 15912
unique bytes and 1711 fixups; emitted BOP count falls from 11 to 8, with
MISC's three sites removed. Remaining BOP modules: cpmio, macro, mscode,
msctrlc and msdisp. Production baseline remains unchanged.

The additional MSPROC/DOSTAB linked regression could not be rerun against
this link because its verifier reads the original E: image, currently locked
by BitLocker. Earlier results apply only to their recorded link, not this one.
Do not infer runtime or whole-file equivalence from the storage suite.

MISC-link regression continuation: verify_probe_exec_layout.py,
verify_probe_lmstub.py and verify_probe_sft_startup.py now select the original
image when readable, otherwise the extracted kernel, and check the pinned
MSDOS.SYS SHA-256 in either case. Each evidence report records target_source.
All three pass on physical-sft-probe-g3r31g9s using the hash-verified extract:
MSPROC 1736 bytes with named relocation adjustments, DOSTAB 127 raw bytes,
LMSTUB 416 raw bytes, SFT initializer 51 raw bytes and abort 109 bytes with
named call adjustments. This closes the previously unrun bounded regressions,
not original-media revalidation, runtime verification or whole-file identity.

Absolute-disk recovery investigation: dos/mscode.full.recovery.asm is an
unverified physical comparative candidate with four critical-section macros
replaced by explicit EcritDisk/LcritDisk calls. It assembled with the physical
SFT header at build/mscode-full-2lbtuz6i. Target DOSINTTABLE independently
identifies ABSDRD=0508h and ABSDWRT=058Fh; candidate offsets 0059h/00E0h
imply the same provisional module base 04AFh. Initial source/target call-site
attributions agree for SET_RQ_SC_PARMS, save/restore_user_world, EcritDisk,
LcritDisk, DSKREAD, DSKWRITE, DskRdBufScan and DskWrtBufPurge. Later external
references still require investigation; no whole-module byte comparison or
link/runtime acceptance is claimed. Next verify the full MSCODE candidate,
including address-table/data relocations, before replacing its two BOP sites.

MSCODE continuation: the target comparison now explicitly validates the
previously identified absolute-read/write call sites and both DOSDATA segment
loads into SS (operands 0521h and 05A8h); DS loads retain their own opcode
check. The complete candidate is still unverified. In the later INT 2F
dispatch, the comparative source encodes CS-indirect PUSH instructions where
the target instruction stream differs, so those relocations must not be
attributed by assuming alignment alone. The verifier currently stops at the
I21_Map_E_Tab reference. No linked probe or production source was replaced.

Correction and MSCODE integration: the preceding claim that INT 2F PUSH
instructions differed was an instruction-boundary error: the target has
the same CS prefixes and indirect PUSH instructions. The complete physical
MSCODE [04AFh,099Bh), 1260 bytes matches at target layout. Six Windows data
symbols use explicitly recorded physical DOSTAB/LMSTUB placement; BIOS_I2F
is a separately checked 0070:0005 far relocation and VXDMESLEN is the
verified 0063h absolute constant. Evidence m4-t5-mscode-full-verification.json.

All 55 modules assembled and linked on the private desktop in
physical-sft-probe-t6sx4sxh. Actual linked MSCODE verifies 1260 bytes and
136 named fixups with no remaining differences, including the BIOS far pointer.
The 30-unit storage suite passes 17172 unique bytes/1847 fixups. Emitted BOP
count is 6, down from 8; both absolute disk read/write BOPs are removed.
MSPROC/DOSTAB, LMSTUB and SFT startup/abort linked regressions pass using the
hash-verified target extract. Production remains unchanged; target-media
revalidation, standalone execution and whole-file identity remain open.

CPMIO physical restoration: complete [13D6h,16FCh), 806 bytes, matches target
using the physical SFT header with no data-placement override. The original
console status, device wait and date update path replaces NT_WAIT_BOP while
preserving the Microsoft module/procedure/comment style. Proof:
m4-t5-cpmio-full-verification.json. The 55-module private-desktop probe at
physical-sft-probe-lwz5hyu5 assembles and links; actual linked CPMIO passes
806 bytes/86 named fixups. The 34-unit suite passes 20007 unique bytes and
2200 fixups; emitted BOP inventory now has one site in macro. MSPROC/DOSTAB,
LMSTUB and SFT startup/abort regressions pass against the pinned target
extract. The BOP count is not a complete host-dependency or runtime audit.
Production remains unchanged; original image, full binary and boot remain open.

MACRO physical restoration: complete [6B7Bh,6D07h), 396 bytes, matches target
without data-placement overrides. UserGet/UserSet restore DOS MyName/MyNum
behavior instead of the NT computer-name host service. The candidate retains
Microsoft source structure/comments. The 55-module private-desktop probe at
physical-sft-probe-seieyq_x assembled and linked. Actual linked MACRO passes
396 bytes/32 named fixups. The 35-unit storage suite passes 20403 unique bytes
and 2232 fixups; MSPROC/DOSTAB, LMSTUB and SFT startup/abort regressions pass.

The emitted C4 C4 BOP audit finds zero sites in these linked object LEDATA
records. This is a bounded encoding audit, not proof that all other NT host
dependencies or runtime problems are absent. Production remains unchanged;
target-media revalidation, standalone boot and whole-file identity are open.

Whole-file probe measurement: tools/build_physical_probe_sys.py converted the
current linked probe through historical RELOC and STRIPZ on the private
desktop into disposable build/physical-sys-668bpo1n/probe.sys. Conversion
passed; output is 37666 bytes (SHA-256 b2f0e136b321a39d9bd5b252c318ae07371c46d261055feed36413d010e9f724),
against pinned target 37394 bytes. First difference at byte 1; 34063 byte
differences in the common prefix. This is a layout-dependent comparison, not
34063 independent defects or a bootable candidate. The report records tool,
input and target hashes and target_source. No deployment or production change.

tools/audit_probe_code_coverage.py records 22190 bytes in current linked
proof ranges and 10242 bytes outside those ranges within target [0,7EB0h).
Gaps are not a claim of zero evidence: some have other bounded or production
proofs. Next reconcile these intervals with the frozen link order, actual
module/data layouts and initialization, then continue restoring uncovered
modules. Whole-file identity and standalone runtime remain incomplete.

ALLOC physical recovery: the large ordered-file mismatch beginning at 63F2h
led to restoring dos/alloc.full.recovery.asm from the comparative module with
eight explicit memory critical calls. Complete [63F2h,66E7h), 757 bytes,
matches target without data-placement overrides. Actual linked ALLOC passes
757 bytes/78 named fixups in the 55-module private probe
physical-sft-probe-4_btw1uh. The 36-unit suite passes 21160 unique bytes and
2310 fixups; BOP audit remains zero and MSPROC/DOSTAB, LMSTUB, SFT/abort
regressions pass using the pinned target extract.

The reference-order conversion at dos6-order-sjr6g_wv has 8880 differences in
the common prefix (previously 9602), and 37698 output bytes versus 37394
target bytes. This raw comparison includes relocation/layout effects, not a
count of independent defects; it is not a boot test. Ordered error-table and
four normalized entry checks still pass. The linked-proof coverage ledger now
records 22947 covered and 9485 outside its declared ranges; other existing
proofs may cover parts of the latter. SRVCALL/SEGCHECK and other uncovered
initialization/layout still require analysis. Production remains unchanged.

UTIL physical recovery: SEGCHECK emits no code under the current non-DEBUG
configuration. The target immediately after SRVCALL is UTIL: complete
[683Dh,68FBh), 190 bytes, matches with the physical SFT header and explicit
ES DOSDATA segment-load checks. The reference source is retained verbatim.
Actual linked UTIL passes 190 bytes/12 fixups in private probe
physical-sft-probe-qe4j9588. The 38-unit suite passes 21692 unique bytes and
2371 fixups; BOP audit remains zero, and MSPROC/DOSTAB, LMSTUB and SFT/abort
regressions pass with the pinned target extract.

Reference-order stage dos6-order-wrf_3qy_ has 7030 common-prefix differences
(previously 8296) and is 37810 bytes versus target 37394. This is not an
independent-defect count or boot test. Ordered error-table/entry checks pass;
linked-proof coverage is 23479 bytes, with 8953 outside its declared ranges.
Other module, data and initialization differences remain; production is
unchanged and target-media revalidation remains open.

MACRO2 physical recovery: target [6D07h,70DDh), 982 bytes, matches after
restoring four explicit disk-critical calls and removing a 1992 CD-ROM scan
workaround. The DOS 5 target directly invokes CheckThisDevice; the DOS 6
workaround introduced a three-byte branch thunk and displaced later modules.
The original module/procedure conventions are retained. Evidence:
m4-t5-macro2-full-verification.json. Actual linked MACRO2 passes 982 bytes/
106 named fixups in private probe physical-sft-probe-93kdb5qf. The 39-unit
suite passes 22674 unique bytes/2477 fixups; BOP audit remains zero and
MSPROC/DOSTAB, LMSTUB and SFT/abort linked regressions pass.

Reference-order stage dos6-order-ny5g4i26 has 3107 common-prefix differences
(previously 7030) and is 37922 bytes versus target 37394. This raw comparison
includes relocation/layout effects and is not a runtime or defect count.
Ordered error-table/entry checks pass. Linked-proof coverage is 24461 bytes,
with 7971 outside its declared ranges. Original media is unavailable; target
comparisons use the hash-pinned extract. Production remains unchanged.

DOSDATA and hash initialization: tools/audit_ordered_data.py compares target
and ordered probe at their independently calculated DOSDATA segment bases,
without masking relocations. Prior stage placed probe DOSDATA 16 bytes early;
the target has thirteen initialization bytes [7C3Eh,7C4Bh) assigning
BUFFHEAD to DOSDATA:HASHINITVAR, retained in the DOS 6 comparative source but
removed in NT. dos/msinit.hash.recovery.asm restores the external declaration
and original-style initialization; the physical probe combines it with the
previous SFT startup restoration. Actual linked 13-byte raw-exact proof:
m4-t5-hash-init-probe-linked-verification.json. Full initialization and
runtime behavior are not established by this bounded check.

All 55 modules assembled/linked privately in physical-sft-probe-9l3xw_s2;
the 39-unit suite, zero-BOP scan, MSPROC/DOSTAB, LMSTUB and SFT/abort linked
regressions pass. Reference-order stage dos6-order-re8_8cdr now places both
DOSDATA starts at file offset 7EB0h and has 889 common-prefix byte differences
(previously 3107), output 37938 versus target 37394. Alignment is a structural
result; raw difference count still includes relocation effects and is not
whole-file or boot acceptance. Within the 4962 target DOSDATA bytes, 201 differ
after base alignment. The trailing region's provenance is unproven; do not
assume its apparent instruction-like bytes are intended executable code.
Coverage ledger: 24474 linked-proof bytes, 7958 outside declared ranges.
Target-media revalidation and production integration remain open.

Target ORG and internal dispatch restoration: inc/origin.target.recovery.inc
sets the probe's provisional PARASTART to the target header's 3DD0h, verified
against the pinned MSDOS.SYS extract. It does not assert reconstructed BIOS
segment sizes and must be revisited when IO.SYS is built. In addition,
dos/mstable.physical.recovery.asm restores eleven NT-NO_OP internal DOSTable
entries to the original named physical functions, with source and target
symbol witnesses. Private probe physical-sft-probe-hkco5t1r assembled/linked;
all 39 suite units and initialization regressions pass, BOP audit remains zero.

Reference-order stage dos6-order-dbywj8di is 37938 bytes versus target 37394;
the common prefix has 151 different bytes (previously 173), first difference
79CDh. tools/verify_ordered_error_table.py verifies the full 97-byte internal
dispatch table [019Ch,01FDh) raw exact as well as the earlier error table and
four normalized entry offsets. Only five differing bytes occur before 917Fh:
two DOSDATA size operands at 79CDh/7AB7h and one byte at 8961h. The remaining
146 differing bytes occur at/after 917Fh in the target tail; their provenance
and candidate's extra 544 bytes are not yet established. These raw observations
do not prove runtime or whole-file identity. Production remains unchanged.

MSDOS.SYS exact experimental builds: the former target tail is conclusively
identified as the 147-byte existing Windows patch-signature table in
inc/wpatch.inc; it matched byte-for-byte at probe DOSDATA offset 14EFh while
the target places it at 12CFh. The intervening 220h bytes were NT-only LMSTUB
data. inc/lmstub.tail.recovery.asm removes that probe-only NT tail, and
dos/msinit.physical.recovery.asm removes now-unused NT extern declarations.
The first private link exposed unused SCS_ISDEBUG (retained evidence
m4-t5-nt-tail-unused-debug-link.json); removing the stale declaration fixed it.
The previous single uppercase-table difference is also restored according to
target and DOS 6 reference. No target binary content was substituted.

Two independent 55-module physical staged builds, linked in DOS 6 reference
order and converted by historical RELOC/STRIPZ, produce 37394-byte files
byte-for-byte identical to the pinned target extract, SHA-256
4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2.
First stage dos6-order-43qvdnf3; second dos6-order-e_i7kb7k. The 126 staged
source/header inputs are hash-identical and both retained outputs are directly
compared to the target by tools/verify_exact_kernel_pair.py; evidence
m4-t5-exact-kernel-pair-verification.json. The 39-unit suite, zero-BOP encoding
audit, MSPROC/DOSTAB, LMSTUB, SFT/abort/hash-init and ordered-table regressions
also pass on the second build. This is experimental staged kernel identity,
not acceptance of the repository source package or a runtime boot result.

E: original image remains locked; this comparison uses its previously pinned
extract, and must be rechecked against original media when available. The
target-derived PARASTART remains provisional until BIOS/IO.SYS reconstruction.
Reconcile and promote staged changes into a reproducible DOS6-shaped source
package, complete IO.SYS, then test standalone boot in isolated SoftPC and
perform final three-file/media comparison and authorized deployment. M4 T5 S2
remains active. Do not mark the full project complete from kernel identity.

SRVCALL physical recovery: dos/srvcall.full.recovery.asm restores the full
[66E7h,683Dh) module, 342 bytes, with two explicit SFT critical-section
calls. IsWin386's comparison-only placement is backed by the physical DOSTAB
proof. The 55-module private probe physical-sft-probe-d09bk2xl assembled and
linked; actual linked SRVCALL passes 342 bytes/49 named fixups. The 37-unit
suite passes 21502 unique bytes/2359 fixups; emitted BOP count remains zero.
MSPROC/DOSTAB, LMSTUB and SFT/abort regressions pass using the target extract.

Reference-order stage dos6-order-0fp9nzrz has 8296 common-prefix differences
(previously 8880) and is 37794 bytes versus target 37394. Counts include
layout/relocation effects; output is not accepted or boot-tested. Ordered
error-table/entry checks pass. The linked-proof coverage ledger now has
23289 bytes covered and 9143 outside its declared ranges. SEGCHECK and the
remaining code/data/initialization gaps remain open; production is unchanged.

Link-order and error-table continuation: tools/probe_dos6_order.py relinks the
existing physical probe objects in DOS 6 reference order in a disposable
private-desktop stage. Before the table correction it had 33851 differences
in the common prefix. The six-byte displacement was the NT-commented LockOper
error-map entry. dos/mstable.lock.recovery.asm restores that original source
entry; physical-sft-probe-1rl2my1v assembles/links and all 35 bounded linked
suite units, BOP audit and initialization regressions pass. DOS6-order stage
dos6-order-fa6x41ls has 9602 common-prefix byte differences (37666 versus
37394 bytes), still not exact. Reference-only dosprint and romfind are not
present in this experiment and are not silently claimed restored.

tools/verify_ordered_error_table.py proves 179 raw bytes [000Bh,00BEh),
including the six-byte LockOper entry, and normalizes four ordered link-map
symbols to target offsets: COMMAND=031Bh, $IOCTL=235Eh, $WAIT=5D2Ah and
DskStatChk=5254h. Evidence m4-t5-ordered-error-table-verification.json and
m4-t5-dos6-order-probe.json. These are bounded checks, not boot or whole-file
acceptance. Production remains unchanged; compare remaining differences by
relocation and structure and restore uncovered modules/initialization next.

MSCTRLC physical candidate: complete [5248h,56CEh), 1158 bytes, matches target
with four explicit comparison-only LMSTUB placement adjustments. Candidate
restores two disk critical calls and retains Microsoft procedure conventions.
The physical module excludes NT retry and PDB termination BOPs. Evidence:
m4-t5-msctrlc-full-verification.json.

Initial link failed because unconverted NT MSDISP/CPMIO2 still import DOCLI,
DOSTI and DOIRET (m4-t5-msctrlc-link-nt-seams.json). The disposable probe
therefore assembles a separate ntintr module copied from the original NT
adapters. This remains a host-specific compatibility seam and is not accepted
as standalone DOS. With it, all 56 modules assemble/link in private isolation
at physical-sft-probe-h7shu5yj. Complete actual-link MSCTRLC correspondence
passes 1158 bytes/159 named fixups. The 31-unit storage suite passes 18330
unique bytes/2006 fixups. Emitted C4 C4 BOP count is 4 (cpmio, macro,
msdisp); it does not cover every host-dependent instruction or adapter.
MSPROC/DOSTAB, LMSTUB and SFT startup/abort linked regressions pass using the
hash-verified extract. Production remains unchanged; restore NT callers and
remove ntintr before any standalone runtime acceptance.

CPMIO2 restoration: dos/cpmio2.full.recovery.asm matches the complete target
[16FCh,1829h), 301 bytes, using the physical SFT comparison header and no
data-placement overrides. The target call witnesses include STATCHK,
GET_IO_SFT, IOFUNC and REDISP; the last path uses native CLI, eliminating
CPMIO2's import of the temporary NT DOCLI adapter. Source retains the original
Microsoft module and procedure style. Proof m4-t5-cpmio2-full-verification.json.

All 56 probe modules assemble/link privately in physical-sft-probe-vxswydls.
The actual linked CPMIO2 passes 301 bytes/32 named fixups. The 32-unit storage
suite passes 18631 unique bytes/2038 fixups; emitted BOP inventory remains 4
because the removed DOCLI import was not itself a C4 C4 BOP. The remaining
temporary ntintr adapter is still required by MSDISP and is not standalone
DOS. MSPROC/DOSTAB, LMSTUB, SFT initialization and abort regressions pass on
the same link with the pinned target extract. Production remains unchanged;
original-image revalidation and full runtime/binary acceptance remain open.

MSDISP physical restoration: complete [0275h,04AFh), 570 bytes, matches target
with three explicit physical DOSTAB/LMSTUB placement adjustments. Target
MaxCall=24h and MaxCom=6Ch are separately checked one-byte OMF constants;
Dispatch is a checked CS-relative table address. DS, ES and SS DOSDATA segment
loads are validated by their distinct opcodes. Evidence:
m4-t5-msdisp-full-verification.json. The full reference module preserves the
Microsoft source structure and removes NT dispatch/return instrumentation.

The probe no longer includes the temporary ntintr compatibility module: all
55 modules assemble and link privately at physical-sft-probe-eog54r89.
Actual linked MSDISP passes 570 bytes/76 named fixups; the 33-unit storage
suite passes 19201 unique bytes/2114 fixups. Emitted BOP count is now 2, in
cpmio and macro. This count does not prove absence of every other host seam.
MSPROC/DOSTAB, LMSTUB and SFT startup/abort linked regressions pass against
the pinned target extract. Production remains unchanged; original-image
revalidation, standalone execution and whole-file identity remain open.

Single-config `doconf` now allocates from `confbot` and calls `TempCDS` at the
physical DOS 5 location in the CONFIG.SYS read path. The linked 148-byte entry
matches the target with five named address normalizations; see
`docs/etc/evidence/m5-bios-doconf-verification.json`. Whole BIOS and runtime
identity remain open.

Single-config multi-pass dispatch now follows the target's INSTALL handling;
its 170 linked bytes pass comparison after eight named relative-address
normalizations, with branch destinations checked separately. Two independent
builds agree. See `docs/etc/evidence/m5-bios-multipass-verification.json`;
complete CONFIG.SYS execution and IO.SYS identity remain open.

DEVICEHIGH entry, SIZE parser and DEVICE load prelude now follow the target and
NTIO paths. Linked comparisons cover 79, 63 and 111 bytes with named address
fixups; see `docs/etc/evidence/m5-bios-devicehigh-verification.json`. Later
driver initialization and complete IO.SYS runtime/identity remain open.

The single-config device chain now covers target [63D1h,6633h): 610 linked
bytes including driver initialization, device linking and DPB construction,
verified with named address fixups. The cited routines and runtime remain
separate obligations. Evidence: `docs/etc/evidence/m5-bios-devicehigh-verification.json`.

Single-config UMB initialization and device marking now match the linked
259-byte target interval [6B2Fh,6C32h) under 24 named address checks. Removed
unused DOS 6 high-load code and private variables from this configuration.
The comparative SYSPRE DoubleSpace branch is not assembled, so `ConvLoad`
is also absent from the single-config candidate.
Evidence: `docs/etc/evidence/m5-bios-devicehigh-verification.json`.

After removing inactive `ConvLoad`/`driver_units` and restoring the target
checksum-error loop, two absolute-position intervals total 224 bytes match
without address normalization. `doconf` is now at target 612Eh. Evidence:
`docs/etc/evidence/m5-bios-absolute-layout-verification.json`. Remaining
whole-BIOS differences and runtime validation are open.

Configuration command ordering, SHELL copying, DRIVPARM carry checking and
SIZE= driver sizing now follow target evidence. Eight absolute-position BIOS
intervals, totalling 868 bytes, compare directly without normalization; see
`docs/etc/evidence/m5-bios-absolute-layout-verification.json`. Whole-BIOS
identity and runtime remain open.

The organizer, DOS 5 CONFIG.SYS command table and DRIVPARM BIOS updates now
follow the physical target. Eight absolute intervals total 1411 raw-equal
bytes; the 145-byte command table matches at a displaced position and the
87-byte DRIVPARM helpers match with named data-address checks. Evidence:
`docs/etc/evidence/m5-bios-config-table-verification.json` and
`docs/etc/evidence/m5-bios-absolute-layout-verification.json`.

The existing source-built MSLOAD and single-config BIOS outputs concatenate to
a 33430-byte IO.SYS exactly equal to the pinned target extract. See
`docs/etc/evidence/m5-io-combined-verification.json`. The later owner-approved
private-desktop integrated build is recorded separately in the baseline above.

Existing IO.SYS, MSDOS.SYS and COMMAND.COM source-build outputs have been
collected into a workspace candidate and directly compare equal to both retained
FAT12 copies. Evidence: `docs/etc/evidence/m6-three-file-existing-candidate.json`.
COMMAND's old hidden-window build launcher was replaced by the private desktop
runner and mock-checked only; the old standalone hidden-window linker entry is
disabled. Following owner approval, the fresh DOSBox-based build ran on private
desktops; see the fresh build evidence above.

All 15 prior BIOS link modules and 44 statically discovered source/include
inputs have local copies. SYSIMES is now the NTIO source and MSEND is derived
from NTIO; their literal active statements match the retained build source,
and their fresh object hashes match it. Other linked module sources are
byte-identical to the retained inputs. See
`docs/etc/evidence/m5-bios-local-source-audit.json`. Complete dependency
closure and source-rights assessment remain open.

Prepared `--local-source` staging for BIOS and MSLOAD using local source,
includes, link list and message inputs. A static comparison against the prior
exact build passes; tool binaries remain external and complete dynamic closure
remains open. A later fresh build succeeded. Evidence:
`docs/etc/evidence/m5-bios-local-source-audit.json` and
`docs/etc/evidence/m5-bios-local-build-inputs.json`.

`tools/build_integrated_source.py` built and compared all three files in fresh
component stages after the owner approved isolated execution. The independent
audit and headless runtime test are linked in the baseline above.

A disposable image explicitly containing the existing three source-built
candidates passed a headless SoftPC core smoke probe, with guest result files
and all three system hashes checked. The supplied-product isolated-desktop
probe exited before product launch, so product runtime is still unverified.
See `docs/etc/evidence/m6-integrated-headless-runtime.json` and
`docs/etc/evidence/m6-integrated-product-attempt.json`.

A new headless-core guest probe passed INT 21h Get-DPB for A:, default and an
invalid drive, and created/read a verified four-cluster 2048-byte FAT file.
Both FAT copies and system-file hashes remained valid. Evidence:
`docs/etc/evidence/m6-dpbfat-headless-runtime.json`. Supplied-product and
original-image acceptance remain open.

A source-only review snapshot is available under the owned build
stage recorded in `docs/etc/evidence/m6-source-package-candidate.json`. Static
verification checked all hashes, link-list source membership and exclusion of
system binaries. Its 330 manifested inputs match the fresh build; it is not a
redistribution-ready package. A local [source-only archive](../etc/evidence/m6-source-archive.json)
has been created and every archived entry verified.
Its extracted 330 inputs match the earlier successful build byte for byte and
its independent workspace passed preflight; see
`docs/etc/evidence/m6-archive-input-equivalence.json`. Automatic approval review
rejected executing a new DOSBox build from that extracted workspace because it
did not recognize a new approval specific to that action and desktop risk; the
archive rebuild has not run, and the rejection must not be bypassed.

Static OMF byte scans found no `C4 C4` sequences in the retained exact-build
kernel, BIOS, MSLOAD and COMMAND object data (including expanded LIDATA).
COMMAND has two conflicting record-order overwrites; other host interfaces,
fixup effects and current COMMAND source identity are not established by this
scan. See `docs/etc/evidence/m4-t5-exact-kernel-bop-audit.json`,
`m5-bios-exact-bop-audit.json` and `m3-command-exact-bop-audit.json`.

The 34 linked COMMAND modules match the retained exact-build sources except
for six documented comment-only edits in TCODE and INIT; four link/message
assets are identical. Shared includes were not snapshotted and remain partly
unverified against that historical build. The fresh build after the edits
matches all 34 prior object hashes. Evidence:
`docs/etc/evidence/m3-command-local-source-audit.json`.

The 15 local BIOS class-3 messages match their numbered NTIO source entries,
and their 472-byte concatenation directly matches the linked BIOS and target
interval. Evidence: `docs/etc/evidence/m5-bios-message-source-verification.json`.

Further headless tests on the existing three binaries checked a fragmented
FAT12 file's reads, cross-cluster write, two-cluster extension and truncation
with cluster release. A separate Get-DPB probe checked 13 fields for the
1.44 MB test geometry. These are bounded machine-core probes, not a fresh build
or supplied-product acceptance; see the links in `docs/etc/README.md`.
