# DOS 7.0a toolchain remediation

M5 T11 S1 is complete. No successor task is admitted here.

The sole entry is `extras/build.cmd`. It uses CMD/BAT, original DOS tools and
native C utilities, reports progress, publishes to `extras/assets` only after
all three exact comparisons pass, and pauses at completion.

The final fresh build is `extras/build/cmd-2319-5304`. Its 334 input hashes
match before/after; IO.SYS (223148 bytes), MSDOS.SYS (6 bytes) and COMMAND.COM
(92870 bytes) match the fixed Win95 A targets. Success/failure pause and
publication rollback have been observed. No forbidden scripts or cache copies
remain, including ignored directories.

| File class | Unchanged | Modified | Added | Retired |
| --- | ---: | ---: | ---: | ---: |
| Core source/build inputs | 241 | 29 | 37 | 88 |
| Project tools/entry | 0 | 2 | 22 | 389 |
| Registered resources | 3 | 0 | 0 | 0 |

These identity counts compare the pre-migration maintained DOS 7 baseline,
not original DOS 6 text. All 811 entries have explicit dispositions.
390 forbidden script/cache files were deleted across the whole tree.

- [Completion evidence](../etc/toolchain-completion.json)
- [File-level dispositions](../etc/toolchain-file-dispositions.json)
- [Completed queue](../etc/toolchain-audit-queue.json)
- [Independent completion audit](../history/M5-T11-completion-audit.md)
- [Build dependencies](../build-dependencies.md)

Historical component records remain evidence of their individual stages.
The fixed source organization is now installed; runtime source rewriting and
the former Python build chain are retired.
