# DOS 6.20 quality audit closure

M5 / T6 / S1 is verified and closed. This is the separate task-level acceptance
audit; historical reconstruction ledgers do not replace the quality ledger.

## Requirement-to-evidence audit

| Requirement | Current result and evidence |
| --- | --- |
| All assembly, nonassembly and scripts included | quality-final-ledger.json freezes 330 dispositions: 280 maintained and 50 retired. Core directories, excluded originals, research experiments, host tools, DOS scripts and executable configuration are included. Generated build stages and image-derived targets are not source. No unregistered code remains. |
| Maximize DOS 6.00 agreement | 225 core-tree files: 195 byte-identical to DOS 6.00 (190 original entries plus 5 restored files), 30 individually reviewed differences. Of those 30, 2 received original comment restoration and 28 were retained for target-required behavior/data. quality-audit-queue.json records each decision. |
| Preserve original structure, including empty branches | Original empty ELSE in sysconf.asm retained; unnecessary normalization of original repeated forms avoided. Required 6.20 changes remain in existing modules. The two source edits changed comments/alignment only; quality-audit-batch1.json records effective-content equality. |
| Original build form, without target patches | The three makefiles and tools.ini are byte-identical originals. build.bat invokes historical message tools and NMAKE; nosrv.bat supplies the original rule's command interface. build_three.py only stages, checks pinned tools, isolates execution and compares outputs. No target copying into outputs, byte patching, source substitution or fallback recipes. |
| Reduce autonomous duplication | Original 51 tooling entries: 5 modified, 4 retained unchanged, 42 retired. Twenty duplicate listing checkers consolidated into one read-only checker and interval data; equivalence and negative checks recorded. Eight completed COPY experiments retired. Forty excluded original files retained byte-identically. |
| Exact three-core binaries | quality-completion-check.json directly compares all three retained outputs with frozen targets and verifies source-image identity. IO.SYS 40566 bytes; MSDOS.SYS 38138; COMMAND.COM 54619. All exact. original-make-production-build.json records the successful source build and toolchain. |
| No unnecessary rebuild | All core/build inputs match the accepted build. Only runner C formatting and its helper's source-hash pin differ, with token/pin equivalence and unchanged executable established. No rebuild for this closure. |
| No PowerShell; isolated desktop only | No PowerShell files found, including ignored directories. Current scripts use Python, DOS batch and the private-desktop C launcher. No Computer Use or guest smoke test required. |
| Build outputs excluded from Git | Git confirms extras/build is ignored and no files beneath it are tracked. |
| Reproducible reporting | quality-final-ledger.json records current hashes and all dispositions; quality-current-status.json has no pending original tools or changed/missing entries. Build instructions are in states/BUILD.md. |

## Scope and provenance limits

The four message inputs are absent from the primary DOS 6.00 reference and are
not counted as original-identical. Target-derived text and descriptive symbols
remain reconstructed; the three required STUB tail bytes have unknown historical
origin. Exact binary identity does not establish historical source spelling.
These limitations are documented, not deferred quality tasks.

Added support is separately counted: five restored original core/build files,
four DOS build support files and two listing-checker files. Counts above do not
mix unchanged-to-reference with unchanged-during-audit.

There are no open quality-audit transfers or remaining implementation tasks.
Historical probes remain referenced by their evidence records; retired source
backups are disposable material under ignored extras/build. No commit, deployment
or release package was performed.
