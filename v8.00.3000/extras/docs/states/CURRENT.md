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
