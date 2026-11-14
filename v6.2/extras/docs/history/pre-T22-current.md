# Build progress visibility

## M5 T10 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New, T10 follows closed T9
Admission And Approval | Owner requested visible activity for v5.0, v6.2, v6.21 and v6.22 builds
Objective | Visible host phases, hash progress, live isolated compiler phase and useful failure log pointers
Non-goals | No DOS source/instruction/recipe changes, no full DOS rebuild solely for presentation
Reference Baseline | Accepted per-version CMD builds and fixed three-core outputs
Candidate Proposal | Add CMD progress, DOS batch status markers, native C console/log heartbeat; update launcher pins
Files And ABI Surface | Four extras/build.cmd helpers, four DOS batches, four native launcher copies and host pin files
Applicable Rules | CMD/BAT/C only; no PowerShell, Computer Use or forbidden temp directories
Verification | Compare effective DOS commands before/after; native fixture tests; CMD helper probes; unchanged core inputs and assets
Expected Markers | Stage messages, every 25 hashes, current phase every 5 seconds, flushed console and host.log
Asset Needs | Existing isolated runner; fixture and compiler output in ignored project build directory
Reporting Requirements | Report changed files and unchanged core count; distinguish phase from percentage
Stop Conditions | Altered compiler command, wrong launcher hash, lost exit status or failed fixture
Exit Criteria | Four versions updated, progress and failure behavior verified, acceptance addendum recorded
Original Owner Request | Builds need visible output so the user knows they are working
Similar-Issue Sweep | Silent pre/post hashes, redirected native output, stale cached launcher, failure diagnostics

S1 and T10 closed after targeted verification. No active S remains. Prior completed status is in ../history/pre-T10-current.md.

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
