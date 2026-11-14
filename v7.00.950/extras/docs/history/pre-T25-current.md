# DOS 7.x 启动软盘基线与版本队列

## M6 T13 S1 Packet — deferred

Field | Required record
--- | ---
Identifier Mode | New; M5 T12 closed and archived in history/M5-T12-closed.md
Admission And Approval | Owner requested chronological DOS 7.0/7.1 reconstruction tasks, earliest 950 identity review, local E:/core/collection boot-floppy search, and numeric directory naming
Objective | Freeze boot-floppy identities, compare core groups and establish earliest 950 provenance before source changes
Non-goals | Installation CDs are not target substitutes; no VM boots, Computer Use, non-CMD/BAT/C toolchain, or edits to accepted core sources
Reference Baseline | Closed v7.00.950 acceptance; E:/core/collection/systems/x86_16_dos/msdos_7xx boot media
Candidate Proposal | M6 T13–T19 in dos7-task-queue.json; T13 deferred by owner-directed T20 admission; T15 superseded; sole active packet is v7.10.1111/extras/docs/states/CURRENT.md
Files And ABI Surface | extras/tools/fatcore.c; boot-version-survey.json; DOS7-VERSIONS.md; no core ABI changes
Applicable Rules | rules/EXECUTION.md, CODING.md, DOCUMENT.md and owner naming/boot-floppy instructions
Verification | FAT copies, cluster bounds/end/length, SHA256, direct byte comparison; no source rebuild for research
Expected Markers | Per-media identity with uncertainty; duplicate groups; explicit OSR attribution; source baseline selected by actual bytes
Asset Needs | Existing local boot images and boot-ISO floppy payloads; derived files stay in ignored extras/build/version-survey
Reporting Requirements | Source modified 0, source unchanged newly audited 0; research tool added 1 C file; 13 media, 5 executable pairs, 7 triples
Stop Conditions | Uncertain provenance remains explicit; do not label an image original or OSR-specific solely from filename/date/string
Exit Criteria | Earliest-950 attribution and requested release-to-floppy mappings verified or explicitly dispositioned; no unsupported equivalence claims
Original Owner Request | Reconstruct DOS variants from 95 OSR1/2/2.1/2.5 and 98 FE/SE; first identify boot floppies in local collection
Similar-Issue Sweep | Mislabelled FE/SE noram images, ISO wrappers, configurations vs executable revisions, language vs version differences

P1 completed the seven IMG and six boot-ISO sample survey. All extracted files have recorded sizes and hashes; six wrappers add no distinct triples. Current v7.00.950 equals 95a IMG (COMMAND string 4.00.950); this is not proof of earliest unmodified Microsoft provenance. Two noram labels contradict actual FE/SE core bytes. The extra 4.10.1998 pair needs language/revision attribution. OSR1/2.1/2.5 remain unidentified in the current boot sample set; do not claim absent.

Naming is v7.00.950, v7.10.1111, v7.10.1998, v7.10.2222, v8.00.3000. The existing source directory was renamed from v7.0 to v7.00.950 at the owner's explicit request. Windows component builds and A/B/C suffixes are not DOS build IDs. Same-build variant identity belongs in extras manifests.

Next: finish boot-media provenance/variant classification in T13 S1, then earliest-950 disposition; do not start several reconstruction branches. No new DOS source audits or rebuilds occurred.

- [Chronology, comparison and task plan](../design/DOS7-VERSIONS.md)
- [Media evidence](../etc/boot-version-survey.json)
- [T13–T19 queue](../etc/dos7-task-queue.json)


P2: Owner-selected O:/assets/w9xbd media surveyed; see ../design/W9XBD-BASELINE.md and ../etc/w9xbd-version-survey.json. Five images extracted and hashed. Eight comparable executables equal previous samples. The new 950 disk has a four-byte MSDOS.SYS; the accepted build still emits the historical six-byte configuration. This rename does not retarget configuration or binary acceptance.

Directory rename: O:/repos.hobby/ms-dos-rebuilt/v7.0 -> O:/repos.hobby/ms-dos-rebuilt/v7.00.950. Build entry derives ROOT from its own directory, so no build-script change is needed. Historical evidence and disposable build logs retain their original recorded paths. No DOS instruction changed and no rebuild was run.


## T20 admission transfer

Owner explicitly admitted M6 T20 for v7.10.1111 implementation. T13 unresolved provenance/variant classification is retained as deferred, not declared complete; it does not prevent use of the pinned and verified 950 source baseline. Planned T15 OSR2 work is superseded by T20. Sole active S now lives in ../../../../v7.10.1111/extras/docs/states/CURRENT.md. T20 follows the full-tree recommendation in ../design/950-1111-DIFF.md. No parallel active S is introduced.
