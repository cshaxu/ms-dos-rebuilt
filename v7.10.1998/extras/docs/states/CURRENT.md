# M6 T27 - Rebuild the Win98 First Edition core

## M6 T27 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner admitted the Win98 FE core rebuild. |
| Objective | Build IO.SYS, MSDOS.SYS and COMMAND.COM byte for byte against the frozen floppy. |
| Non-goals | Other DOS source versions, alternate implementations, output patches and guest execution. |
| Reference Baseline | v7.10.1111 commit 038583503f4954d7f6254b7cd5f0c83d529fce02; [frozen FE target](../etc/target-baseline.json). |
| Candidate Proposal | Full source tree from 1111. Reuse verified code blocks and modify the original modules in dependency order. |
| Files And ABI Surface | Loader, BIOS, DOS kernel, configuration and registry, COMMAND and their resource tables. |
| Applicable Rules | [Execution](../rules/EXECUTION.md) and [coding](../rules/CODING.md). |
| Verification | Map binary differences to linked code and resource blocks. Build using inherited tools. Verify and publish with full FC /B and SHA-256. |
| Expected Markers | MATCH for each core file, unchanged inputs and publication PASS. |
| Asset Needs | Frozen targets in ignored extras/baselines/targets; validated outputs in ignored extras/assets. |
| Reporting Requirements | Report actual changed and byte-identical source counts, component evidence and pushed P identifiers. |
| Stop Conditions | Reject target-byte regressions in verified blocks, output substitution and duplicate implementations. |
| Exit Criteria | All three official outputs match the frozen target and the closure is pushed. |
| Original Owner Request | Use 1111 alone to reconstruct the three Win98 FE core components, decide source layout after block diff, and submit and push in MTSP parts. |
| Similar-Issue Sweep | Check each mapped component for shared field, call-site, layout and resource changes. |

P1 freezes the target, records the [binary comparison](../etc/block-baseline.md), and seeds the full source and production build entry.

P1 build stage `cmd-30323-14713` produced the three files. MSDOS.SYS and all COMMAND resource bytes matched the FE target. COMMAND linked code and IO.SYS require further reconstruction. The publication gate remains in force.

P2 restores the five extra SYSINIT slots and localized text in the existing resource source. All 4767 bytes of the linked resource match the frozen FE block. The FE message slots shift later indices; call sites and the remaining BIOS layout are still under reconstruction. The bytes outside the resource remain subject to the complete-image gate.
