# Later BIOS reference

`syspre.asm` is the DOS 6-era DBLSPACE loader previously retained in the
project BIOS directory. It emitted no code in the DOS 5 target build and is
kept here for historical comparison.

The removed DBLSPACE-only headers are in `inc/`; exact removed conditional
fragments are recorded in `docs/etc/evidence/m6-bios-dblspace-hooks-source.json`.

Unreferenced 1992 HIGHLOAD, HIGHVAR and HIGHEXIT headers are retained in
`inc/`; the current target build does not include them.
