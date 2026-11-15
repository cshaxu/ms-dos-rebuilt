# MS-DOS 7.10.1111 · Windows 95 OSR2

**Follow FAT32 into the Windows 95 boot core.**

This full source tree starts from [7.00.950](../v7.00.950/README.md) and reproduces the three files from the Dell OEM OSR2 boot floppy. The changes can be followed through the existing startup, disk, and filesystem modules using the source audit.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
```

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 214,836 |
| `MSDOS.SYS` | 9 |
| `COMMAND.COM` | 93,812 |

[Build dependencies](extras/docs/build-dependencies.md) · [Source audit](extras/docs/states/CURRENT.md) · [Target manifest](extras/docs/etc/target-baseline.json)
