# M6 T28 closure audit

| Requirement | Disposition and evidence |
| --- | --- |
| Rebuild the Win98 SE core | S1 covers all three requested files. P1 froze the inputs, P2 recovered RTC and date changes, and P3 verified the finished implementation. S1 is closed with no open transfer. |
| Freeze the target media | The [target manifest](../etc/target-baseline.json) records the original floppy and SHA-256 for each extracted FAT12 file. |
| Minimize the mirror diff against 1998 | The [binary block analysis](../etc/block-baseline.md) shows the exact inherited blocks. The build uses only the source tree at v7.10.1998 commit `06366005ac97ac8c6a5f2c58f4b02825a88883a2` plus the SE overlay. Of 291 tracked baseline paths in bios, cmd, dos, inc and lang, 284 identical files were staged and seven were modified. The effective tree has zero additions and zero deletions. |
| Verify every product | `extras/build.cmd` exited 0 in stage `cmd-2557-8989`. Input snapshots matched. Full FC /B and SHA-256 checks passed, and all three published copies were independently compared with the extracted targets. |
| Retain build and publication evidence | The stage records `result.txt`, `inputs-before.txt`, `inputs-after.txt`, `outputs.sha256` and per-file comparison logs. The verified copies are in `extras/assets`. |
| Deliver incrementally | P1–P3 were pushed to main. The verified implementation is `ee962c1f4e42d122831a1ef1d8c0cf9dbea63da8`. This audit closes T28. |

## Modified baseline files

- `bios/msbio1.asm`
- `bios/mschar.asm`
- `bios/ststate.asm`
- `cmd/command/tparse.asm`
- `cmd/command/tspc.asm`
- `inc/parse.asm`
- `lang/usa/messages/comimsg.inc`

## Verified published files

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `IO.SYS` | 222390 | `2db8f238742c374f264ead1c44f87d69af42c24688a3a80f7d9657bc952d5d20` |
| `MSDOS.SYS` | 4 | `6f79be296fea04639aeb6c1d62657e4c9ee87ebfaf433548a23e2e022d9739f0` |
| `COMMAND.COM` | 93890 | `c3b5899620d6c58b90727b640bb7bb6a723f6013629c9459c241e9dc9e7ff20b` |
