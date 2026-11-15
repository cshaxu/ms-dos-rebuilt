# MS-DOS 7.10.2222 · Windows 98 Second Edition

**Seven changed source files on the First Edition tree reproduce the Second Edition core.**

The build overlays [7.10.1998](../../v7.10.1998/README.md) at commit `0636600`. The changes cover BIOS startup and RTC handling, date parsing, and the copyright year. The closure audit lists all seven paths and records the three exact outputs.

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
| `COMMAND.COM` | 93,890 |

[Build, closure audit, and hashes](docs/states/T28-closure.md) · [Binary block comparison](docs/etc/block-baseline.md) · [Target manifest](docs/etc/target-baseline.json)
