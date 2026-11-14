# M6 T25 S1 P71: file 177

177 dos/handle.asm: accepted_modified. Complete effective v6.22 diff reviewed.
Retain shared return/error paths, explicit compare encodings, access-date
subfunctions and directory-entry date validation/flush handling. The existing
directory structures have no last-access-date member, so the 12h date offset
is not mislabeled with a different inherited field.

Normalize indentation of added date paths/validator and two return jumps.
Replace BYTE PTR ES:[bx+5],40h with ES:[bx].buf_flags,buf_dirty for the dirty
test and set. buffer.inc (included by dossym.inc) defines those exact values.
Keep the original write-time handling and 950 access-date implementation;
no second path or alternate implementation added.

Affected HANDLE rebuilt; kernel freshly linked unchanged against preceding
verified stage. IO.SYS freshly packed target-exact. Unaffected MSDOS.SYS and
COMMAND.COM inherited and compared target-exact. All 293 inputs match stage.
Evidence file177-build.txt and file177-make.txt.

Prefix 177/293: modified 91, exact 26, necessary unchanged 24, no same-name
reference unchanged 36; separate tool change 1. Next 178 dos/idle.asm.
Full clean build and completion audit remain pending.
