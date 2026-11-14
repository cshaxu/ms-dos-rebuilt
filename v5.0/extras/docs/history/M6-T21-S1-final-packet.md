# Current state: DOS 5 reference-difference audit

## M6 T21 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; global T21 follows T20. T20 S4 is deferred on owner reprioritization, not closed.
Admission And Approval | Owner explicitly admitted a new DOS5 task to audit every reference difference in fixed dir /a /b /s order.
Objective | Justify every DOS5 difference from OpenNT/DOS6/DOS4; align necessary differences with reference structure and style where safe; preserve binary output.
Non-goals | No other-version implementation work; no new second paths, output patches, VM acceptance, unrelated cleanup or commit.
Reference Baseline | v5.0 current source and frozen targets; OpenNT base/mvdm/dos/v86; archaeology v6.0 and v4.0/src. Reference hashes are frozen in the candidate manifest.
Candidate Proposal | Fixed 243-file queue; process one file at a time; per-hunk necessity/style decisions; compile and compare each changed file before advancing.
Files And ABI Surface | bios, cmd, dos, inc and messages: source, headers, message inputs and build recipes; extras and root metadata excluded with explicit scope.
Applicable Rules | Project rules and current owner overrides; CMD/BAT/C only; no Computer Use; no D:/temp or D:/tempu. Current per-change compilation overrides earlier format-only exemption.
Verification | Initial assets versus frozen targets: all three FC /B passed. Historical accepted build cmd-6108-11594 is evidence, not a new build. Each source edit requires affected compilation and byte comparison before advancement.
Expected Markers | Accepted queue prefix only; no unverified modified file; unchanged affected emitted code/data and linked component; all-three target match at integration checkpoints.
Asset Needs | Existing extras/baselines/targets and extras/assets; preserve target input files.
Reporting Requirements | Sequence, current file, modified count, reference-identical count, retained-necessary-diff count and remaining count. Classification is not completion.
Stop Conditions | Binary mismatch, changed frozen input, unresolved dependency or undocumented difference: retain current file as pending; do not skip ahead.
Exit Criteria | All 243 files disposed with valid hashes and reference/evidence links; every retained edit verified; separate task completion audit and all-three target comparison.
Original Owner Request | Audit all DOS5 differences from OpenNT/DOS6/DOS4 in dir /a /b /s order; compile affected scope for each changed file and prove no output change.
Similar-Issue Sweep | Follow the frozen order, never jump to another source file to repair an incidental finding; record later-file issues without editing them. NT/BOP or post-DOS5 content cannot pass merely through reference identity.

## Current progress

- Completed prefix: **243/243**. Modified: **20**. Reference-identical: **193**. Necessary differences retained: **30**.
- Current file: **243/243 all files disposed; completion audit pending**. Remaining: **0**.
- Latest ordered decisions: [file evidence](../etc/evidence/T21-243-usa-message.md).
- Latest verified build: cmd-32179-8869; all three targets MATCH; source matches staged input.
- Queue: [T21 file ledger](../etc/T21-file-ledger.csv). Initial SHA256 values remain frozen.
- References: [candidate hashes](../etc/T21-reference-candidates.csv).
- Initial classification: 193 identical and 50 differing; classification is not completed review.
- Prior per-file evidence is retained under ../etc/evidence/T21-*.

Prior v5 state: ../history/pre-M6-T21-current-state.md. T21 remains active.
