# M6 T29 - Prepare the Windows Me core rebuild

## M6 T29 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner admitted preparation of v8.00.3000 under the established minimum source diff standard. |
| Objective | Freeze the 3000 targets and define the smallest source delta that can build all three core files exactly. |
| Non-goals | Other editions, duplicate implementations, target binary substitution, and guest execution. |
| Reference Baseline | Effective v7.10.2222 source at `0e557eb928f84339d1718c82e15fbfe163526aa8`, including its pinned source inputs, plus the Astro component references identified in the [source and binary comparison](../etc/decoded-comparison.md), and the [Windows Me startup floppy](../etc/target-baseline.json). |
| Candidate Proposal | Start with a source overlay and retain the inherited module layout. Retain the Astro directory and object structure for components whose implementation is identified in the target. |
| Files And ABI Surface | Boot container and loader, BIOS, DOS kernel, configuration, COMMAND and message resources. |
| Applicable Rules | [Execution](../../../../v7.10.1998/extras/docs/rules/EXECUTION.md) and [coding](../../../../v7.10.1998/extras/docs/rules/CODING.md). |
| Verification | Check target and baseline hashes and map exact matching binary ranges. During implementation, build from pinned source and compare every complete output with the floppy. |
| Expected Markers | Frozen SHA-256 values for all three targets. Final build requires three direct byte matches, matching SHA-256 and verified publication. |
| Asset Needs | Freeze targets in ignored extras/baselines/targets. Keep subsequent build evidence and published copies under the version extras tree. |
| Reporting Requirements | Report modified and identical source counts and distinguish packed bytes, linked code matches and completed products. |
| Stop Conditions | Do not infer source changes from compressed offsets. Investigate unexplained mismatches before publishing. |
| Exit Criteria | S1 prepares a verified target and source baseline with a block analysis. T29 closes after three exact products and a pushed closure audit. |
| Original Owner Request | Admit a new T to prepare the v8.00.3000 source. |
| Similar-Issue Sweep | Check version and copyright resources, and account for loader, compressed payload, and any appended IO.SYS sections separately. |

P1 freezes the OAK floppy targets, verifies the three 2222 product hashes, and records the [initial block comparison](../etc/block-baseline.md). Source changes: zero. Next work is to align the decoded IO.SYS payload with the 2222 linker map and align COMMAND ranges to the existing source modules.

P2 decodes the IO.SYS payload and localizes exact block reuse in the BIOS, DOS kernel, configuration manager and COMMAND. It records Astro as a component source baseline, with confirmed and prospective component mappings. No product source changed.
