# MS-DOS 8.00.3000 · Windows Me

**The Windows Me OAK boot core, reconstructed from loader to command prompt.**

The DOS core and startup build reuse the effective [Windows 98 SE tree](../../v7.10.2222/extras/README.md). The integrated HIMEM provider comes from the DOS 6.0 Astro source baseline. The native link includes the startup, registry, and resume code. The CM/DS packer recreates the on-disk `IO.SYS`, which also contains the DOS kernel. `MSDOS.SYS` is a four-byte text marker.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
extras\build.cmd io
```

The first command builds `COMMAND.COM`. The second builds `IO.SYS` and generates `MSDOS.SYS`.

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 116,736 |
| `MSDOS.SYS` | 4 |
| `COMMAND.COM` | 93,040 |

[Build and verification record](docs/states/CURRENT.md#m6-t29-closure) · [IO.SYS build baseline](docs/etc/io-build-baseline.md) · [Target manifest](docs/etc/target-baseline.json)
