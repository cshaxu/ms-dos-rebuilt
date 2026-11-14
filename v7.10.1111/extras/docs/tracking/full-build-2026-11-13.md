# Full build verification, 2026-11-13

Stage: `extras/build/cmd-4039-24987`.
Entry: `extras/build.cmd <nul` (the interactive entry retains its final pause).

This clean build assembles `bios/crtstart.asm` and links `crtstart.obj` in place
of the extracted runtime's `m0000.obj`. The source expresses the configuration
startup error callback as `__farstub`. The library extraction tool no longer
has `--dos-startup`, module-name-based external-symbol rewriting, or removal
of a selected CRT comment record. Ordinary library alias resolution remains.

All three full-length outputs passed FC /B against the frozen 1111 targets:

| Output | Bytes | SHA256 |
| --- | ---: | --- |
| IO.SYS | 214836 | 1a6ca94a7f3e5012e1bdcf696f5b48f644a7b64ab74b0a6693f971cff8769730 |
| MSDOS.SYS | 9 | 472fb39f336892336c6f34a0929d8c77dde16a98324ee9aff2118bab36a65852 |
| COMMAND.COM | 93812 | b4ba73da07374d504c426098566f4fc559580c84ae2465a827de57df4e23fddd |

The authoritative digest log is `outputs.sha256` in the stage. Input snapshots
before and after compilation matched. The build returned zero and published
all three verified files to `extras/assets`.

Retained evidence: `result.txt`, `outputs.sha256`, `inputs-before.txt`,
`inputs-after.txt`, `inputs-compare.log`, individual `*.compare.log`, and the
assembler listings/linker maps in the stage.

The core file inventory now contains 291 files: 174 byte-identical to 950,
116 modified, one added (`bios/crtstart.asm`); three baseline files were removed.
See `source-inventory-current.csv`. This is a source inventory, not a claim
that all text is original Microsoft source or that every file was compiled.

This report supersedes the earlier failed-build snapshot in this file.
Whole-image byte identity is verified; the completed task-wide source-reuse
and build-policy audit is recorded in `../T20-CLOSURE.md`. Historical partial function counts must
not be presented as the current binary completion state. The original target
has no complete symbol table, so its original function count remains unknown.

After this build, formatting was restored without changing effective source.
`post-build-format-check.log` compares all 291 current core files with this
stage: 223 byte-identical, 67 trailing whitespace/EOF-only, one indentation
and EOF-only. No repeat compilation was required for those changes.
