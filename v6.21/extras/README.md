# MS-DOS 6.21

**A compact source overlay that rebuilds the US English 6.21 floppy core.**

The build stages the sibling [6.20 tree](../../v6.2/README.md) and applies the 6.21 changes at their original source paths. The binary difference map connects the changed code to the floppy, making this a short route into what changed between the releases.

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

[Build guide](docs/BUILD.md) · [Binary difference map](docs/etc/binary-difference-map.json) · [Target manifest](docs/etc/target-baseline.json)
