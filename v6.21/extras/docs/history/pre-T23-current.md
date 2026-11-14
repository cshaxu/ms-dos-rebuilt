# DOS 6.21 and 6.22 quality audit

## M4 T9 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; T9 follows closed T8; one joint S1 owns both versions
Admission And Approval | Owner explicitly requested the same source/tool remediation for 6.21 and 6.22 and deletion of all non-CMD/BAT/C scripts
Objective | Audited minimal source overlays; original DOS toolchain; pure CMD/BAT orchestration; exact three-core outputs per version
Non-goals | No full source duplication, other version edits, VM smoke tests, image mounts, archives or Git commits
Reference Baseline | Verified v6.20 M5 T7 source/tools; original DOS6 references; frozen per-version image extracts and mapping evidence
Candidate Proposal | Verify 225-file base; audit local overlays in order; remove redundant 6.22 overlay; migrate merge/check/build/publish into CMD manifests; remove obsolete scripts after verification
Files And ABI Surface | Both version file queues in extras/docs/etc/quality-audit-queue.json; baseline sources readonly, original conditions retained
Applicable Rules | Local four rules plus latest owner instructions; no PowerShell, Computer Use, D:/temp or D:/tempu
Verification | Source and tool hashes, exact overlay inventory, old-to-current baseline proof, two full builds, FC /B all six outputs, guard and publication failure tests
Expected Markers | No pending file; only CMD/BAT/C tooling; manual extras/build.cmd; exact outputs in each extras/assets
Asset Needs | Existing native private desktop runner, historical DOS tools and per-version fixed targets
Reporting Requirements | Modified versus reference-identical counts, inherited review reuse, ordered remaining units
Stop Conditions | Unexpected input drift or binary mismatch; resolve before publication
Exit Criteria | Both complete audits, original-tool CMD builds and exact assets; no other scripts/caches; separate T9 completion audit
Original Owner Request | Apply the same source and compiler-tool remediation to 6.21 and 6.22; delete all non-CMD/BAT/C scripts
Similar-Issue Sweep | Baseline hash drift, redundant overlays, implicit dependency on 6.21, old Python wrappers, ignored script copies, target substitution, rollback

S1 and T9 closed. No active S remains. This is the sole joint packet.
v6.22 CURRENT links here.
Historical source ledgers remain immutable; the new manifests explicitly adopt
the already-verified current 6.20 baseline. No source instruction edits planned.

## Verified completion

Both extras/build.cmd entries build directly from reviewed v6.2 sources plus
local manifests, with identical CMD logic and unchanged DOS6 makefiles.
All six compiled files match their fixed image extracts and are published
in each version extras/assets.

Version | DOS6 reference-identical | Inherited review reused | Local differences retained | Assembly changes this audit
--- | --- | --- | --- | ---
6.21 | 194 | 29 | 2 | 0
6.22 | 193 | 26 | 6 | 0

Each merged tree contains 225 source/build inputs. These counts distinguish
exact originals from reviewed reconstruction. The redundant 6.22 tcmd2a.asm
was identical to v6.2 and removed; 6.22 no longer depends on v6.21. Original
empty conditions and target differences remain intact.

Per version: 10 new build/manifest files, one C launcher format alignment,
no instruction changes. Script/cache deletions: 6.21 15 files; 6.22 10 files.
Final scans include ignored work and find no other scripts, script archives
or forbidden runtime calls. No pending local audit files remain.

Accepted runs: 6.21 extras/build/cmd-13142-29453 (238 input records),
6.22 extras/build/cmd-13149-18182 (242 records). All accepted hashes remain
unchanged after cleanup. No redundant rebuild was performed. Guards reject
changed/missing/unlisted sources, wrong hashes and outputs; partial publication
rollback restores all three previous files. Build and targets are ignored
and untracked. See ../BUILD.md, ../etc/quality-final-audit.json and
[separate task audit](../history/M4-T9-completion-audit.md).

Exact historical source wording and optional configurations are not implied
by the three-core output proof. No in-scope transfer remains.

## Build progress update: M5 T10 S1

Visible progress added across all four versions. See
../etc/build-progress-acceptance.json. This addendum supersedes earlier current
launcher/build-helper hash claims; the original DOS build evidence remains
valid because source and effective compiler commands are unchanged. Four
tooling files changed per version; no DOS source change or rebuild.

## Current build entry location

The only build.cmd is extras/build.cmd. The former root wrapper and tools
helper have been merged into it. Progress, pause, exit status and lock behavior
are preserved. See ../etc/build-entry-location.json. Historical manifests
retain old paths as evidence; this relocation addendum owns current paths.
