Historical reconstruction plan. The current build and quality audit are in
[BUILD](BUILD.md) and [CURRENT](states/CURRENT.md); old script commands below
are retired records, not current instructions.

# MS-DOS 6.22 reconstruction plan

Scope: reconstruct only IO.SYS, MSDOS.SYS, and COMMAND.COM as a source overlay on the frozen 6.21/6.20 source baselines. Keep project metadata, tools, targets, and generated builds under extras. Identify differences from the target binaries, modify the corresponding source files, and preserve the existing Microsoft source style.

Acceptance: hash and extract the target image without mounting; verify the complete input inventory and overlay; build all three components using the historical toolchain; compare each complete output byte-for-byte with its target. This acceptance has passed; the evidence is in [final-build-evidence.json](etc/final-build-evidence.json). Re-run after any future source or tool change.
