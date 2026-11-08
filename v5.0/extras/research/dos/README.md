# Earlier kernel investigation sources

This directory preserves the initial OpenNT import, intermediate recovery
slices and comparison experiments. It is not an input to the current kernel
build; similarly named files may differ from the verified sources.

The current kernel is in `../../dos/`, its shared includes are in `../../inc/`,
and the link order is in `../../dos/msdos.lnk`. See
`../../docs/states/CURRENT.md` for build evidence and limitations. Original
source provenance is not established by byte identity.

The `*.recovery.asm` files are research material, not additional link modules.
Older research scripts may still refer to the pre-migration `dos/` path; the
current build uses `tools/build_reconstructed_kernel.py` from the project root.

The imported OpenNT build files are preserved as `opennt.makefile` and
`opennt.make.inc`; they describe NTDOS and are not current build recipes.

`diskread.final-slice.asm` preserves the final unlinked DISKREAD recovery slice; its two procedures were already integrated into `dos/disk.asm`. The original ledger index and verification are in `../../docs/etc/evidence/file-review-068-diskread.json`.
