# M6 T27 closure audit

| Requirement | Disposition and evidence |
| --- | --- |
| Reconstruct the Win98 FE core | The sole S1 packet and P1–P23 history cover the three named files. No open S or transfer remains. |
| Freeze the original media and targets | The [target manifest](../etc/target-baseline.json) identifies the 1,474,560-byte FAT12 floppy. An independent FAT12 chain walk verified the image hash and compared the three extracted files directly with the frozen targets. |
| Choose the source layout after the binary comparison | The [ordered block comparison](../etc/block-baseline.md) records dispersed changes across the BIOS, kernel, configuration and COMMAND, with reusable loader and message regions. P1 seeded the complete source tree from v7.10.1111 commit `038583503f4954d7f6254b7cd5f0c83d529fce02`. |
| Reuse the inherited implementation | The frozen source universe is the 291 tracked paths in bios, cmd, dos, inc and lang. Git blob comparison with implementation commit `28792bc86480b837fc0585329b72a87b049b1cad` gives 255 identical and 36 modified, with zero additions and zero deletions. The boot, kernel and configuration changes use the inherited modules and entry points. |
| Verify three complete products | `v7.10.1998\extras\build.cmd` exited 0 in stage `cmd-30048-6604`. Input snapshots matched. The build performed full FC /B and SHA-256 verification of each file, followed by publication and byte comparison of every published copy. Independent comparison against the frozen targets confirmed all three published files. |
| Preserve build provenance and publish | The build entry, tool hash manifest, historical makefiles, linker inputs and object ordering are under the version tree. The build records `inputs-before.txt`, `inputs-after.txt`, `outputs.sha256`, the per-file comparison logs and `result.txt` in the named stage. Verified files are in `extras/assets`. |
| Submit and push incrementally | P1–P23 were pushed to main. P23 is the verified implementation commit. This audit closes S1 and T27. |

| Published file | Bytes | SHA-256 |
| --- | ---: | --- |
| `IO.SYS` | 222390 | `1c4b40d1743e3149d414fc8ee0ddf098686b74bda8f6fd2bf14b0def489b458a` |
| `MSDOS.SYS` | 4 | `6f79be296fea04639aeb6c1d62657e4c9ee87ebfaf433548a23e2e022d9739f0` |
| `COMMAND.COM` | 93880 | `48485a9b5d1e736edc46b896de6726160811aeee02d50e5a4df3c2a1c5a69bd7` |
