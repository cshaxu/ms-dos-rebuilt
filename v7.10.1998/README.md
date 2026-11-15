# MS-DOS 7.10.1998 · Windows 98 First Edition

**The First Edition floppy core, rebuilt from the Windows 95 OSR2 lineage.**

This full tree starts from [7.10.1111](../v7.10.1111/README.md). The changes span startup, registry configuration, and COMMAND. The closure audit traces them from the binary comparisons to the final build.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
```

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 222,390 |
| `MSDOS.SYS` | 4 |
| `COMMAND.COM` | 93,880 |

[Build and closure audit](extras/docs/states/T27-closure.md) · [Binary block comparison](extras/docs/etc/block-baseline.md) · [Target manifest](extras/docs/etc/target-baseline.json)
