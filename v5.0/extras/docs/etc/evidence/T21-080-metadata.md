# T21 file 80: COMMAND reconstruction metadata

This is project-authored Markdown, not Microsoft source. It has no reference
counterpart and belongs under extras by the owner's directory policy. Moved
cmd/command/RECONSTRUCTION.md to extras/docs/command-reconstruction.md and
corrected the build entry to v5.0/extras/build.cmd. Output location remains
extras/assets. Historical evidence references are retained with paths relative
to extras/docs. Historical records themselves are not rewritten.

The frozen queue keeps sequence 80 and raw dir position 90, plus the original
initial SHA256. Its path now names the current location; T21-relocations.csv
records the original path. The raw admission inventory and earlier proofs
still preserve the original path, so no file was dropped or re-sorted.

The original 243 queue entries now comprise 242 source/build/resource files
and this relocated metadata file. The full production build does not consume
this note. For audit-helper compatibility only, an evidence copy is placed in
the stage at its new path, outside compiler search roots. Production build.cmd
and original compiler recipes are unchanged. No replacement note or second
implementation remains in cmd/command.

Full build cmd-25422-19888 completed with exit code 0; all three outputs match
frozen targets and were published. All 34 COMMAND objects and COMMAND.COM
are unchanged (T21-080-object-compare.log). The 243-entry audit checker passes
with the relocated metadata snapshot included; compiler input snapshots before
and after build also match. The historical checker calls all entries "source",
but this record explicitly identifies the one metadata entry.

Prefix 80/243: 8 modified entries (7 source/build files plus 1 relocated note),
60 reference-identical, 12 necessary differences. Next: 81 resmsg.equ.
