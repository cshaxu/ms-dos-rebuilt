# M5 T11 completion audit

The audit treats completion as unproven until checked against the final tree.
The requested scope is the complete DOS 7.0a three-core toolchain migration.

| Requirement | Observed evidence | Result |
| --- | --- | --- |
| Sole extras/build.cmd entry | Hidden/ignored-inclusive inventory returned only extras/build.cmd | Pass |
| CMD/BAT/C and original DOS tools | Entry and tools inspected; historical executables, C headers and runtime pinned in tools.lst; BUILDMSG compiled by C 6.00 | Pass |
| No build-time source slicing, merging or text patching | Static BIOS/configuration units and ordinary make/link inputs are installed; native tools process message/OMF/container formats | Pass |
| Fresh source build | extras/build/cmd-2319-5304 built BIOS, kernel, COMMAND, all configuration units and CRT inputs without cached object inputs | Pass |
| Exact IO.SYS, MSDOS.SYS, COMMAND.COM | Fresh outputs and published extras/assets files independently compared with fixed targets using FC /B | Pass |
| Input stability | 334-file before/after snapshots are byte-identical | Pass |
| Visible progress | Eight phases and five-second native isolated-launcher status observed during the real build | Pass |
| Pause and exit status | Success paused and exited 0; actual failed build paused and exited 1 | Pass |
| Publication failure handling | Verbatim production publication block tested with read-only second output; all previous assets restored | Pass |
| Forbidden scripts/cache copies removed | 390 deleted; whole-tree hidden/ignored-inclusive suffix scan empty; no __pycache__ directories or archives found | Pass |
| File-level dispositions and counts | All 811 inventory entries resolved; toolchain-file-dispositions.json and completed queue agree | Pass |
| Build outputs ignored | git check-ignore confirms extras/build/cmd-2319-5304/result.txt | Pass |
| User execution restrictions | CMD execution and private-desktop compiler launch only; no Computer Use, PowerShell or D:/temp writes | Pass |
| Active documentation | Root README, extras README, build-dependencies.md and CURRENT describe the new sole entry | Pass |

Source counts against the frozen maintained DOS 7 baseline: 241 unchanged,
29 modified, 37 added, 88 retired through consolidation/renaming.
Tool counts: 2 modified, 22 added, 389 retired. Three graphic/resource files
are unchanged. The 390 forbidden files removed also include ignored cache
files outside the maintained-tool baseline; the tool retirement count includes
the duplicated BIOS message data include.

The earlier official-directory run failed because the new batch files used LF
line endings and CMD failed to resolve an existing label. CMD/BAT files were
converted to CRLF. The final full run completed all phases, snapshots,
comparisons, publication and pause. The source instructions were not changed
to address this host-script issue.

Historical component reports retain their original staged paths and status.
The current authoritative result is toolchain-completion.json. Exact binary
identity is not a claim of original Microsoft source-text identity.

No required work remains for M5 T11 S1.
