# DOS 7.00.950 quality audit against effective DOS 6.22

## M6 T25 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; T25 follows closed T24
Admission And Approval | Owner requested same audit/repair standard for v7.00.950 and explicitly replaced DOS6.0 reference with v6.22
Objective | Minimize unnecessary differences from effective v6.22 source while retaining required 950 behavior, current structure and exact three outputs
Non-goals | No independent DOS6.0/OpenNT/DOS4/other-version source comparison, no retargeting the accepted 950 triple, no full reference copy or worktree
Reference Baseline | Effective v6.22: 225 baseline paths with its local overlays selected first; each hash verified against accepted cmd-19618-967 build copy
Candidate Proposal | Freeze actual DIR order; classify equality only against effective reference; audit all nonidentical/new files sequentially; compile each modified file before accepting later files
Files And ABI Surface | All 293 files under bios, cmd, dos, inc, lang; extras tools/resources are build dependencies and evidence, not part of this frozen source universe
Applicable Rules | Latest v6.22-only owner requirement overrides historical broader references; CMD/BAT/C only; no Computer Use or forbidden temp paths; preserve existing Microsoft-style structures and empty conditions
Verification | Frozen source/reference hashes, per-file disposition, affected compilation after each edit, all three outputs against own 950 targets; unchanged files need no redundant build
Expected Markers | Raw DIR ordinal, source hash, effective reference supplier/hash, disposition, compile/object/output evidence for every edit
Asset Needs | Existing original tools and accepted CMD build, isolated compiler desktop, ignored extras/build; assets remain extras/assets
Reporting Requirements | Current ordinal/total; modified/exact/necessary/no-reference counts; distinguish global hash classification from completed review
Stop Conditions | Unexpected source/reference drift, lost provenance, compiler failure or changed target bytes; resolve before advancing
Exit Criteria | All 293 files dispositioned, every source edit verified, separate full-scope completion audit and three exact outputs
Original Owner Request | Admit new audit/repair task for v7.00.950, with v6.22 as audit baseline
Similar-Issue Sweep | Unnecessary text changes, duplicate implementations, unjustified new modules, conditional branches, relocation/alignment, source-generated resources versus opaque bytes

S1 active. T13's historical deferred provenance work remains deferred and is
not marked complete by this audit. Archived prior packet: history/pre-T25-current.md.
Owner-directed T25 is this conversation's active work; no v7.10 source touched.

## Frozen scope

etc/T25/dir-raw.txt is the completed actual dir /a /b /s output, filtered into
inventory.csv without sorting. 293 files: 90 exact, 133 differing, 70 without
same-name effective-reference files. Later entries remain pending even if their
hash classification is already known. reference.csv freezes all 225 effective
v6.22 paths, supplier paths and hashes; v6.2 supplier paths are inherited v6.22
inputs verified against the accepted v6.22 build, not an independent reference.

## Initial prefix review

1. bios/apmequ.inc: exact effective v6.22 source; no edit.
2. bios/biosmsg.asm: no same-name reference. Small resource-only module exports
   BCode_end, includes the language resource table and emits its target trailer.
   IOSYSMSG and the resource length are documented at target file offset 4B92h
   in bios-code-resource-mapping-evidence.json; original target observations
   record 99 MPAD units. Existing makefile links this module at the resource
   boundary. Keep symbolic length, REPT and resource/include organization;
   no duplicate implementation or justified merge within unchanged structure.
3. bios/biosseg.inc: retain BYTE_BIOS_INIT/BYTE_SYSINIT alignment branches.
   Existing word-aligned declarations remain intact in ELSE; byte-aligned
   variants are selected by actual consumers (including MSINIT and SYSINIT).
   The same options are preserved in ROMDOS and non-ROMDOS forms. Do not delete
   these as unused branches or force reference alignment onto the 950 layout.

Initial prefix counts: modified 0; exact 1; necessary difference 1; no same-name reference 1.
Current three assets were directly FC/B compared with own frozen 950 targets:
IO.SYS, MSDOS.SYS and COMMAND.COM all equal. This is an existing-asset check,
not a claim that a new build has run. The accepted six-byte MSDOS.SYS config
remains the target; other media provenance does not silently change it.

## Current prefix: 124/293

Modified source/build files 54, exact 21, necessary unchanged 13,
no same-name reference unchanged 36. Next: 125, cmd/command/tcmd1b.asm. Tooling modified
1 (ioimage.c case-insensitive map symbol lookup), outside source count.
See etc/T25/part1.md. BIOSTAIL.OBJ is unchanged; all compiler/link phases ran,
then packaging failure was diagnosed and repaired. Fresh three-output FC/B
checks pass after resumed packaging; 293 current inputs match build copies.
Original failed build record retained. Final full automatic build is still
required before closing T25. Stage: extras/build/cmd-21179-26898.

See etc/T25/part2.md for files 11-20. Each additional source edit was freshly
assembled and its OBJ checked byte-identical before proceeding. CFGPUB uses
the same OMF ordering step as production. These incremental checks inherit
the previously verified images rather than claiming fresh full links.
See etc/T25/part3.md for files 21-37. BIOS makefile now uses the reference
link_opts form and message dependency grouping. NMAKE /a rebuilt BIOS/loader;
both generated binaries are unchanged. Repacked IO.SYS equals its target;
the two unaffected images also compare exact. All 293 source inputs verified.
See etc/T25/part4.md for files 38-44. MSBIO1 restores reference error-return,
calendar data and vector-table forms; MSBIO2 restores its unchanged broadcast
paragraph; MSCHAR restores retry-count comments. Each edit passed a BIOS/loader
rebuild and fresh IO.SYS repack before advancing. All three target checks pass.
See etc/T25/part5.md for files 45-50. MSDIOCTL restores the original disabled
comment-block form; MSDISK removes a duplicate constant and restores the
reference error-table declarations and symbolic ROMREAD. Each passed the
affected BIOS/loader build and fresh IO.SYS comparison before advancing.
See etc/T25/part6.md for files 51-54. MSINIT restores inherited floppy
initialization paragraphs and corrects stale pointer comments; MSINT13 uses
existing Windows/HMA function symbols instead of numeric literals. Each
passed a separate BIOS/loader rebuild and fresh IO.SYS packing, with all three
own target comparisons exact. MSLOAD and PATHSRC retain necessary target
behavior without edits. Latest stage: extras/build/t25-msint13-27044-30683;
build evidence is recorded in file52-build.txt.
See etc/T25/part7.md for files 55-65. Eight PnP modules have clearer interface
contracts; seven replace address-derived local labels with operation names.
Each was freshly assembled and its OBJ verified byte-identical before the
next edit. Explicit Toshiba near jumps changed encoding under original MASM;
that attempt was reverted and the final source reverified. POWER/POWER.INC/
PTIME are exact effective-reference files. Latest verified stage:
extras/build/t25-pnptosh-28579-3394. Three inherited target images remain exact;
these checks do not claim fresh full linking or packaging.
See etc/T25/part8.md for files 66-68. RAPIOPEN replaces five fixed root-table
addresses with existing symbols; REGFIND removes a redundant entry alias and
names validation branches; REGINIT drops four unused externals. Each edit
was assembled and CONFIG.EXE freshly linked unchanged, then IO.SYS freshly
packed and verified exact. Other two inherited images also match targets.
Latest verified stage: extras/build/t25-reginit-29702-30830.
See etc/T25/part9.md for files 69-82. REGOPEN removes an unused external;
REGPDIFF corrects its calling-contract header. REGVM fixes its module title;
REGVMCAL replaces sixteen identical wrapper bodies with a parameterized MASM
macro, preserving every entry/service/argument size. REGREAD, REGROOT,
REGSTART and REGSTR retain necessary target behavior; six ROM files are exact
effective-reference files. REGOPEN passed fresh configuration linking and
IO.SYS packing; subsequent changed objects are freshly compiled byte-identical.
All three target comparisons pass. Latest stage:
extras/build/t25-regvmcal-31253-24515. Final full automatic build remains pending.
See etc/T25/part10.md for files 83-84. RQVALUE retains distinct API argument
contracts while sharing the local cores. SI1TAIL uses existing HMA symbols
for two function constants; required 950 initialization behavior is retained.
BIOS and loader rebuilt unchanged, freshly packed IO.SYS matches its target,
and the two inherited images also compare exact. All 293 inputs match stage
extras/build/t25-si1tail-31851-25394.
See etc/T25/part11.md for file 85. SI2FRONT restores 69 inherited conditional
jump lines and replaces three adjacent-byte expressions with boot_mode.
BIOS and loader rebuilt unchanged; freshly packed IO.SYS matches the target.
The other two inherited images also compare exact. All 293 inputs match
extras/build/t25-si2front-125-13495.
File 86 STKINIT restores 20 symbolic field/state/entry-size references from
the effective reference. A separate BIOS/loader rebuild and IO.SYS repack
passed unchanged; all three target checks and 293-input check passed.
Latest stage: extras/build/t25-stkinit-540-2287.
See etc/T25/part12.md for file 87. STSTATE restores the original h_buffers
declaration/comment while preserving necessary 950 state and aliases.
BIOS/loader rebuild and fresh IO.SYS comparison pass, as do the two inherited
image comparisons and 293-input check. Latest stage:
extras/build/t25-ststate-909-4441.
Files 88-89 are also recorded in part12.md. SYSCONF restores inherited
declarations and existing parser/device/CDS/system-call symbols; curdir.inc
supplies its actual CDS dependency. BIOS/loader rebuild and fresh IO.SYS
comparison pass, as do the two inherited images and all 293 source inputs.
SYSIMES retains the required indexed resource without edits. Latest stage:
extras/build/t25-sysconf-1552-24725.
See etc/T25/part13.md for file 90. SYSINIT1 uses inherited boot-header and
arena fields instead of hard-coded offsets, restores existing system-call
symbols and original INSTALL flag comments. BIOS/loader rebuild and fresh
IO.SYS match, as do the two inherited images and all 293 source inputs.
Latest stage: extras/build/t25-sysinit1-2091-28740.
File 91 SYSINIT2 restores 60 DOS call-number expressions and two configuration
command codes using existing symbols. BIOS/loader and fresh IO.SYS remain
byte-identical; two inherited target checks and 293-input check also pass.
Latest stage: extras/build/t25-sysinit2-2620-510; see part13.md.
See etc/T25/part14.md for file 92. SYSPRE restores inherited DOS service/error
symbols and matching declaration/instruction formatting. Required 950 preload
negotiation and reserved-memory/allocator placement remain intact. BIOS/loader
rebuilt unchanged, fresh IO.SYS matches target, and two inherited images also
match. All 293 source inputs match extras/build/t25-syspre-3449-10861.
File 93 BUILDMSG retains only necessary C-header and message-class format
differences; see part14.md. No edit or redundant build for this file.
Files 94-95 retain necessary message/parser ABI constants and link order;
see part15.md. Neither file changed or required a redundant build.
File 96 restores three inherited date-message comments and a blank separator.
Messages regenerated unchanged, original command build passed, repacked
COMMAND.COM matches its target; inherited IO.SYS/MSDOS.SYS also match.
All 293 inputs match extras/build/t25-command-skl-4367-16507. See part15.md.
File 97 uses the inherited flush/no-echo DOS service expression in the new
Ctrl-C check. Required resident checksum, message pointers and pipe cleanup
remain in their original flows. COMMAND rebuild/repack is byte-identical;
two inherited target images and all 293 staged inputs also pass.
Latest stage: extras/build/t25-command1-4749-28887; see part15.md.
File 98 restores eleven existing DOS service expressions and the original
ROMDOS conditional spelling. COMMAND rebuild/repack and all target checks pass;
all 293 inputs match extras/build/t25-command2-final-5297-32379.
Files 99/100 are respectively reference-exact and necessary unchanged.
See part16.md for files 98-100. File 101 restores 27 reference initialization
comment lines, original external declaration grouping and five DOS service
expressions. COMMAND rebuild/repack is byte-identical and all target/source
checks pass. Latest stage: extras/build/t25-copy-5742-19602; see part17.md.
File 102 retains required destination interface/action handling and shared
DestDelete cleanup. File 103 restores 76 reference lines and two continuation
comments while preserving 950 filename behavior. COMMAND rebuild/repack and
all target/input checks pass. Latest: extras/build/t25-copypr2-6199-17051;
see part18.md. File 104 restores inherited return comments and corrects the
old interface description for full switches, quotes, UNC and NUL input.
No instruction changed; original command build/repack and target checks pass.
Latest stage: extras/build/t25-cparse-6685-12932; see part19.md.
File 105 restores effective-v6.22 declaration/ASSUME formatting and the 16-bit
division paragraph, preserving 950 arithmetic and packed result representation.
COMMAND rebuild/repack and all target/input checks pass. Latest stage:
extras/build/t25-cratio-7064-14563; see part20.md. Next: 106 cmd/command/dir.asm.
File 106 restores inherited DIR code/comment formatting and twelve DOS service
expressions, and removes stale orphan headers. Required long-name/access-date,
output and disk-query behavior retained. COMMAND rebuild/repack and all target
and input checks pass; extras/build/t25-dir-8093-25207. See part21.md.
Files 107-110: retain default environment and separate initialization resource,
restore FORDATA's original header, verify IFEQU reference-exact. COMMAND build
and fresh repack pass; all target/input checks pass. Latest verified stage:
extras/build/t25-fordata-8589-20565; see part22.md. Next: 111 init.asm.
Files 111-112: INIT restores original PSP/batch/Carousel paragraphs and switch
comments, replaces seven DOS service constants with symbols, and relocates a
misplaced procedure header. IPARSE is reference-exact. COMMAND rebuild/repack
and all target/input checks pass; extras/build/t25-init-9317-25395.
See part23.md. File 113 corrects LOADHI's dynamic-buffer input comment and
restores declaration/CRLF consistency. COMMAND rebuild/repack and all target
and input checks pass; extras/build/t25-loadhi-9709-4484; see part24.md.
File 114 restores COMMAND makefile path variables, original dependency order
and shared formatting. Independent check verifies all 540 dependency edges
unchanged. Original COMMAND build/repack and all target/input checks pass;
extras/build/t25-command-make-10562-24538; see part25.md.
File 115 restores the inherited PARSE2 token loop and updates stale interface
comments. Original COMMAND rebuild/repack and all target/input checks pass;
extras/build/t25-parse2-11809-1661; see part26.md.
File 116 normalizes PATH1's necessary LFN/UNC branches and declarations to the
surrounding reference style. COMMAND rebuild/repack and all target/input checks
pass; extras/build/t25-path1-12286-30833; see part27.md.
File 117 removes PATH2's unused FORDATA include and ten unused added external
declarations; restores inherited search formatting and corrects interface notes.
COMMAND rebuild/repack and all target/input checks pass;
extras/build/t25-path2-12746-6262; see part28.md.
Files 118-120: restore RDATA inherited conditional/comment forms and service
symbols without layout changes; retain RESCLASS resource boundary and verify
RESMSG reference-exact. COMMAND rebuild/repack and all target/input checks pass;
extras/build/t25-rdata-13269-22071; see part29.md.
File 121 removes RUCODE's duplicate export and obsolete disk-message input
contract, restores inherited MsgRetriever comments and ten DOS service symbols.
COMMAND rebuild/repack and all target/input checks pass;
extras/build/t25-rucode-13899-32129; see part30.md.
File 122 retains required STUB relocation, A20 alias check, additional resident
entry pointers and pre-EXEC message checksum. Complete diff/caller review found
no safe unnecessary change; no edit or redundant build. See part31.md.
File 123 restores TBATCH's inherited EOF/label/echo/overflow/argument comments,
declaration and allocation-block formatting, and seek expression. Shared percent
expansion and required dynamic-buffer/path/notification behavior remain intact.
COMMAND rebuild/repack and all target/input checks pass;
extras/build/t25-tbatch-15022-26797; see part32.md.
File 124 restores TBATCH2's IF instruction formatting, inherited argument
comments and separate declarations. EOF sequence, LFN/UNC lookup and dynamic
command-buffer behavior remain intact. COMMAND rebuild/repack and all target
and input checks pass; extras/build/t25-tbatch2-15502-1181; see part33.md.
Next: 125 tcmd1b.asm. Full automatic final build remains pending.
