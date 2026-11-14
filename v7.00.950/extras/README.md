# MS-DOS 7.0a reconstruction workspace

The version root contains the full maintained core source tree. Project
metadata, tooling, references and generated artifacts belong under `extras`.
The active MTSP task and acceptance evidence are in
[CURRENT.md](docs/states/CURRENT.md).

Run `extras\build.cmd` from the version root. This is the sole build entry;
it uses original DOS compilation tools, CMD/BAT and native C utilities.
See [build dependencies](docs/build-dependencies.md). Successful outputs are
published to `extras/assets` after all three pass exact comparisons.

Build stages and extracted verification targets are ignored. Historical
research reports preserve earlier reconstruction evidence; retired script
names are historical references, not runnable build instructions.
The toolchain migration records are under `docs/etc/toolchain-*`.

## Version-specific source policy

This tree reconstructs MS-DOS 7.0a only. DOS 6.22 is a reference baseline, not a
supported build target. Retain applicable feature conditions and follow the
established dependency order. Configuration and registry compilation units
are maintained as ordinary ASM source; no build-time source splitting,
merging, text replacement or target executable copying is used.

The configuration program uses `bios/config.mak`, `bios/config.lnk`, the
registered original CRT and original LINK /EXEPACK. The whole-core build also
includes the original registered boot graphic. Exact binary identity does
not claim original Microsoft source-text identity.
