# M1 T2 S1 completion

Status: closed for the reference-input and dependency investigation described by the packet below. This closure does not claim that the complete 6.20 reconstruction or T2 as a whole is closed.

Exit evidence:

- [Reference dependency inventory](../etc/reference-dependency-inventory.json) records explicit includes, message candidates and known dynamic/conditional limits.
- [Local reference reproduction](../etc/local-baseline-reproduction.json) records matching 16 BIOS, 57 DOS and 35 COMMAND objects across the reference comparison builds, using provisional candidate messages. Those reference outputs did not equal the 6.20 targets.
- [Build guide](../states/BUILD.md) and [runner provenance](../etc/local-runner-provenance.json) document current fixed tools and selected project message inputs.
- Source attribution of the STUB tail remains open under [acceptance audit](../etc/acceptance-audit.json); this is transferred as a 6.20 reconstruction issue and is not resolved by this closure.

The dependency scan is conservative, and the baseline reproduction does not prove every conditional configuration. No additional component rebuild is implied by this administrative closure.

## M1 T2 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner-directed continuation of 6.20 reconstruction plan. |
| Objective | Determine DOS 6.0 three-core reference build inputs, message sources and toolchain candidates. |
| Non-goals | No 6.20 source qualification, runtime test, packaging or target identity claim. |
| Reference Baseline | Frozen DOS 6.0 candidate inventory, three retained DOS 6.20 target files. |
| Candidate Proposal | `../reconstruction-plan.md`, M1 T2 S1. |
| Files And ABI Surface | Read-only reference trees; dependency analysis tools and evidence under `extras/`. |
| Applicable Rules | Execution, architecture, coding and documentation; no Computer Use. |
| Verification | Reproducible inventory of explicit includes and message templates, pinned candidate tools; distinguish conditional/ambiguous/unresolved references. |
| Expected Markers | Source closure candidates, missing dependencies and message/toolchain evidence. |
| Asset Needs | Local DOS 6.0, DOS 4, OpenNT and v5.0 reference trees and local tools. |
| Reporting Requirements | Separate directly observed dependencies from inferred and version-unverified resource substitutes. |
| Stop Conditions | Reference mutation, unrecorded substitution or incompatible target changes. |
| Exit Criteria | Enumerated actual inputs and missing items sufficient to plan a 6.0 reference build; unresolved resource issues remain explicitly tracked. |
| Original Owner Request | Reconstruct three MS-DOS 6.20 core components with DOS 6.0 as basis. |
| Similar-Issue Sweep | BIOS loader and core, DOS and COMMAND links, includes and generated message classes. |
