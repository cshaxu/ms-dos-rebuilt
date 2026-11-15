# M6 T29 - Rebuild the Windows Me core

## M6 T29 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner designated S1 for the COMMAND.COM source package under the established minimum source diff standard. |
| Objective | Build the 3000 COMMAND.COM from the 2222 source with the smallest evidenced changes. |
| Non-goals | Other editions, duplicate implementations, target binary substitution, and guest execution. IO.SYS and its Astro component references remain in the subsequent T29 scope. |
| Reference Baseline | Effective v7.10.2222 source at `0e557eb928f84339d1718c82e15fbfe163526aa8`, including its pinned source inputs, plus the Astro component references identified in the [source and binary comparison](../etc/decoded-comparison.md), and the [Windows Me startup floppy](../etc/target-baseline.json). |
| Candidate Proposal | Use a source overlay in the inherited module layout, with extras/build.cmd as the entry point. |
| Files And ABI Surface | COMMAND and its shared include files, message resources and historical build inputs. |
| Applicable Rules | [Execution](../../../../v7.10.1998/extras/docs/rules/EXECUTION.md) and [coding](../../../../v7.10.1998/extras/docs/rules/CODING.md). |
| Verification | Check target and baseline hashes and map exact matching binary ranges. Build COMMAND.COM from pinned source and compare the complete file with the floppy. |
| Expected Markers | S1 requires a direct COMMAND.COM byte match, matching SHA-256 and verified publication. |
| Asset Needs | Freeze targets in ignored extras/baselines/targets. Keep subsequent build evidence and published copies under the version extras tree. |
| Reporting Requirements | Report modified and identical source counts and distinguish packed bytes, linked code matches and completed products. |
| Stop Conditions | Do not infer source changes from compressed offsets. Investigate unexplained mismatches before publishing. |
| Exit Criteria | S1 closes when the source overlay builds and publishes the exact floppy COMMAND.COM. T29 closes after three exact products and a pushed closure audit. |
| Original Owner Request | Build the v8.00.3000 COMMAND.COM source package as T29 S1. |
| Similar-Issue Sweep | Check version and copyright resources, and account for loader, compressed payload, and any appended IO.SYS sections separately. |

P1 freezes the OAK floppy targets, verifies the three 2222 product hashes, and records the [initial block comparison](../etc/block-baseline.md). Source changes: zero. Next work is to align the decoded IO.SYS payload with the 2222 linker map and align COMMAND ranges to the existing source modules.

P2 decodes the IO.SYS payload and localizes exact block reuse in the BIOS, DOS kernel, configuration manager and COMMAND. It records Astro as a component source baseline, with confirmed and prospective component mappings. No product source changed.

P3 integrates the Windows Millennium banner and 4.90.3000 version string into the historical build. Stage `cmd-10845-25468` produced a 93,906-byte COMMAND.COM with unchanged source snapshots. Three of the 120 baseline paths in cmd/command, inc and lang/usa/messages differ. The target byte comparison remains open, and no asset was published.

P4 restores the CHCP query-only path, CHCP help and restart messages, and the target resident stub layout. Stage `cmd-11626-5666` produced 93,833 bytes and matched the complete 3000 message resource area. The linked code still requires the remaining startup and DIR changes. Seven source paths are changed against the 120-path baseline in this delivery.

P5 connects the DOS 8.00 startup check and VDM restart prompt, completes the resident stub stack layout, and applies the existing uncompressed-volume DIR configuration. Stage `cmd-12713-13173` assembled and linked 92,963 bytes with an exact message resource area. The byte gate remains open. Eleven of the 120 baseline source paths differ.

P6 aligns DIR with the target, retaining the inherited switch and sort table and restoring the UNC disk-space query and directory entry layout. It removes obsolete APPEND command hooks, aligns the transient parser and stack, and restores the embedded DOS 8 copyright strings. Build stage `cmd-15535-26452` exited 0. All input snapshots match. Full byte comparison and SHA-256 passed for the 93,040-byte COMMAND.COM. An independent comparison confirmed that the published copy and the file extracted from the OAK floppy are identical. The effective 2222 source universe in cmd/command, inc and lang/usa/messages has 16 modified and 104 identical paths, with no additions or deletions.

S1 closed after the COMMAND source overlay, historical build entry, direct byte match, target hash and publication were verified. T29 remains open for the remaining core files, including the Astro component work identified for IO.SYS.

## M6 T29 S2 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner admitted the IO.SYS build and mapping baseline. |
| Objective | Establish a reproducible historical IO build and a source-linked comparison map for the decoded 3000 target. |
| Non-goals | Implementation of 3000 changes or exact recompression. |
| Reference Baseline | Effective 2222 source at `0e557eb928f84339d1718c82e15fbfe163526aa8` and the [frozen Windows Me floppy](../etc/target-baseline.json). Astro references remain pinned as recorded in the component comparison. |
| Candidate Proposal | Reuse the historical command-line toolchain with the io-baseline entry. Compare compiled component images and the target payload in explicit address spaces. |
| Files And ABI Surface | IO loader, BIOS, DOS kernel, SYSINIT and configuration maps. No DOS source edits in this packet. |
| Applicable Rules | [Execution](../../../../v7.10.1998/extras/docs/rules/EXECUTION.md) and [coding](../../../../v7.10.1998/extras/docs/rules/CODING.md). |
| Verification | Rerun the independent build, verify linked outputs and hashes, directly check anchor bytes and match source and tool input snapshots. |
| Expected Markers | 2222 IO.SYS identity, 278,016-byte decoded target identity and usable link maps. |
| Asset Needs | Original target in extras/baselines/targets and stage outputs in ignored extras/build. |
| Reporting Requirements | Track modified and identical product source paths, exact same-origin byte ranges, and still unassigned boundaries. |
| Stop Conditions | Flag any reference mismatch or unsupported object attribution before advancing. |
| Exit Criteria | Reproducible IO baseline build and source-linked block maps, with provenance and outstanding boundaries recorded. |
| Original Owner Request | Admit S2 and execute the first IO.SYS subtask. |
| Similar-Issue Sweep | Cross-check offset spaces, stripped and EXEPACK images, and linker contributions that are only present in memory. |

P1 built and verified the [IO.SYS baseline and object maps](../etc/io-build-baseline.md) in stage `io-17513-19154`. It changed zero product source paths and verified 242 identical paths in the build scope. S2 is closed. Exact CM/DS re-encoding is the next S.

## M6 T29 S3 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner authorized continuous IO.SYS recovery through final verification. |
| Objective | Reproduce the 3000 CM/DS stream exactly and identify its container boundaries. |
| Non-goals | Loader and trailer assembly recovery and full IO integration belong to the later implementation packets. |
| Reference Baseline | [S2 IO baseline](../etc/io-build-baseline.md) and the [Windows Me OAK target](../etc/target-baseline.json). |
| Candidate Proposal | Implement the proved longest-match policy in C and run it from the existing baseline entry. |
| Files And ABI Surface | CM/DS block headers, match coding, sector markers, alignment and trailer boundary. |
| Applicable Rules | [Execution](../../../../v7.10.1998/extras/docs/rules/EXECUTION.md) and [coding](../../../../v7.10.1998/extras/docs/rules/CODING.md). |
| Verification | Compare the encoded 3000 stream directly against the frozen file and round-trip a separate input. |
| Expected Markers | All six DS blocks and the aligned CM terminator match. |
| Asset Needs | Use the existing ignored target and stage paths. |
| Reporting Requirements | Record exact stream bytes, block counts, source file counts and separately mapped code extents. |
| Stop Conditions | Locate the first mismatching token or compare offset before accepting the encoder. |
| Exit Criteria | Exact CM stream generated from the payload and the output boundaries recorded. |
| Original Owner Request | Continue to fully recover IO.SYS using the established S route. |
| Similar-Issue Sweep | Verify all six target chunks, cross-block dictionary reset and a partial final sector. |

P1 closed S3. The C encoder produced the [exact 111,840-byte CM stream](../etc/io-cm-encoder.md) in stage `io-20237-4893`. Zero product source paths changed and all 242 baseline paths match. The loader and startup decompressor are retained as explicit assembly recovery items in the subsequent IO work.

## M6 T29 S4 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner authorized continuous IO.SYS recovery. |
| Objective | Restore DOS BIOS and DOS kernel code and service interfaces against the decoded 3000 target using the 2222 layout and symbols. |
| Non-goals | Integrated Astro driver implementations and final container assembly are covered in later S packets. |
| Reference Baseline | [S2 linked objects and target anchors](../etc/io-build-baseline.md) and the frozen 2222 source. |
| Candidate Proposal | Link the DOS kernel from the 3000 source overlay. Resolve coherent interrupt and dependency groups against the decoded payload. |
| Files And ABI Surface | DOS dispatch, disk/DPB/FAT services, and the BIOS and kernel interface. |
| Applicable Rules | [Execution](../../../../v7.10.1998/extras/docs/rules/EXECUTION.md) and [coding](../../../../v7.10.1998/extras/docs/rules/CODING.md). |
| Verification | Actual assembly and link, stable source snapshots, and block comparisons that distinguish relocated operands from instruction changes. |
| Expected Markers | Exact blocks and independently identified remaining references. |
| Asset Needs | Retain linked binaries, maps and listings under ignored extras/build. |
| Reporting Requirements | Modified and identical source counts, relevant aligned block bytes and remaining instruction or reference changes. |
| Stop Conditions | Resolve link errors and unsupported target mappings before accepting a block. |
| Exit Criteria | Covered BIOS and kernel service blocks linked and verified against their target positions, with real driver coupling recorded for S5–S7. |
| Original Owner Request | Continue until IO.SYS is fully rebuilt. |
| Similar-Issue Sweep | Check related branch encodings, calling conventions and duplicate entry paths in each audited group. |

P1 introduced `extras/build.cmd io-kernel` and rebuilt the DOS kernel with the 3000 source overlay in stage `io-21207-18674`. The 185-byte version and error-map prefix matches target payload offset 34,356 in full. The 1,344-byte Get/Set object aligns at target offset 36,793. Three near branches have the exact 3000 encodings, four interrupt-mask instructions were removed, and 1,293 bytes directly match at corresponding local offsets. The 51 other bytes remain for linked-reference verification. One source file changed in P1. The staged 242-path scope has five changed and 237 identical files against 2222, including four inherited S1 changes.

P2 rebuilt the kernel in stage `io-22049-6483` after updating the dispatch branches in `mscode.asm`, cache handling in `buf.asm`, and the file-pointer path in `diskset.asm`. At mapped target block offsets, the build directly matches 765 of 1,172 dispatch bytes, 442 of 753 cache bytes, and 151 of 183 disk-setup bytes. These are local comparisons. Other bytes still include instruction and link differences. Three source files changed in P2. In the full build scope, eight of 242 source paths differ from 2222 and 234 match exactly.

P3 rebuilt `fat.asm` and `crit.asm` in stage `io-23134-3242`. The complete 211-byte critical-section object exactly matches target payload offset 40,552. FAT restores the target register saves in the error path, the media-change path, and FSINFO branch changes. Its 1,715-byte code object is one byte shorter than the 1,716-byte target block. The remaining length difference is accounted for by a 32-bit absolute memory address and a short conditional branch. Linked operand values remain to be compared after layout integration. Two source files changed in P3. Against 2222, ten of 242 staged source paths differ and 232 match.

P4 rebuilt the complete 2,097-byte `misc.asm` object in stage `io-24492-18131`. At target payload offset 38,148, 2,029 bytes match directly. The Get-DPB and extended drive branches, PSP copy width and DOS version initialization are assembled from the existing procedures. FAT now uses the target short error branch after reading the boot buffer. The shared DOS segment load still accounts for the three-byte difference in FAT code length. Two source files changed in P4, of which `misc.asm` is new to the overlay. Against 2222, 11 of 242 staged source paths differ and 231 match.

P5 rebuilt `dir.asm`, `dir2.asm`, `dev.asm` and `mknode.asm` in stage `io-25217-12213`. Direct matches at mapped object starts are 883 of 951 bytes for DIR, 748 of 787 for DEV, and 1,109 of 1,158 for MKNODE. These three object lengths match the target, and the MKNODE instruction sequence matches when address operands are disregarded. The unchanged 412-byte FCB object matches 405 bytes at its relocated position. DIR2 retains a three-byte address-width difference and a two-byte branch-width difference. Four source files changed in P5. Against 2222, 15 of 242 staged source paths differ and 227 match.

P6 rebuilt FAT and DIR2 in stage `io-26242-12108`. Both code objects now have the target lengths. FAT directly matches 1,661 of 1,716 bytes at payload offset 68,283. DIR2 directly matches 1,038 of 1,066 bytes at offset 51,551. The two confirmed 32-bit addressing sites use a common macro that leaves the DOS segment address to the linker. Other uses of the existing 16-bit macro retain their original encoding. Three files changed in P6. Against 2222, 16 of 242 staged source paths differ and 226 match.

P7 rebuilt the absolute disk I/O, disk write and ROM disk procedures in stage `io-26709-9035`. All three object lengths match the target. Direct comparisons at the confirmed target offsets give 363 of 387 bytes for DISKIO, 1,069 of 1,127 for DISK3 and 1,340 of 1,405 for ROM. The source changes restore the five disk-write branch encodings and the target interrupt-mask policy. Three source files changed in P7. Against 2222, 19 of 242 staged source paths differ and 223 match.

P8 rebuilt disk reads and lock error handling in stage `io-27261-23275`. DISK2 retains both volume-label access checks while removing the local sharing retry and its callers. Its 605-byte code object matches 571 bytes at target offset 64,741. LOCKIO retains the 66-byte error routine and matches 64 bytes at target offset 70,754. The two other bytes are the near call displacement to HARDERR. Both object lengths match the target. Two source files changed in P8. Against 2222, 21 of 242 staged source paths differ and 221 match.

P9 rebuilt IOCTL, DINFO and DIRCALL in stage `io-28012-5041`. The respective target-sized code objects directly match 796 of 1,047 bytes at payload offset 44,206, 590 of 630 at 47,262, and 574 of 641 at 48,780. The original IOCTL jump table and shared entry labels are in place. Updates cover the generic handle failure return, the FSINFO early exits, and the directory error branches. Three source files changed in P9. Against 2222, 24 of 242 staged source paths differ and 218 match.

P10 rebuilt file deletion, opening and handle lookup in stage `io-28525-21373`. The target-sized DELETE, OPEN and HANDLE objects directly match 429 of 461 bytes at payload offset 45,253, 343 of 357 at 46,905, and 692 of 733 at 59,605. The final HANDLE return and the first instruction of the next object establish the boundary at 60,338. The former local share retries and owner test are removed from the original call paths. Three source files changed in P10. Against 2222, 27 of 242 staged source paths differ and 215 match.

P11 rebuilt file closes, renames and LFN directory removal in stage `io-29786-8721`. The CLOSE, RENAME and LFN objects directly match 384 of 413 bytes at payload offset 48,367, 584 of 624 at 45,714, and 378 of 404 at 62,968. Changes retain the existing access-date and commit entries, remove target-absent local sharing notifications, and restore the LFN bounds branch. The existing Installed assembly condition now compares explicitly with FALSE so MASM keeps the intended case when 386 instructions are selected. Three files changed in P11. Against 2222, 30 of 242 staged source paths differ and 212 match.

P12 rebuilt FCBIO and FCBIO2 in stage `io-30733-12799`. Both code objects have the target lengths and directly match 1,110 of 1,143 bytes at payload offset 41,946 and 279 of 292 at 43,089. The existing record-position and record-transfer interfaces now return the target unsupported-operation status. Device and volume-label handling remains in the original paths. Two source files changed in P12. Against 2222, 32 of 242 staged source paths differ and 210 match.

P13 linked the DOS 8 resident code at origin `3EA0h` in stage `io-31079-5250`. The offset is established independently from the linked target references to DOS_OPEN and DOS_CREATE. The assembled segment words, MSVERS and error-map prefix match the continuous 189-byte range at payload offset 34,352 byte for byte. The target dispatch code is split around this resident range, with the main INT 21h entry at payload offset 33,840 and the resident control and register helpers at 34,878. Two source includes changed in P13. Against 2222, 34 of 242 staged source paths differ and 208 match.

P14 rebuilt the split dispatcher in stage `io-32689-28567`. The linked COMMAND entry is at `3CA0h`. Its 512-byte region matches 510 target bytes at payload offset 33,840, with the two differing bytes in near-call displacements to LCritAll and DskStatChk. All 202 bytes of the resident helper block match at offset 34,878, including the default INT 24h handler at linked offset `412Dh`. The high block and interrupt entry are assembled from the original dispatcher source as separate objects in the historical link order. Six input files changed in P14. Against 2222, 39 of 242 staged paths differ and 203 match.

P15 rebuilt LOCK and SHARE in stage `io-525-18174`. Both code objects have the target lengths and directly match 94 of 103 bytes at payload offset 62,773 and 88 of 92 at 62,876. The legacy local sharing entry and retry routines have no remaining active callers. The network lock and existing error handling paths remain. Three files changed in P15. Against 2222, 41 of 242 staged paths differ and 201 match.
