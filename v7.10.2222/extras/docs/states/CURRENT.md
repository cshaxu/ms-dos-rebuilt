# M6 T28 - Rebuild the Win98 Second Edition core

## M6 T28 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner admitted the Win98 SE rebuild and specified minimum source diff against 1998. |
| Objective | Build IO.SYS, MSDOS.SYS and COMMAND.COM exactly from the 1998 source base plus the SE changes. |
| Non-goals | Other source baselines, duplicate implementations, output patches and guest execution. |
| Reference Baseline | v7.10.1998 commit 06366005ac97ac8c6a5f2c58f4b02825a88883a2 and the [frozen SE floppy](../etc/target-baseline.json). |
| Candidate Proposal | A source overlay. The [binary block analysis](../etc/block-baseline.md) identifies changes in BIOS and COMMAND and exact inherited blocks. |
| Files And ABI Surface | Inherited loader, BIOS, DOS kernel, configuration, COMMAND and message resources. |
| Applicable Rules | [Execution](../../../../v7.10.1998/extras/docs/rules/EXECUTION.md) and [coding](../../../../v7.10.1998/extras/docs/rules/CODING.md). |
| Verification | Build from the pinned Git tree and the overlay, compare all three products with the extracted floppy bytes and verify SHA-256. |
| Expected Markers | MATCH for the three files, unchanged build inputs, and publication PASS. |
| Asset Needs | Frozen files in ignored extras/baselines/targets and verified outputs in ignored extras/assets. |
| Reporting Requirements | Count actual modified and identical files against the frozen source, and report linked binary evidence and pushed parts. |
| Stop Conditions | Reject alternative implementations, output substitution, and unexplained differences in verified blocks. |
| Exit Criteria | Three exact products, verified publication, and a pushed closure audit. |
| Original Owner Request | Admit a new T to build v7.10.2222 from 1998 with the smallest source diff. |
| Similar-Issue Sweep | Check all linked callers and resource offsets affected by each binary delta. |

P1 freezes both baselines, selects the overlay, and restores the Windows build string in the inherited COMMAND source.

P2 reuses the RTC refresh routine, restores the SE BIOS flags and expands two-digit years in the existing SYSPARSE date path. Stage cmd-1022-3510 builds all three files. MSDOS.SYS matches. IO.SYS differs only at 13E2h and COMMAND.COM still has a one-byte length difference and linked operand differences.

P3 restores the SYSINIT load segment, the leading byte of the transient parser workspace and the copyright year in the inherited message source. Stage `cmd-2557-8989` exited 0, verified matching input snapshots, matched all three targets by direct byte comparison and SHA-256, and published the verified copies. The staged source tree has seven modified and 284 identical files out of 291 baseline paths.

P4 closes S1 and T28. See the [closure audit](T28-closure.md) for verification and source accounting.
