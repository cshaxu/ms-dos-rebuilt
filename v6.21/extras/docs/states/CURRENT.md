# DOS 6.21 and 6.22 DOS6-only audit

## M4 T23 S2 Packet

Field | Required record
--- | ---
Identifier Mode | Continuation; T23 S1 verified and closed, S2 now active
Admission And Approval | Owner requests the same audit and repair for v6.21 and v6.22; autonomous execution authorized
Objective | Minimize unnecessary original-DOS6 source differences while preserving each version's exact three outputs and overlay layout
Non-goals | No full source copies, other DOS source references, cross-version binary comparisons, VM tests, worktrees, or unrelated source edits
Reference Baseline | Original v6.0 source only for quality; inherited v6.2 inputs reuse T22 evidence after hash verification; per-version frozen targets for output checks
Candidate Proposal | S1 audit v6.21; S2 audit v6.22; preserve local DIR order; reconcile only proven baseline pin changes; build and byte-compare each version
Files And ABI Surface | v6.21 two local overlay inputs; v6.22 six; each merges into 225 source/build inputs; existing extras/tools/dosbuild manifests and extras/build.cmd
Applicable Rules | Fixed DIR order; preserve original conditions and structure; CMD/BAT/C only; no PowerShell or Computer Use; no D:/temp or D:/tempu writes
Verification | Hash-check inherited T22 evidence; review each local difference; compile each edited file before advancing; verify three outputs against that version's own frozen targets
Expected Markers | Local ordinal/path/hash/reference/disposition, inherited coverage, exact three-target results and final completion audit
Asset Needs | Existing pinned original tools and isolated runner; ignored extras/build staging; extras/assets outputs
Reporting Requirements | Modified, DOS6-identical, necessary differences and missing-reference counts; distinguish local overlay and inherited scope
Stop Conditions | Unexplained input drift, compiler failure or output mismatch; repair before accepting file or publishing
Exit Criteria | Both 225-input merged scopes covered, all eight local inputs reviewed, manifest repairs verified, six outputs exact, separate completion audit
Original Owner Request | Prepare new T and audit/repair 6.21 and 6.22 to the same standard
Similar-Issue Sweep | Stale baseline pins after T22, redundant overlays, lost original branches, altered literals, second implementation paths and incorrect identity claims

S1 and S2 closed; T23 complete. No active S remains. This is the sole joint packet.
The v6.22 CURRENT file points here. Historical T9 packet archived separately.

## Frozen order and first review

Raw DIR outputs saved as etc/T23/dir-raw.txt in each version. Source order:

Version | Local ordinal | Path | State
--- | --- | --- | ---
6.21 | 1 | cmd/command/tcmd2a.asm | Reviewed: retain explicit minor version 21; no edit
6.21 | 2 | lang/usa/messages/comimsg.inc | Reviewed: no same-name DOS6 reference; retain original-format macro and target text
6.22 | 1 | bios/syspre.asm | Necessary differences retained
6.22 | 2 | cmd/command/cratio.asm | Original DOS6 comment restored; object/targets verified unchanged
6.22 | 3 | inc/copyrigh.inc | Required target year retained
6.22 | 4 | inc/versiona.inc | Required minor version retained
6.22 | 5 | lang/usa/messages/comimsg.inc | Accepted without same-name DOS6 reference
6.22 | 6 | lang/usa/messages/usa-ms-dos.msg | Accepted without same-name DOS6 reference

First file compared directly to v6.0/cmd/command/tcmd2a.asm: replaces XCHG
AH,AL with MOV AL,21 after clearing AH, so VER shows the required minor version.
Original labels, comments and surrounding instructions otherwise identical.
No needless structural difference identified. Local progress: 1/2, modified 0,
reference-identical 0, necessary difference 1. No fresh build claim yet.

Both existing builds use v6.2 baseline.lst plus overlay.lst. T22 changed four
inherited file hashes while preserving outputs. Verify old pins against T22
entry hashes and new pins against reviewed/build hashes before updating them;
do not suppress source-integrity checks or blindly re-pin all files.

## S1 verified completion

v6.21 baseline.lst repaired: four proven T22 hash updates, all 225 baseline
inputs checked against accepted T22 build. Fresh cmd-16751-1050 passed all
three target byte comparisons and published assets. 225 merged inputs verified
against the fresh build copy: 194 exact DOS6, 27 necessary differences, 4 without
same-name reference. Local source modifications 0; tooling files modified 1.
See etc/T23/S1-audit.md and retained build/hash evidence.

## S2 verified completion

All six local files audited in order; one source comment restored, two tooling
manifests repaired. Merged 225 inputs: 193 exact DOS6, 28 necessary differences,
4 without same-name reference. Local counts: modified 1, exact 0, retained
necessary 3, no reference 2. Structure unchanged.

cmd-17372-11632 compilation produced BUILD.OK=PASS but the runner timed out
waiting for exit. The original FAIL result remains evidence. Independent checks
validated all 241 source/tool snapshot records, all 225 effective input copies,
CRATIO.OBJ identity and all three compiled files against v6.22 targets. Existing
assets also match; no publication was required. This proves source/output
acceptance without claiming the automatic build invocation succeeded.

See v6.22 extras/docs/etc/T23/S2-audit.md and the joint completion audit at
history/M4-T23-completion-audit.md. All six version-specific asset comparisons
pass; no local file or audit verification remains pending.
