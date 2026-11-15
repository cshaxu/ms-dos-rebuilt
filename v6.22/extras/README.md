# MS-DOS 6.22

**The US English 6.22 floppy core, built directly on 6.20.**

The sibling [6.20 tree](../../v6.2/README.md) supplies the shared source. The overlay carries the 6.22 changes needed to reproduce its own startup floppy. You can build 6.22 as soon as the 6.20 source and tools are available.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
```

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 40,774 |
| `MSDOS.SYS` | 38,138 |
| `COMMAND.COM` | 54,645 |

[Build guide](docs/BUILD.md) · [Final build evidence](docs/etc/final-build-evidence.json) · [Target manifest](docs/etc/target-baseline.json)
