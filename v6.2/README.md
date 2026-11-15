# MS-DOS 6.20

**The full 6.20 core, rebuilt for the US English startup floppy.**

The maintained tree follows DOS 6.00 conventions. It is the base for both the [6.21](../v6.21/extras/README.md) and [6.22](../v6.22/extras/README.md) builds, so start here to read the shared DOS 6.x implementation.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
```

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 40,566 |
| `MSDOS.SYS` | 38,138 |
| `COMMAND.COM` | 54,619 |

[Build guide](extras/docs/states/BUILD.md) · [Source audit](extras/docs/quality-audit-closure.md) · [Target manifest](extras/docs/etc/target-baseline.json)
