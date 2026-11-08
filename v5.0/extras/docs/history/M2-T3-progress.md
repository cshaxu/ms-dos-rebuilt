# Current state

## Current work

M2 T3 S1 is active, technical identity achieved and awaiting task closure audit: COMMAND.COM has rebuilt twice to all 47845 target bytes with zero differences. Authoritative result: [whole-file identity](../etc/evidence/m2-t3-command-identity.md). IO.SYS/MSDOS.SYS reconstruction, focused SoftPC shell tests, final package and deployment remain unfinished. M1 T2 is closed; see [audit](../history/M1-T2-build-audit.md). Older progress entries below are historical and superseded by this result.

## M2 T3 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Active goal authorizes progression from the verified reference build to target reconstruction. |
| Objective | Recover target COMMAND symbol constraints and module layouts; turn evidence-backed differences into source changes. |
| Non-goals | No opaque target-byte patching or claim of whole DOS recovery from partial matches. |
| Reference Baseline | T1 target hashes, T2 clean reference build and imported-source manifest. |
| Candidate Proposal | Goal and roadmap M2; T2 completion audit. |
| Files And ABI Surface | COMMAND source, include/layout definitions, analysis tools and evidence. |
| Applicable Rules | Execution, coding, architecture and documentation rules. |
| Verification | Rebuild from source; inspect symbol constraints, byte differences and applicable target tests. |
| Expected Markers | Consistent repeated symbol references and progressively verified target module bytes. |
| Asset Needs | Original image read-only; existing T2 build maps retained as disposable comparison inputs. |
| Reporting Requirements | Distinguish candidate mappings, direct matches, changed source and unresolved behavior. |
| Stop Conditions | Stop on conflicting symbol constraints or unaccounted byte substitutions. |
| Exit Criteria | First bounded set of symbol constraints independently corroborated and ready for source layout restoration. |
| Original Owner Request | 实现 MS-DOS 5.00 源代码考古恢复; continue active goal. |
| Similar-Issue Sweep | Apply consistency checks to all references of each inferred symbol. |

## Technical baseline

Target image: `E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img`, SHA-256 `168bd67f0d0feaca7f47c0677e64aab51666460c116dd8bbaf8343e83364948c`, length 258048 bytes. Its BPB declares 1474560 bytes. The [baseline evidence](../etc/evidence/m0-t1-s1-baseline.md) records repeatable FAT12 inspection, extraction and independent hash checks for the following.

| Target | Bytes | SHA-256 |
| --- | ---: | --- |
| IO.SYS | 33430 | dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0 |
| MSDOS.SYS | 37394 | 4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2 |
| COMMAND.COM | 47845 | 74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89 |

Both FAT copies match; no allocated cluster starts in the missing image tail, but that tail is not proven zero. A padded copy may be used as an explicitly qualified test medium; never alter the supplied image. The DOS 6 makefiles refer to a missing `v6.0/messages` directory; toolchain/resource completeness and all builds remain unverified. SoftPC and its configuration are in `O:\DOS`; the user authorizes changing that configuration for the task. No target build, VM boot, deployment, or source-level reconstruction has been verified.

Owned scratch: build/t2-s1 and build/t2-command. Reference compilation is owned by this executor; each MASM invocation has a 15-second limit, full run a 10-minute budget; per-module logs and exit results are in the stage and compact evidence JSON. No production DOS source is changed.

Latest evidence: full OpenNT COMMAND reference assembled, linked and converted to 50384 bytes; repeated link hash matched. Target remains 47845 bytes and unequal. Symbol-prefix map verifies the -256 MAP-to-COM bias and provides 212 unique-prefix candidates; no DOS 5 routine is declared restored. See the build investigation record.

First reconstruction slice: ForOff assembles to 39 target-identical bytes at COMMAND.COM offset 0x3286 using explicitly provisional target-address equates in its test harness. OMF record checksums and absence of fixups verified; no complete module or runtime equivalence claimed.

TFOR follow-up: full 718-byte reference module aligns with the target; all differences are in external operand words. Production tfor.asm is now an unchanged OpenNT module baseline; the prior ForOff experiment is in tests/fixtures. Includes and target linker layout remain unresolved.

Local source baseline now contains 109 imported COMMAND/include/message files; import provenance ledger retained. build/t2-local is owned active scratch. All 34 local-source object hashes match reference objects; generated message resources were reused and a clean local pipeline remains pending.

T3 entry reconstruction: tcode.asm now uses CLI/STI and omits the NT-only entry EXECPATH_SIZE reset. Clean candidate is 50309 bytes; first 80 TCOMMAND bytes align after address-word masking. Target exact match and behavioral verification remain incomplete.

T3 prompt recovery: restored three suppressed CRLF2/PRINT_PROMPT calls. Candidate 50318 bytes; 304-byte entry prefix matches modulo annotated address operands. Three call destinations verified against candidate MAP and target constraints. Full binary and runtime tests remain outstanding.

T3 REGCOM recovery: restored DOSKey/DOS buffered input and removed the host-only reentry/prompt/TSR subgraph. Corrected two target short-jump encodings. Clean build passes; 468-byte entry region now matches modulo address words. Full target identity and runtime verification remain outstanding.

T3 parser recovery: removed target-absent UNC special branch and empty-command NT path reset/CS override. Clean candidate is 48478 bytes. TCOMMAND-through-EXITJ instruction layout (759 bytes) matches modulo annotated address words. Exact data/layout recovery and runtime testing remain incomplete.

T3 resident prefix: removed two target-absent AX save/restore pairs in stub.asm. CheckA20 19-byte routine now matches exactly; Batch/EchoFlag MAP addresses match target constraints. Candidate 48462 bytes; Io_Stderr-related one-byte drift and other layout gaps remain.

T3 handle recovery: removed Io_Stderr after restoring target init/HeadFix behavior. Nine resident addresses now match; 70 HeadFix bytes match exactly. Clean candidate 48430 bytes; full image still differs and guest tests remain pending.

T3 PAUSE recovery: removed NT skip-pause condition; clean candidate 48416 bytes. Thirteen-byte opcode layout and all three call destinations verified. SCS_PAUSE initialization and final target addresses remain unresolved.

T3 init cleanup: removed target-absent COMSPEC host notification and six unused resident symbols (nine bytes). Clean candidate 48384 bytes; direct checksum entry verified modulo layout words. Four active NT state bytes still precede PIPEFILES; full target identity remains unachieved.

T3 startup: restored local version-error handling, removed host queries and /Z startup handler, switched init command-state query to 5500h. Removed two unused state bytes. Clean candidate 48208 bytes; first 120 ConProc bytes match modulo annotated words. Protocol responder and remaining init paths still pending.

T3 protocol/banner: query and responder use 5500h; removed NT first-instance/banner state. PipeFiles now equals target 0x31F and InitFlag=0x31D. Eleven responder bytes match exactly. Clean candidate 48192 bytes; remaining initialization, code/data differences and runtime tests outstanding.

T3 AUTOEXEC: restored local AUTOEXEC/KAUTOEXE paths and filename data, four-paragraph allocations and 49-byte resident copy. Clean candidate 48304 bytes; filename/storage checks pass. The 166-byte initialization slice retains four non-address differences in two exit branches; destinations verified, encoding/layout still unresolved. See ../etc/evidence/m2-t3-autoexec.md. S1 remains active; NT environment setup and full target/runtime equivalence remain outstanding.

T3 local environment/startup tail: removed host environment retrieval, restored date initialization and copyright calls, and permanent EXIT recycling. Latest clean candidate 48318 bytes (m2-t3-exit-build.json). The 113-byte environment and 228-byte AUTOEXEC/startup slices match modulo annotated addresses; both formerly differing exit jumps now match exactly. EXIT data operands and TCOMMAND destination verified. Full binary identity and guest execution remain outstanding; S1 stays active. Evidence: ../etc/evidence/m2-t3-environment.md.

T3 resident buffer: restored 80-byte MsgBuffer/SafePathBuffer. Clean candidate 48110 bytes (m2-t3-resident-buffer-build.json). DATARES/CODERES and ConProc boundaries now align with target. First 5216 bytes contain exactly 21 differing bytes within 15 identified later-layout operands; all other bytes equal. Earlier bounded environment/entry checks pass. Init DoDate remains +13 bytes and transient start +16 bytes; transient NT buffer/state adaptations remain. Evidence: ../etc/evidence/m2-t3-resident-buffer.md. No whole-target identity or guest verification yet.

T3 INIT module: removed the leftover early banner, CheckHelp /Z path and descriptor, and three unused file wrappers. Complete 2277-byte init.asm code contribution aligns at target 0x1460; 41 differing bytes are all annotated address words. Seven-switch parser header matches exactly; ICONDEV aligns at 0x1D50. Latest candidate 48062 bytes (m2-t3-init-z-build.json); prefix differences reduced to 14 bytes. Source/message/transient layout and runtime remain unfinished. Evidence: ../etc/evidence/m2-t3-init-module.md.

T3 executable path: removed NT pre-supplied executable branch and 37-byte cmdinfo; restored EXECPATH=131 bytes and path_search bound=128. Clean candidate 47868 bytes (m2-t3-execpath-layout-build.json); bounded path and 759-byte entry checks pass. Candidate remains unequal to target; 23-byte total size difference does not measure coverage. Message/data and transient code layout remain outstanding. Evidence: ../etc/evidence/m2-t3-execpath.md.

T3 initialization messages: restored target DOS 5 banner. The 839-byte initialization-message region now matches exactly; TCOMMAND aligns at 0x2324. First 8736 bytes have 18 remaining differing bytes in 14 later-layout operand words. Clean candidate 47900 bytes (m2-t3-message-build.json), still unequal; environment and entry regressions pass. Remaining transient internal layout/data and guest tests are pending. Evidence: ../etc/evidence/m2-t3-messages.md.

T3 PATH display: restored scasb2-based PATH display/copy and shared scan limit 0x100. Final candidate 47905 bytes (m2-t3-scan-limit-build.json). Nine sequential transient code contributions, 9331 bytes from 0x2324, match modulo listing-annotated address words; PATH call and scan routine match exactly. Next comparison: tenv2 at 0x4797. Full operands, remaining later code/data and runtime unverified. Evidence: ../etc/evidence/m2-t3-path-display.md.

T3 EXEC copy/PATH construction: restored REP MOVSB resident pathname copy and removed NT UNC bypass. Latest clean candidate 47888 bytes (m2-t3-path-unc-build.json). Twenty-one code contributions through cparse, 17379 bytes at 0x2324, match modulo annotated operands; exact edited sequences pass. Next: tparse at 0x6707, whose suppressed include listing needs inspection before treating operand differences as defects. Full binary and runtime remain unverified. Evidence: ../etc/evidence/m2-t3-exec-copy.md.

T3 full COMMAND identity: expanded parser listing without binary change, restored VER text/metadata, removed NT table and two unused data bytes. Two independent clean stages produce the target SHA-256 74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89; both direct comparisons find zero differences. See m2-t3-command-identity-build.json and m2-t3-command-repeat-build.json plus their verification/source-snapshot records. Next: separate T3 audit and focused COMMAND runtime validation; whole DOS goal remains active.
