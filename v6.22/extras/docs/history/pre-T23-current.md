# DOS 6.22 quality audit complete

Joint M4 T9 S1 and T9 are closed. No active S remains. Sole packet:
[6.21 CURRENT](../../../../v6.21/extras/docs/states/CURRENT.md).

Run extras/build.cmd. Six local differences overlay verified v6.20 directly;
v6.21 is no longer a dependency. All three compiled files match the 6.22
target byte for byte and are published in extras/assets.

Of 225 merged inputs, 193 match DOS6 originals exactly, 26 reuse inherited
review and 6 are retained target differences. No assembly instructions changed;
one reference-identical overlay was removed. Ten build files were added,
one C tool aligned to reviewed baseline formatting, and ten scripts/cache
files deleted. No other script language remains, including ignored copies.
All 242 accepted input hashes remain unchanged after cleanup.
See [BUILD](../BUILD.md), [final audit](../etc/quality-final-audit.json) and
[task audit](../history/M4-T9-completion-audit.md).

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
