# M6 T26 S1 - Audit v7.10.1111 against v7.00.950

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner admitted a new T using only v7.00.950 as the audit baseline. |
| Objective | Remove avoidable 1111 differences in the original source paths and restore 950 structure, style and comments wherever the 1111 target permits. |
| Non-goals | Other DOS versions as evidence, parallel implementations, output patches, and guest execution. |
| Reference Baseline | 950 source and binary reference at `a99af370ce0432c0f0bca04c271c97c70b09a7e3`; 1111 source before edits at `db7ee2e`; byte acceptance from [frozen 1111 media](../etc/target-baseline.json). |
| Candidate Proposal | Read files in the frozen order. Accept exact files by byte comparison. For differences, trace edited code and data to corresponding linked regions; retain only changes with evidence. |
| Files And ABI Surface | Core source in bios, cmd, dos, inc, lang. Record each exact, reduced, retained, added or absent path. Keep demonstrated 1111 layout, interfaces and behavior. |
| Applicable Rules | [Coding](../rules/CODING.md), [execution](../rules/EXECUTION.md). Use inherited build tools and CMD/BAT/C build support. |
| Verification | For each assembler-affecting edit, build the affected component and directly compare its outputs. Review comment and formatting changes against emitted source statements. Clean builds verify all three products at delivery and closure. |
| Expected Markers | IO.SYS, MSDOS.SYS and COMMAND.COM show MATCH; input snapshot and publication pass. |
| Asset Needs | Verified binaries in extras/assets; frozen inputs remain in extras/baselines/targets. |
| Reporting Requirements | Report the current ordinal, files modified by this audit, files byte-identical to 950 and retained differences. Commit and push each verified P. |
| Stop Conditions | Reject edits that change frozen 1111 bytes or create another implementation of an existing path. |
| Exit Criteria | All 294 paths have a justified disposition, all three products match the targets, and the last P is pushed. |
| Original Owner Request | Use only v7.00.950 to audit and reduce v7.10.1111 differences in binary-corresponding source, code style and structure. |
| Similar-Issue Sweep | During each file review, check adjacent declarations, alternate entry points, duplicate implementations and equivalent statement forms. |

The inventory was frozen with `dir /a /b /s bios cmd dos inc lang` in each version root, filtering directory entries. The three 950-only entries were inserted at their 950 positions relative to common paths. Of 291 files present in 1111, 126 initially matched 950, 164 differed and one was added. See [ordered inventory](../etc/T26/inventory.csv), [reviewed files](../etc/T26/reviewed.csv) and [baseline evidence](../etc/T26/baseline.md).

T20 S4 is archived [here](../history/T20-S4.md). Its verified registry work is part of the production baseline.

P12 completed ordinals 164–182. Of 182 reviewed paths, 97 distinct source files were edited and 93 now match 950, including 37 made exact by audit edits. Continue with ordinal 183.

[Verified P12 build](../etc/T26/P12.md).
