# MS-DOS 5.00

**From boot sector handoff to the DOS prompt, in a DOS 6-style source tree.**

The reconstructed BIOS, kernel, and command interpreter match the selected 5.00 boot floppy. OpenNT’s DOS guest sources are a key reference alongside DOS 4 and DOS 6. Read `bios/` for startup, `dos/` for the kernel, and `cmd/command/` for the interpreter. Shared definitions and messages are in `inc/` and `messages/`.

## Build and verify

From the version directory in Windows CMD:

```bat
extras\build.cmd
```

Use the configured historical tools and extracted reference files in `extras/baselines/targets`. The build compares the outputs byte for byte and publishes verified copies to `extras/assets`.

| File | Verified bytes |
| --- | ---: |
| `IO.SYS` | 33,430 |
| `MSDOS.SYS` | 37,394 |
| `COMMAND.COM` | 47,845 |

[Build and tool requirements](extras/docs/etc/build-and-compare.md) · [Verification record](extras/docs/states/CURRENT.md)
