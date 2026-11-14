Historical reconstruction plan. The current build and quality audit are in
[BUILD](BUILD.md) and [CURRENT](states/CURRENT.md); old script commands below
are retired records, not current instructions.

# MS-DOS 6.21 three-core reconstruction plan

The owner directs a binary-first reconstruction based on `v6.2`: identify differences in the target binaries, map them to source files, and process affected files in fixed order. Do not re-audit unchanged files from scratch. Store only changed source files in `v6.21`; metadata, tools and disposable builds live under `extras`. The baseline project is read-only.

- M0: fix image and reference hashes, inspect FAT12 without mounting, and freeze the source input inventory.
- M1: compare complete 6.20 and 6.21 system files and map changes to source.
- M2: handle the mapped source files in order; verify each change against the target.
- M3: create a clean temporary merged tree and build all three components; compare every byte with the extracted image files.

The selected image is truncated outside the three complete file chains. No computer use, SoftPC validation, image mounting, packaging or deployment is required. `D:/temp` and `D:/tempu` must not be used. Historical source provenance is recorded as evidence where available and uncertainty is not a blocker.
