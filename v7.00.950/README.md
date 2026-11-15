# MS-DOS 7.00.950 · Windows 95

**A full core source tree for the Windows 95 4.00.950 startup floppy.**

The reconstruction starts from [MS-DOS 6.22](../v6.22/extras/README.md). The long-filename interface and semantics were checked against Microsoft’s XP NTDOS guest sources. The accepted 4.00.950 floppy has a six-byte `MSDOS.SYS`. A separately surveyed Windows 95 boot disk has identical executables and a four-byte marker. Earlier reconstruction records may use the former directory name, `v7.0`.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
```

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 223,148 |
| `MSDOS.SYS` | 6 |
| `COMMAND.COM` | 92,870 |

[Build dependencies](extras/docs/build-dependencies.md) · [Binary verification](extras/docs/etc/toolchain-completion.json) · [Target manifest](extras/docs/target-baseline.json)
