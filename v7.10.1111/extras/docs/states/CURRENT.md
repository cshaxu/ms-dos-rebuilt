# Owner priority change: DOS 5 audit

The owner admitted M6 T21 for v5.0. T20 S4 is deferred, not closed;
no active S remains in v7.10.1111. Its P1 byte-exact result remains valid.
The prior packet below is retained as a deferred handoff record; references
to active work in that packet no longer describe the current priority.

---

# M6 T20 - Registry reduction follow-up

The byte-exact reconstruction S1/S2/S3 remains verified. The owner reopened
source reduction against v7.00.950; this follow-up is not yet closed.

## M6 T20 S4 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | Owner-Reopen |
| Admission And Approval | Owner explicitly requested actual registry simplification, integration and all-three byte verification. |
| Objective | Reduce unnecessary implementation differences against 950 without altering 1111 outputs. |
| Non-goals | No formatting-only sweep, output patches, new second paths or other-version source references. |
| Reference Baseline | v7.00.950 and frozen 1111 targets. |
| Candidate Proposal | P1 implemented and verified; broader procedure reuse analysis remains active. |
| Files And ABI Surface | P1: bios/regread.asm; four instruction expressions in three existing procedures; ABI unchanged. |
| Applicable Rules | CODING.md; EXECUTION.md; owner requires Microsoft structure/style, CMD/BAT/C only and isolated execution. |
| Verification | Clean build cmd-14133-21559 returned zero; IO.SYS, MSDOS.SYS and COMMAND.COM MATCH; input snapshots match. |
| Expected Markers | All-three MATCH and publication PASS. |
| Asset Needs | Verified outputs published to extras/assets. |
| Reporting Requirements | P1 changes one source file; zero newly identical files. Whole core: 174 identical to 950, 116 modified, one added, three removed. |
| Stop Conditions | Reject any simplification that changes target bytes or introduces a second implementation. |
| Exit Criteria | Each retained source change has integrated build evidence; broader registry reduction needs a separate completion assessment. |
| Original Owner Request | Simplify registry against the original 950 implementation, integrate actual changes and verify all three outputs. |
| Similar-Issue Sweep | Examined explicit operand-size encodings in regstart/regopen/regfind/regread and configio; retain ES cases whose ordinary MASM encoding changes prefix order. |

P1 evidence: [registry reduction](../tracking/registry-reduction-2026-11-13.md).
Prior reconstruction closure: [T20-CLOSURE.md](../T20-CLOSURE.md).
