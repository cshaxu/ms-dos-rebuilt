# T26 baseline

- 950 source commit `a99af370ce0432c0f0bca04c271c97c70b09a7e3`, with no local changes in scope.
- 1111 starting tree recorded by `db7ee2e` and verified with `v7.10.1111\extras\build.cmd < nul` in stage `cmd-17500-10905`. The input snapshots matched. All three products matched by `fc /b` and were published.
- 1111 output SHA-256 values match the [frozen target manifest](../target-baseline.json).

| Product | 950 bytes | 1111 bytes | Initial binary comparison |
| --- | ---: | ---: | --- |
| IO.SYS | 223148 | 214836 | At least 131920 target bytes in 626 ordered matching runs. Linked configuration begins at 176640 in 950 and 187392 in 1111. |
| MSDOS.SYS | 6 | 9 | Disk text changes from `3b5359530d0a` to `3b5739354542440d0a`. |
| COMMAND.COM | 92870 | 93812 | At least 68730 target bytes in 273 ordered matching runs. Linked image begins at 16720 in 950 and 16992 in 1111. |

The matching runs are from [blockdiff.c](../../../tools/blockdiff.c), using unique 32-byte seeds, exact byte comparisons and ordered nonoverlap. Repeated data, short regions and relocated operands can fall outside the measured runs. These counts locate differences and do not measure source coverage.

950 reference SHA-256 values

- IO.SYS: `477eb53a2b3b81cefe58bcad409c682044e4ee4bf35dad678f80e1c5afbf35a5`
- MSDOS.SYS: `d28c3a421236bb61081f706193f51f32b9f8b957598d94b6b3b143ae52b1ea03`
- COMMAND.COM: `a74c700063cd6b1c91523952bfc80e9393c125d39ada0164d48b5098089fcef3`
