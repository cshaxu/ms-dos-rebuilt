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
