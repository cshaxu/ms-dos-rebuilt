# T21 file 7: bios/makefile

Status: modified and verified; build cmd-17396-11313 returned zero.

## Reference comparison and disposition

- DOS6 bios/makefile supplies the dependency/target form, link_opts macro,
  message-class target layout and BIOS module organization.
- DOS4 src/BIOS/MAKEFILE corroborates the multiline msload.obj dependency
  rule, makefile as a prerequisite, and the separate loader/BIOS concatenation.
- OpenNT doskrnl/bios/makefile explains the retained dosmac.inc repetition
  in msinit dependencies. Preserve it; NTIO, BOP/service headers, spc modules,
  binplace and NT symbol-generation rules do not belong in the DOS5 build.

Changes confined to this file:

1. Restore the DOS6 multi-line msbio.cl1 through msbio.cl9 target declaration.
   Retain the explicit original DOS nosrvbld invocation used by this build.
2. Restore `link_opts = /MAP` and use it in both link commands. Expanded
   compiler/link arguments remain unchanged.
3. Expand msload.obj prerequisites in reference style. Add makefile and the
   five omitted directly included headers bpb.inc, bootform.inc, dossym.inc,
   dosmac.inc, mult.inc. Evidence: msload.asm lines 37-43. Include path resolution
   selects common/bpb.inc and the DOS5 private bios/inc headers respectively.
   This prevents these direct edits from leaving an outdated loader object.
   It does not claim a complete transitive dependency audit of every rule.

Retained differences: fixed three-core target instead of DOS6 ROM/compressed/
distribution builds; DOS5 private include directory alongside shared headers;
selected OEMBASE assembly flags and warning level; DOS5 module list and link
order; explicit map filename retained for inspection; current DOS message
input name. Do not import DoubleSpace, syspre, ROM modules or NT host paths to
obtain superficial reference identity. Copyright header follows the existing
DOS4-style file rather than fabricating provenance.

## Validation

Run `extras/build.cmd <nul`, clean stage `extras/build/cmd-17396-11313`.
Direct FC /B comparisons against accepted cmd-6108-11594 passed for all 15 BIOS
objects (including optional POWER/PTIME) and msload.com, msbio.bin, IO.SYS.
The object files themselves match; no metadata exception was required.
See `T21-007-object-compare.log` for the finite object list.
The clean build returned zero, matched input snapshots, compared all three
final target files exactly and published successfully. File 8 is now admitted.

The initial source hash remains in T21-file-ledger.csv; the changed makefile
hash is recorded in this build's inputs-before.txt/inputs-after.txt.
