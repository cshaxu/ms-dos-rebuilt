# MS-DOS 7.00.950 core reconstruction

Full core source tree reconstructed from the verified MS-DOS 6.22 baseline.
IO.SYS (223148 bytes), MSDOS.SYS (6 bytes), and COMMAND.COM (92870 bytes)
have all been rebuilt and compared byte for byte with the accepted 4.00.950 boot-disk targets.
This directory was renamed from v7.0 to v7.00.950. Historical evidence retains
the original path names. The newly surveyed O:/assets/w9xbd disk has identical
executables but a four-byte MSDOS.SYS; the build's accepted six-byte configuration
has not been changed by the directory rename.
See [current evidence](extras/docs/etc/toolchain-completion.json).

From this directory, run:

```bat
extras\build.cmd
```

The sole entry uses CMD/BAT, original DOS NMAKE, MASM/ML, Microsoft C 6.00,
LINK/LIB and message tools, plus native C format utilities. It prevents
concurrent builds, prints phase progress and pauses on success or failure.
No Python, PowerShell, JavaScript or TypeScript runtime is required.

Each build creates a fresh `extras/build/cmd-*` directory containing linked
components, logs, input snapshots, output hashes and `result.txt`. All three
outputs must match before they are published to `extras/assets`.
It stops on build errors, binary differences, or changed source inputs.
Temporary files stay in the current build directory; historical GUI tools run on
an isolated desktop. No Computer Use or virtual-machine boot acceptance is used.

Historical toolchain locations and the frozen target files must be available;
see [build dependencies](extras/docs/build-dependencies.md). The build retains
a compatible historical CRT and the registered original non-executable boot
logo. Exact executable identity does not claim original Microsoft source-text
identity. Metadata, research and tooling live under [extras](extras/README.md).
Build outputs and extracted target files are ignored by Git.
