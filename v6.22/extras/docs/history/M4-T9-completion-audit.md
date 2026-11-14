# M4 T9 completion audit

Status: closed. Joint S1 covers v6.21 and v6.22. This separate task audit maps
the owner request to evidence. The sole packet is v6.21 CURRENT.

The owner requested original-tool source/build remediation and deletion of
all non-CMD/BAT/C scripts. Minimal source overlays are preserved.

Requirement | Result and evidence
--- | ---
Complete scope | Each 225-input merged tree classified in quality-source-audit.json; local file queues have no pending entries
Reference form | 6.21: 194 DOS6-identical, 29 inherited reviews, 2 local differences; 6.22: 193, 26, 6 respectively
Source preservation | No assembly instruction edits; original empty conditions and target-specific differences retained
Reduce duplication | Reference-identical 6.22 tcmd2a.asm removed; both versions depend directly on v6.20
Original tools | Three makefiles byte-identical to DOS6; pinned DOS MASM/NMAKE/LINK/message tools; no source or binary patches
CMD build | Both versions use identical host logic and DOS batch; only source/target manifests differ
Exact outputs | Both full builds exited zero; all six compiled files equal image-derived targets and published assets
Input integrity | All 238/242 before-and-after records match and remain unchanged after cleanup
Failure paths | Changed/missing/unlisted source, bad hash/output rejected; partial publication restored all previous assets
Script removal | 15 files removed in 6.21, 10 in 6.22; whole-tree scan including ignored work finds no forbidden scripts, archives or runtime calls
Git exclusions | Build and target directories ignored and untracked

Evidence files are under each extras/docs/etc. Accepted stages:
extras/build/cmd-13142-29453 (6.21) and cmd-13149-18182 (6.22).
IO/MSDOS/COMMAND sizes: 40566/38138/54619 for 6.21 and
40774/38138/54645 for 6.22. Hashes and paths: quality-build-acceptance.json.
Original target manifests remain unchanged.

Each version added ten build/manifest files and aligned one C tool with
reviewed v6.20 formatting. Local queues grew from 13 to 23 and 18 to 28,
including cached scripts. Five additional ignored Python copies were removed
from 6.21. quality-script-retirement.json records all deletion hashes.

The 225-file baseline matches the accepted v6.20 M5 T7 snapshot. Only
sysinit1.asm and sysinit2.asm differ from older overlay-era hashes; their
completed audit and full-build proof justify current baseline adoption.
Inherited reconstruction is not mislabeled as exact original source.

No in-scope transfer remains. Exact output applies to the selected three-core
configuration, not original source provenance or optional builds. Pinned local
tools and target extracts remain required. No image mount, SoftPC smoke test,
O:/DOS deployment, candidate archive or Git commit was performed. Removal
of unused scripts and documentation changes required no extra DOS build.
